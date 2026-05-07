# Loading SKILL.md into your AI client

[`SKILL.md`](../SKILL.md) is the InstantGMP behavior guide for AI assistants.
It is plain Markdown and client-agnostic. The recommended way to install it
depends on what your client supports.

## Option 1 — Native skill / agent file (preferred)

Some clients auto-discover one of these filenames at the project root or in a
known config folder. If yours does, just drop `SKILL.md` (or a copy) into the
right place.

| Client family                                | File / folder                                              |
| -------------------------------------------- | ---------------------------------------------------------- |
| OpenCode, Codex CLI, Aider, generic agents.md | `AGENTS.md` at project root (this repo already has one)    |
| Claude Code CLI                              | `<repo>/.claude/skills/instantgmp-mcp/SKILL.md`            |
| Cursor (rules)                               | `.cursorrules` or `.cursor/rules/instantgmp.mdc`           |
| Cline                                        | `.clinerules` at project root                              |
| Continue                                     | `~/.continue/config.yaml` system message                   |
| Windsurf                                     | `.windsurfrules` at project root                           |

## Option 2 — Paste into the client's "system prompt" / "custom instructions"

Most AI clients have a free-text box for custom instructions, system prompt, or
"rules". Copy the contents of `SKILL.md` and paste it there.

In practice it works to drop in the whole file — the model just needs to see
the rules and the canonical query chains. If you have a small character limit,
keep at minimum sections **1 (hard rules)**, **2 (the 7 servers)**, and **9
(authentication & connection)**, and link to this repo for the rest.

## Option 3 — Reference the file at runtime

If your client lets the agent read project files, you can write a one-line
custom instruction like:

> Before answering any InstantGMP question, read `./SKILL.md` and follow the
> rules and query chains it describes.

This works well in Claude Code, OpenCode, Cursor agent mode, and similar tools.

## Updating the skill

When this repo updates `SKILL.md`, re-pull the file (or re-copy/paste it into
your client's config). The MCP server config does not need to change unless
endpoint URLs change.
