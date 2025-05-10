# javam ☕

一个基于 Bash 的 Zulu JDK 版本管理 CLI 工具，轻量、开箱即用，简单高效！

## ✨ 功能特性

- 一键下载 zulu8/zulu11/zulu17/zulu21
- 支持选择指定版本安装或切换
- 自动配置 JAVA_HOME 和 PATH
- 显示当前 Java 使用情况（含当前用的给出标记）
- 可规范删除已安装版本
- 所有内容中文控制台控制，不需任何三方依赖

## ⚡ 快速使用

```bash
# 下载并安装 javam
curl -sSL https://raw.githubusercontent.com/USYDShawnTan/javam/main/install.sh | bash

# 然后直接启动
javam
```

## ▶ 主界面菜单

```text
==============================
 ☕ javam - Java 管理工具 CLI 面板
==============================
当前 Java 版本：OpenJDK 17
JAVA_HOME: ~/.javam/versions/zulu17...

👉 已安装版本列表：
[ ] zulu8
[✔] zulu17 (当前使用)
[ ] zulu11
[ ] zulu21

1. 一键安装所有版本（默认切换 zulu21）
2. 指定版本安装/切换
3. 查看当前版本
4. 删除某个版本
5. 退出
```

## 📝 项目给证

MIT License

本项目由 @小谈 维护，我希望它是个简洁、好用的 Java 版本切换工具，最后帮助我更好地开 MC 服 ☕

---

想优化功能？提炼 UI？接入镜像？ 来 Issue/提 PR 我一定看！
