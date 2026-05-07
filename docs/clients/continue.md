# Continue (VS Code / JetBrains)

[Continue](https://docs.continue.dev/) supports MCP servers via its
`config.yaml` (recent versions) or `config.json` (older versions).

## 1. Open Continue's config

Run the Command Palette command:

> Continue: Open Config

The file lives at `~/.continue/config.yaml` (or `config.json` in older builds).

## 2. Add the seven InstantGMP servers

In `config.yaml`, add an `mcpServers` section:

```yaml
mcpServers:
  - name: instantgmp-inventory
    type: http
    url: https://yourcompany.igmpapp.com/rest/mcpservers/inventory/mcpinventoryserver
    headers:
      X-Api-User: your_api_user
      X-Api-Password: your_api_password
  - name: instantgmp-setup
    type: http
    url: https://yourcompany.igmpapp.com/rest/mcpservers/setup/mcpsetupserver
    headers:
      X-Api-User: your_api_user
      X-Api-Password: your_api_password
  - name: instantgmp-logs
    type: http
    url: https://yourcompany.igmpapp.com/rest/mcpservers/logs/mcplogsserver
    headers:
      X-Api-User: your_api_user
      X-Api-Password: your_api_password
  - name: instantgmp-ebr
    type: http
    url: https://yourcompany.igmpapp.com/rest/mcpservers/ebr/mcpebrserver
    headers:
      X-Api-User: your_api_user
      X-Api-Password: your_api_password
  - name: instantgmp-qms
    type: http
    url: https://yourcompany.igmpapp.com/rest/mcpservers/qms/mcpqmsserver
    headers:
      X-Api-User: your_api_user
      X-Api-Password: your_api_password
  - name: instantgmp-projects
    type: http
    url: https://yourcompany.igmpapp.com/rest/mcpservers/projects/mcpprojectsserver
    headers:
      X-Api-User: your_api_user
      X-Api-Password: your_api_password
  - name: instantgmp-docs
    type: http
    url: https://yourcompany.igmpapp.com/rest/mcpservers/docs/mcpdocsserver
    headers:
      X-Api-User: your_api_user
      X-Api-Password: your_api_password
```

If you're on an older Continue build that uses `config.json`, you can paste
the JSON form straight from
[`mcp-servers.example.json`](../../mcp-servers.example.json) into an
`mcpServers` key.

## 3. Load the skill

Continue exposes a "system message" or "rules" section per assistant. Open
your assistant config and paste the contents of `SKILL.md` into the
`systemMessage` (or `rules`) field. Alternatively reference it:

```yaml
rules:
  - "Before answering any InstantGMP question, read ./SKILL.md and follow it."
```

## 4. Verify

Ask Continue:

> List the first three projects in InstantGMP.

It should call `instantgmp-projects.query_projects` and cite real records.
