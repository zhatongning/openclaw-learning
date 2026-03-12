#!/bin/bash

# OpenClaw 学习笔记 - GitBook 快速启动脚本

set -e

echo "🦞 OpenClaw 学习笔记 - GitBook 设置"
echo "========================================"
echo ""

# 检查是否安装了 gitbook-cli
if ! command -v gitbook &> /dev/null; then
    echo "⚠️  GitBook CLI 未安装"
    echo ""
    echo "请选择安装方式："
    echo "1) npm"
    echo "2) yarn"
    echo "3) 跳过（手动安装）"
    read -p "请选择 (1/2/3): " choice
    
    case $choice in
        1)
            echo "正在安装 GitBook CLI (npm)..."
            npm install -g gitbook-cli
            ;;
        2)
            echo "正在安装 GitBook CLI (yarn)..."
            yarn global add gitbook-cli
            ;;
        3)
            echo "跳过安装。请手动安装 GitBook CLI："
            echo "  npm install -g gitbook-cli"
            echo "  或"
            echo "  yarn global add gitbook-cli"
            exit 0
            ;;
        *)
            echo "无效选择"
            exit 1
            ;;
    esac
fi

echo "✅ GitBook CLI 已安装"
echo ""

# 安装 GitBook 依赖
echo "📦 安装 GitBook 依赖..."
gitbook install

echo ""
echo "✅ 依赖安装完成"
echo ""

# 询问是否启动本地服务器
read -p "是否启动本地服务器预览？(y/n): " start_server

if [[ $start_server == "y" || $start_server == "Y" ]]; then
    echo ""
    echo "🚀 启动本地服务器..."
    echo "访问 http://localhost:4000 查看效果"
    echo "按 Ctrl+C 停止服务器"
    echo ""
    gitbook serve
else
    echo ""
    echo "📖 构建静态文件..."
    gitbook build
    
    echo ""
    echo "✅ 构建完成！"
    echo "静态文件位于: _book/ 目录"
    echo ""
    echo "下一步："
    echo "1. 查看构建结果: open _book/index.html"
    echo "2. 部署到 GitHub Pages: cd _book && git init && ..."
    echo "3. 发布到 GitBook.com: 参考 GITBOOK_GUIDE.md"
fi
