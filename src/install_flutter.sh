#!/bin/bash
# ============================================
# Flutter SDK 安装脚本
# 适用于 RideHermes 乘客端开发
# ============================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 配置变量
FLUTTER_VERSION="3.24.5"
FLUTTER_DIR="$HOME/flutter"
INSTALL_DIR="$HOME"
TMP_DIR="/tmp/flutter_install"

# 创建临时目录
mkdir -p "$TMP_DIR"

log_info "=========================================="
log_info "Flutter SDK 安装脚本"
log_info "版本: $FLUTTER_VERSION"
log_info "安装目录: $FLUTTER_DIR"
log_info "=========================================="
echo ""

# ============================================
# 函数：检测系统类型
# ============================================
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# ============================================
# 函数：检查依赖
# ============================================
check_dependencies() {
    log_info "检查系统依赖..."
    
    local missing_deps=()
    
    for cmd in curl wget unzip tar xz; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_warn "缺少以下工具: ${missing_deps[*]}"
        log_info "尝试安装缺失的依赖..."
        
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y curl wget unzip xz-utils
        elif command -v yum &> /dev/null; then
            sudo yum install -y curl wget unzip xz
        else
            log_error "无法自动安装依赖，请手动安装: ${missing_deps[*]}"
            exit 1
        fi
    fi
    
    log_success "依赖检查完成"
}

# ============================================
# 方法1：从官方源下载
# ============================================
download_from_official() {
    log_info "尝试从 Flutter 官方源下载..."
    
    local url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
    local output="$TMP_DIR/flutter.tar.xz"
    
    log_info "下载 URL: $url"
    
    if curl -fL --connect-timeout 30 --max-time 300 -o "$output" "$url"; then
        if [ -s "$output" ] && [ $(stat -c%s "$output") -gt 1000000 ]; then
            log_success "官方源下载成功"
            echo "$output"
            return 0
        fi
    fi
    
    log_warn "官方源下载失败"
    return 1
}

# ============================================
# 方法2：从清华镜像下载
# ============================================
download_from_tsinghua() {
    log_info "尝试从清华镜像下载..."
    
    local url="https://mirrors.tuna.tsinghua.edu.cn/flutter/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
    local output="$TMP_DIR/flutter.tar.xz"
    
    log_info "下载 URL: $url"
    
    if curl -fL --connect-timeout 30 --max-time 300 -o "$output" "$url"; then
        if [ -s "$output" ] && [ $(stat -c%s "$output") -gt 1000000 ]; then
            log_success "清华镜像下载成功"
            echo "$output"
            return 0
        fi
    fi
    
    log_warn "清华镜像下载失败"
    return 1
}

# ============================================
# 方法3：从华为云镜像下载
# ============================================
download_from_huaweicloud() {
    log_info "尝试从华为云镜像下载..."
    
    local url="https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com/flutter/${FLUTTER_VERSION}/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
    local output="$TMP_DIR/flutter.tar.xz"
    
    log_info "下载 URL: $url"
    
    if curl -fL --connect-timeout 30 --max-time 300 -o "$output" "$url"; then
        if [ -s "$output" ] && [ $(stat -c%s "$output") -gt 1000000 ]; then
            log_success "华为云镜像下载成功"
            echo "$output"
            return 0
        fi
    fi
    
    log_warn "华为云镜像下载失败"
    return 1
}

# ============================================
# 方法4：从 GitHub Releases 下载
# ============================================
download_from_github() {
    log_info "尝试从 GitHub Releases 下载..."
    
    local url="https://github.com/flutter/flutter/releases/download/${FLUTTER_VERSION}/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
    local output="$TMP_DIR/flutter.tar.xz"
    
    log_info "下载 URL: $url"
    
    if curl -fL --connect-timeout 30 --max-time 300 -o "$output" "$url"; then
        if [ -s "$output" ] && [ $(stat -c%s "$output") -gt 1000000 ]; then
            log_success "GitHub Releases 下载成功"
            echo "$output"
            return 0
        fi
    fi
    
    log_warn "GitHub Releases 下载失败"
    return 1
}

# ============================================
# 方法5：使用 git clone（稳定分支）
# ============================================
clone_from_git() {
    log_info "尝试从 GitHub 克隆 Flutter 仓库..."
    
    if [ -d "$FLUTTER_DIR" ]; then
        log_warn "目录已存在: $FLUTTER_DIR"
        read -p "是否删除并重新克隆? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$FLUTTER_DIR"
        else
            log_info "跳过克隆步骤"
            return 0
        fi
    fi
    
    if git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR" --depth 1; then
        log_success "Git 克隆成功"
        return 0
    fi
    
    log_warn "Git 克隆失败"
    return 1
}

# ============================================
# 解压安装
# ============================================
extract_flutter() {
    local archive="$1"
    
    log_info "解压 Flutter 到 $INSTALL_DIR..."
    
    if [[ "$archive" == *.tar.xz ]]; then
        tar xf "$archive" -C "$INSTALL_DIR"
    elif [[ "$archive" == *.zip ]]; then
        unzip -q "$archive" -d "$INSTALL_DIR"
    else
        log_error "未知压缩格式: $archive"
        return 1
    fi
    
    if [ -d "$FLUTTER_DIR" ]; then
        log_success "解压完成"
        return 0
    else
        log_error "解压失败，目录不存在: $FLUTTER_DIR"
        return 1
    fi
}

# ============================================
# 配置环境变量
# ============================================
configure_env() {
    log_info "配置环境变量..."
    
    local shell_rc=""
    if [ -f "$HOME/.bashrc" ]; then
        shell_rc="$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -f "$HOME/.profile" ]; then
        shell_rc="$HOME/.profile"
    fi
    
    if [ -n "$shell_rc" ]; then
        # 检查是否已经配置
        if grep -q "flutter/bin" "$shell_rc"; then
            log_info "环境变量已配置在 $shell_rc"
        else
            echo "" >> "$shell_rc"
            echo "# Flutter SDK" >> "$shell_rc"
            echo "export PATH=\"\$PATH:$FLUTTER_DIR/bin\"" >> "$shell_rc"
            log_success "环境变量已添加到 $shell_rc"
            log_info "请运行: source $shell_rc"
        fi
    fi
    
    # 立即生效（当前 shell）
    export PATH="$PATH:$FLUTTER_DIR/bin"
}

# ============================================
# 验证安装
# ============================================
verify_installation() {
    log_info "验证 Flutter 安装..."
    
    if command -v flutter &> /dev/null; then
        log_success "Flutter 命令可用"
        
        log_info "运行 flutter doctor..."
        flutter doctor -v || true
        
        log_success "Flutter 安装验证完成"
        return 0
    else
        log_error "Flutter 命令不可用，请检查 PATH"
        return 1
    fi
}

# ============================================
# 配置 Flutter 国内镜像
# ============================================
configure_mirrors() {
    log_info "配置 Flutter 国内镜像..."
    
    export FLUTTER_STORAGE_BASE_URL="https://mirrors.tuna.tsinghua.edu.cn/flutter"
    export PUB_HOSTED_URL="https://mirrors.tuna.tsinghua.edu.cn/dart-pub"
    
    log_info "镜像已配置（当前 shell）"
    log_warn "如需永久生效，请添加到 shell 配置文件:"
    echo "  export FLUTTER_STORAGE_BASE_URL=\"https://mirrors.tuna.tsinghua.edu.cn/flutter\""
    echo "  export PUB_HOSTED_URL=\"https://mirrors.tuna.tsinghua.edu.cn/dart-pub\""
}

# ============================================
# 主函数
# ============================================
main() {
    local os=$(detect_os)
    log_info "检测到系统: $os"
    
    if [ "$os" != "linux" ]; then
        log_warn "此脚本主要为 Linux 设计，其他系统可能需要调整"
    fi
    
    # 检查依赖
    check_dependencies
    
    # 配置镜像
    configure_mirrors
    
    # 尝试各种下载方法
    local archive=""
    
    # 方法1: 官方源
    if [ -z "$archive" ]; then
        archive=$(download_from_official) || true
    fi
    
    # 方法2: 清华镜像
    if [ -z "$archive" ]; then
        archive=$(download_from_tsinghua) || true
    fi
    
    # 方法3: 华为云镜像
    if [ -z "$archive" ]; then
        archive=$(download_from_huaweicloud) || true
    fi
    
    # 方法4: GitHub Releases
    if [ -z "$archive" ]; then
        archive=$(download_from_github) || true
    fi
    
    # 方法5: Git 克隆
    if [ -z "$archive" ]; then
        if clone_from_git; then
            log_success "通过 Git 克隆完成"
            configure_env
            verify_installation
            exit 0
        fi
    fi
    
    # 如果所有方法都失败
    if [ -z "$archive" ]; then
        log_error "所有下载方法都失败了！"
        log_info ""
        log_info "请尝试以下手动安装方法:"
        log_info "1. 从其他机器下载 Flutter SDK"
        log_info "   下载地址: https://flutter.dev/docs/get-started/install"
        log_info "2. 将下载的文件拷贝到: $TMP_DIR/flutter.tar.xz"
        log_info "3. 重新运行此脚本"
        log_info ""
        log_info "或者手动安装:"
        log_info "1. 下载 Flutter SDK"
        log_info "2. 解压到: $FLUTTER_DIR"
        log_info "3. 添加 $FLUTTER_DIR/bin 到 PATH"
        exit 1
    fi
    
    # 解压
    if ! extract_flutter "$archive"; then
        log_error "解压失败"
        exit 1
    fi
    
    # 配置环境变量
    configure_env
    
    # 验证安装
    verify_installation
    
    # 清理
    log_info "清理临时文件..."
    rm -rf "$TMP_DIR"
    
    echo ""
    log_success "=========================================="
    log_success "Flutter 安装完成！"
    log_success "=========================================="
    echo ""
    log_info "下一步:"
    log_info "1. 重新加载 shell 配置: source ~/.bashrc (或 ~/.zshrc)"
    log_info "2. 验证安装: flutter --version"
    log_info "3. 进入项目目录: cd /home/test/data/ride-ai/v0.1/src/passenger-app"
    log_info "4. 安装依赖: flutter pub get"
    log_info "5. 生成代码: flutter pub run build_runner build --delete-conflicting-outputs"
    log_info "6. 运行应用: flutter run"
    echo ""
}

# ============================================
# 执行主函数
# ============================================
main "$@"
