#!/bin/bash
# 一键部署脱敏版描字帖到腾讯云 CVM（Ubuntu + Nginx + HTTPS/certbot）
# 用法：cd /tmp && curl -fsSL -o deploy.sh "https://cdn.jsdelivr.net/gh/qiao07-gif/miaozitie@main/deploy.sh" && sudo bash deploy.sh
# 前置：域名 miaozitie.top 的 A 记录已指向本机 49.232.57.123，且腾讯云安全组放通 22/80/443
set -e
COMMIT="14daa4a"   # 钉死本次部署 commit（含ICP号+公安备案双号），避免 @main 在 jsDelivr 上偶发截断/缓存旧版
DOMAIN="miaozitie.top"

echo "【1/6】安装 Nginx..."
sudo apt-get update -y
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
echo "  ✓ Nginx 已启动"

echo "【2/6】从 jsDelivr 拉取脱敏版（钉死 @${COMMIT} + 备用域名 gcore，带重试）..."
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

echo "【3/6】校验确为新版（防 CDN 未刷新/旧版误部署）..."
grep -q "cardSchemeOverride" index-domestic.html || { echo "WARNING: 缺 cardSchemeOverride -> 不是新版"; exit 1; }
grep -q "url(#cbs"          index-domestic.html || { echo "WARNING: 缺 url(#cbs -> 不是新版"; exit 1; }
grep -q "素材来源"           index-domestic.html || { echo "WARNING: 缺 素材来源 -> 脱敏未生效"; exit 1; }
grep -q "鲁公网安备37150202001150号" index-domestic.html || { echo "WARNING: 缺 公安备案footer -> 国内版异常"; exit 1; }
grep -q "鲁ICP备2026048614号-1" index-domestic.html || { echo "WARNING: 缺 ICP备案footer -> 国内版异常"; exit 1; }
SIZE=$(stat -c%s index-domestic.html 2>/dev/null || echo 0)
echo "  校验通过（含公安备案footer），大小: ${SIZE} 字节"
[ "$SIZE" -lt 1000000 ] && { echo "WARNING: 文件过小，可能CDN未缓存，请截图告知"; exit 1; }

echo "【4/6】部署到 /var/www/html 并配置 Nginx 站点（server_name=${DOMAIN}）..."
[ -f /var/www/html/index.html ] && sudo cp /var/www/html/index.html /var/www/html/index.html.bak && echo "  已备份 -> index.html.bak"
sudo mv -f index-domestic.html /var/www/html/index.html
sudo mv -f og-cover.png /var/www/html/og-cover.png
sudo bash -c "cat > /etc/nginx/sites-available/miaozitie <<'EOF'
server {
    listen 80;
    server_name ${DOMAIN};
    root /var/www/html;
    index index.html;
    location / { try_files \$uri \$uri/ /index.html; }
}
EOF"
sudo ln -sf /etc/nginx/sites-available/miaozitie /etc/nginx/sites-enabled/miaozitie
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
echo "  ✓ HTTP 站点已就绪（域名解析到本机后即可 http://${DOMAIN}/ 访问）"

echo "【5/6】申请 HTTPS 证书（certbot，需域名已解析到本机 80 端口）..."
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d "${DOMAIN}" --non-interactive --agree-tos --register-unsafely-without-email --redirect \
  || echo "WARNING: certbot 失败——请确认 (1)域名 ${DOMAIN} A记录已指向本机 49.232.57.123 (2)腾讯云安全组放通80/443。修正后重跑: sudo certbot --nginx -d ${DOMAIN} --redirect"
echo "  ✓ 证书阶段结束"

echo "【6/6】验活..."
ls -la /var/www/html/index.html
curl -sI "https://${DOMAIN}/" | head -3 || curl -sI "http://${DOMAIN}/" | head -3
echo ""
echo "DEPLOY_OK 成功！浏览器打开： https://${DOMAIN}/  （应底部见「鲁公网安备37150202001150号」）"
echo "   回退：sudo cp /var/www/html/index.html.bak /var/www/html/index.html && sudo systemctl reload nginx"
