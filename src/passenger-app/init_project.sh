#!/bin/bash
# Flutter 项目初始化脚本
# 请在终端中手动执行此脚本

set -e

echo "=========================================="
echo "  RideHermes 乘客端 - 项目初始化"
echo "=========================================="
echo ""

# 配置环境变量
export PATH="$PATH:$HOME/flutter/bin"
export PUB_HOSTED_URL="https://mirrors.tuna.tsinghua.edu.cn/dart-pub"
export FLUTTER_STORAGE_BASE_URL="https://mirrors.tuna.tsinghua.edu.cn/flutter"

echo "✅ 环境变量已配置"
echo "  PATH=$PATH"
echo "  PUB_HOSTED_URL=$PUB_HOSTED_URL"
echo "  FLUTTER_STORAGE_BASE_URL=$FLUTTER_STORAGE_BASE_URL"
echo ""

# 验证 Flutter 安装
echo "=========================================="
echo "  验证 Flutter 安装"
echo "=========================================="
flutter --version
echo ""

# 运行 flutter doctor
echo "=========================================="
echo "  运行 flutter doctor"
echo "=========================================="
flutter doctor -v
echo ""

# 进入项目目录
cd /home/test/data/ride-ai/v0.1/src/passenger-app
echo "✅ 已进入项目目录: $(pwd)"
echo ""

# 安装依赖
echo "=========================================="
echo "  安装依赖 (flutter pub get)"
echo "=========================================="
flutter pub get
echo ""

# 生成代码
echo "=========================================="
echo "  生成代码 (build_runner)"
echo "=========================================="
flutter pub run build_runner build --delete-conflicting-outputs
echo ""

echo "=========================================="
echo "  ✅ 初始化完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 配置高德地图 API Key:"
echo "   编辑 lib/config/app_config.dart"
echo ""
echo "2. 运行应用:"
echo "   flutter run           # Android"
echo "   flutter run -d ios   # iOS"
echo "   flutter run -d chrome # Web"
echo ""
