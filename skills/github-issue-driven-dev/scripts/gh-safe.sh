#!/usr/bin/env bash
# gh-safe.sh — 幂等的 GitHub CLI 写操作包装与纯净图床直传工具
#
# 核心能力：
#   1. issue-create: 创建前查重，防止网络重试或智能体重新执行导致重复建单
#   2. issue-comment: 评论前比对最近评论正文，防止重复追加完全相同的评论
#   3. issue-close: 幂等关闭已解决的 Issue，支持指定关闭理由与结案说明
#   4. issue-view: 便捷查看指定 Issue 的状态、标题与讨论
#   5. upload-asset: 直传图片/视频到 GitHub 官方 user-attachments，零 git 提交，零污染仓库

set -euo pipefail

# 依赖检查
check_dependencies() {
  local missing=()
  command -v gh >/dev/null 2>&1 || missing+=("gh (GitHub CLI: brew install gh && gh auth login)")
  command -v jq >/dev/null 2>&1 || missing+=("jq (JSON 处理器: brew install jq)")
  command -v curl >/dev/null 2>&1 || missing+=("curl")
  if [ ${#missing[@]} -gt 0 ]; then
    echo "[gh-safe] 缺少必要依赖：" >&2
    for m in "${missing[@]}"; do
      echo "  - $m" >&2
    done
    exit 1
  fi
}

get_repo() {
  if [ -n "${REPO:-}" ]; then
    echo "$REPO"
    return
  fi
  local detected
  detected=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)
  if [ -z "$detected" ]; then
    detected=$(git remote get-url origin 2>/dev/null | sed -E 's/.*github\.com[:\/]([^\/]+\/[^\/\.]+)(\.git)?/\1/' || true)
  fi
  if [ -z "$detected" ]; then
    echo "[gh-safe] 错误：无法自动识别当前 GitHub 仓库。请在 Git 仓库目录下执行或设置环境变量 REPO=owner/repo" >&2
    exit 1
  fi
  echo "$detected"
}

# 规范化 Issue 编号：支持输入 123 或 #123
normalize_issue() {
  local raw="${1:?缺少 issue 编号}"
  echo "${raw#\#}"
}

# 读取正文内容：支持文件路径、标准输入 (-) 或直接字符串
read_body_content() {
  local input="${1:?缺少正文参数}"
  if [ "$input" = "-" ]; then
    cat
  elif [ -f "$input" ]; then
    cat "$input"
  else
    echo "$input"
  fi
}

check_dependencies

cmd="${1:-}"
shift || true

case "$cmd" in
  issue-create)
    REPO=$(get_repo)
    TITLE="${1:?缺少 issue 标题}"
    shift

    # 用 list 直读 API 查重（检查所有状态的同名 Issue）
    existing=$(gh issue list --repo "$REPO" --state all --limit 100 --json number,title,url \
      | jq -r --arg t "$TITLE" '.[] | select(.title == $t) | .url' | head -n 1)

    if [ -n "$existing" ]; then
      echo "[gh-safe] 同标题 issue 已存在，跳过创建: $existing"
      echo "$existing"
      exit 0
    fi

    gh issue create --repo "$REPO" --title "$TITLE" "$@"
    ;;

  issue-comment)
    REPO=$(get_repo)
    RAW_ISSUE="${1:?缺少 issue 编号}"
    ISSUE=$(normalize_issue "$RAW_ISSUE")
    BODY_ARG="${2:?缺少评论内容（支持文件路径、'-' 或文本字符串）}"

    BODY_CONTENT=$(read_body_content "$BODY_ARG")

    if [ -z "$(echo "$BODY_CONTENT" | tr -d '[:space:]')" ]; then
      echo "[gh-safe] 错误：评论正文不能为空" >&2
      exit 1
    fi

    # 与最近 20 条评论比对正文（忽略收尾空白）
    dup=$(gh issue view "$ISSUE" --repo "$REPO" --json comments \
      | jq --arg b "$BODY_CONTENT" '[.comments[-20:][] | select((.body | rtrimstr("\r\n") | rtrimstr("\n")) == ($b | rtrimstr("\r\n") | rtrimstr("\n")))] | length')

    if [ "$dup" -gt 0 ]; then
      echo "[gh-safe] 相同正文的评论已存在于 #${ISSUE}，跳过发表。"
      exit 0
    fi

    TMP_BODY=$(mktemp)
    echo "$BODY_CONTENT" > "$TMP_BODY"
    gh issue comment "$ISSUE" --repo "$REPO" --body-file "$TMP_BODY"
    rm -f "$TMP_BODY"
    echo "[gh-safe] 已成功在 #${ISSUE} 发表评论"
    ;;

  issue-close)
    REPO=$(get_repo)
    RAW_ISSUE="${1:?缺少 issue 编号}"
    ISSUE=$(normalize_issue "$RAW_ISSUE")
    REASON="${2:-completed}" # completed | not_planned
    COMMENT_ARG="${3:-}"

    # 检查当前状态是否已是 CLOSED
    state=$(gh issue view "$ISSUE" --repo "$REPO" --json state -q .state)
    if [ "$state" = "CLOSED" ]; then
      echo "[gh-safe] #${ISSUE} 当前已是 CLOSED 状态，跳过关闭操作。"
      exit 0
    fi

    if [ -n "$COMMENT_ARG" ]; then
      "$0" issue-comment "$ISSUE" "$COMMENT_ARG"
    fi

    gh issue close "$ISSUE" --repo "$REPO" --reason "$REASON"
    echo "[gh-safe] 已关闭 #${ISSUE} (理由: $REASON)"
    ;;

  issue-view)
    REPO=$(get_repo)
    RAW_ISSUE="${1:?缺少 issue 编号}"
    ISSUE=$(normalize_issue "$RAW_ISSUE")
    gh issue view "$ISSUE" --repo "$REPO" "$@"
    ;;

  upload-asset)
    REPO=$(get_repo)
    FILE="${1:?缺少要上传的文件路径}"
    if [ ! -f "$FILE" ]; then
      echo "[gh-safe] 错误：文件不存在: $FILE" >&2
      exit 1
    fi

    FILENAME=$(basename "$FILE")
    EXT="${FILENAME##*.}"
    case "$(echo "$EXT" | tr '[:upper:]' '[:lower:]')" in
      png) MIME="image/png" ;;
      jpg|jpeg) MIME="image/jpeg" ;;
      gif) MIME="image/gif" ;;
      webp) MIME="image/webp" ;;
      svg) MIME="image/svg+xml" ;;
      mov) MIME="video/quicktime" ;;
      mp4) MIME="video/mp4" ;;
      webm) MIME="video/webm" ;;
      pdf) MIME="application/pdf" ;;
      *) MIME="application/octet-stream" ;;
    esac

    TOKEN=$(gh auth token 2>/dev/null || true)
    if [ -z "$TOKEN" ]; then
      echo "[gh-safe] 错误：无法获取 GitHub Auth Token，请执行 gh auth login" >&2
      exit 1
    fi

    REPO_ID=$(gh api "repos/$REPO" --jq .id 2>/dev/null || true)
    if [ -z "$REPO_ID" ]; then
      echo "[gh-safe] 错误：无法获取仓库 ID ($REPO)，请确认仓库存在且具有访问权限" >&2
      exit 1
    fi

    TMP_OUT=$(mktemp)
    HTTP_CODE=$(curl -s -w "%{http_code}" -o "$TMP_OUT" \
      "https://uploads.github.com/user-attachments/assets?name=${FILENAME}&content_type=${MIME}&repository_id=${REPO_ID}" \
      -X POST \
      -H "Authorization: Bearer $TOKEN" \
      -H "Accept: application/json" \
      --data-binary "@$FILE")

    URL=$(jq -r .url "$TMP_OUT" 2>/dev/null || true)
    if [ -z "$URL" ] || [ "$URL" = "null" ]; then
      echo "[gh-safe] 上传失败 (HTTP $HTTP_CODE)" >&2
      if [ -f "$TMP_OUT" ]; then
        cat "$TMP_OUT" >&2
      fi
      rm -f "$TMP_OUT"
      exit 1
    fi
    rm -f "$TMP_OUT"

    echo "$URL"
    ;;

  *)
    echo "用法:" >&2
    echo "  $0 issue-create <标题> [gh issue create 参数...]" >&2
    echo "  $0 issue-comment <issue编号> <正文文件|正文内容|-（stdin）>" >&2
    echo "  $0 issue-close <issue编号> [completed|not_planned] [结案评论内容/文件]" >&2
    echo "  $0 issue-view <issue编号> [gh issue view 参数...]" >&2
    echo "  $0 upload-asset <文件路径>" >&2
    echo "" >&2
    echo "环境变量配置 (可选):" >&2
    echo "  REPO=owner/repo   显式指定目标 GitHub 仓库 (默认自动检测当前 Git 目录)" >&2
    exit 2
    ;;
esac
