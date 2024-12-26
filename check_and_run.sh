#!/bin/bash

# 自动化配置Nginx并设置HKDVB直播源

set -e

# 检查是否为root用户
if [ "$(id -u)" -ne 0 ]; then
  echo "请使用root用户或使用sudo执行此脚本。"
  exit 1
fi

# 需要检查和下载的脚本文件URL和路径
SCRIPT_URL="https://raw.githubusercontent.com/tmxk2021/CF-IPTV/master/setup_hkdvb.sh"
SCRIPT_PATH="/root/setup_hkdvb.sh"

# 检查脚本文件是否存在
if [ -f "$SCRIPT_PATH" ]; then
  echo "脚本文件已存在，直接赋予执行权限并执行..."
  chmod +x "$SCRIPT_PATH"
else
  echo "脚本文件不存在，正在下载..."
  curl -o "$SCRIPT_PATH" "$SCRIPT_URL"
  chmod +x "$SCRIPT_PATH"
  echo "脚本文件已下载并赋予执行权限。"
fi

# 运行脚本
echo "正在运行脚本..."
"$SCRIPT_PATH"

# 结束
echo "脚本执行完毕。"
