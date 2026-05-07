# AGENTS.md — pointer file for InstantGMP MCP

This file follows the [agents.md](https://agents.md) convention so AI tools that
auto-discover an `AGENTS.md` (OpenCode, Codex CLI, Aider, etc.) pick up the
right behavior guide.

The canonical, authoritative rules for AI assistants using the InstantGMP MCP
servers live in [`SKILL.md`](./SKILL.md).

**Read `SKILL.md` and follow it.** It defines:

- The hard rules (read-only, no fabrication, audit-defensible citations).
- The 7 MCP servers and what each is for.
- Status lifecycles, default classifications, and canonical query chains.
- Things the AI must NOT do, things it SHOULD do, and worked examples.

If you only have one chance to load context for this project, load `SKILL.md`.
