# Personal AI Agent Skills Collection

本仓库用于沉淀、管理与共享个人 AI Agent Skills，适配支持 Agent Skills 规范的 AI 编程助手及智能体环境（如 Google Antigravity、Claude Code、Cursor 等）。

---

## 📁 目录结构规范

每个 Skill 独立为一个子目录，结构遵循标准 Skill 规范：

```text
skills/
├── _template/                  # 新建 Skill 的模板
│   └── SKILL.md
├── <skill-name>/               # 具体技能目录（名称小写短横线命名，如 code-review）
│   ├── SKILL.md                # 【必须】核心指令文档（包含 YAML frontmatter）
│   ├── scripts/                # 【可选】辅助脚本或可执行工具
│   ├── references/             # 【可选】供 Agent 查阅的技术参考资料、手册
│   └── examples/               # 【可选】示例文件或配置范例
└── ...
```

### SKILL.md 文件结构

```markdown
---
name: your-skill-name
description: 描述此技能的功能以及何时触发该技能（包含明确的触发关键词和场景）。
---

# 技能名称

## 概述 (Overview)
简要介绍该技能的用途与核心能力。

## 适用场景 (When to Use)
- 触发场景与条件说明
- 哪些场景不适用

## 工作流与执行指南 (Workflow & Guidelines)
详细的执行步骤、思考路径与约束。

## 最佳实践与注意事项 (Best Practices)
规范要求、边界情况与踩坑点。
```

---

## 🛠️ 如何添加新技能

1. 复制模板目录：
   ```bash
   cp -r skills/_template skills/my-new-skill
   ```
2. 编辑 `skills/my-new-skill/SKILL.md`，补全 YAML frontmatter（`name` 和 `description`）以及具体的业务指令和指南。
3. 若该技能需要辅助脚本或参考文档，放置在对应子目录（`scripts/`、`references/` 等）中。
4. 在下方的技能索引表中登记新技能，提交并推送：
   ```bash
   git add .
   git commit -m "feat: add my-new-skill"
   git push
   ```

---

## 📚 技能索引 (Skills Index)

| 技能名称 | 说明 | 适用场景 | 状态 |
| :--- | :--- | :--- | :--- |
| [_template](skills/_template/SKILL.md) | Skill 模板 | 用于快速创建新 Skill | ✅ 模板 |

*(随着沉淀的技能增加，可在此表格中持续补充)*

---

## 📄 开源协议

本项目基于 [MIT 协议](LICENSE) 开源。
