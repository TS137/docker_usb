#!/usr/bin/env bash
set -euo pipefail

RTMP_TARGET="${RTMP_TARGET:-rtmp://nginx-rtmp:1935/live/stream}"
EXTRA_RTMP_TARGET="${EXTRA_RTMP_TARGET:-}"
CAMERA_DEVICE="${CAMERA_DEVICE:-/dev/video0}"
RESOLUTION="${RESOLUTION:-1280x720}"
FRAMERATE="${FRAMERATE:-30}"
BITRATE="${BITRATE:-2000k}"

# Wait for Nginx RTMP to be ready
echo "[camera-streamer] Waiting for RTMP server at ${RTMP_TARGET}..."
until nc -z nginx-rtmp 1935 2>/dev/null; do
    echo "[camera-streamer] RTMP server not ready, retrying..."
    sleep 2
done

echo "[camera-streamer] RTMP server ready. Starting capture and encoding..."

# Calculate GOP: keyframe every 2 seconds to ensure 3s HLS segments align properly
GOP=$((FRAMERATE * 2))

if [ -n "${EXTRA_RTMP_TARGET}" ]; then
    echo "[camera-streamer] Also pushing to external target: ${EXTRA_RTMP_TARGET}"

    # Use tee muxer to output to both RTMP targets from a single camera capture
    ffmpeg \
        -f v4l2 \
        -input_format mjpeg \
        -video_size "${RESOLUTION}" \
        -framerate "${FRAMERATE}" \
        -i "${CAMERA_DEVICE}" \
        -c:v libx264 \
        -preset veryfast \
        -tune zerolatency \
        -g "${GOP}" \
        -keyint_min "${GOP}" \
        -sc_threshold 0 \
        -b:v "${BITRATE}" \
        -an \
        -f tee \
        -map 0:v \
        "[f=flv:flvflags=no_duration_filesize]${RTMP_TARGET}|[f=flv:flvflags=no_duration_filesize]${EXTRA_RTMP_TARGET}"
else
    ffmpeg \
        -f v4l2 \
        -input_format mjpeg \
        -video_size "${RESOLUTION}" \
        -framerate "${FRAMERATE}" \
        -i "${CAMERA_DEVICE}" \
        -c:v libx264 \
        -preset veryfast \
        -tune zerolatency \
        -g "${GOP}" \
        -keyint_min "${GOP}" \
        -sc_threshold 0 \
        -b:v "${BITRATE}" \
        -an \
        -f flv \
        -flvflags no_duration_filesize \
        "${RTMP_TARGET}"
fi
