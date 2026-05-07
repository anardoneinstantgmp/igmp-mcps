# Claude Code CLI

[Claude Code](https://docs.claude.com/en/docs/claude-code) is Anthropic's
terminal-based coding agent. It supports MCP via project-local `.mcp.json`
or user-scope config.

## 1. Drop the MCP config in

Create a `.mcp.json` file at the root of the project where you'll run Claude
Code. Use [`mcp-servers.template.json`](../../mcp-servers.template.json) as a
starting point — copy the `mcpServers` object out of it.

```bash
cp mcp-servers.template.json .mcp.json
```

(Or paste the seven `instantgmp-*` server entries into an existing `.mcp.json`.)

## 2. Set the credentials

Claude Code expands `${VAR}` references in `.mcp.json` from the calling shell's
environment. Set the three vars:

```bash
# bash / zsh
export IGMP_URL=https://yourcompany.igmpapp.com
export IGMP_API_USER=your_api_user
export IGMP_API_PASSWORD=your_api_password
```

```powershell
# PowerShell
$Env:IGMP_URL          = "https://yourcompany.igmpapp.com"
$Env:IGMP_API_USER     = "your_api_user"
$Env:IGMP_API_PASSWORD = "your_api_password"
```

For persistence on Windows, use the bundled helper:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\setup.ps1
```

It prompts for the three values, sets them as User-scope env vars, probes
the InstantGMP server, and writes a literal-value `mcp-config.json` next to
your home directory in case you'd rather paste literals than expand env vars.

## 3. Load the skill

Claude Code auto-discovers skills under `.claude/skills/<name>/SKILL.md`.
Copy this repo's `SKILL.md` into that location (or symlink it):

```bash
mkdir -p .claude/skills/instantgmp-mcp
cp SKILL.md .claude/skills/instantgmp-mcp/SKILL.md
```

Claude Code will load it whenever a relevant question is asked.

Alternative: drop a one-liner into your `CLAUDE.md` / `AGENTS.md`:

> Before answering any InstantGMP question, read `./SKILL.md` and follow it.

## 4. Verify

In the project, start Claude Code and ask:

> List the first three projects in InstantGMP.

You should see Claude call `instantgmp-projects.query_projects` and quote real
project records back. If you don't, run `claude mcp list` to confirm the seven
servers loaded, and double-check `IGMP_URL` has no trailing slash.
