# Any MCP-compatible AI client (generic)

The InstantGMP MCP servers speak the standard
[Model Context Protocol](https://modelcontextprotocol.io/) over **HTTP with
custom headers**. Any client that supports MCP HTTP transport can talk to
them.

## What you need

- An InstantGMP base URL (e.g. `https://yourcompany.igmpapp.com`, **no trailing slash**)
- An `APIUser`-type personnel record's login and password (the `X-Api-User` /
  `X-Api-Password` headers)
- An AI client that supports MCP "http" / "streamable-http" servers with
  custom headers

## The standard config

The config below is the wire-level shape. Every supported client expects either
this exact JSON (as `mcpServers`) or a small variant of it (TOML, YAML, or a
GUI form with the same fields).

```json
{
  "mcpServers": {
    "instantgmp-inventory": {
      "type": "http",
      "url": "https://YOUR-IGMP-HOST/rest/mcpservers/inventory/mcpinventoryserver",
      "headers": {
        "X-Api-User": "YOUR_API_USER",
        "X-Api-Password": "YOUR_API_PASSWORD"
      }
    },
    "instantgmp-setup":    { "type": "http", "url": "https://YOUR-IGMP-HOST/rest/mcpservers/setup/mcpsetupserver",       "headers": { "X-Api-User": "YOUR_API_USER", "X-Api-Password": "YOUR_API_PASSWORD" } },
    "instantgmp-logs":     { "type": "http", "url": "https://YOUR-IGMP-HOST/rest/mcpservers/logs/mcplogsserver",         "headers": { "X-Api-User": "YOUR_API_USER", "X-Api-Password": "YOUR_API_PASSWORD" } },
    "instantgmp-ebr":      { "type": "http", "url": "https://YOUR-IGMP-HOST/rest/mcpservers/ebr/mcpebrserver",           "headers": { "X-Api-User": "YOUR_API_USER", "X-Api-Password": "YOUR_API_PASSWORD" } },
    "instantgmp-qms":      { "type": "http", "url": "https://YOUR-IGMP-HOST/rest/mcpservers/qms/mcpqmsserver",           "headers": { "X-Api-User": "YOUR_API_USER", "X-Api-Password": "YOUR_API_PASSWORD" } },
    "instantgmp-projects": { "type": "http", "url": "https://YOUR-IGMP-HOST/rest/mcpservers/projects/mcpprojectsserver", "headers": { "X-Api-User": "YOUR_API_USER", "X-Api-Password": "YOUR_API_PASSWORD" } },
    "instantgmp-docs":     { "type": "http", "url": "https://YOUR-IGMP-HOST/rest/mcpservers/docs/mcpdocsserver",         "headers": { "X-Api-User": "YOUR_API_USER", "X-Api-Password": "YOUR_API_PASSWORD" } }
  }
}
```

A copy with environment-variable placeholders is at
[`mcp-servers.template.json`](../../mcp-servers.template.json), and a copy
with literal `REPLACE_ME` placeholders is at
[`mcp-servers.example.json`](../../mcp-servers.example.json).

## Steps

1. Decide where your client stores MCP config (file path, settings UI, or
   project-local config). Consult its docs.
2. Paste the seven server entries from above into that config.
3. Either:
   - Set the env vars `IGMP_URL`, `IGMP_API_USER`, `IGMP_API_PASSWORD` if your
     client expands `${VAR}` in MCP config (most modern clients do), **or**
   - Inline the literal values into the JSON.
4. Restart the AI client so it reconnects with the new config.
5. Load [`SKILL.md`](../../SKILL.md) into the client's system prompt or rules
   file (see [`docs/skill-loading.md`](../skill-loading.md)).
6. Test with a simple query: *"List the first three projects in InstantGMP."*
   The AI should call `instantgmp-projects.query_projects` and quote real
   project records back to you.

## Tips

- **No trailing slash** on `IGMP_URL`. The seven server URLs each append their
  own path.
- The `X-Api-User` / `X-Api-Password` headers go on every request. Most clients
  send these as static headers per server. If yours rotates auth, you'll need
  a wrapper script.
- All seven servers are **read-only** — they never mutate state. If your
  client exposes "tool approval" prompts you can safely auto-allow these.
- The `APIUser` personnel record should be dedicated per AI client / per
  environment. Don't reuse a real human user's login. (See `SKILL.md` §9.)
