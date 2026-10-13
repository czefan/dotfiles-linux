# Dotfiles (Linux / WSL)

基于 [chezmoi](https://www.chezmoi.io/) 与 [mise](https://mise.jdx.dev/) 管理的 Linux / WSL 个人开发环境配置仓库。

## 包含配置

| 类别 | 配置文件 | 说明 |
| :--- | :--- | :--- |
| **Zsh 终端** | [`dot_zshrc`](./dot_zshrc) | 环境变量加载、历史记录、fzf 预览、别名与 Starship 提示符 |
| **开发工具链 (mise)** | [`config.toml`](./dot_config/mise/config.toml) | 统一版本控制（Node.js, Go, Python/uv, CLI 工具链） |
| **Git 配置** | [`dot_gitconfig`](./dot_gitconfig)、[`ignore`](./dot_config/git/ignore) | Git 基础信息、delta 语法高亮与全局忽略规则 |
| **规范与规则** | [`GEMINI.md`](./dot_gemini/GEMINI.md)、[`dot_markdownlint.json`](./dot_markdownlint.json) | 全局开发规则与 Markdown 格式化规范 |

## 新设备快速恢复

在全新 Linux 或 WSL 环境中，执行以下两步即可完成全套开发环境恢复：

```bash
# 1. 一键拉取并应用全部配置文件
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply czefan/dotfiles-linux

# 2. 一键安装全部运行时语言与 CLI 工具链
mise install
```

## 日常维护

* **VS Code 可视化编辑与提交**：

  ```bash
  code $(chezmoi source-path)
  ```

  打开仓库时会自动执行 `chezmoi re-add` 拉取外部修改；在 VS Code 中按 `Ctrl+S` 保存文件会自动触发 `chezmoi apply` 实时同步回系统原文件。
* **命令行常用操作**：

  ```bash
  chezmoi add <file>   # 纳入新配置文件
  chezmoi re-add       # 将外部系统原文件的修改同步回仓库
  chezmoi diff         # 查看仓库与系统原文件的差异
  chezmoi apply        # 将仓库配置应用到系统
  ```

## License

[MIT](./LICENSE)
