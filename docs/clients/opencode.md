# OpenCode

[OpenCode](https://opencode.ai/) is a terminal-based AI coding agent that
supports MCP servers natively.

## 1. Add the MCP servers to OpenCode config

OpenCode reads `~/.config/opencode/opencode.json` (user-scope) or
`opencode.json` at the project root (project-scope).

Add an `mcp` section. The schema differs slightly from the canonical MCP shape
— OpenCode keys each server under `mcp` and uses `type: "remote"` for HTTP
servers:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "instantgmp-inventory": {
      "type": "remote",
      "url": "https://yourcompany.igmpapp.com/rest/mcpservers/inventory/mcpinventoryserver",
      "headers": {
        "X-Api-User": "your_api_user",
        "X-Api-Password": "your_api_password"
      },
      "enabled": true
    },
    "instantgmp-setup":    { "type": "remote", "url": "https://yourcompany.igmpapp.com/rest/mcpservers/setup/mcpsetupserver",       "headers": { "X-Api-User": "your_api_user", "X-Api-Password": "your_api_password" }, "enabled": true },
    "instantgmp-logs":     { "type": "remote", "url": "https://yourcompany.igmpapp.com/rest/mcpservers/logs/mcplogsserver",         "headers": { "X-Api-User": "your_api_user", "X-Api-Password": "your_api_password" }, "enabled": true },
    "instantgmp-ebr":      { "type": "remote", "url": "https://yourcompany.igmpapp.com/rest/mcpservers/ebr/mcpebrserver",           "headers": { "X-Api-User": "your_api_user", "X-Api-Password": "your_api_password" }, "enabled": true },
    "instantgmp-qms":      { "type": "remote", "url": "https://yourcompany.igmpapp.com/rest/mcpservers/qms/mcpqmsserver",           "headers": { "X-Api-User": "your_api_user", "X-Api-Password": "your_api_password" }, "enabled": true },
    "instantgmp-projects": { "type": "remote", "url": "https://yourcompany.igmpapp.com/rest/mcpservers/projects/mcpprojectsserver", "headers": { "X-Api-User": "your_api_user", "X-Api-Password": "your_api_password" }, "enabled": true },
    "instantgmp-docs":     { "type": "remote", "url": "https://yourcompany.igmpapp.com/rest/mcpservers/docs/mcpdocsserver",         "headers": { "X-Api-User": "your_api_user", "X-Api-Password": "your_api_password" }, "enabled": true }
  }
}
```

OpenCode also supports `${env:VAR}` references; if you'd rather use env vars,
set `IGMP_URL`, `IGMP_API_USER`, `IGMP_API_PASSWORD` and use
`"X-Api-User": "{env:IGMP_API_USER}"` etc.

## 2. Load the skill

OpenCode auto-discovers `AGENTS.md` at the project root, and this repo ships
one that points at `SKILL.md`. So if you `cd` into the repo's working copy
before launching OpenCode, the skill loads automatically.

For other projects, copy `AGENTS.md` (or `SKILL.md` directly) into the project
root.

## 3. Verify

Run `opencode` in the project, then ask:

> List the first three projects in InstantGMP.

It should call `instantgmp-projects.query_projects` and cite real records.
