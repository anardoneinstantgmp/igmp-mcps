# Cursor

[Cursor](https://docs.cursor.com/context/model-context-protocol) supports MCP
servers via `~/.cursor/mcp.json` (user-scope) or `<project>/.cursor/mcp.json`
(project-scope).

## 1. Create the MCP config

```bash
mkdir -p ~/.cursor
cp mcp-servers.template.json ~/.cursor/mcp.json
```

(or use `<project>/.cursor/mcp.json` if you want it project-local)

Cursor expands `${VAR}` references, so the env-var version of the config works.
You can also paste literal values from `mcp-servers.example.json` if you'd
rather not deal with environment variables.

## 2. Set the env vars (only if you used the template form)

Set `IGMP_URL`, `IGMP_API_USER`, `IGMP_API_PASSWORD` in your shell or system
environment. On Windows you can use the bundled `scripts\setup.ps1` helper.

## 3. Reload Cursor

Cursor → Settings → MCP. The seven `instantgmp-*` servers should appear with
green status indicators. If any are red, click the row to see the error.

## 4. Load the skill as a Cursor rule

Cursor reads `.cursor/rules/*.mdc` (project-scope) or you can paste rules in
**Settings → Rules**. Save the contents of this repo's `SKILL.md` as
`.cursor/rules/instantgmp.mdc`:

```bash
mkdir -p .cursor/rules
cp SKILL.md .cursor/rules/instantgmp.mdc
```

(For older Cursor versions that use `.cursorrules`, copy `SKILL.md` to
`.cursorrules` instead.)

## 5. Verify

In Cursor's chat (Agent mode), ask:

> List the first three projects in InstantGMP.

Cursor should call `instantgmp-projects.query_projects` and cite real records.
