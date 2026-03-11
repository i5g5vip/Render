#!/bin/sh

# TrustTunnel 卸载脚本
set -u

# 定义颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # 无颜色

log() {
  echo "[INFO] $1"
}

error_exit() {
  echo "${RED}[ERROR] $1${NC}" 1>&2
  exit 1
}

# 默认安装路径与安装脚本保持一致
INSTALL_DIR="/opt/trusttunnel"
SYSTEMD_PATH="/etc/systemd/system/trusttunnel.service"

# 解析参数，允许用户通过 -o 指定不同的安装目录
while getopts 'o:h' opt "$@"; do
  case "$opt" in
    'o') INSTALL_DIR="$OPTARG" ;;
    'h')
      echo "用法: ./uninstall.sh [-o output_dir]"
      exit 0
      ;;
    *) exit 1 ;;
  esac
done

# 检查是否为 root 权限，因为涉及停止服务和删除 /opt 文件
if [ "$(id -u)" != "0" ]; then
  error_exit "请使用 sudo 或 root 权限运行此脚本。"
fi

echo "============================================================"
echo "          正在卸载 TrustTunnel Endpoint..."
echo "============================================================"

# 1. 停止并禁用 Systemd 服务
if [ -f "$SYSTEMD_PATH" ]; then
  log "发现 Systemd 服务，正在停止并清理..."
  systemctl stop trusttunnel.service 2>/dev/null || true
  systemctl disable trusttunnel.service 2>/dev/null || true
  rm -f "$SYSTEMD_PATH"
  systemctl daemon-reload
  log "Systemd 服务已移除。"
fi

# 2. 停止运行中的进程（双重保险）
if pgrep -x "trusttunnel_endpoint" > /dev/null; then
  log "正在终止运行中的 trusttunnel_endpoint 进程..."
  pkill -9 -x "trusttunnel_endpoint"
fi

# 3. 删除安装目录
if [ -d "$INSTALL_DIR" ]; then
  log "正在从 '$INSTALL_DIR' 删除文件..."
  # 删除安装脚本中提到的特定文件
  rm -f "$INSTALL_DIR/trusttunnel_endpoint"
  rm -f "$INSTALL_DIR/setup_wizard"
  rm -f "$INSTALL_DIR/trusttunnel.service.template"
  rm -f "$INSTALL_DIR/LICENSE"
  
  # 尝试删除整个目录（如果目录中还有用户配置文件，此处可根据需求选择是否 rm -rf）
  # 为了彻底卸载，这里使用 rm -rf
  rm -rf "$INSTALL_DIR"
  log "安装目录 '$INSTALL_DIR' 已清理。"
else
  log "未发现安装目录 '$INSTALL_DIR'，跳过此步。"
fi

echo "============================================================"
echo "  ${GREEN}TrustTunnel 已成功从系统中移除。${NC}"
echo "============================================================"
