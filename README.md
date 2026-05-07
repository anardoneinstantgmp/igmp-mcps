# InstantGMP MCP — generic install kit

Connect any MCP-compatible AI client to your InstantGMP server.

This repo distributes three things that any AI client can use:

1. **`SKILL.md`** — the AI-behavior guide. Tells the assistant how (and how
   not) to use the InstantGMP MCP servers. Enforces 21 CFR Part 11, cGMP, and
   GAMP 5 constraints: read-only, no fabrication, audit-defensible citations.
   Drop it into your client's system prompt / rules / `AGENTS.md` /
   `.cursorrules` / etc.

2. **`mcp-servers.template.json`** and **`mcp-servers.example.json`** — the
   wire-level MCP config. Seven HTTP-transport servers behind two header
   credentials. Either form works in any standards-compliant MCP client.

3. **`scripts/setup.ps1`** (Windows) and **`scripts/setup.sh`** (Linux/macOS)
   — interactive helpers that prompt for the URL + API user + password,
   probe the server, set OS env vars, and write a literal-value JSON config
   for clients that don't expand env vars.

There is **no client-specific packaging** in this repo. Per-client install
recipes live in [`docs/clients/`](./docs/clients/).

## Repository layout

```
igmp-mcps/
├── README.md                        # this file
├── LICENSE
├── SKILL.md                         # the AI behavior guide (canonical)
├── AGENTS.md                        # pointer file for tools that auto-discover AGENTS.md
├── mcp-servers.template.json        # MCP config with ${IGMP_URL} placeholders
├── mcp-servers.example.json         # MCP config with literal REPLACE_ME placeholders
├── docs/
│   ├── skill-loading.md             # how to load SKILL.md into any AI client
│   └── clients/
│       ├── generic.md               # for any MCP-compatible client
│       ├── claude-code.md
│       ├── cline.md
│       ├── continue.md
│       ├── cursor.md
│       ├── windsurf.md
│       ├── opencode.md
│       ├── qwen.md
│       └── kimi.md
└── scripts/
    ├── setup.ps1                    # Windows interactive setup
    └── setup.sh                     # Linux / macOS interactive setup
```

## Quick start

You'll need three values from your InstantGMP administrator:

- **InstantGMP base URL**, e.g. `https://yourcompany.igmpapp.com`
  (no trailing slash)
- **API user** — login of an `APIUser`-type personnel record
  (don't use a real human user's credentials)
- **API password** — that user's password

Then:

### 1. Configure your AI client to talk to the seven InstantGMP MCP servers

Pick the recipe for your client:

| Client                                   | Guide                                |
| ---------------------------------------- | ------------------------------------ |
| Any MCP-compatible client                | [`docs/clients/generic.md`](./docs/clients/generic.md)        |
| Claude Code CLI                          | [`docs/clients/claude-code.md`](./docs/clients/claude-code.md) |
| Cline (VS Code)                          | [`docs/clients/cline.md`](./docs/clients/cline.md)             |
| Continue (VS Code / JetBrains)           | [`docs/clients/continue.md`](./docs/clients/continue.md)       |
| Cursor                                   | [`docs/clients/cursor.md`](./docs/clients/cursor.md)           |
| Windsurf                                 | [`docs/clients/windsurf.md`](./docs/clients/windsurf.md)       |
| OpenCode                                 | [`docs/clients/opencode.md`](./docs/clients/opencode.md)       |
| Qwen Code                                | [`docs/clients/qwen.md`](./docs/clients/qwen.md)               |
| Kimi (CLI / hosted)                      | [`docs/clients/kimi.md`](./docs/clients/kimi.md)               |

If your client isn't in the table, follow the generic guide — almost every
MCP client accepts a variation of the same JSON.

### 2. Optional: run the setup helper

If you'd rather not edit JSON by hand, run the helper for your platform.
It'll prompt for URL/user/password, probe the server, set environment
variables system-wide, and write a literal-value `mcp-config.json` you can
paste into any client that needs literal values.

```powershell
# Windows (regular User PowerShell, no admin)
powershell -ExecutionPolicy Bypass -File scripts\setup.ps1
```

```bash
# Linux / macOS
./scripts/setup.sh
```

### 3. Load `SKILL.md` into your AI client

`SKILL.md` is a plain Markdown rules document. It tells the AI how to behave
when answering InstantGMP questions. **Without it, the AI will not respect
the read-only / no-fabrication / no-write-shaped-retry rules.**

Drop it into your client's rules / system-prompt slot. The exact filename
varies by client — see [`docs/skill-loading.md`](./docs/skill-loading.md) for
the full table. Common choices:

- `AGENTS.md` at the project root (this repo already ships one)
- `.cursorrules`, `.clinerules`, `.windsurfrules` for those clients
- A copy under `.claude/skills/instantgmp-mcp/SKILL.md` for Claude Code
- Paste the contents into the client's "Custom instructions" / "System
  prompt" box otherwise

### 4. Verify

Restart your AI client, then ask it:

> List the first three projects in InstantGMP.

It should call `instantgmp-projects.query_projects` and return real project
records with citations like *"per `query_projects` page=1, project 'PE-001'
…"*. If it instead invents project names, the skill isn't loaded — re-check
step 3.

## Switching between InstantGMP servers (named profiles, Windows only today)

Support staff who connect to multiple servers (prod, QA, customer A, …) can
save each one as a named profile and switch between them with one command.
Profiles live at `%USERPROFILE%\.instantgmp\profiles\<name>.json` with the
password DPAPI-encrypted under the current Windows user.

```powershell
.\scripts\setup.ps1 -Save qa            # prompt + save as profile "qa", activate
.\scripts\setup.ps1 -Use   qa            # switch to "qa"
.\scripts\setup.ps1 -List                # list profiles
.\scripts\setup.ps1 -Delete qa           # remove "qa"
```

After switching, restart your AI client so it picks up the new env vars (or
re-paste the new `mcp-config.json` into clients that take literal values).

A profile-switching mode for `setup.sh` may be added later — open an issue
if you need it.

## How per-user credentials work

The setup helpers store the URL, API user, and API password in the **current
operating-system user's environment** (Windows User-scope env vars; Linux
`~/.bashrc` or `~/.zshrc`). Each user's values are independent. The repo
itself contains zero secrets.

The literal-value `mcp-config.json` written by the helpers lives in the user's
home directory (`%USERPROFILE%\.instantgmp\mcp-config.json` on Windows,
`~/.config/instantgmp/mcp-config.json` on Linux/macOS) and is readable only by
that user (`chmod 600` on Linux/macOS).

Profiles on Windows are encrypted with DPAPI, which is bound to the current
Windows user on the current machine — they cannot be copied to another user
or another PC.

## Updating

When this repo updates:

- **Skill** — re-pull `SKILL.md` (or `AGENTS.md`) and re-copy it into the
  rules slot your client uses. Older versions can be removed.
- **MCP config** — only re-run the setup helper if the URL pattern or
  header names change. Existing user configs continue to work otherwise.
- **Setup scripts** — re-pull `scripts/setup.ps1` or `scripts/setup.sh`.
  Existing profiles are unaffected.

## Removing it

To clear everything from a user's machine:

```powershell
# Windows
[Environment]::SetEnvironmentVariable('IGMP_URL',          $null, 'User')
[Environment]::SetEnvironmentVariable('IGMP_API_USER',     $null, 'User')
[Environment]::SetEnvironmentVariable('IGMP_API_PASSWORD', $null, 'User')
[Environment]::SetEnvironmentVariable('IGMP_ACTIVE_PROFILE', $null, 'User')
Remove-Item -Recurse -Force "$env:USERPROFILE\.instantgmp"
```

```bash
# Linux / macOS
sed -i.bak '/# >>> instantgmp-mcp >>>/,/# <<< instantgmp-mcp <<</d' ~/.bashrc 2>/dev/null
sed -i.bak '/# >>> instantgmp-mcp >>>/,/# <<< instantgmp-mcp <<</d' ~/.zshrc  2>/dev/null
rm -rf ~/.config/instantgmp
```

Then remove the seven `instantgmp-*` server entries from your AI client's
MCP config and remove the skill rule file (whichever filename you chose).

## Security & compliance notes

- The MCP config on disk contains the literal API password (it has to — that's
  what HTTP headers carry). The file lives in the user's home directory and is
  readable only by that user.
- The `SKILL.md` §9 rule requires using a dedicated `APIUser`-type personnel
  record per AI client per environment — never a real human's production
  login.
- All MCP calls are written to InstantGMP's API Audit Trail (DDS-AUD-11) under
  the API User identity. Treat MCP calls as auditable events, not casual reads.
- All seven MCP servers are **read-only**. Any operation that would mutate
  state must happen in the InstantGMP UI under an interactive digital
  signature.

## License

See [`LICENSE`](./LICENSE).

## Support

- The skill source is `SKILL.md`. Edit there if you want to extend or override
  AI behavior for your environment.
- Questions about the MCP servers themselves go to your InstantGMP
  administrator.
- Bug reports / improvement requests for the install kit: open an issue on
  the GitHub repo.
