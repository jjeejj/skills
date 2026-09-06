---
name: github-issue-driven-dev
description: Standard GitHub Issue-driven development, tracking, and RCA workflow. Use whenever tracking requirements or bugs via GitHub Issues, creating or updating issues, filing bug reports, posting progress updates or root-cause analysis (RCA) comments, linking related issues, closing resolved issues, or uploading screenshots/videos to GitHub user-attachments without polluting the git repo. Triggers on phrases like 'file an issue', 'create bug report', 'post RCA', 'track on issue', 'upload screenshot to issue', 'close issue', or Chinese equivalents like '提issue', '创建issue', '记录到issue', 'RCA留底', '问题留痕', '上传截图到issue'.
license: Apache-2.0
metadata:
  version: v2
  author: user
---

# GitHub Issue-Driven Development & Tracking Workflow

Standardizes requirements-driven development, progress audit trails, cross-linking, issue resolution, and zero-pollution asset uploads on GitHub.

---

## Installation

Install directly into your AI agent environment via `skills`:

```bash
# Shorthand (recommended)
npx skills add jjeejj/skills --skill github-issue-driven-dev

# Or using the full repository URL
npx skills add https://github.com/jjeejj/skills --skill github-issue-driven-dev
```

---

## Core Principles

1. **User Visual Assets Zero Loss (🚨 Critical Protocol)**: Whenever a user uploads or references any screenshot, screen recording, or diagnostic log (e.g., `.user_uploaded/media_*.png`), the agent **MUST** upload it via `gh-safe.sh upload-asset "<filepath>"` **BEFORE** writing code, formulating implementation plans, or replying with technical findings, and embed it as Markdown in the associated GitHub Issue or comment.
2. **One Issue Per Scope**: Every new feature, enhancement, or bug report must have a corresponding GitHub Issue filed first.
3. **Audit Trails & Progress Logging**: When encountering edge cases, discovering unexpected regressions, or completing a fix, append an update or Root Cause Analysis (RCA) comment to the issue.
4. **Bidirectional Cross-Referencing**: When a new issue depends on or relates to an existing issue, explicitly reference `#<number>` and notify the origin issue.
5. **Zero-Pollution Asset Storage**: Media files must NEVER be committed to the Git repository. Always route through GitHub's official attachment storage (`user-attachments/assets`).
6. **Idempotent Write Operations**: Never invoke bare `gh issue create` or `gh issue comment` without deduplication checks. Always use `gh-safe.sh` to prevent duplicate tickets and repeated comments caused by agent retries or network replays.

---

## Script Location & Resolution

The helper script `gh-safe.sh` is located inside the skill's `scripts/` directory. When executing commands, resolve the script path in this order:

1. **Project-local script (Preferred if integrated)**: `./scripts/gh-safe.sh`
2. **Skill-bundled script**: `<skill-directory>/scripts/gh-safe.sh`
3. **Target Repository**:
   - Defaults automatically to the current Git repository via `gh repo view` or `git remote get-url origin`.
   - Explicit repository override: `REPO=owner/repo <script-path> <command> ...`

---

## Language Consistency Rule (严禁中英文混杂)

**Strict Uniformity Requirement**: The generated issue title, section headings, and content body MUST remain 100% linguistically consistent.
- **Chinese context** (user uses Chinese or repo primarily in Chinese): Use **pure Chinese headings and content**. NEVER output English headings like `## Symptoms` followed by Chinese body text!
- **English context** (user uses English or international repo): Use **pure English headings and content**.

---

## Complete Workflow & Usage Guide

### 1. File Feature or Enhancement Issue (`enhancement`, `P0/P1/P2/P3`)

```bash
# Checks for existing issues with the same title before creating:
<path-to>/gh-safe.sh issue-create "Title" --body-file <body.md> --label enhancement --label P1
```

**Markdown Body Template**:

::: tabs
@tab Chinese (中文项目/中文用户)
```markdown
## 背景
[现状描述与痛点分析]

## 需求
- [需求点 1]
- [需求点 2]

## 关联 Issue（若有）
- **前置依赖**：#3
- **相关需求**：#9

## 验收步骤
1. [具体验证步骤 1]
2. [具体验证步骤 2]

## 验收标准
- [最终达成的预期效果]

## 优先级
[P0 / P1 / P2 / P3]
```

@tab English (International / English)
```markdown
## Background
[Context and problem statement]

## Requirements
- [Requirement item 1]
- [Requirement item 2]

## Related Issues (If any)
- **Preceding dependency**: #3
- **Related requirement**: #9

## Acceptance Steps
1. [Verification step 1]
2. [Verification step 2]

## Acceptance Criteria
- [Expected outcome]

## Priority
[P0 / P1 / P2 / P3]
```
:::

---

### 2. File Bug Report Issue (`bug`, `P0/P1/P2`)

```bash
<path-to>/gh-safe.sh issue-create "Title" --body-file <body.md> --label bug --label P1
```

**Markdown Body Template**:

::: tabs
@tab Chinese (中文项目/中文用户)
```markdown
## 现象
[发生的问题与直观表现，包含环境：系统版本、架构、屏幕分辨率]

## 复现步骤
1. [步骤 1]
2. [步骤 2]

## 现场截图 / 录屏证据（若有）
![现场证据](https://github.com/user-attachments/assets/xxxx)

## 关联 Issue（若有）
- **关联上游**：#10

## 影响面
[受影响的功能或受众]

## 初步排查与可能方向
- [代码定位或怀疑点]

## 验收标准
- [修复后的正确表现]
```

@tab English (International / English)
```markdown
## Symptoms
[Observed error and visual behavior, including OS version, architecture, screen resolution]

## Steps to Reproduce
1. [Step 1]
2. [Step 2]

## Crash / Visual Evidence (If any)
![Error Screenshot](https://github.com/user-attachments/assets/xxxx)

## Related Issues (If any)
- **Upstream dependency**: #10

## Impact
[Affected user groups or components]

## Initial Investigation & Suspected Areas
- [Suspected code location or mechanism]

## Acceptance Criteria
- [Correct behavior after fix]
```
:::

---

### 3. Log Progress / File RCA Root Cause Analysis (Issue Comment)

Whenever encountering unexpected findings during development or concluding a fix, append a deduplicated comment:

```bash
# Syntax: gh-safe.sh issue-comment <issue_number (e.g. 42 or #42)> <file | text | - (stdin)>
<path-to>/gh-safe.sh issue-comment 42 comment.md
# Or pipe from stdin:
cat comment.md | <path-to>/gh-safe.sh issue-comment 42 -
```

**RCA / Progress Comment Template**:

::: tabs
@tab Chinese (中文项目/中文用户)
```markdown
## 进展 / RCA 根因定位与修复（或 结案报告）

### 现象与证据链
[排查过程中发现的偏差、边界情况、报错日志或 Dump 数据]

### 根因分析 (RCA)
[代码逻辑原因或系统底层机制]

### 应对方案调整 / 修复细节
- **改动文件**：`path/to/file.ext`
- **关联 Commit**：`commit_hash`

### 验证情况
- 自动化测试运行及结果
- 手工端到端或诊断验证结论

### 验收步骤
1. [可供复查的具体步骤]
```

@tab English (International / English)
```markdown
## Progress / RCA: Root Cause & Resolution

### Symptoms & Evidence Chain
[Discrepancies, edge cases, error logs, or diagnostic dumps]

### Root Cause Analysis (RCA)
[Underlying code defect, race condition, or platform mechanism]

### Solution & Changes
- **Modified Files**: `path/to/file.ext`
- **Associated Commit**: `commit_hash`

### Verification
- Automated test command and output
- Manual end-to-end verification results

### Verification Steps
1. [Steps for reviewers/users to verify]
```
:::

---

### 4. 🚨 Critical Protocol: User Visual Assets Zero Loss (Mandatory Gatekeeper)

**Execution Rule**: Whenever the user uploads or references any screenshot, screen recording, or diagnostic log (e.g., path in `.user_uploaded/media_*.png`, `*.png`, `*.jpg`, `*.mov`, `*.mp4`):
- **BEFORE** touching code, formulating implementation plans, or replying with technical findings, the agent **MUST FIRST** execute:
```bash
URL=$(<path-to>/gh-safe.sh upload-asset "/path/to/screenshot.png")
echo "$URL"
# Output example: https://github.com/user-attachments/assets/62a7a917-cbf9-4ab8-b85d-d21cafbe93b0
```

**Direct Embedding & Autonomous Continuation (No Confirmation Prompt Needed)**:
- Do NOT block or wait for user confirmation.
- Immediately embed the returned URL into the relevant GitHub Issue body or comment:
  `![Screenshot description]($URL)`
- Inform the user in the response that the asset has been uploaded and embedded, and proceed with the technical work.
- **Pre-commit Anti-Pollution Guard**: NEVER commit media files directly to git (`git add *.png`).
- **No Automatic Commits**: NEVER run `git commit` or `git push` automatically without explicit user instruction.
- **Supported Formats**: PNG, JPG, JPEG, GIF, WebP, SVG, MOV, MP4, WEBM, PDF.

---

### 5. Close Resolved Issue (`issue-close`)

Once acceptance verification is complete:

```bash
# Syntax: gh-safe.sh issue-close <issue_number> [completed|not_planned] [closing_comment_or_file]
<path-to>/gh-safe.sh issue-close 42 completed "Merged into main and released in v1.2.0. All verifications passed."
```

---

### 6. Git Commit & PR Linkage

Follow standard keywords in commit messages or pull requests to link or auto-close issues:
- Fix bug and auto-close: `fix(auth): handle expired token safely (Fixes #42)`
- Feature delivery and auto-close: `feat(export): support jsonl streaming export (Closes #108)`
- Reference without closing: `refactor(db): optimize query indexes (Refs #56)`

---

## References & Examples

- **[Conventions & Label Taxonomies](references/conventions.md)**: Full priority matrix (P0-P3), type labels, and GitHub auto-closing keywords.
- **Example Files**:
  - [Bug Issue Example](examples/bug_issue_example.md)
  - [Feature Issue Example](examples/enhancement_issue_example.md)
  - [RCA Comment Example](examples/rca_comment_example.md)
