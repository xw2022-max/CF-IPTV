#!/bin/bash

# 自动化配置Nginx并设置HKDVB直播源
set -e

CONFIG_FILE="/etc/setup_hkdvb.conf"

# 检查是否为root用户
if [ "$(id -u)" -ne 0 ]; then
  echo "请使用root用户或使用sudo执行此脚本。"
  exit 1
fi

# 读取或输入配置
if [ -f "$CONFIG_FILE" ]; then
  echo "检测到已有配置文件：$CONFIG_FILE"
  source "$CONFIG_FILE"
  echo "当前配置为："
  echo "HKDVB_TOKEN: $HKDVB_TOKEN"
  echo "SERVER_IP: $SERVER_IP"
  echo "FEIYANG_IP: $FEIYANG_IP"

  # 提示用户是否修改配置
  echo -n "是否修改配置？(y/n，10秒内未选择将默认使用当前配置): "
  
  # 使用timeout命令设置超时
  read -t 10 choice || choice="n"  # 如果没有输入，默认选择 n

  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "请输入您的HKDVB直播源token（通过Telegram联系@hkanime_bot获取，按回车跳过）："
    read -r HKDVB_TOKEN
    echo "请输入您的服务器IP地址（此项必须提供）："
    read -r SERVER_IP
    if [ -z "$SERVER_IP" ]; then
      echo "服务器IP地址未提供，脚本停止运行。"
      exit 1
    fi
    echo "如果您需要使用肥羊IP，请输入肥羊IP（直接按回车可跳过）："
    read -r FEIYANG_IP

    # 如果未提供肥羊IP，则默认使用SERVER_IP
    [ -z "$FEIYANG_IP" ] && FEIYANG_IP="$SERVER_IP"

    # 保存配置
    cat > "$CONFIG_FILE" << EOF
HKDVB_TOKEN="$HKDVB_TOKEN"
SERVER_IP="$SERVER_IP"
FEIYANG_IP="$FEIYANG_IP"
EOF
    echo "配置已保存到 $CONFIG_FILE"
  else
    echo "使用记录的配置运行脚本..."
  fi
else
  echo "未检测到配置文件，需要输入初始配置..."
  echo "请输入您的HKDVB直播源token（通过Telegram联系@hkanime_bot获取，按回车跳过）："
  read -r HKDVB_TOKEN
  echo "请输入您的服务器IP地址（此项必须提供）："
  read -r SERVER_IP
  if [ -z "$SERVER_IP" ]; then
    echo "服务器IP地址未提供，脚本停止运行。"
    exit 1
  fi
  echo "如果您需要使用肥羊IP，请输入肥羊IP（直接按回车可跳过）："
  read -r FEIYANG_IP

  # 如果未提供肥羊IP，则默认使用SERVER_IP
  [ -z "$FEIYANG_IP" ] && FEIYANG_IP="$SERVER_IP"

  # 保存配置
  cat > "$CONFIG_FILE" << EOF
HKDVB_TOKEN="$HKDVB_TOKEN"
SERVER_IP="$SERVER_IP"
FEIYANG_IP="$FEIYANG_IP"
EOF
  echo "配置已保存到 $CONFIG_FILE"
fi

# 输出确认
echo "HKDVB_TOKEN: $HKDVB_TOKEN"
echo "SERVER_IP: $SERVER_IP"
echo "FEIYANG_IP: $FEIYANG_IP"

# 以下是脚本原有的功能部分
# 安装Nginx（幂等性）
echo "检查Nginx是否已安装..."
if ! command -v nginx &> /dev/null; then
  echo "Nginx未安装，开始安装..."
  sudo apt update && sudo apt install -y nginx
else
  echo "Nginx已安装，跳过安装步骤。"
fi

# 下载并替换Nginx配置文件（强制替换）
NGINX_CONF_URL="https://raw.githubusercontent.com/rad168/iptv/refs/heads/main/mytv/nginx.conf"
NGINX_CONF_PATH="/etc/nginx/nginx.conf"
echo "下载并强制替换Nginx配置文件..."
curl -o "$NGINX_CONF_PATH" "$NGINX_CONF_URL"

# 配置Nginx监听80端口（避免重复添加）
if ! grep -q "server_name $SERVER_IP;" "$NGINX_CONF_PATH"; then
  echo "添加Nginx监听80端口的配置..."
  sed -i "/http {/a \\
      server { \\
          listen 80; \\
          server_name $SERVER_IP; \\
          location / { \\
              root /var/www/html; \\
              index index.html index.htm; \\
          } \\
          location /mytv.m3u { \\
              root /var/www/html; \\
              default_type application/octet-stream; \\
              allow all; \\
          } \\
      }" "$NGINX_CONF_PATH"
else
  echo "Nginx配置中已包含相关设置，跳过修改。"
fi

# 重启Nginx
echo "重启Nginx服务..."
sudo systemctl restart nginx

# 下载并修改M3U文件（强制替换）
M3U_URL="https://raw.githubusercontent.com/tmxk2021/CF-IPTV/refs/heads/main/mytv.m3u"
M3U_PATH="/var/www/html/mytv.m3u"
echo "下载并强制替换M3U文件..."
curl -o "$M3U_PATH" "$M3U_URL"
echo "修改M3U文件中的服务器IP和token..."
sed -i "s/服务器ip/$SERVER_IP/g" "$M3U_PATH"
sed -i "s/你的token/$HKDVB_TOKEN/g" "$M3U_PATH"
sed -i "s/肥羊IP/$FEIYANG_IP/g" "$M3U_PATH"

# 修改/etc/hosts，避免重复添加
HOSTS_FILE="/etc/hosts"
EDGE_IP="172.67.178.1"
EDGE_DOMAIN="edge3.hkdvb.com"
if ! grep -q "$EDGE_DOMAIN" "$HOSTS_FILE"; then
  echo "添加$EDGE_DOMAIN到/etc/hosts..."
  echo "$EDGE_IP  $EDGE_DOMAIN" >> "$HOSTS_FILE"
else
  echo "$EDGE_DOMAIN已存在于/etc/hosts，跳过添加。"
fi

# 提供新的播放地址
echo "部署完成！您的M3U播放地址为: http://$SERVER_IP/mytv.m3u"
echo "您可以使用此地址观看直播。"
