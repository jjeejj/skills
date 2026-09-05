# GitHub Issue & Task Conventions

本规范定义了基于 GitHub Issues 驱动开发过程中的标签体系、优先级划分、生命周期状态及 Git Commit / PR 联动规范。

---

## 1. 标签体系 (Label Taxonomy)

### 1.1 类型标签 (Type)
| 标签名 | 颜色建议 | 说明 |
| :--- | :--- | :--- |
| `bug` | `#d73a4a` (红) | 缺陷排查与修复 |
| `enhancement` | `#a2eeef` (浅蓝) | 新功能、功能增强或演进需求 |
| `documentation` | `#0075ca` (蓝) | 文档编写、规范更新或注释补充 |
| `refactor` | `#cfd3d7` (灰) | 代码重构（不改变外部行为） |
| `chore` | `#fef2c0` (浅黄) | 构建脚本、依赖升级或辅助性杂务 |

### 1.2 优先级标签 (Priority)
| 优先级 | 适用场景 | 响应与跟进要求 |
| :--- | :--- | :--- |
| `P0` | **阻断性紧急故障**：生产服务不可用、数据丢失损坏、主干构建破损 | 立即中断其他工作，集中排查并实时留痕 |
| `P1` | **高优先级**：核心功能受阻、主流程关键缺陷、当前迭代必须交付的需求 | 优先排期，排查定位需输出完整 RCA |
| `P2` | **普通优先级**：非核心功能缺陷、常规需求演进、有可行变通方案的问题 | 正常排期开发 |
| `P3` | **次要/低优先级**：体验优化、边缘场景小瑕疵、非紧迫的技术债 | 资源充裕时处理 |

---

## 2. Issue 关联与提交联动语法

### 2.1 Git Commit 关联规范
在 Git 提交信息中显式关联 Issue，推荐采用 Conventional Commits 格式：

```bash
# 修复 Bug 并在 PR 合并或推送主干时自动关闭 Issue
fix(core): resolve memory leak on background reload (Fixes #42)

# 新增功能并关闭对应需求 Issue
feat(auth): support OAuth2 token refresh (Closes #108)

# 阶段性进展提交，仅引用不关闭
refactor(store): split state reducer logic (Refs #56)
```

### 2.2 GitHub 自动关闭关键字 (Closing Keywords)
在 Commit Message 或 PR 描述中包含以下关键词，合并至默认分支时会自动关闭目标 Issue：
- `Fixes #<编号>` / `Fixed #<编号>` / `Fix #<编号>`
- `Closes #<编号>` / `Closed #<编号>` / `Close #<编号>`
- `Resolves #<编号>` / `Resolved #<编号>` / `Resolve #<编号>`

### 2.3 跨 Issue 双向引用 (Cross-referencing)
在讨论或 Issue 描述中引用其他 Issue：
- 同仓库：直接输入 `#<编号>`，如 `#15`
- 跨仓库：输入 `<owner>/<repo>#<编号>`，如 `octocat/hello-world#33`
- 关联关系说明：明确写出关系性质，如 `前置依赖: #12`、`下游需求: #18`、`衍生 Bug: #25`

---

## 3. RCA (Root Cause Analysis) 质量标准

当修复重要或复杂的 Bug 时，结案评论中必须包含以下要素：
1. **现象与证据链 (Symptoms & Evidence)**：直观现象、报错日志片段、系统环境、重现最小样本。
2. **根因分析 (Root Cause Analysis)**：深入解释代码逻辑失误、并发竞态、边界缺失或第三方行为变更，拒绝“修改了变量名故修复”等敷衍说明。
3. **修复方案与改动细节 (Fix Details)**：列出修改文件与关键逻辑变更。
4. **验证结论 (Verification)**：自动化测试命令输出、手工验证表现与防回退措施。
