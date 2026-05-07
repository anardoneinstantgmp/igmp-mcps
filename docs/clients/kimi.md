# Kimi (Moonshot)

Moonshot's [Kimi](https://www.moonshot.ai/) AI is available through several
front-ends. The two most common surfaces for MCP usage today are:

- **Kimi-CLI / Kimi Code** — terminal coding agent built on Kimi K2 with
  native MCP support.
- **Kimi Chat web app + API** — Kimi's hosted product, where MCP servers are
  added through the Kimi tools / connectors UI.

## Kimi-CLI / Kimi Code (terminal)

Most Kimi terminal builds are forks of OpenCode or Codex CLI and use the same
config format. Try one of these locations (whichever exists on your install):

- `~/.config/kimi/kimi.json`  — newer builds
- `~/.config/kimi-cli/config.json`
- `~/.kimi/settings.json`     — older builds
- `~/.config/opencode/opencode.json` if your Kimi CLI is OpenCode-based

Add an `mcp` (or `mcpServers`) block matching the
[OpenCode shape](./opencode.md) or the canonical
[generic shape](./generic.md):

```json
{
  "mcpServers": {
    "instantgmp-inventory": {
      "type": "http",
      "url": "https://yourcompany.igmpapp.com/rest/mcpservers/inventory/mcpinventoryserver",
      "headers": {
        "X-Api-User": "your_api_user",
        "X-Api-Password": "your_api_password"
      }
    }
    /* …six more entries — see mcp-servers.example.json … */
  }
}
```

If Kimi rejects the `type: http` key, drop it — older MCP clients infer the
transport from the presence of `url`.

For the skill, drop `AGENTS.md` (already in this repo) into the project root —
Kimi-CLI builds on the agents.md convention.

## Kimi Chat (hosted)

In the Kimi web app:

1. Go to **Settings → Tools / MCP servers** (the menu name changes between
   product versions).
2. Click **Add MCP server**.
3. For each of the seven `instantgmp-*` servers, enter:
   - **Type / Transport:** HTTP
   - **URL:** the server URL from
     [`mcp-servers.example.json`](../../mcp-servers.example.json) (replace
     `REPLACE_ME` with your InstantGMP host)
   - **Headers:** `X-Api-User` and `X-Api-Password` set to your `APIUser`
     credentials
4. Save and reload the chat.

For the skill, paste the contents of `SKILL.md` into Kimi's **Custom
instructions** / **System prompt** box.

## Verify

Either CLI or web, ask:

> List the first three projects in InstantGMP.

Kimi should call `instantgmp-projects.query_projects` and cite real records.
If it instead invents project names, the skill isn't loaded — re-check step 2
or 4 of the section above.
