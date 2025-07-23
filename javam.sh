#!/bin/bash

# =====================================
# javam CLI - v2.0 (Refactored)
# Author: Xiaotan
# Description: Manage Zulu JDK versions via CLI panel
# =====================================

## 检测是否通过管道执行，如果是则重新执行脚本
if [[ ! -t 0 ]]; then
  # 标准输入不是终端，说明是通过管道执行的
  temp_script=$(mktemp)
  cat > "$temp_script"
  chmod +x "$temp_script"
  
  # 尝试重定向到终端设备并传递所有参数
  if [[ -c /dev/tty ]]; then
    exec "$temp_script" "$@" < /dev/tty
  else
    # 直接执行，传递所有参数
    exec "$temp_script" "$@"
  fi
  exit $?
fi

## 设置安装目录
JDK_DIR="$HOME/.javam/versions"
mkdir -p "$JDK_DIR"

## 支持的版本和链接（可维护）
declare -A JDK_URLS=(
  [zulu8]="https://cdn.azul.com/zulu/bin/zulu8.82.0.21-ca-jdk8.0.432-linux_x64.tar.gz"
  [zulu11]="https://cdn.azul.com/zulu/bin/zulu11.78.15-ca-jdk11.0.26-linux_x64.tar.gz"
  [zulu17]="https://cdn.azul.com/zulu/bin/zulu17.52.17-ca-jdk17.0.12-linux_x64.tar.gz"
  [zulu21]="https://cdn.azul.com/zulu/bin/zulu21.36.17-ca-jdk21.0.4-linux_x64.tar.gz"
)

## 定义颜色和样式变量
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
AZURE='\033[36m'
PLAIN='\033[0m'
BOLD='\033[1m'
SUCCESS="\033[1;32m✅${PLAIN}"
WARN="\033[1;43m 警告 ${PLAIN}"
ERROR="\033[1;31m✘${PLAIN}"
TIP="\033[1;44m 提示 ${PLAIN}"
WORKING="\033[1;36m◉${PLAIN}"

## 全局变量
INTERACTIVE_MODE="true"
SILENT_MODE="false"
FORCE_INSTALL="false"
BACKUP_CONFIGS="true"
AUTO_SET_DEFAULT="false"
SPECIFIED_VERSION=""
CLEAN_SCREEN="true"

## 主函数
function main() {
    permission_judgment
    handle_command_options "$@"
    collect_system_info
    check_environment
    run_start
    
    # 如果是非交互模式，直接执行指定操作
    if [[ "${INTERACTIVE_MODE}" == "false" ]]; then
        execute_non_interactive_mode
    else
        run_interactive_mode
    fi
    
    run_end
}

## 权限检查
function permission_judgment() {
    # Java管理通常不需要root权限，但某些系统配置可能需要
    if [[ -n "$REQUIRE_ROOT" && "$REQUIRE_ROOT" == "true" ]] && [[ $EUID -ne 0 ]]; then
        output_error "权限不足，请使用 Root 用户运行本脚本"
    fi
}

## 处理命令行选项
function handle_command_options() {
    function output_command_help() {
        local script_name="javam"
        # 如果是通过管道执行的临时文件，显示友好的脚本名
        if [[ "$0" == *"/tmp/"* ]] || [[ "$0" == *"tmp."* ]]; then
            script_name="javam"
        else
            script_name="$(basename "$0")"
        fi
        
        echo -e "\n${BOLD}javam - Java 版本管理工具${PLAIN}\n"
        echo -e "使用方法: $script_name [选项]\n"
        echo -e "命令选项(名称/含义/值)：\n"
        echo -e "  --install <version>          安装指定的Java版本                                        zulu8|zulu11|zulu17|zulu21"
        echo -e "  --use <version>              切换到指定的Java版本                                      zulu8|zulu11|zulu17|zulu21"
        echo -e "  --list                       列出所有可用和已安装的Java版本                            无"
        echo -e "  --remove <version>           删除指定的Java版本                                        zulu8|zulu11|zulu17|zulu21"
        echo -e "  --install-all                安装所有支持的Java版本                                    无"
        echo -e "  --set-default <version>      设置默认Java版本                                          zulu8|zulu11|zulu17|zulu21"
        echo -e "  --current                    显示当前Java版本信息                                      无"
        echo -e "  --install-global             安装为全局命令                                            无"
        echo -e "  --install-only               仅安装javam到系统（一键安装模式）                         无"
        echo -e "  --interactive                启用交互模式（默认）                                      无"
        echo -e "  --silent                     静默模式，减少输出                                        无"
        echo -e "  --force                      强制安装，覆盖已存在版本                                  无"
        echo -e "  --no-backup                  不备份原有配置                                            无"
        echo -e "  --auto-set-default           自动设置最新安装版本为默认                                无"
        echo -e "  --clean-screen               是否在运行前清除屏幕                                      true 或 false"
        echo -e "  --help                       显示此帮助信息                                            无\n"
        echo -e "示例用法："
        echo -e "  $script_name --install zulu17          # 安装Java 17"
        echo -e "  $script_name --use zulu21              # 切换到Java 21"
        echo -e "  $script_name --list                    # 列出所有版本"
        echo -e "  $script_name --install-all --silent   # 静默安装所有版本"
        echo -e "  $script_name --install-only            # 一键安装javam到系统"
        echo -e "  $script_name                           # 启动交互模式\n"
        echo -e "一键安装命令："
        echo -e "  ${GREEN}curl -sSL https://raw.githubusercontent.com/USYDShawnTan/javam/main/javam.sh | bash -s -- --install-only${PLAIN}\n"
        echo -e "项目地址: https://github.com/USYDShawnTan/javam"
    }

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --install)
            if [[ "$2" ]]; then
                if [[ -n "${JDK_URLS[$2]}" ]]; then
                    SPECIFIED_VERSION="$2"
                    INTERACTIVE_MODE="false"
                    ACTION="install"
                    shift
                else
                    command_error "$2" "有效的Java版本 (zulu8|zulu11|zulu17|zulu21)"
                fi
            else
                command_error "$1" "Java版本"
            fi
            ;;
        --use|--switch)
            if [[ "$2" ]]; then
                if [[ -n "${JDK_URLS[$2]}" ]]; then
                    SPECIFIED_VERSION="$2"
                    INTERACTIVE_MODE="false"
                    ACTION="use"
                    shift
                else
                    command_error "$2" "有效的Java版本 (zulu8|zulu11|zulu17|zulu21)"
                fi
            else
                command_error "$1" "Java版本"
            fi
            ;;
        --remove|--uninstall)
            if [[ "$2" ]]; then
                if [[ -n "${JDK_URLS[$2]}" ]]; then
                    SPECIFIED_VERSION="$2"
                    INTERACTIVE_MODE="false"
                    ACTION="remove"
                    shift
                else
                    command_error "$2" "有效的Java版本 (zulu8|zulu11|zulu17|zulu21)"
                fi
            else
                command_error "$1" "Java版本"
            fi
            ;;
        --list)
            INTERACTIVE_MODE="false"
            ACTION="list"
            ;;
        --current)
            INTERACTIVE_MODE="false"
            ACTION="current"
            ;;
        --install-all)
            INTERACTIVE_MODE="false"
            ACTION="install_all"
            ;;
        --install-global)
            INTERACTIVE_MODE="false"
            ACTION="install_global"
            ;;
        --install-only)
            INTERACTIVE_MODE="false"
            ACTION="install_only"
            ;;
        --set-default)
            if [[ "$2" ]]; then
                if [[ -n "${JDK_URLS[$2]}" ]]; then
                    SPECIFIED_VERSION="$2"
                    INTERACTIVE_MODE="false"
                    ACTION="set_default"
                    shift
                else
                    command_error "$2" "有效的Java版本 (zulu8|zulu11|zulu17|zulu21)"
                fi
            else
                command_error "$1" "Java版本"
            fi
            ;;
        --interactive)
            INTERACTIVE_MODE="true"
            ;;
        --silent)
            SILENT_MODE="true"
            ;;
        --force)
            FORCE_INSTALL="true"
            ;;
        --no-backup)
            BACKUP_CONFIGS="false"
            ;;
        --auto-set-default)
            AUTO_SET_DEFAULT="true"
            ;;
        --clean-screen)
            if [[ "$2" ]]; then
                case "$2" in
                [Tt]rue|[Ff]alse)
                    CLEAN_SCREEN="${2,,}"
                    shift
                    ;;
                *)
                    command_error "$2" "true 或 false"
                    ;;
                esac
            else
                command_error "$1" "true 或 false"
            fi
            ;;
        --help|-h)
            output_command_help
            exit 0
            ;;
        *)
            command_error "$1"
            ;;
        esac
        shift
    done
}

## 收集系统信息
function collect_system_info() {
    # 检测操作系统
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
    else
        OS_NAME="Unknown"
        OS_VERSION="Unknown"
    fi
    
    # 检测架构
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            SUPPORTED_ARCH="true"
            ;;
        aarch64|arm64)
            SUPPORTED_ARCH="true"
            ARCH_SUFFIX="aarch64"
            ;;
        *)
            SUPPORTED_ARCH="false"
            ;;
    esac
    
    # 检测shell类型
    CURRENT_SHELL=$(basename "$SHELL")
}

## 检查环境
function check_environment() {
    # 检查必要命令
    local required_commands=("curl" "tar" "java")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd" && [[ "$cmd" != "java" ]]; then
            output_error "缺少必要命令: $cmd，请先安装"
        fi
    done
    
    # 检查网络连接
    if [[ "${SILENT_MODE}" != "true" ]]; then
        log_info "检查网络连接..."
        if ! curl -s --connect-timeout 5 https://www.baidu.com > /dev/null; then
            log_warn "网络连接检查失败，可能影响下载"
        fi
    fi
}

## 执行非交互模式
function execute_non_interactive_mode() {
    case "$ACTION" in
        install)
            install_java_version "$SPECIFIED_VERSION"
            ;;
        use)
            switch_java_version "$SPECIFIED_VERSION"
            ;;
        remove)
            remove_java_version "$SPECIFIED_VERSION"
            ;;
        list)
            list_java_versions
            ;;
        current)
            show_current_java
            ;;
        install_all)
            install_all_java_versions_silent
            ;;
        install_global)
            install_global_command_non_interactive
            ;;
        install_only)
            install_script_standalone
            ;;
        set_default)
            set_default_java_version "$SPECIFIED_VERSION"
            ;;
        *)
            output_error "未知操作: $ACTION"
            ;;
    esac
}

## 运行交互模式
function run_interactive_mode() {
    while true; do
        if [[ "${CLEAN_SCREEN}" == "true" ]]; then
            clear
        fi
        print_banner
        print_current_java
        print_menu
        
        read -p "请输入你的选择 [1-7]: " choice
        case $choice in
            1) install_all_java_versions ;;
            2) select_and_install_java_version ;;
            3) show_current_java ;;
            4) uninstall_java_menu ;;
            5) show_help_info ;;
            6) install_global_command ;;
            7) log_info "再见！"; exit 0 ;;
            *) log_error "请输入 1-7 之间的数字"; sleep 1 ;;
        esac
    done
}

## 辅助函数
function command_exists() {
    command -v "$@" &>/dev/null
}

function command_error() {
    local tmp_text="请确认后重新输入"
    if [[ "${2}" ]]; then
        tmp_text="请在该选项后指定${2}"
    fi
    output_error "命令选项 ${BLUE}$1${PLAIN} 无效，${tmp_text}！"
}

function output_error() {
    [[ "$1" ]] && echo -e "\n$ERROR $1\n"
    exit 1
}

function log_info() {
    [[ "${SILENT_MODE}" != "true" ]] && echo -e "${SUCCESS} $1"
}

function log_warn() {
    echo -e "${WARN} $1"
}

function log_error() {
    echo -e "${ERROR} $1"
}

function log_working() {
    [[ "${SILENT_MODE}" != "true" ]] && echo -e "${WORKING} $1"
}

## 核心功能函数
function print_banner() {
    if [[ "${SILENT_MODE}" == "true" ]]; then
        return
    fi
    echo -e "${BOLD}======================================${PLAIN}"
    echo -e "${BOLD} ☕ javam - Java 管理工具 CLI 面板${PLAIN}"
    echo -e "${BOLD}======================================${PLAIN}"
}

function print_menu() {
    echo -e "\n${BOLD}功能菜单:${PLAIN}"
    echo -e "1. 一键安装所有版本（默认使用 zulu21）"
    echo -e "2. 安装或切换指定版本"
    echo -e "3. 查看当前版本信息"
    echo -e "4. 删除某个版本"
    echo -e "5. 帮助信息"
    echo -e "6. 安装为全局命令"
    echo -e "7. 退出"
    echo
}

function print_current_java() {
    if type -p java >/dev/null 2>&1 && [[ -n "$JAVA_HOME" ]]; then
        echo -e "\n${BOLD}当前 Java 版本:${PLAIN}"
        java -version 2>&1 | head -n 1
        echo -e "JAVA_HOME: ${BLUE}$JAVA_HOME${PLAIN}"
    else
        echo -e "\n${WARN} 当前未设置 Java 环境变量 (JAVA_HOME)"
    fi

    echo -e "\n${BOLD}👉 已安装版本列表:${PLAIN}"
    current_dirname=$(get_current_java_version_dirname)
    for ver in "${!JDK_URLS[@]}"; do
        url=${JDK_URLS[$ver]}
        fname=$(basename "$url")
        dirname="${fname%.tar.gz}"
        if [[ -d "$JDK_DIR/$dirname" ]]; then
            if [[ "$dirname" == "$current_dirname" ]]; then
                echo -e "${GREEN}[✅]${PLAIN} $ver（当前使用）"
            else
                echo -e "${GREEN}[✅]${PLAIN} $ver"
            fi
        else
            echo -e "${RED}[ ]${PLAIN} $ver"
        fi
    done
    echo
}

function get_current_java_version_dirname() {
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

function set_current_java() {
    export JAVA_HOME="$1"
    export PATH="$JAVA_HOME/bin:$PATH"
    log_info "已切换到：$JAVA_HOME"
    
    if [[ "${SILENT_MODE}" != "true" ]]; then
        java -version
    fi

    # 确定shell配置文件
    shell_rc=""
    if [[ -n "$ZSH_VERSION" ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]]; then
        shell_rc="$HOME/.bashrc"
    else
        # 尝试检测默认shell
        case "$CURRENT_SHELL" in
            zsh) shell_rc="$HOME/.zshrc" ;;
            bash) shell_rc="$HOME/.bashrc" ;;
            *) shell_rc="$HOME/.profile" ;;
        esac
    fi

    # 备份配置文件
    if [[ "${BACKUP_CONFIGS}" == "true" && -f "$shell_rc" ]]; then
        cp "$shell_rc" "${shell_rc}.javam.bak.$(date +%Y%m%d_%H%M%S)"
    fi

    # 更新配置文件
    sed -i '/# javam 自动设置/,$d' "$shell_rc" 2>/dev/null || true
    echo "# javam 自动设置" >> "$shell_rc"
    echo "export JAVA_HOME=\"$JAVA_HOME\"" >> "$shell_rc"
    echo "export PATH=\"$JAVA_HOME/bin:\$PATH\"" >> "$shell_rc"
    
    log_info "设置已写入 $shell_rc"
    log_info "请执行 'source $shell_rc' 或重新打开终端以生效新设置"
}

function install_java_version() {
    local version="$1"
    local url="${JDK_URLS[$version]}"
    local fname=$(basename "$url")
    local dirname="${fname%.tar.gz}"
    local target_dir="$JDK_DIR/$dirname"

    if [[ -d "$target_dir" && "${FORCE_INSTALL}" != "true" ]]; then
        log_info "$version 已安装，使用 --force 强制重新安装"
        return 0
    fi

    log_working "正在下载 $version..."
    cd "$JDK_DIR"
    
    if ! curl -LO "$url"; then
        log_error "下载失败: $version"
        return 1
    fi

    log_working "正在解压 $version..."
    if ! tar -xzf "$fname"; then
        log_error "解压失败: $version"
        rm -f "$fname"
        return 1
    fi

    rm -f "$fname"
    log_info "安装完成: $version"

    if [[ "${AUTO_SET_DEFAULT}" == "true" ]]; then
        set_current_java "$target_dir"
    fi

    return 0
}

function switch_java_version() {
    local version="$1"
    local url="${JDK_URLS[$version]}"
    local fname=$(basename "$url")
    local dirname="${fname%.tar.gz}"
    local target_dir="$JDK_DIR/$dirname"

    if [[ ! -d "$target_dir" ]]; then
        log_warn "$version 未安装，正在安装..."
        install_java_version "$version"
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi

    set_current_java "$target_dir"
    return 0
}

function remove_java_version() {
    local version="$1"
    local url="${JDK_URLS[$version]}"
    local fname=$(basename "$url")
    local dirname="${fname%.tar.gz}"
    local target_dir="$JDK_DIR/$dirname"

    if [[ ! -d "$target_dir" ]]; then
        log_warn "$version 未安装"
        return 1
    fi

    if [[ "${INTERACTIVE_MODE}" == "true" ]]; then
        read -p "⚠️ 确定要删除 $version？[y/N]: " confirm
        [[ "$confirm" != "y" && "$confirm" != "Y" ]] && return 0
    fi

    rm -rf "$target_dir"
    log_info "已删除 $version"
}

function list_java_versions() {
    echo -e "\n${BOLD}可用的Java版本:${PLAIN}"
    for ver in "${!JDK_URLS[@]}"; do
        url=${JDK_URLS[$ver]}
        fname=$(basename "$url")
        dirname="${fname%.tar.gz}"
        if [[ -d "$JDK_DIR/$dirname" ]]; then
            echo -e "  ${GREEN}✅${PLAIN} $ver (已安装)"
        else
            echo -e "  ${RED}✘${PLAIN} $ver (未安装)"
        fi
    done
    echo
}

function show_current_java() {
    if command_exists java; then
        echo -e "\n${BOLD}当前Java版本信息:${PLAIN}"
        java -version
        echo -e "\nJAVA_HOME: ${BLUE}${JAVA_HOME:-"未设置"}${PLAIN}"
    else
        echo -e "\n${WARN} 未找到Java安装"
    fi
    
    if [[ "${INTERACTIVE_MODE}" == "true" ]]; then
        read -p "按任意键返回菜单..." _
    fi
}

function install_all_java_versions() {
    log_working "开始批量下载所有支持的 Java 版本..."
    local installed_count=0
    
    for ver in "${!JDK_URLS[@]}"; do
        if install_java_version "$ver"; then
            ((installed_count++))
        fi
    done
    
    log_info "批量安装完成，共安装 $installed_count 个版本"
    
    # 设置默认版本为zulu21
    if [[ -n "${JDK_URLS[zulu21]}" ]]; then
        switch_java_version "zulu21"
    fi
    
    if [[ "${INTERACTIVE_MODE}" == "true" ]]; then
        read -p "按任意键返回菜单..." _
    fi
}

function install_all_java_versions_silent() {
    SILENT_MODE="true"
    install_all_java_versions
}

function select_and_install_java_version() {
    current_ver=$(get_current_java_version_dirname)
    echo -e "\n${BOLD}请选择 Java 版本:${PLAIN}"
    
    local options=()
    for ver in "${!JDK_URLS[@]}"; do
        options+=("$ver")
    done
    options+=("返回")
    
    PS3="请输入编号选择版本（当前为：$current_ver）："
    select ver in "${options[@]}"; do
        [[ "$ver" == "返回" ]] && break
        
        if [[ -n "${JDK_URLS[$ver]}" ]]; then
            switch_java_version "$ver"
            if [[ "${INTERACTIVE_MODE}" == "true" ]]; then
                read -p "按任意键返回菜单..." _
            fi
            break
        else
            log_error "无效选择"
        fi
    done
}

function uninstall_java_menu() {
    echo -e "\n${BOLD}选择要删除的版本:${PLAIN}"
    cd "$JDK_DIR" 2>/dev/null || { log_error "目录不存在: $JDK_DIR"; return 1; }
    
    local dirs=(*/)
    if [[ ${#dirs[@]} -eq 1 && "${dirs[0]}" == "*/" ]]; then
        log_warn "没有已安装的Java版本"
        if [[ "${INTERACTIVE_MODE}" == "true" ]]; then
            read -p "按任意键返回菜单..." _
        fi
        return 0
    fi
    
    dirs+=("返回")
    
    select dir in "${dirs[@]}"; do
        [[ "$dir" == "返回" ]] && break
        
        if [[ -d "$JDK_DIR/$dir" ]]; then
            read -p "⚠️ 确定要删除 $dir？[y/N]: " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                rm -rf "$JDK_DIR/$dir"
                log_info "已删除 $dir"
            fi
            if [[ "${INTERACTIVE_MODE}" == "true" ]]; then
                read -p "按任意键返回菜单..." _
            fi
            break
        else
            log_error "无效路径"
        fi
    done
}

function set_default_java_version() {
    local version="$1"
    switch_java_version "$version"
}

function show_help_info() {
    output_command_help
    if [[ "${INTERACTIVE_MODE}" == "true" ]]; then
        read -p "按任意键返回菜单..." _
    fi
}

function install_global_command() {
    echo -e "\n${BOLD}安装 javam 为全局命令${PLAIN}"
    echo -e "这将把 javam 安装到 ${BLUE}/usr/local/bin/javam${PLAIN}，使你可以在任意目录使用 javam 命令。\n"
    
    read -p "是否继续？[y/N]: " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "取消安装"
        if [[ "${INTERACTIVE_MODE}" == "true" ]]; then
            read -p "按任意键返回菜单..." _
        fi
        return 0
    fi
    
    install_global_command_execute
}

function install_global_command_non_interactive() {
    install_global_command_execute
}

function install_global_command_execute() {
    local install_path="/usr/local/bin/javam"
    local current_script="$0"
    
    # 如果是临时文件（通过管道执行），需要重新下载
    if [[ "$current_script" == *"/tmp/"* ]] || [[ "$current_script" == *"tmp."* ]]; then
        log_working "检测到通过管道执行，正在下载最新版本..."
        local temp_download=$(mktemp)
        if ! curl -sSL "https://raw.githubusercontent.com/USYDShawnTan/javam/main/javam.sh" -o "$temp_download"; then
            log_error "下载失败，请检查网络连接"
            return 1
        fi
        current_script="$temp_download"
    fi
    
    # 检查是否有sudo权限
    log_working "安装 javam 到 $install_path..."
    if [[ $EUID -ne 0 ]]; then
        if ! sudo cp "$current_script" "$install_path"; then
            log_error "安装失败，请检查sudo权限"
            return 1
        fi
        if ! sudo chmod +x "$install_path"; then
            log_error "设置执行权限失败"
            return 1
        fi
    else
        if ! cp "$current_script" "$install_path"; then
            log_error "安装失败"
            return 1
        fi
        if ! chmod +x "$install_path"; then
            log_error "设置执行权限失败"
            return 1
        fi
    fi
    
    # 清理临时文件
    if [[ "$current_script" == *"/tmp/"* ]] && [[ -f "$current_script" ]]; then
        rm -f "$current_script" 2>/dev/null || true
    fi
    
    log_info "✅ 安装完成！你现在可以在任意目录直接使用 ${GREEN}javam${PLAIN} 命令啦 🎉"
    log_info "💡 使用 ${BLUE}javam --help${PLAIN} 查看帮助信息"
    log_info "💡 使用 ${BLUE}javam${PLAIN} 启动交互模式"
    
    if [[ "${INTERACTIVE_MODE}" == "true" ]]; then
        read -p "按任意键返回菜单..." _
    fi
}

## 一键安装脚本功能（集成）
function install_script_standalone() {
    echo "📦 javam 一键安装脚本"
    echo "======================================"
    echo "这个脚本将会："
    echo "1. 下载最新版本的 javam"
    echo "2. 安装到 /usr/local/bin/javam"
    echo "3. 设置执行权限"
    echo "======================================"
    echo
    
    read -p "是否继续安装？[y/N]: " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "❌ 安装已取消"
        exit 0
    fi
    
    install_global_command_execute
}

function run_start() {
    if [[ "${CLEAN_SCREEN}" == "true" && "${INTERACTIVE_MODE}" == "true" ]]; then
        clear
    fi
    if [[ "${SILENT_MODE}" != "true" ]]; then
        echo -e "${BOLD}javam v2.0 - Java版本管理工具${PLAIN}"
        [[ "${INTERACTIVE_MODE}" == "false" ]] && echo
    fi
}

function run_end() {
    if [[ "${SILENT_MODE}" != "true" ]]; then
        echo -e "\n✨ 操作完成！项目地址: ${AZURE}https://github.com/USYDShawnTan/javam${PLAIN}\n"
    fi
}

# 如果直接执行脚本（不是被source），则运行main函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
