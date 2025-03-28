#!/bin/sh

URL="https://pan.v1.mk/api/fs/list"

DATA='{"path": "/每期视频中用到的文件分享/allinone二进制文件/"}'

response=$(curl -s -X POST -H "Content-Type: application/json" -d "$DATA" "$URL")

if echo "$response" | grep -q '"code":200'; then
    file_info=$(echo "$response" | jq -r '.data.content[] | select(.name | contains("allinone_linux_arm64") and endswith(".zip")) | .name')

    if [ -n "$file_info" ]; then
        echo "找到文件: $file_info"
        
        xxxx=$(echo "$file_info" | grep -oE '[0-9]+')
        
        echo "提取的 xxxx 值: $xxxx"
        
        download_url="https://pan.v1.mk/p/每期视频中用到的文件分享/allinone二进制文件/$file_info"
        echo "开始下载: $download_url"

        tmp_dir="/tmp/allinone-update"
        mkdir -p "$tmp_dir"

        curl -o "$tmp_dir/$file_info" "$download_url"

        echo "下载完成，开始停止服务..."

        /etc/init.d/allinone stop

        echo "服务已停止，开始解压..."

        unzip -o "$tmp_dir/$file_info" -d /tmp/allinone

        echo "更新完成！"

        echo "正在修改权限..."
        chmod 777 /tmp/allinone/allinone_linux_arm64

        echo "正在恢复服务..."
        /etc/init.d/allinone start
        echo "服务已恢复运行！"

        echo "清理临时目录..."
        rm -rf "$tmp_dir"
        echo "临时目录已删除！"
    else
        echo "未找到符合条件的文件"
    fi
else
    echo "请求失败，响应内容: $response"
fi
