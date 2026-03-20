#!/bin/bash
# 启动坦克对战游戏 Web 服务器

cd "$(dirname "$0")/exports/web"
echo "🎮 启动坦克对战游戏 Web 服务器..."
echo "📍 访问地址: http://localhost:8890"
echo "🛑 按 Ctrl+C 停止服务器"
echo ""

python3 -m http.server 8890
