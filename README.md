# Docker USB Camera RTMP Streaming Server

在 Arch Linux 下基于 Docker 的本地 USB 摄像头 RTMP 推流服务器，支持 HLS Web 实时预览。

## 功能

- V4L2 摄像头自动检测与采集
- libx264 软件编码，无硬件依赖
- RTMP 推流至本地 Nginx 服务端，同时支持外部 RTMP 目标
- HLS 实时预览页面，支持移动端浏览器
- 自动重连、健康检查

## 快速开始

```bash
# 克隆项目
git clone https://github.com/TS137/docker_usb.git
cd docker_usb

# 运行设置脚本
chmod +x setup.sh
./setup.sh
```

Web 预览页面将在 `http://localhost:8080` 可用。

## 手动配置

```bash
# 复制配置模板
cp .env.example .env

# 编辑配置（修改摄像头设备、分辨率等）
vim .env

# 构建并启动
docker compose up -d
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CAMERA_DEVICE` | `/dev/video0` | 摄像头设备路径 |
| `RESOLUTION` | `1280x720` | 采集分辨率 |
| `FRAMERATE` | `30` | 采集帧率 |
| `BITRATE` | `2000k` | 视频码率 |
| `RTMP_TARGET` | `rtmp://nginx-rtmp:1935/live/stream` | 本地推流地址 |
| `EXTRA_RTMP_TARGET` | (空) | 外部 RTMP 推流地址 |
| `NGINX_HTTP_PORT` | `8080` | Web 预览端口 |
| `NGINX_RTMP_PORT` | `1935` | RTMP 接收端口 |

## 前置依赖

- Docker
- Docker Compose
- USB 摄像头 (UVC 兼容)

```bash
# Arch Linux 安装 Docker
sudo pacman -S docker docker-compose
sudo systemctl enable --now docker
```

## 目录结构

```
.
├── docker-compose.yml    # 服务编排
├── .env.example          # 配置模板
├── setup.sh              # 一键部署脚本
├── entrypoint.sh         # 采集容器入口脚本
├── Dockerfile.camera     # FFmpeg 采集编码镜像
├── Dockerfile.nginx      # Nginx RTMP 镜像
├── nginx.conf            # Nginx RTMP + HLS 配置
├── web/index.html        # HLS 预览页面
└── README.md
```

## 常用命令

```bash
# 查看日志
docker compose logs -f

# 停止服务
docker compose down

# 重启
docker compose restart
```
