#!/bin/bash
# Flutter 项目初始化完成脚本
# 请在终端中手动执行

set -e

echo "=========================================="
echo "  RideHermes 乘客端 - 初始化"
echo "=========================================="
echo ""

# 配置环境变量
export PATH="$PATH:$HOME/flutter/bin"
export PUB_HOSTED_URL="https://mirrors.tuna.tsinghua.edu.cn/dart-pub"
export FLUTTER_STORAGE_BASE_URL="https://mirrors.tuna.tsinghua.edu.cn/flutter"

echo "✅ 环境变量已配置"
echo ""

# 进入项目目录
cd /home/test/data/ride-ai/v0.1/src/passenger-app
echo "✅ 已进入项目目录: $(pwd)"
echo ""

# 检查 pubspec.lock
if [ ! -f "pubspec.lock" ]; then
    echo "=========================================="
    echo "  运行 flutter pub get"
    echo "=========================================="
    flutter pub get
    echo ""
fi

# 运行 build_runner
echo "=========================================="
echo "  运行 build_runner (生成代码)"
echo "=========================================="
flutter pub run build_runner build --delete-conflicting-outputs
echo ""

# 检查生成的文件
echo "=========================================="
echo "  检查生成的文件"
echo "=========================================="
echo "*.freezed.dart 文件:"
find lib -name "*.freezed.dart" 2>/dev/null | head -10
echo ""
echo "*.g.dart 文件:"
find lib -name "*.g.dart" 2>/dev/null | head -10
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
