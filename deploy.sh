#!/usr/bin/env bash
set -euo pipefail
JAR_URL="https://github.com/Zinco-798/yicheng-deploy/releases/download/deploy-2026-11-12/backend.jar"
FRONT_URL="https://github.com/Zinco-798/yicheng-deploy/releases/download/deploy-2026-11-12/frontend.tar.gz"
JAR=/opt/yicheng-connect/back/target/demo1-0.0.1-SNAPSHOT.jar
WEB=/var/www/yicheng-connect
TS=$(date +%Y%m%d-%H%M%S)
BACKUP=/var/backups/yicheng-connect/manual-$TS

echo "== 1/6 下载部署包 =="
cd /tmp
curl -fL -o backend-new.jar "$JAR_URL"
curl -fL -o frontend-new.tar.gz "$FRONT_URL"
ls -lh backend-new.jar frontend-new.tar.gz

echo "== 2/6 备份当前版本 =="
mkdir -p "$BACKUP"
[ -f "$JAR" ] && cp "$JAR" "$BACKUP/backend.jar"
tar -czf "$BACKUP/frontend.tar.gz" -C "$WEB" . 2>/dev/null || true
echo "备份目录：$BACKUP"

echo "== 3/6 替换后端 =="
mkdir -p "$(dirname "$JAR")"
cp /tmp/backend-new.jar "$JAR"

echo "== 4/6 替换前端 =="
rm -rf "$WEB"/*
tar -xzf /tmp/frontend-new.tar.gz -C "$WEB"
chown -R www-data:www-data "$WEB" 2>/dev/null || true

echo "== 5/6 重启后端 =="
systemctl restart yicheng-connect
for i in $(seq 1 45); do
  if curl -sf http://127.0.0.1:8080/api/health >/dev/null 2>&1; then break; fi
  sleep 2
done

echo "== 6/6 验证 =="
curl -s http://127.0.0.1:8080/api/health; echo
curl -s -o /dev/null -w "nginx /: %{http_code}\n" http://127.0.0.1/
curl -s -o /dev/null -w "nginx /m: %{http_code}\n" http://127.0.0.1/m
echo "DEPLOY OK $(date '+%F %T')  BACKUP=$BACKUP"