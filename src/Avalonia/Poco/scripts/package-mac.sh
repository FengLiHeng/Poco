#!/usr/bin/env bash
# 把 Poco 打包成签名的 macOS .app（含番茄图标 + bundle id + 原生通知 dylib）
# 仅适配 Apple Silicon（M 系列 / arm64）。
#
# 用法：
#   bash scripts/package-mac.sh          # Release（正式，专注 25 分钟）
#   bash scripts/package-mac.sh Debug    # Debug（测试，秒级时长）
set -euo pipefail

cd "$(dirname "$0")/.."          # 进入 src/Poco

APP="Poco"
BUNDLE_ID="com.poco.pomodoro"
RID="osx-arm64"                  # M 系列芯片
CONFIG="${1:-Release}"           # 传 Debug 可得秒级测试时长

# —— 前置检查 ——
command -v dotnet  >/dev/null || { echo "✗ 未找到 dotnet"; exit 1; }
command -v swiftc  >/dev/null || { echo "✗ 未找到 swiftc（需安装 Xcode / Command Line Tools）"; exit 1; }
command -v iconutil >/dev/null || { echo "✗ 未找到 iconutil"; exit 1; }
if [ "$(uname -m)" != "arm64" ]; then
  echo "⚠ 当前不是 arm64 机器；本脚本只产出 M 系列（osx-arm64）包。"
fi
OUT="bin/mac"
APPDIR="$OUT/$APP.app"
CONTENTS="$APPDIR/Contents"
MACOS="$CONTENTS/MacOS"
RES="$CONTENTS/Resources"

echo "==> 清理"
rm -rf "$APPDIR"
mkdir -p "$MACOS" "$RES"

echo "==> dotnet publish (self-contained $RID, $CONFIG)"
dotnet publish Poco.csproj -c "$CONFIG" -r "$RID" --self-contained true \
  -p:UseAppHost=true -o "$OUT/publish"

echo "==> 拷贝发布产物到 Contents/MacOS"
cp -R "$OUT/publish/." "$MACOS/"

echo "==> 编译原生库 libPocoNotify.dylib（通知 + 菜单栏倒计时文本）"
swiftc -O -emit-library -target arm64-apple-macosx12.0 \
  -o "$MACOS/libPocoNotify.dylib" \
  native/PocoNotify.swift native/PocoTray.swift \
  -framework UserNotifications -framework AppKit

echo "==> 生成 Poco.icns"
ICONSET="$OUT/Poco.iconset"
rm -rf "$ICONSET"; mkdir -p "$ICONSET"
SRC="Assets/tomato.png"
for s in 16 32 128 256 512; do
  d=$((s*2))
  sips -z "$s" "$s" "$SRC" --out "$ICONSET/icon_${s}x${s}.png"   >/dev/null
  sips -z "$d" "$d" "$SRC" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$RES/Poco.icns"

echo "==> 写 Info.plist"
cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Poco</string>
  <key>CFBundleDisplayName</key><string>Poco</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>$APP</string>
  <key>CFBundleIconFile</key><string>Poco</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <!-- 菜单栏 accessory：无 Dock 图标、不进 Cmd-Tab、无顶部应用菜单，纯活在菜单栏 -->
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

echo "==> ad-hoc 代码签名（原生通知在新版 macOS 需签名）"
# 由内向外签：先签嵌套的 dylib，再签 .app 外层。
# （--deep 已被 Apple 弃用，改为显式逐项签名）
codesign --force --sign - "$MACOS/libPocoNotify.dylib"
codesign --force --sign - "$APPDIR"

echo ""
echo "✓ 完成（$CONFIG / $RID）：$APPDIR  [$(du -sh "$APPDIR" | cut -f1)]"
echo "  运行：open \"$PWD/$APPDIR\""
