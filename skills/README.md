# Skill template: write the description like a search result

The AI sees only a skill's `name` and `description` until a task matches, so the first
sentence of the description decides whether the skill is ever opened.

Pattern: **what it does. When to use it. When not to.**

`supplier-file-check/SKILL.md` follows the open Agent Skills format, so the same folder works in:

- Cursor: `.cursor/skills/supplier-file-check/SKILL.md`
- Databricks Genie Code: `/Users/<you>/.assistant/skills/supplier-file-check/SKILL.md`

A skill is opened only when the AI decides the task needs it. Anything that must happen
every time belongs in an always-loaded file (`AGENTS.md`, instructions, or an always-on rule),
or in a hook if it has to be enforced.

References: [Cursor Agent Skills](https://cursor.com/docs/context/skills),
[Databricks Genie Code skills](https://docs.databricks.com/aws/en/genie-code/skills).
