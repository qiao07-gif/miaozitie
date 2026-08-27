#!/bin/bash
# 一键部署脱敏版描字帖到腾讯云 CVM（Ubuntu + Nginx）
# 用法：cd /tmp && curl -fsSL -o deploy.sh "https://cdn.jsdelivr.net/gh/qiao07-gif/miaozitie@main/deploy.sh" && sudo bash deploy.sh
set -e
COMMIT="6cb4943"   # 钉死本次部署 commit，避免 @main 在 jsDelivr 上偶发截断/缓存旧版

echo "【1/5】安装 Nginx（首次约 1-2 分钟，请耐心等）..."
sudo apt-get update -y
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
echo "  ✓ Nginx 已启动"

echo "【2/5】从 jsDelivr 拉取脱敏版（钉死 @${COMMIT} + 备用域名 gcore，带重试）..."
cd /tmp
pull_ok=0
for CDN in \
  "https://cdn.jsdelivr.net/gh/qiao07-gif/miaozitie@${COMMIT}" \
  "https://gcore.jsdelivr.net/gh/qiao07-gif/miaozitie@${COMMIT}" ; do
  echo "  尝试 CDN: ${CDN}"
  for i in 1 2 3; do
    if curl -fL -o index-domestic.html "${CDN}/index-domestic.html" && \
       curl -fL -o og-cover.png "${CDN}/og-cover.png"; then
      echo "  第 $i 次拉取成功"; pull_ok=1; break 2
    fi
    echo "  第 $i 次失败，2 秒后重试..."; sleep 2
  done
  [ "$pull_ok" -eq 1 ] && break
  echo "  ${CDN} 失败，切换下一个 CDN"
done
[ "$pull_ok" -eq 0 ] && { echo "ERROR: 所有 CDN 拉取失败，请截图告知"; exit 1; }

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
