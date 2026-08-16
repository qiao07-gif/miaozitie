#!/bin/bash
# 一键部署脱敏版描字帖到腾讯云 CVM（Ubuntu + Nginx）
# 用法：cd /tmp && curl -fsSL -o deploy.sh "https://cdn.jsdelivr.net/gh/qiao07-gif/miaozitie@main/deploy.sh" && sudo bash deploy.sh
set -e

echo "【1/5】安装 Nginx（首次约 1-2 分钟，请耐心等）..."
sudo apt-get update -y
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
echo "  ✓ Nginx 已启动"

echo "【2/5】从 jsDelivr 拉取脱敏版（@main，带重试应对首拉未缓存）..."
cd /tmp
for i in 1 2 3 4 5; do
  if curl -fL -o index-domestic.html "https://cdn.jsdelivr.net/gh/qiao07-gif/miaozitie@main/index-domestic.html" && \
     curl -fL -o og-cover.png "https://cdn.jsdelivr.net/gh/qiao07-gif/miaozitie@main/og-cover.png"; then
    echo "  第 $i 次拉取成功"; break
  fi
  echo "  第 $i 次拉取失败，3 秒后重试..."; sleep 3
done

echo "【3/5】校验确为新版（防 CDN 未刷新/旧版误部署）..."
grep -q "cardSchemeOverride" index-domestic.html || { echo "WARNING: 缺 cardSchemeOverride -> 不是新版，疑似CDN未同步，请截图告知"; exit 1; }
grep -q "url(#cbs"          index-domestic.html || { echo "WARNING: 缺 url(#cbs -> 不是新版"; exit 1; }
grep -q "素材来源"           index-domestic.html || { echo "WARNING: 缺 素材来源 -> 脱敏未生效"; exit 1; }
SIZE=$(stat -c%s index-domestic.html 2>/dev/null || echo 0)
echo "  校验通过，大小: ${SIZE} 字节"
[ "$SIZE" -lt 1000000 ] && { echo "WARNING: 文件过小，可能CDN未缓存，请截图告知"; exit 1; }

echo "【4/5】备份旧版并部署..."
[ -f /var/www/html/index.html ] && sudo cp /var/www/html/index.html /var/www/html/index.html.bak && echo "  已备份 -> index.html.bak"
sudo mv -f index-domestic.html /var/www/html/index.html
sudo mv -f og-cover.png /var/www/html/og-cover.png
sudo systemctl reload nginx
echo "  ✓ 已部署并重载 Nginx"

echo "【5/5】验活..."
ls -la /var/www/html/index.html
curl -sI http://localhost/ | head -3
echo ""
echo "DEPLOY_OK 成功！浏览器打开： http://49.232.57.123/"
echo "   回退：sudo cp /var/www/html/index.html.bak /var/www/html/index.html && sudo systemctl reload nginx"
