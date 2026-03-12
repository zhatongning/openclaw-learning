#!/bin/bash

# GitHub Pages 手动部署脚本

set -e

echo "🦞 OpenClaw 学习笔记 - GitHub Pages 部署"
echo "=========================================="
echo ""

# 检查是否在项目目录
if [ ! -f "book.json" ]; then
    echo "❌ 错误：请在项目根目录运行此脚本"
    exit 1
fi

# 检查 gitbook-cli 是否安装
if ! command -v gitbook &> /dev/null; then
    echo "⚠️  GitBook CLI 未安装"
    echo "正在安装 GitBook CLI..."
    npm install -g gitbook-cli
fi

echo "📦 安装 GitBook 依赖..."
gitbook install

echo ""
echo "🔨 构建 GitBook 静态文件..."
gitbook build

echo ""
echo "✅ 构建完成！"
echo ""

# 检查构建结果
if [ -d "_book" ]; then
    echo "📊 构建统计："
    echo "   - 文件数: $(find _book -type f | wc -l)"
    echo "   - 大小: $(du -sh _book | cut -f1)"
    echo ""
    
    read -p "是否本地预览？(y/n): " preview
    
    if [[ $preview == "y" || $preview == "Y" ]]; then
        echo ""
        echo "🌐 启动本地服务器..."
        echo "访问 http://localhost:4000"
        echo "按 Ctrl+C 停止"
        echo ""
        gitbook serve
    else
        echo ""
        echo "📝 下一步："
        echo "1. 提交更改: git add . && git commit -m 'Build GitBook'"
        echo "2. 推送到 GitHub: git push"
        echo "3. GitHub Actions 会自动部署到 GitHub Pages"
        echo ""
        echo "✅ 完成！"
    fi
else
    echo "❌ 构建失败：未找到 _book 目录"
    exit 1
fi
