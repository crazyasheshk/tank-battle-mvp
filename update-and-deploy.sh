#!/bin/bash
# 自动更新并部署游戏到 GitHub Pages

set -e  # 遇到错误立即退出

cd "$(dirname "$0")"

echo "🎮 开始更新游戏..."

# 1. 重新导出 Web 版本
echo "📦 导出 Web 版本..."
godot --headless --export-release "Web" exports/web/index.html

# 2. 复制到 docs 目录
echo "📋 复制文件到 docs..."
cp -r exports/web/* docs/

# 3. 提交到 Git
echo "💾 提交更改..."
git add docs/ exports/web/
git commit -m "Update game - $(date '+%Y-%m-%d %H:%M:%S')"

# 4. 推送到 GitHub
echo "🚀 推送到 GitHub..."
git push

echo ""
echo "✅ 部署完成！"
echo "🌐 游戏地址: https://crazyasheshk.github.io/tank-battle-mvp/"
echo "⏱️  等待 1-2 分钟后刷新页面即可看到更新"
