#!/usr/bin/env bash
# gh-safe.sh — Idempotent GitHub CLI wrapper and clean asset uploader
#
# Core Capabilities:
#   1. issue-create: Checks for existing issues before creating to avoid duplicates from retries.
#   2. issue-comment: Compares with recent comments to prevent posting identical duplicate comments.
#   3. issue-close: Idempotently closes resolved issues with reason and optional closing comment.
#   4. issue-view: Inspects issue status, title, and conversation.
#   5. upload-asset: Directly uploads images/videos to GitHub user-attachments without git commits.

set -euo pipefail

# Check dependencies
check_dependencies() {
  local missing=()
  command -v gh >/dev/null 2>&1 || missing+=("gh (GitHub CLI: brew install gh && gh auth login)")
  command -v jq >/dev/null 2>&1 || missing+=("jq (JSON processor: brew install jq)")
  command -v curl >/dev/null 2>&1 || missing+=("curl")
  if [ ${#missing[@]} -gt 0 ]; then
    echo "[gh-safe] Missing required dependencies:" >&2
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
    echo "[gh-safe] Error: Unable to detect current GitHub repository. Run inside a git repo or set REPO=owner/repo" >&2
    exit 1
  fi
  echo "$detected"
}

# Normalize issue identifier (supports 123 or #123)
normalize_issue() {
  local raw="${1:?Missing issue number}"
  echo "${raw#\#}"
}

# Read body content from file path, stdin (-), or direct string
read_body_content() {
  local input="${1:?Missing body argument}"
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
    TITLE="${1:?Missing issue title}"
    shift

    # Deduplicate against existing issues across all states
    existing=$(gh issue list --repo "$REPO" --state all --limit 100 --json number,title,url \
      | jq -r --arg t "$TITLE" '.[] | select(.title == $t) | .url' | head -n 1)

    if [ -n "$existing" ]; then
      echo "[gh-safe] Issue with identical title already exists, skipping creation: $existing"
      echo "$existing"
      exit 0
    fi

    gh issue create --repo "$REPO" --title "$TITLE" "$@"
    ;;

  issue-comment)
    REPO=$(get_repo)
    RAW_ISSUE="${1:?Missing issue number}"
    ISSUE=$(normalize_issue "$RAW_ISSUE")
    BODY_ARG="${2:?Missing comment content (file path, '-', or text string)}"

    BODY_CONTENT=$(read_body_content "$BODY_ARG")

    if [ -z "$(echo "$BODY_CONTENT" | tr -d '[:space:]')" ]; then
      echo "[gh-safe] Error: Comment body cannot be empty" >&2
      exit 1
    fi

    # Deduplicate against the 20 most recent comments (ignoring trailing whitespace)
    dup=$(gh issue view "$ISSUE" --repo "$REPO" --json comments \
      | jq --arg b "$BODY_CONTENT" '[.comments[-20:][] | select((.body | rtrimstr("\r\n") | rtrimstr("\n")) == ($b | rtrimstr("\r\n") | rtrimstr("\n")))] | length')

    if [ "$dup" -gt 0 ]; then
      echo "[gh-safe] Identical comment already exists on #${ISSUE}, skipping."
      exit 0
    fi

    TMP_BODY=$(mktemp)
    echo "$BODY_CONTENT" > "$TMP_BODY"
    gh issue comment "$ISSUE" --repo "$REPO" --body-file "$TMP_BODY"
    rm -f "$TMP_BODY"
    echo "[gh-safe] Comment posted to #${ISSUE}"
    ;;

  issue-close)
    REPO=$(get_repo)
    RAW_ISSUE="${1:?Missing issue number}"
    ISSUE=$(normalize_issue "$RAW_ISSUE")
    REASON="${2:-completed}" # completed | not_planned
    COMMENT_ARG="${3:-}"

    # Check if already closed
    state=$(gh issue view "$ISSUE" --repo "$REPO" --json state -q .state)
    if [ "$state" = "CLOSED" ]; then
      echo "[gh-safe] #${ISSUE} is already closed, skipping."
      exit 0
    fi

    if [ -n "$COMMENT_ARG" ]; then
      "$0" issue-comment "$ISSUE" "$COMMENT_ARG"
    fi

    gh issue close "$ISSUE" --repo "$REPO" --reason "$REASON"
    echo "[gh-safe] Closed #${ISSUE} (reason: $REASON)"
    ;;

  issue-view)
    REPO=$(get_repo)
    RAW_ISSUE="${1:?Missing issue number}"
    ISSUE=$(normalize_issue "$RAW_ISSUE")
    gh issue view "$ISSUE" --repo "$REPO" "$@"
    ;;

  upload-asset)
    REPO=$(get_repo)
    FILE="${1:?Missing file path to upload}"
    if [ ! -f "$FILE" ]; then
      echo "[gh-safe] Error: File not found: $FILE" >&2
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
      echo "[gh-safe] Error: Unable to retrieve GitHub auth token. Run 'gh auth login' first." >&2
      exit 1
    fi

    REPO_ID=$(gh api "repos/$REPO" --jq .id 2>/dev/null || true)
    if [ -z "$REPO_ID" ]; then
      echo "[gh-safe] Error: Unable to fetch repository ID for $REPO. Verify access permissions." >&2
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
      echo "[gh-safe] Upload failed (HTTP $HTTP_CODE)" >&2
      if [ -f "$TMP_OUT" ]; then
        cat "$TMP_OUT" >&2
      fi
      rm -f "$TMP_OUT"
      exit 1
    fi
    rm -f "$TMP_OUT"

    echo "$URL"
    ;;

  issue-edit)
    REPO=$(get_repo)
    RAW_ISSUE="${1:?Missing issue number}"
    ISSUE=$(normalize_issue "$RAW_ISSUE")
    BODY_ARG="${2:?Missing new body (file path, '-', or text string)}"
    shift 2 || true

    BODY_CONTENT=$(read_body_content "$BODY_ARG")
    TMP_BODY=$(mktemp)
    echo "$BODY_CONTENT" > "$TMP_BODY"
    gh issue edit "$ISSUE" --repo "$REPO" --body-file "$TMP_BODY" "$@"
    rm -f "$TMP_BODY"
    echo "[gh-safe] Updated issue #${ISSUE}"
    ;;

  comment-edit)
    REPO=$(get_repo)
    COMMENT_ID="${1:?Missing comment ID}"
    BODY_ARG="${2:?Missing new body (file path, '-', or text string)}"

    BODY_CONTENT=$(read_body_content "$BODY_ARG")
    TMP_BODY=$(mktemp)
    echo "$BODY_CONTENT" > "$TMP_BODY"
    jq -n --rawfile body "$TMP_BODY" '{body: $body}' \
      | gh api -X PATCH "repos/$REPO/issues/comments/$COMMENT_ID" --input - >/dev/null
    rm -f "$TMP_BODY"
    echo "[gh-safe] Updated comment ${COMMENT_ID}"
    ;;

  *)
    echo "Usage:" >&2
    echo "  $0 issue-create <title> [gh issue create flags...]" >&2
    echo "  $0 issue-comment <issue_number> <body_file | text | - (stdin)>" >&2
    echo "  $0 issue-edit <issue_number> <body_file | text | - (stdin)> [gh issue edit flags...]" >&2
    echo "  $0 comment-edit <comment_id> <body_file | text | - (stdin)>" >&2
    echo "  $0 issue-close <issue_number> [completed|not_planned] [closing_comment_text_or_file]" >&2
    echo "  $0 issue-view <issue_number> [gh issue view flags...]" >&2
    echo "  $0 upload-asset <file_path>" >&2
    echo "" >&2
    echo "Environment Variables (Optional):" >&2
    echo "  REPO=owner/repo   Explicitly target repository (defaults to current git repo)" >&2
    exit 2
    ;;
esac
