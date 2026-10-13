#!/usr/bin/env bash
set -euo pipefail

# 确保 chezmoi 与常见工具所在目录在 PATH 中
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRET_PATTERN='(_authToken\s*=|"gh_token"\s*:|<password>[^<]+</password>|npm_[A-Za-z0-9]{10,}|gh[pousr]_[A-Za-z0-9]{10,}|github_pat_[A-Za-z0-9_]{10,})'

# 1. 自动挂载 Git pre-commit 敏感信息拦截钩子（防止新设备克隆后丢失）
PRE_COMMIT_PATH="$REPO_ROOT/.git/hooks/pre-commit"
mkdir -p "$REPO_ROOT/.git/hooks"

cat << 'EOF' > "$PRE_COMMIT_PATH"
#!/bin/sh
SECRET_PATTERN='(_authToken\s*=|"gh_token"\s*:|<password>[^<]+</password>|npm_[A-Za-z0-9]{10,}|gh[pousr]_[A-Za-z0-9]{10,}|github_pat_[A-Za-z0-9_]{10,})'
if git diff --cached -U0 -- . ':(exclude).vscode/sync-watch.sh' | grep -E -i "$SECRET_PATTERN" >/dev/null 2>&1; then
    echo "❌ [Security] 检测到暂存区包含疑似 Token 或密码，已拦截提交！请执行 git diff --cached 检查。"
    exit 1
fi
EOF
chmod +x "$PRE_COMMIT_PATH"

# 2. 打开 VS Code 时，自动拉回外部最新修改
chezmoi re-add

# 检查拉回的改动中是否包含敏感凭据
DIFF_OUTPUT=$(git -C "$REPO_ROOT" diff -U0 -- . ':(exclude).vscode/sync-watch.sh' 2>/dev/null || true)
if echo "$DIFF_OUTPUT" | grep -E -i "$SECRET_PATTERN" >/dev/null 2>&1; then
    echo -e "\033[31m[警告] 检测到外部配置拉回了疑似 Token/密码，提交前请务必检查 git diff！\033[0m"
fi

echo -e "\033[32m[chezmoi] 已拉取外部最新配置，正在监听 Ctrl+S 保存实时同步...\033[0m"

# 3. 监听仓库内文件保存（Ctrl+S），防抖实时同步回系统原文件
if command -v inotifywait >/dev/null 2>&1; then
    # 事件驱动模式 (安装了 inotify-tools 时，内核级零延迟)
    inotifywait -m -r -q -e close_write,moved_to,create --exclude '(\.git|\.vscode)' "$REPO_ROOT" | while read -r dir events filename; do
        sleep 0.2
        chezmoi apply --force
        echo -e "\033[36m[$(date +'%H:%M:%S')] 已实时同步至系统: ${filename}\033[0m"
    done
else
    # 极简监听模式 (基于仓库内部文件状态变化，零额外依赖)
    get_state() {
        find "$REPO_ROOT" -not -path '*/.git*' -not -path '*/.vscode*' -type f -exec stat -c '%n %Y' {} + 2>/dev/null | sort
    }

    LAST_STATE="$(get_state)"
    while true; do
        sleep 0.5
        CURRENT_STATE="$(get_state)"
        if [ "$CURRENT_STATE" != "$LAST_STATE" ]; then
            sleep 0.2
            chezmoi apply --force
            LAST_STATE="$(get_state)"
            echo -e "\033[36m[$(date +'%H:%M:%S')] 已实时同步至系统原文件\033[0m"
        fi
    done
fi
