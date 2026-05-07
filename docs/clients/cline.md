# Cline (VS Code)

[Cline](https://github.com/cline/cline) is a VS Code extension that runs an
agentic coding loop. It supports MCP servers configured in
`cline_mcp_settings.json`.

## 1. Open Cline's MCP settings

In VS Code, open the Command Palette and run:

> Cline: Open MCP Settings

That opens `cline_mcp_settings.json` in your editor. (If you don't see the
command, click the Cline panel's MCP icon and pick **Configure MCP Servers**.)

## 2. Add the seven InstantGMP servers

Paste the seven server entries from
[`mcp-servers.example.json`](../../mcp-servers.example.json) — Cline's MCP
config uses literal values, not `${VAR}` placeholders.

The shape Cline expects is the same `mcpServers` object:

```json
{
  "mcpServers": {
    "instantgmp-projects": {
      "type": "http",
      "url": "https://yourcompany.igmpapp.com/rest/mcpservers/projects/mcpprojectsserver",
      "headers": {
        "X-Api-User": "your_api_user",
        "X-Api-Password": "your_api_password"
      }
    }
    /* …six more entries — see mcp-servers.example.json … */
  }
}
```

Replace the URL host, `X-Api-User`, and `X-Api-Password` for each of the seven
servers (`instantgmp-inventory`, `-setup`, `-logs`, `-ebr`, `-qms`,
`-projects`, `-docs`).

Save the file.

## 3. Reload Cline's MCP servers

In the Cline panel's MCP tab, click **Restart** (or close and reopen VS Code).
You should see all seven `instantgmp-*` servers listed as **Connected**.

## 4. Load the skill

Drop a copy of `SKILL.md` from this repo into your project root as
`.clinerules`:

```bash
cp SKILL.md .clinerules
```

Cline auto-loads `.clinerules` as part of its system prompt.

## 5. Verify

Ask Cline:

> List the first three projects in InstantGMP.

It should call `instantgmp-projects.query_projects` and cite real records.
