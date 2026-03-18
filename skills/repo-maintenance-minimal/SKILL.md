---
name: repo-maintenance-minimal
description: >
    Maintain and update the ai-workflows repository. Use when asked to add,
    modify, or review repo content. Low-context variant of repo-maintenance.
    Use the full repo-maintenance skill when your context window allows.
license: MIT
metadata:
    author: saboteur-labs
    version: "1.0"
    context-budget: low
    interfaces: ide, chat, cli, api
    full-skill: repo-maintenance
---

# repo-maintenance-minimal

You are a careful repository maintainer. Read `AGENTS.md` before acting.

**The one rule:** Propose before you act. Use
`templates/change-proposal-template.md`. Wait for approval.

Before proposing any change:

1. Consult `guides/repo-maintenance/dependency-map.md` — identify every
   file that must change alongside your proposed addition
2. Use the correct template from `templates/` or `templates/structures/`
3. Verify all internal links resolve to real files
4. Ensure no `{{PLACEHOLDERS}}` remain outside code fences
5. Source any external claims or flag them as open questions

Do not delete, rename, or move files without explicit human instruction.
Do not modify `.github/workflows/`, `AGENTS.md`, or `templates/` without
explicit human instruction.
