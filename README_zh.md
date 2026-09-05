<div align="right">
  <a href="./README.md">🇺🇸 English</a> | <b>🇨🇳 简体中文</b>
</div>

# 个人 AI Agent Skills 仓库

本仓库用于沉淀、管理与共享个人 AI Agent Skills，遵循标准 Agent Skills 规范，适配 Claude Code、Google Antigravity、Cursor 等 AI 编程助手与智能体环境。

---

## 📁 目录结构规范

每个 Skill 独立为一个子目录，结构遵循标准 Skill 规范：

```text
skills/
├── <skill-name>/               # 技能目录（命名采用小写短横线，如 my-skill）
│   ├── SKILL.md                # 【必须】核心指令文档（包含 YAML frontmatter）
│   ├── scripts/                # 【可选】辅助执行脚本或工具
│   ├── references/             # 【可选】参考文档与技术规范
│   └── examples/               # 【可选】使用范例
└── ...
```

---

## 🛠️ 创建与沉淀 Skill

推荐使用 [Anthropic skill-creator](https://www.skills.sh/anthropics/skills/skill-creator) 辅助生成与调优 Skill：

1. **调用 skill-creator**：
   - 描述你的技能目标、输入输出、触发条件与预期流程。
   - `skill-creator` 会引导完成需求梳理，并自动生成结构规范的 `SKILL.md`（包含经过调优的 description 与 YAML frontmatter）。
2. **存入仓库**：
   - 将生成的技能目录保存至 `skills/<skill-name>/`。
3. **提交与推送**：
   ```bash
   git add .
   git commit -m "feat: add <skill-name>"
   git push
   ```

---

## 📚 技能索引 (Skills Index)

| 技能名称 | 安装命令 | 说明 | 适用场景 |
| :--- | :--- | :--- | :--- |
| [`github-issue-driven-dev`](skills/github-issue-driven-dev) | `npx skills add https://github.com/jjeejj/skills --skill github-issue-driven-dev` | GitHub Issue 驱动开发、过程留底与 RCA 闭环规范 | 需求立项、缺陷报告、过程进展/RCA 评论、Issue 状态流转与关闭、免 Git 污染附件直传 |

*(随着沉淀的技能增加，可在此表格中持续登记)*

---

## 📄 开源协议

本项目基于 [MIT 协议](LICENSE) 开源。
