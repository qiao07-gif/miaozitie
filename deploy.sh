#!/bin/bash
# 一键部署脱敏版描字帖到腾讯云 CVM（Ubuntu + Nginx）
# 用法：cd /tmp && curl -fsSL -o deploy.sh "https://cdn.jsdelivr.net/gh/qiao07-gif/miaozitie@main/deploy.sh" && sudo bash deploy.sh
set -e

echo "【1/4】安装 Nginx（首次约 1-2 分钟，请耐心等）..."
sudo apt-get update -y
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
echo "  ✓ Nginx 已启动"

echo "【2/4】从 jsDelivr CDN 下载脱敏版页面（约 3MB，1Mbps 带宽需约半分钟，请耐心等）..."
cd /tmp
curl -fL -o index-domestic.html "https://cdn.jsdelivr.net/gh/qiao07-gif/miaozitie@main/index-domestic.html?_=$(date +%s)"
curl -fL -o og-cover.png "https://cdn.jsdelivr.net/gh/qiao07-gif/miaozitie@main/og-cover.png?_=$(date +%s)"
SIZE=$(stat -c%s index-domestic.html 2>/dev/null || echo 0)
echo "  下载完成，index.html 大小: ${SIZE} 字节"
if [ "$SIZE" -lt 1000000 ]; then
  echo "  ⚠️ 文件太小（${SIZE} 字节），可能 CDN 未缓存。请截图本段结果告诉我。"
  exit 1
fi

echo "【3/4】部署到网站目录..."
sudo mv -f index-domestic.html /var/www/html/index.html
sudo mv -f og-cover.png /var/www/html/og-cover.png
sudo systemctl reload nginx
echo "  ✓ 已部署并重载 Nginx"

echo "【4/4】验活..."
ls -la /var/www/html/index.html
curl -sI http://localhost/ | head -3
echo ""
echo "✅ 全部完成！请用浏览器打开： http://49.232.57.123/"
