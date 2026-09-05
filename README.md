<div align="right">
  <b>🇺🇸 English</b> | <a href="./README_zh.md">🇨🇳 简体中文</a>
</div>

# Personal AI Agent Skills Collection

A curated collection of personal AI Agent Skills following the standard Agent Skills specification. Compatible with Claude Code, Google Antigravity, Cursor, and other agentic development environments.

---

## 📁 Repository Structure

Each skill is organized in its own self-contained directory:

```text
skills/
├── <skill-name>/               # Skill directory (lowercase, hyphen-separated, e.g., my-skill)
│   ├── SKILL.md                # [Required] Core instructions with YAML frontmatter
│   ├── scripts/                # [Optional] Helper scripts and executable utilities
│   ├── references/             # [Optional] Reference manuals and domain knowledge
│   └── examples/               # [Optional] Usage examples and sample configurations
└── ...
```

---

## 🛠️ Creating & Managing Skills

We recommend using [Anthropic's skill-creator](https://www.skills.sh/anthropics/skills/skill-creator) to scaffold, iterate, and evaluate skills:

1. **Invoke `skill-creator`**:
   - Describe your skill's goals, triggers, expected inputs/outputs, and step-by-step procedures.
   - `skill-creator` will interactively guide the process and generate an optimized `SKILL.md` (with tested frontmatter and triggers).
2. **Add to Repository**:
   - Place the generated skill folder under `skills/<skill-name>/`.
3. **Commit & Push**:
   ```bash
   git add .
   git commit -m "feat: add <skill-name>"
   git push
   ```

---

## 📚 Skills Index

| Skill Name | Description | When to Use |
| :--- | :--- | :--- |
| *(Pending)* | - | - |

*(New skills will be documented here as they are added)*

---

## 📄 License

This repository is licensed under the [MIT License](LICENSE).
