# AI config patterns

Small, copyable patterns for configuring AI coding assistants (Cursor and Databricks Genie Code)
on data and supply chain projects. Each one comes from a problem I hit while building with AI,
and each is written up in my LinkedIn series on AI config.

| Pattern | What it solves | Folder |
|---|---|---|
| Deploy commit guard | A rule said "commit before you deploy". It got skipped. A hook makes sure. | [`hooks/`](hooks/) |
| Skill description template | Skills the AI never opens, or opens for the wrong job. | [`skills/`](skills/) |
| AGENTS.md canary | Rules the AI never loaded, because they were in the wrong file or folder. | [`canary/`](canary/) |

## Where a rule should live

```
Must the rule hold every time?
├─ No  → Skill (opened when the AI decides the task needs it)
└─ Yes → Must it be blocked, not just asked?
         ├─ Yes → Hook (Cursor; Genie Code has no hooks of its own)
         └─ No  → Is it a project fact every tool needs?
                  ├─ Yes → AGENTS.md
                  └─ No  → Instructions (Genie Code) / always-on rule (Cursor)
```

## Notes

- All examples are generic and written for this repo. None of them is copied from an employer's setup.
- Tool behavior changes. Each folder links the official docs it was checked against (October 2026); test with the canary before you rely on a rule.

Vic Chen · [LinkedIn](https://www.linkedin.com/in/vic-chen)

License: MIT
