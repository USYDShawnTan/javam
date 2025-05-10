#!/bin/bash

# =====================================
# javam CLI - v1.3
# Author: Xiaotan
# Description: Manage Zulu JDK versions via CLI panel
# =====================================

# 设置安装目录
JDK_DIR="$HOME/.javam/versions"
mkdir -p "$JDK_DIR"

# 支持的版本和链接（可维护）
declare -A JDK_URLS=(
  [zulu8]="https://cdn.azul.com/zulu/bin/zulu8.82.0.21-ca-jdk8.0.432-linux_x64.tar.gz"
  [zulu11]="https://cdn.azul.com/zulu/bin/zulu11.78.15-ca-jdk11.0.26-linux_x64.tar.gz"
  [zulu17]="https://cdn.azul.com/zulu/bin/zulu17.52.17-ca-jdk17.0.12-linux_x64.tar.gz"
  [zulu21]="https://cdn.azul.com/zulu/bin/zulu21.36.17-ca-jdk21.0.4-linux_x64.tar.gz"
)

# 设置当前版本
set_current_java() {
  export JAVA_HOME="$1"
  export PATH="$JAVA_HOME/bin:$PATH"
  echo "✅ 已切换到：$JAVA_HOME"
  java -version

  shell_rc=""
  if [ -n "$ZSH_VERSION" ]; then
    shell_rc="$HOME/.zshrc"
  else
    shell_rc="$HOME/.bashrc"
  fi

  sed -i '/# javam 自动设置/,$d' "$shell_rc"
  echo "# javam 自动设置" >> "$shell_rc"
  echo "export JAVA_HOME=\"$JAVA_HOME\"" >> "$shell_rc"
  echo "export PATH=\"$JAVA_HOME/bin:\$PATH\"" >> "$shell_rc"
  echo "✅ 设置已写入 $shell_rc"

  echo "💡 请关闭当前终端并重新打开，即可生效新设置。"
}

# 获取当前实际 Java 版本路径对应的目录名
get_current_java_version_dirname() {
  current_java_path=$(readlink -f $(which java) 2>/dev/null || true)
  for dir in "$JDK_DIR"/*; do
    if [[ -x "$dir/bin/java" ]]; then
      linked=$(readlink -f "$dir/bin/java")
      if [[ "$linked" == "$current_java_path" ]]; then
        basename "$dir"
        return
      fi
    fi
  done
  echo ""
}

# 打印横幅
print_banner() {
  echo "=============================="
  echo " ☕ javam - Java 管理工具 CLI 面板"
  echo "=============================="
}

# 当前 Java 状态
print_current_java() {
  if type -p java >/dev/null 2>&1 && [[ -n "$JAVA_HOME" ]]; then
    echo "当前 Java 版本："
    java -version 2>&1 | head -n 1
    echo "JAVA_HOME: $JAVA_HOME"
  else
    echo "⚠️ 当前未设置 Java 环境变量 (JAVA_HOME)"
  fi

  echo "👉 已安装版本列表："
  current_dirname=$(get_current_java_version_dirname)
  for ver in "${!JDK_URLS[@]}"; do
    url=${JDK_URLS[$ver]}
    fname=$(basename "$url")
    dirname="${fname%.tar.gz}"
    if [ -d "$JDK_DIR/$dirname" ]; then
      if [[ "$dirname" == "$current_dirname" ]]; then
        echo "[✔] $ver（当前使用）"
      else
        echo "[✔] $ver"
      fi
    else
      echo "[ ] $ver"
    fi
  done
  echo
}

# 批量安装全部版本并设置 zulu21
install_all_java_versions() {
  echo "📦 开始批量下载所有支持的 Java 版本..."
  cd "$JDK_DIR"
  for ver in "${!JDK_URLS[@]}"; do
    url="${JDK_URLS[$ver]}"
    fname=$(basename "$url")
    if [ ! -d "$JDK_DIR/${fname%.tar.gz}" ]; then
      echo "📥 正在下载 $ver..."
      curl -LO "$url"
      tar -xzf "$fname" && rm "$fname"
      echo "✅ 安装完成: $ver"
    else
      echo "✅ 已存在: $ver，跳过"
    fi
  done
  set_current_java "$JDK_DIR/zulu21.36.17-ca-jdk21.0.4-linux_x64"
  read -p "按任意键返回菜单..." _
}

# 安装或切换指定版本
select_or_install_java_version() {
  current_ver=$(get_current_java_version_dirname)
  echo "请选择 Java 版本："
  PS3="请输入编号选择版本（当前为：$current_ver）："
  options=("zulu8" "zulu11" "zulu17" "zulu21" "返回")
  select ver in "${options[@]}"; do
    [[ $ver == "返回" ]] && return
    url=${JDK_URLS[$ver]}
    if [ -z "$url" ]; then echo "❌ 无效版本"; return; fi

    fname=$(basename "$url")
    dirname="${fname%.tar.gz}"

    if [ -d "$JDK_DIR/$dirname" ]; then
      echo "✅ $ver 已下载，正在切换..."
    else
      echo "📥 正在下载 $ver..."
      cd "$JDK_DIR"
      curl -LO "$url"
      tar -xzf "$fname" && rm "$fname"
      echo "✅ 已安装：$ver"
    fi

    set_current_java "$JDK_DIR/$dirname"
    read -p "按任意键返回菜单..." _
    return
  done
}

# 删除 JDK
uninstall_java_menu() {
  echo "选择要删除的版本："
  cd "$JDK_DIR"
  dirs=(*/)
  select dir in "${dirs[@]}" "返回"; do
    [[ $dir == "返回" ]] && return
    if [ -d "$JDK_DIR/$dir" ]; then
      read -p "⚠️ 确定要删除 $dir？[y/N]: " confirm
      [[ $confirm == "y" || $confirm == "Y" ]] || return
      rm -rf "$JDK_DIR/$dir"
      echo "🗑️ 已删除 $dir"
      read -p "按任意键返回菜单..." _
      return
    else
      echo "❌ 无效路径"
      return
    fi
  done
}

# 主循环
while true; do
  clear
  print_banner
  print_current_java
  echo "1. 一键安装所有版本（默认使用 zulu21）"
  echo "2. 安装或切换指定版本"
  echo "3. 查看当前版本信息"
  echo "4. 删除某个版本"
  echo "5. 退出"
  echo
  read -p "请输入你的选择 [1-5]：" choice
  case $choice in
    1) install_all_java_versions ;;
    2) select_or_install_java_version ;;
    3) java -version; read -p "按任意键返回菜单..." _ ;;
    4) uninstall_java_menu ;;
    5) echo "👋 再见！"; exit 0 ;;
    *) echo "❌ 请输入 1-5 之间的数字"; sleep 1 ;;
  esac
done
