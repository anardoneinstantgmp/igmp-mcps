# Windsurf

[Windsurf](https://docs.windsurf.com/windsurf/cascade/mcp) (the Codeium
fork of VS Code) supports MCP via `~/.codeium/windsurf/mcp_config.json`.

## 1. Create the MCP config

```bash
mkdir -p ~/.codeium/windsurf
cp mcp-servers.example.json ~/.codeium/windsurf/mcp_config.json
```

Edit the file to replace `REPLACE_ME` placeholders with your InstantGMP host,
API user, and API password. Windsurf's config takes literal values.

## 2. Reload Windsurf's MCP

Windsurf → Cascade panel → **Configure MCP** → click the refresh / reload
button. The seven `instantgmp-*` servers should appear as connected.

## 3. Load the skill

Save this repo's `SKILL.md` to your project root as `.windsurfrules`:

```bash
cp SKILL.md .windsurfrules
```

Windsurf auto-loads `.windsurfrules` as part of its system prompt.

## 4. Verify

Ask Cascade:

> List the first three projects in InstantGMP.

It should call `instantgmp-projects.query_projects` and cite real records.
