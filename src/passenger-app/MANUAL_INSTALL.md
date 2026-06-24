# Flutter 手动安装指南

如果自动安装脚本失败，请按照本指南手动安装。

## 方法一：从其他机器拷贝（推荐）

1. 在有网络的机器上下载 Flutter SDK：
   ```bash
   # 下载地址（选择一个）：
   # 官方：https://flutter.dev/docs/get-started/install
   # 清华镜像：https://mirrors.tuna.tsinghua.edu.cn/flutter/flutter_infra_release/releases/stable/linux/
   # 选择：flutter_linux_3.24.5-stable.tar.xz
   ```

2. 将下载的文件拷贝到目标机器：
   ```bash
   # 从其他机器拷贝到目标机器
   scp flutter_linux_3.24.5-stable.tar.xz user@target:/home/test/
   ```

3. 在目标机器上解压：
   ```bash
   cd /home/test
   tar xf flutter_linux_3.24.5-stable.tar.xz
   ```

4. 配置环境变量：
   ```bash
   echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
   source ~/.bashrc
   ```

5. 验证安装：
   ```bash
   flutter --version
   flutter doctor
   ```

## 方法二：使用 Git 克隆（如果网络允许）

```bash
# 克隆 Flutter 仓库（稳定分支）
git clone https://github.com/flutter/flutter.git -b stable ~/flutter --depth 1

# 配置环境变量
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# 验证
flutter --version
```

## 方法三：使用国内镜像源

如果直接连接官方源慢，可以配置国内镜像：

```bash
# 配置环境变量（临时）
export FLUTTER_STORAGE_BASE_URL="https://mirrors.tuna.tsinghua.edu.cn/flutter"
export PUB_HOSTED_URL="https://mirrors.tuna.tsinghua.edu.cn/dart-pub"

# 然后执行克隆或下载
git clone https://mirrors.tuna.tsinghua.edu.cn/flutter/flutter.git -b stable ~/flutter --depth 1
```

## 安装后的配置

### 1. 运行 flutter doctor

```bash
flutter doctor -v
```

根据输出安装缺失的依赖（Android SDK、Chrome 等）。

### 2. 配置 Android 开发环境（如果需要）

```bash
# 下载 Android SDK 或使用 Android Studio
# 配置 ANDROID_HOME 环境变量
echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.bashrc
echo 'export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"' >> ~/.bashrc
```

### 3. 配置高德地图 API Key

编辑 `/home/test/data/ride-ai/v0.1/src/passenger-app/lib/config/app_config.dart`：

```dart
static const String amapApiKey = '你的高德地图API_KEY';
static const String amapApiKeyIos = '你的iOS_API_KEY';
```

获取 API Key：https://lbs.amap.com/api/

## 项目初始化

安装完 Flutter 后，进入项目目录执行：

```bash
cd /home/test/data/ride-ai/v0.1/src/passenger-app

# 1. 安装依赖
flutter pub get

# 2. 生成代码（freezed, json_serializable）
flutter pub run build_runner build --delete-conflicting-outputs

# 3. 运行应用
flutter run  # Android
flutter run -d ios  # iOS
flutter run -d chrome  # Web (调试用)
```

## 常见问题

### Q: flutter 命令找不到
```bash
# 检查 PATH
echo $PATH
# 应该包含 /home/test/flutter/bin

# 如果没有，重新加载配置
source ~/.bashrc
# 或者手动添加
export PATH="$PATH:$HOME/flutter/bin"
```

### Q: flutter pub get 失败
```bash
# 配置国内镜像
export PUB_HOSTED_URL="https://mirrors.tuna.tsinghua.edu.cn/dart-pub"
export FLUTTER_STORAGE_BASE_URL="https://mirrors.tuna.tsinghua.edu.cn/flutter"

# 然后重新执行
flutter pub get
```

### Q: Android 许可证问题
```bash
flutter doctor --android-licenses
# 按 y 接受所有许可证
```

### Q: 无法连接 Android 设备
```bash
# 检查设备
flutter devices

# 启动 ADB
adb start-server

# 检查 USB 调试是否开启（真机）
```

## 验证安装成功

```bash
# 1. 检查 Flutter 版本
flutter --version
# 应该显示：Flutter 3.24.5, Dart 3.5.0

# 2. 检查环境
flutter doctor
# 应该显示没有严重问题

# 3. 运行项目
cd /home/test/data/ride-ai/v0.1/src/passenger-app
flutter run -d chrome
# 应该能在 Chrome 中打开应用
```

## 下一步

安装成功后，参考 `/home/test/data/ride-ai/v0.1/src/passenger-app/README.md` 进行开发。
