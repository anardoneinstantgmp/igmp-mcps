# InstantGMP — Cowork plugin marketplace

This repo is a [Cowork / Claude Code plugin
marketplace](https://docs.claude.com/en/docs/claude-code/plugins) that
ships the **InstantGMP** plugin to your company's Cowork users. The
plugin bundles:

- **7 MCP servers** — `instantgmp-inventory`, `instantgmp-setup`,
  `instantgmp-logs`, `instantgmp-ebr`, `instantgmp-qms`,
  `instantgmp-projects`, `instantgmp-docs` — plus the local
  `genexus-knowledge` stdio server.
- **One skill** — `instantgmp-mcp` — that teaches Claude how to use the
  servers correctly under 21 CFR Part 11 / cGMP / GAMP 5 constraints.
- **One slash command** — `/igmp-setup` — that walks each user through
  configuring their personal URL and API credentials.

Each user supplies **their own** InstantGMP server URL and API
credentials. The MCP config in this repo never contains any secrets —
it references `${IGMP_URL}`, `${IGMP_API_USER}`, and
`${IGMP_API_PASSWORD}`, which the bundled setup script writes to each
user's Windows environment.

## Repository layout

```
igmp-mcps/
├── .claude-plugin/
│   └── marketplace.json                  # marketplace manifest
├── plugins/
│   └── instantgmp/
│       ├── .claude-plugin/
│       │   └── plugin.json               # plugin manifest
│       ├── .mcp.json                     # MCP servers (env-var placeholders)
│       ├── commands/
│       │   └── igmp-setup.md             # /igmp-setup slash command
│       ├── scripts/
│       │   └── setup.ps1                 # interactive credential setup
│       └── skills/
│           └── instantgmp-mcp/
│               └── SKILL.md              # the InstantGMP usage skill
└── README.md                             # this file
```

## Admin: publishing the marketplace

1. Push this folder to a git repository your company users can clone
   (GitHub, GitHub Enterprise, GitLab, Bitbucket, Azure DevOps, internal
   SSH host — anything Cowork can `git clone`). The repo is safe to
   make public: it ships only env-var placeholders, never literal
   secrets.

2. (Optional) Tag a release like `v1.0.0` so you can pin users to a
   specific version while you iterate.

3. Have InstantGMP IT provision a dedicated `APIUser`-type personnel
   record for each user (or one per AI client, per environment) — the
   skill (`SKILL.md` §9) explicitly forbids using real production user
   credentials for the API User account.

4. Distribute the install instructions below to your users.

## End user: install

You only need to do this once. After it's done, every Cowork session
will load the InstantGMP MCP servers and skill.

### Step 1 — Add the marketplace

In Cowork, open the slash-command bar and run:

```text
/plugin marketplace add <git-url-of-this-repo>
```

For example:

```text
/plugin marketplace add https://github.com/your-org/igmp-mcps.git
```

### Step 2 — Install the plugin

```text
/plugin install instantgmp@instantgmp
```

(The `@instantgmp` suffix is the marketplace name from
`.claude-plugin/marketplace.json`.)

### Step 3 — Configure your URL and credentials

Run the setup slash command:

```text
/igmp-setup
```

Claude will walk you through running the bundled PowerShell helper. The
helper:

- Prompts for your **InstantGMP base URL** (e.g.
  `https://yourcompany.igmpapp.com`).
- Prompts for your **API user** (`X-Api-User`).
- Prompts for your **API password** (`X-Api-Password`, hidden as you
  type).
- Probes the server to confirm the URL is reachable.
- Writes all three values as **User-scope** Windows environment
  variables: `IGMP_URL`, `IGMP_API_USER`, `IGMP_API_PASSWORD`.

If you'd rather run the helper yourself, open PowerShell and run:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\plugins\instantgmp\scripts\setup.ps1"
```

(Adjust the path if Cowork installed plugins elsewhere on your machine.)

### Step 4 — Restart Cowork

The HTTP MCP servers read environment variables only at app start, so
you must fully quit and reopen Cowork after running `/igmp-setup`.

### Step 5 — Verify

Ask Claude something like:

> List the first three projects in InstantGMP.

If the plugin is working, Claude will call
`instantgmp-projects.query_projects` and cite the records. If it can't
reach the server, double-check `IGMP_URL` (no trailing slash) and that
the `APIUser` credential is active in InstantGMP.

## How per-user credentials work

The `.mcp.json` shipped with the plugin uses environment-variable
placeholders:

```json
{
  "url": "${IGMP_URL}/rest/mcpservers/inventory/mcpinventoryserver",
  "headers": {
    "X-Api-User": "${IGMP_API_USER}",
    "X-Api-Password": "${IGMP_API_PASSWORD}"
  }
}
```

When Cowork loads the plugin, it expands these from each user's own
environment — so the same plugin code points at user A's server with
user A's credentials, and user B's server with user B's credentials.
The repo never contains any secrets.

The `genexus-knowledge` server runs locally as a stdio process and does
not require credentials.

## Updating the plugin

When you push a new commit to the marketplace repo, users can update
with:

```text
/plugin update instantgmp@instantgmp
```

Bump `version` in both `.claude-plugin/marketplace.json` and
`plugins/instantgmp/.claude-plugin/plugin.json` for any breaking change
to the MCP config or skill.

## Removing it

```text
/plugin uninstall instantgmp@instantgmp
/plugin marketplace remove instantgmp
```

The Windows env vars set by `setup.ps1` are not removed automatically.
To clear them:

```powershell
[Environment]::SetEnvironmentVariable('IGMP_URL',          $null, 'User')
[Environment]::SetEnvironmentVariable('IGMP_API_USER',     $null, 'User')
[Environment]::SetEnvironmentVariable('IGMP_API_PASSWORD', $null, 'User')
```

## Security notes

- API passwords are stored in the **User-scope** Windows environment,
  which is readable by the user (and by processes running as that user)
  but not by other users on the machine.
- This is the same trust boundary as `claude_desktop_config.json` or
  `.mcp.json` with literal secrets — no worse, and avoids checking
  secrets into the plugin repo.
- For higher-assurance environments, replace the env-var lookup with a
  Windows Credential Manager / DPAPI-backed wrapper.
- All MCP calls are written to InstantGMP's API Audit Trail
  (DDS-AUD-11) under the `APIUser` identity.

## Support

Edit the skill at
`plugins/instantgmp/skills/instantgmp-mcp/SKILL.md` to evolve how
Claude uses the servers. Bump the plugin version after non-trivial
changes so users know to `/plugin update`.
