#!/bin/bash

set -e

INSTALL_PATH="/usr/local/bin/javam"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/javam.sh"

echo "📦 安装 javam 到 $INSTALL_PATH..."
sudo cp "$SOURCE_FILE" "$INSTALL_PATH"
sudo chmod +x "$INSTALL_PATH"

echo "✅ 安装完成！你现在可以在任意目录直接使用 javam 命令啦 🎉"
