---
description: Configure your InstantGMP server URL and API credentials for the InstantGMP MCP plugin
argument-hint: (no arguments — fully interactive)
---

The user has invoked `/igmp-setup`. Walk them through configuring the
InstantGMP MCP plugin by running the bundled PowerShell setup script.
The script prompts them for their server URL, API user, and API password,
and stores those values in their User-scope Windows environment so the
plugin's `.mcp.json` can resolve `${IGMP_URL}`, `${IGMP_API_USER}`, and
`${IGMP_API_PASSWORD}` at every Cowork launch.

Steps:

1. Confirm the user is on Windows and that Cowork is running. If they're on
   macOS or Linux, tell them this plugin currently ships only a Windows
   PowerShell setup helper and point them at the manual env-var steps in
   the plugin's README.

2. Locate the setup script. It ships inside the plugin at:

   `${CLAUDE_PLUGIN_ROOT}/scripts/setup.ps1`

   Resolve `${CLAUDE_PLUGIN_ROOT}` to the actual path on disk (Cowork sets
   this when the plugin is loaded). If the variable is unavailable in the
   shell context, ask the user to find their Cowork plugins folder and
   adjust accordingly — typically under
   `%USERPROFILE%\.claude\plugins\` or wherever they installed the
   marketplace.

3. Run the script in a User PowerShell window:

   ```powershell
   powershell -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\scripts\setup.ps1"
   ```

   Do NOT run it as Administrator — the env vars must be set under the
   current User scope, not Machine scope, so each user has independent
   credentials.

4. After the script completes successfully, instruct the user to fully
   restart Cowork so the new env vars are picked up by the MCP servers
   (the InstantGMP HTTP MCP servers don't re-read environment after the
   app has started).

5. Once Cowork restarts, verify by asking the user to type a simple
   InstantGMP question like *"list the first three projects"*. If the
   plugin's MCP servers respond, setup is complete.

Reminders:

- The script never sends credentials anywhere — values are stored in the
  current Windows user's environment via
  `[Environment]::SetEnvironmentVariable(..., 'User')`.
- The InstantGMP Detailed Design Specification (DDS) requires a dedicated
  API User credential, not a real production user's login. Tell the user
  to ask their InstantGMP administrator for an `APIUser`-type personnel
  record if they don't have one.
- All MCP calls are recorded in InstantGMP's API Audit Trail (DDS-AUD-11)
  under the API User identity.

Do not paste any password the user types into the chat. Do not echo the
value of `IGMP_API_PASSWORD` back. Treat it as opaque.
