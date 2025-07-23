# javam - Java 版本管理工具

一个简单易用的 Zulu JDK 版本管理工具，支持安装、切换和管理多个 Java 版本。

## 🚀 一键安装

```bash
curl -sSL https://raw.githubusercontent.com/USYDShawnTan/javam/main/javam.sh | bash -s -- --install-only
```

## 🛠️ 使用方法

### 交互模式

```bash
# 启动交互式菜单
javam
```

### 命令行模式

```bash
# 安装指定版本
javam --install zulu17

# 切换到指定版本
javam --use zulu21

# 列出所有版本
javam --list

# 查看当前版本
javam --current

# 安装所有版本（静默模式）
javam --install-all --silent

# 删除指定版本
javam --remove zulu8

# 设置默认版本
javam --set-default zulu21
```

### 直接执行（无需安装）

#### 列出所有版本

```bash
curl -sSL https://raw.githubusercontent.com/USYDShawnTan/javam/main/javam.sh | bash -s -- --list

```

#### 安装指定版本

```bash
# 安装 Java 17
curl -sSL https://raw.githubusercontent.com/USYDShawnTan/javam/main/javam.sh | bash -s -- --install zulu17
```

## 🎯 支持的版本

- **zulu8**: Zulu JDK 8
- **zulu11**: Zulu JDK 11
- **zulu17**: Zulu JDK 17
- **zulu21**: Zulu JDK 21

## 📁 安装位置

- **JDK 安装目录**: `~/.javam/versions/`
- **全局命令路径**: `/usr/local/bin/javam`
- **配置文件**: `~/.bashrc` 或 `~/.zshrc`

## 📋 功能特性

- ✅ 支持 Zulu JDK 8, 11, 17, 21
- ✅ 一键安装所有版本
- ✅ 快速版本切换
- ✅ 全局命令支持
- ✅ 交互式和命令行模式
- ✅ 自动环境变量配置
- ✅ 管道执行兼容

## 🔧 系统要求

- Linux/Unix 系统
- bash shell
- curl 命令
- tar 命令
- sudo 权限（仅全局安装需要）

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License
