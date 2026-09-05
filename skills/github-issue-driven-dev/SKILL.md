---
name: github-issue-driven-dev
description: Standard GitHub Issue-driven development, tracking, and RCA workflow. Use whenever tracking requirements or bugs via GitHub Issues, creating or updating issues, filing bug reports, posting progress updates or root-cause analysis (RCA) comments, linking related issues, closing resolved issues, or uploading screenshots/videos to GitHub user-attachments without polluting the git repo.
license: Apache-2.0
metadata:
  version: v2
  author: user
---

# GitHub Issue-Driven Development & Tracking Workflow

本技能规范并固化了面向 GitHub 项目的**需求驱动开发、过程留底、关联追踪、结案归档与零污染图片上传**的标准开发工作流。

---

## 核心原则 (Core Principles)

1. **一事一议，创建 Issue**：任何新需求立项或 Bug 发现，必须首先在 GitHub 创建对应 Issue 留底追踪。
2. **过程必留痕**：开发或排查过程中，一旦发现新问题、关键边界条件或完成修复，必须在对应 Issue 评论区追加记录（包括 RCA 根因排查与验证结论）。
3. **关联双向追踪**：若新 Issue 与已有 Issue 存在前后依赖或因果关系，必须显式引用 `#<编号>`，并在原 Issue 发表跟进评论。
4. **零污染图片直传**：截图、日志或录屏绝对禁止直接提交到 Git 仓库，必须使用 `gh-safe.sh upload-asset` 上传至 GitHub 官方附件池（`user-attachments/assets`），并在正文中以纯 Markdown 引用。
5. **幂等写操作**：严禁无保护地裸调 `gh issue create` 或 `gh issue comment`。必须通过安全脚本 `gh-safe.sh` 查重后执行，根治智能体因重试或网络重发造成的重复建单与刷屏。

---

## 工具脚本定位与解析

安全包装脚本 `gh-safe.sh` 位于本技能的 `scripts/` 目录中。使用时按以下顺序解析脚本路径：

1. **项目工程内优先**：若当前工程根目录下已集成 `./scripts/gh-safe.sh`，优先使用 `./scripts/gh-safe.sh`；
2. **技能目录定位**：若工程未内置，则直接调用本技能目录下的执行脚本：
   - 当前技能目录：`<skill-dir>/scripts/gh-safe.sh`
3. **仓库定位配置**：
   - 脚本默认通过 `gh repo view` 或 `git remote get-url origin` 自动获取当前仓库；
   - 如需显式指定跨仓库操作，可通过环境变量传参：`REPO=owner/repo <script-path> <command> ...`

---

## 完整工作流与操作指南

### 1. 新建需求 Issue (`enhancement`, `P0/P1/P2/P3`)

```bash
# 执行命令（标题查重，若存在相同标题 Issue 则跳过创建并输出已有链接）
<path-to>/gh-safe.sh issue-create "标题" --body-file <文件.md> --label enhancement --label P1
```

**正文 Markdown 模板**：
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
1. [具体命令或交互验证步骤 1]
2. [具体命令或交互验证步骤 2]

## 验收标准
- [最终达成的预期效果]

## 优先级
[P0 / P1 / P2 / P3]
```

---

### 2. 新建 Bug Issue (`bug`, `P0/P1/P2`)

```bash
# 执行命令
<path-to>/gh-safe.sh issue-create "标题" --body-file <文件.md> --label bug --label P1
```

**正文 Markdown 模板**：
```markdown
## 现象
[发生的问题与直观表现，包含环境：系统版本、硬件或分辨率]

## 复现步骤
1. [步骤 1]
2. [步骤 2]

## 现场截图（若有）
![错误现场](https://github.com/user-attachments/assets/xxxx)

## 关联 Issue（若有）
- **关联上游**：#10

## 影响面
[受影响的功能或受众]

## 初步排查与可能方向
- [代码定位或怀疑点]

## 验收标准
- [修复后的正确表现]
```

---

### 3. 过程发现新问题 / RCA 根因排查留底（Issue 评论）

当开发中遇到未预期问题、需要调整方案，或已定位根本原因完成修复时，在对应 Issue 发表留痕评论：

```bash
# 格式：gh-safe.sh issue-comment <Issue编号(支持 12 或 #12)> <正文文件 | 纯文本 | - (stdin)>
<path-to>/gh-safe.sh issue-comment 42 comment.md
# 或管道输入
cat comment.md | <path-to>/gh-safe.sh issue-comment 42 -
```

**RCA / 进展 Markdown 模板**：
```markdown
## 进展 / 发现新问题（或 结案：根因定位与修复）

### 现象与证据链
[排查过程中发现的偏差、边界情况、报错日志或 Dump 数据]

### 根因分析 (RCA)
[代码逻辑原因或系统底层机制]

### 应对方案调整 / 修复细节
- **改动文件**：`path/to/file.ext`
- **关联 Commit**：`commit_hash`

### 验证情况
- 自动化测试（如 `cargo test` / `npm test` / `pytest`）通过情况
- 手工端到端或诊断验证结论

### 验收步骤
1. [可供用户复查的具体步骤]
```

---

### 4. 零污染图片直传（免 Git 提交）

当用户提供本地图片、截图或录屏时，调用此命令直接上传：

```bash
URL=$(<path-to>/gh-safe.sh upload-asset "/path/to/screenshot.png")
echo "$URL"
# 输出示例：https://github.com/user-attachments/assets/62a7a917-cbf9-4ab8-b85d-d21cafbe93b0
```

随后直接在 Markdown 正文中嵌入链接：
```markdown
![截图描述](https://github.com/user-attachments/assets/62a7a917-cbf9-4ab8-b85d-d21cafbe93b0)
```
- **支持格式**：PNG、JPG、JPEG、GIF、WebP、SVG、MOV、MP4、WEBM、PDF。

---

### 5. 结案与关闭 Issue (`issue-close`)

当需求完成并经验收，或缺陷已合入主干并验证通过后，执行幂等关闭：

```bash
# 语法：gh-safe.sh issue-close <编号> [completed|not_planned] [结案评论文件或正文]
<path-to>/gh-safe.sh issue-close 42 completed "已合入主干并在 v1.2.0 发布，验证全部通过。"
```

---

### 6. Git Commit 与 PR 自动关联联动

在编写 Git 提交信息或创建 Pull Request 时，遵循标准关闭与引用动词：
- 修复 Bug 并自动关闭：`fix(auth): handle expired token safely (Fixes #42)`
- 实现需求并自动关闭：`feat(export): support jsonl streaming export (Closes #108)`
- 阶段性引用但不关闭：`refactor(db): optimize query indexes (Refs #56)`

---

## 进阶资源与参考

- **[规范与标签定义](references/conventions.md)**：包含完整优先级矩阵（P0~P3）、类型标签以及 GitHub 自动关闭关键字。
- **范例文件 (Examples)**：
  - [Bug Issue 范例](examples/bug_issue_example.md)
  - [需求 Issue 范例](examples/enhancement_issue_example.md)
  - [RCA 结案评论范例](examples/rca_comment_example.md)
