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
until ffprobe -v quiet -timeout 2000000 -rtsp_transport tcp "${RTMP_TARGET}" 2>/dev/null || \
      nc -z nginx-rtmp 1935 2>/dev/null; do
    echo "[camera-streamer] RTMP server not ready, retrying..."
    sleep 2
done

echo "[camera-streamer] RTMP server ready. Starting capture and encoding..."

RTMP_URLS="${RTMP_TARGET}"
if [ -n "${EXTRA_RTMP_TARGET}" ]; then
    RTMP_URLS="${RTMP_TARGET}|${EXTRA_RTMP_TARGET}"
    echo "[camera-streamer] Also pushing to external target: ${EXTRA_RTMP_TARGET}"
fi

ffmpeg \
    -f v4l2 \
    -input_format mjpeg \
    -video_size "${RESOLUTION}" \
    -framerate "${FRAMERATE}" \
    -i "${CAMERA_DEVICE}" \
    -c:v libx264 \
    -preset veryfast \
    -tune zerolatency \
    -b:v "${BITRATE}" \
    -an \
    -f flv \
    -flvflags no_duration_filesize \
    "${RTMP_TARGET}" &

FFMPEG_PID=$!

if [ -n "${EXTRA_RTMP_TARGET}" ]; then
    ffmpeg \
        -f v4l2 \
        -input_format mjpeg \
        -video_size "${RESOLUTION}" \
        -framerate "${FRAMERATE}" \
        -i "${CAMERA_DEVICE}" \
        -c:v libx264 \
        -preset veryfast \
        -tune zerolatency \
        -b:v "${BITRATE}" \
        -an \
        -f flv \
        -flvflags no_duration_filesize \
        "${EXTRA_RTMP_TARGET}" &
    EXTRA_PID=$!
    wait $FFMPEG_PID $EXTRA_PID
else
    wait $FFMPEG_PID
fi
