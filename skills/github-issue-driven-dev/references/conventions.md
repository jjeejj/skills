# GitHub Issue & Task Conventions

This specification defines label taxonomies, priority matrices, lifecycle state flows, and Git Commit / PR cross-linking conventions for GitHub Issue-driven development.

---

## 1. Label Taxonomy

### 1.1 Type Labels
| Label | Color Suggestion | Description |
| :--- | :--- | :--- |
| `bug` | `#d73a4a` (Red) | Bug fixes, unexpected errors, crashes, or incorrect behavior |
| `enhancement` | `#a2eeef` (Light Blue) | New features, enhancements, or requirement evolutions |
| `documentation` | `#0075ca` (Blue) | Documentation additions, specification updates, or docstrings |
| `refactor` | `#cfd3d7` (Gray) | Code refactoring without changing external behavior |
| `chore` | `#fef2c0` (Light Yellow) | Build scripts, dependency bumps, or tool maintenance |

### 1.2 Priority Matrix
| Priority | Scenarios | SLA & Follow-up Expectation |
| :--- | :--- | :--- |
| `P0` | **Blocker / Emergency**: Production outage, critical data loss/corruption, broken main branch build | Drop all current work; coordinate immediate hotfix and document root causes in real time |
| `P1` | **High Priority**: Core user journey blocked, major regression, must-deliver milestone feature | Prioritize in current sprint/iteration; require comprehensive RCA on completion |
| `P2` | **Medium Priority**: Non-critical bugs, normal feature requests, issues with viable workarounds | Standard planning and resolution |
| `P3` | **Low Priority**: Polish, minor UI inconsistencies, low-impact technical debt | Addressed when bandwidth permits |

---

## 2. Issue Cross-referencing & PR Linkage

### 2.1 Commit Message Linkage
Explicitly link issues in Git commits using Conventional Commits syntax:

```bash
# Resolve bug and automatically close issue upon merging/pushing to default branch:
fix(core): resolve memory leak on background reload (Fixes #42)

# Implement feature and close issue:
feat(auth): support OAuth2 token refresh (Closes #108)

# Incremental progress commit, reference without closing:
refactor(store): split state reducer logic (Refs #56)
```

### 2.2 GitHub Auto-closing Keywords
When included in commit messages or PR descriptions, these keywords automatically close the referenced issue when merged into the default branch:
- `Fixes #<number>` / `Fixed #<number>` / `Fix #<number>`
- `Closes #<number>` / `Closed #<number>` / `Close #<number>`
- `Resolves #<number>` / `Resolved #<number>` / `Resolve #<number>`

### 2.3 Cross-Issue Referencing
To link related issues in comments or issue descriptions:
- **Same repository**: Use `#<number>`, e.g., `#15`
- **Cross-repository**: Use `<owner>/<repo>#<number>`, e.g., `octocat/hello-world#33`
- **Relationship annotations**: State dependency nature clearly, e.g., `Blocked by: #12`, `Parent feature: #18`, `Follow-up: #25`.

---

## 3. RCA (Root Cause Analysis) Quality Standards

When closing high-impact or complex bug issues, the closing or progress comment must include:
1. **Symptoms & Evidence**: Observable errors, stack traces, log excerpts, reproduction environment, minimal repro case.
2. **Root Cause Analysis (RCA)**: Deep technical explanation of code defect, race condition, missing boundary check, or upstream dependency change.
3. **Fix Details**: Affected files and summary of architectural / logic corrections.
4. **Verification**: Automated test command results, manual validation steps, and regression prevention.
---

## 4. Proactive Asset Handling Protocol & Anti-Patterns

### 4.1 Mandatory Upload Flow
1. **Detection & Upload**: Whenever a user provides or mentions an image, screenshot, or video path (e.g. `.user_uploaded/*`, `*.png`, `*.jpg`, `*.mov`, `*.mp4`), the agent **MUST** immediately run:
   ```bash
   scripts/gh-safe.sh upload-asset "<media_file_path>"
   ```
2. **Direct Embedding (No Confirmation Wait)**: Embed the resulting URL into the corresponding GitHub Issue or comment without pausing or waiting for user confirmation.
3. **Progress Notification**: Inform the user that the asset has been uploaded and embedded, and proceed immediately with the task.

### 4.2 Anti-Patterns (Strictly Prohibited)
- ❌ **Git Tree Contamination**: Never commit image or binary media assets into the Git repository (`git add *.png`).
- ❌ **Local File References**: Never use local file paths (e.g., `file:///path/to/img.png` or `../assets/img.png`) in GitHub Issues, PRs, or comments.
- ❌ **Passive / Forgotten Upload**: Never discuss or troubleshoot a user's screenshot without having proactively uploaded it to GitHub user-attachments first.
- ❌ **Unauthorized Auto-Commits**: Never run `git commit` or `git push` automatically without explicit user instruction.
