# Qwen Code

[Qwen Code](https://github.com/QwenLM/qwen-code) is Alibaba's open-source
agentic coding CLI. It supports MCP servers via `~/.qwen/settings.json` (or
project-local `.qwen/settings.json`).

## 1. Edit Qwen's settings

```bash
mkdir -p ~/.qwen
$EDITOR ~/.qwen/settings.json
```

Add an `mcpServers` block. Qwen Code follows the canonical shape:

```json
{
  "mcpServers": {
    "instantgmp-inventory": {
      "httpUrl": "https://yourcompany.igmpapp.com/rest/mcpservers/inventory/mcpinventoryserver",
      "headers": {
        "X-Api-User": "your_api_user",
        "X-Api-Password": "your_api_password"
      }
    },
    "instantgmp-setup":    { "httpUrl": "https://yourcompany.igmpapp.com/rest/mcpservers/setup/mcpsetupserver",       "headers": { "X-Api-User": "your_api_user", "X-Api-Password": "your_api_password" } },
    "instantgmp-logs":     { "httpUrl": "https://yourcompany.igmpapp.com/rest/mcpservers/logs/mcplogsserver",         "headers": { "X-Api-User": "your_api_user", "X-Api-Password": "your_api_password" } },
    "instantgmp-ebr":      { "httpUrl": "https://yourcompany.igmpapp.com/rest/mcpservers/ebr/mcpebrserver",           "headers": { "X-Api-User": "your_api_user", "X-Api-Password": "your_api_password" } },
    "instantgmp-qms":      { "httpUrl": "https://yourcompany.igmpapp.com/rest/mcpservers/qms/mcpqmsserver",           "headers": { "X-Api-User": "your_api_user", "X-Api-Password": "your_api_password" } },
    "instantgmp-projects": { "httpUrl": "https://yourcompany.igmpapp.com/rest/mcpservers/projects/mcpprojectsserver", "headers": { "X-Api-User": "your_api_user", "X-Api-Password": "your_api_password" } },
    "instantgmp-docs":     { "httpUrl": "https://yourcompany.igmpapp.com/rest/mcpservers/docs/mcpdocsserver",         "headers": { "X-Api-User": "your_api_user", "X-Api-Password": "your_api_password" } }
  }
}
```

If your Qwen version uses `url` instead of `httpUrl`, swap the key — both
forms appear in the wild.

## 2. Load the skill

Qwen Code reads project-local `QWEN.md` as a system instruction. Mirror this
repo's `SKILL.md`:

```bash
cp SKILL.md QWEN.md
```

(or symlink `QWEN.md -> SKILL.md`)

It also picks up `AGENTS.md`, which this repo already ships pointing at
`SKILL.md`.

## 3. Verify

Launch `qwen` and ask:

> List the first three projects in InstantGMP.

You should see Qwen call `instantgmp-projects.query_projects` and cite real
records.
