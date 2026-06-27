#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================="
echo "  USB Camera RTMP Streaming Server Setup"
echo "========================================="
echo ""

# Check Docker
if ! command -v docker &>/dev/null; then
    echo "[ERROR] Docker is not installed."
    echo "  Install: sudo pacman -S docker"
    echo "  Start:   sudo systemctl enable --now docker"
    exit 1
fi

# Check Docker Compose
COMPOSE_CMD=""
if docker compose version &>/dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &>/dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "[ERROR] Docker Compose is not installed."
    echo "  Install: sudo pacman -S docker-compose"
    exit 1
fi

# Detect cameras
echo "[INFO] Detecting camera devices..."
CAMERAS=$(ls /dev/video* 2>/dev/null || true)
if [ -z "$CAMERAS" ]; then
    echo "[ERROR] No camera device found (/dev/video*)."
    echo "  Ensure a USB camera is connected."
    exit 1
fi

echo "[INFO] Available cameras:"
echo "$CAMERAS" | while read -r dev; do
    V4L_INFO=$(v4l2-ctl -d "$dev" -D 2>/dev/null | grep "Driver name\|Card type" | tr '\n' ' ' || echo "Unknown")
    echo "  $dev - $V4L_INFO"
done

# Select camera
DEFAULT_CAMERA=$(echo "$CAMERAS" | head -1)
echo ""
read -r -p "Camera device [$DEFAULT_CAMERA]: " SELECTED_CAMERA
SELECTED_CAMERA="${SELECTED_CAMERA:-$DEFAULT_CAMERA}"

# Select resolution
echo ""
echo "Select resolution:"
echo "  1) 1920x1080 (1080p)"
echo "  2) 1280x720  (720p) [default]"
echo "  3) 640x480   (480p)"
read -r -p "Choice [2]: " RES_CHOICE
case "${RES_CHOICE:-2}" in
    1) RESOLUTION="1920x1080" ;;
    2) RESOLUTION="1280x720" ;;
    3) RESOLUTION="640x480" ;;
    *) RESOLUTION="1280x720" ;;
esac

# Select framerate
echo ""
read -r -p "Framerate [30]: " FRAMERATE
FRAMERATE="${FRAMERATE:-30}"

# Select bitrate
echo ""
echo "Select bitrate:"
echo "  1) 1000k (low)"
echo "  2) 2000k (medium) [default]"
echo "  3) 4000k (high)"
read -r -p "Choice [2]: " BR_CHOICE
case "${BR_CHOICE:-2}" in
    1) BITRATE="1000k" ;;
    2) BITRATE="2000k" ;;
    3) BITRATE="4000k" ;;
    *) BITRATE="2000k" ;;
esac

# External RTMP target
echo ""
read -r -p "External RTMP target (empty to skip): " EXTRA_RTMP_TARGET

# Ports
echo ""
read -r -p "HTTP preview port [8080]: " NGINX_HTTP_PORT
NGINX_HTTP_PORT="${NGINX_HTTP_PORT:-8080}"

read -r -p "RTMP ingest port [1935]: " NGINX_RTMP_PORT
NGINX_RTMP_PORT="${NGINX_RTMP_PORT:-1935}"

# Generate .env
echo ""
echo "[INFO] Generating .env configuration..."

cat > .env <<EOF
CAMERA_DEVICE=$SELECTED_CAMERA
RESOLUTION=$RESOLUTION
FRAMERATE=$FRAMERATE
BITRATE=$BITRATE
RTMP_TARGET=rtmp://nginx-rtmp:1935/live/stream
EXTRA_RTMP_TARGET=$EXTRA_RTMP_TARGET
NGINX_HTTP_PORT=$NGINX_HTTP_PORT
NGINX_RTMP_PORT=$NGINX_RTMP_PORT
EOF

echo "[INFO] Configuration saved to .env"
echo ""

# Build and start
echo "[INFO] Building Docker images..."
$COMPOSE_CMD build

echo ""
echo "[INFO] Starting services..."
$COMPOSE_CMD up -d

echo ""
echo "========================================="
echo "  Server is starting!"
echo "  Web preview: http://localhost:${NGINX_HTTP_PORT}"
echo "  RTMP ingest: rtmp://localhost:${NGINX_RTMP_PORT}/live/stream"
echo "========================================="
echo ""
echo "Commands:"
echo "  View logs:  $COMPOSE_CMD logs -f"
echo "  Stop:       $COMPOSE_CMD down"
echo "  Restart:    $COMPOSE_CMD restart"
