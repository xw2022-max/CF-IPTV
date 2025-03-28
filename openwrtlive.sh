#!/bin/sh

# 自动化配置Nginx并设置直播源(Openwrt)
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
  . "$CONFIG_FILE"
  echo "当前配置为："
  echo "FEIYANG_IP: $FEIYANG_IP"

  # 提示用户是否修改配置
  echo -n "是否修改配置？(y/n，10秒内未选择将默认使用当前配置): "
  
  # 使用read命令设置超时
  read -t 10 choice || choice="n"  # 如果没有输入，默认选择 n

  if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
    echo "请输入设备IP："
    read FEIYANG_IP

    # 保存配置
    cat > "$CONFIG_FILE" << EOF
FEIYANG_IP="$FEIYANG_IP"
EOF
    echo "配置已保存到 $CONFIG_FILE"
  else
    echo "使用记录的配置运行脚本..."
  fi
else
  echo "未检测到配置文件，需要输入初始配置..."
  echo "请输入设备IP："
  read FEIYANG_IP

  # 保存配置
  cat > "$CONFIG_FILE" << EOF
FEIYANG_IP="$FEIYANG_IP"
EOF
  echo "配置已保存到 $CONFIG_FILE"
fi

# 输出确认
echo "FEIYANG_IP: $FEIYANG_IP"

# 安装Nginx（如果未安装）
echo "检查Nginx是否已安装..."
if ! command -v nginx &> /dev/null; then
  echo "Nginx未安装，开始安装..."
  opkg update; opkg install nginx
else
  echo "Nginx已安装，跳过安装步骤。"
fi

# 下载并替换Nginx配置文件（强制替换）
NGINX_CONF_URL="https://raw.githubusercontent.com/rad168/iptv/refs/heads/main/mytv/nginx.conf"
NGINX_CONF_PATH="/etc/nginx/nginx.conf"
echo "下载并强制替换Nginx配置文件..."
curl -o "$NGINX_CONF_PATH" "$NGINX_CONF_URL"

# 配置Nginx监听80端口（避免重复添加）
if ! grep -q "server_name $FEIYANG_IP;" "$NGINX_CONF_PATH"; then
  echo "添加Nginx监听80端口的配置..."
  sed -i "/http {/a \\
    server { \\
        listen 80; \\
        server_name $FEIYANG_IP; \\
        location / { \\
            root /www; \\
            index index.html index.htm; \\
        } \\
        location /allinone.m3u { \\
            root /www; \\
            default_type application/octet-stream; \\
            allow all; \\
        } \\
    }" $NGINX_CONF_PATH

else
  echo "Nginx配置中已包含相关设置，跳过修改。"
fi

# 下载并修改M3U文件
M3U_URL="https://raw.xaxq.pp.ua/tmxk2021/CF-IPTV/refs/heads/main/allinone.m3u"
M3U_PATH="/www/allinone.m3u"
echo "下载M3U文件..."
curl -o "$M3U_PATH" "$M3U_URL"
echo "修改M3U文件中的设备IP..."
sed -i "s/肥羊IP/$FEIYANG_IP/g" "$M3U_PATH"

# 提供新的播放地址
echo "部署完成！您的M3U播放地址为: http://$FEIYANG_IP/allinone.m3u"
echo "您可以使用此地址观看直播。"

