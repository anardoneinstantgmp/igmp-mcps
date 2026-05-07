#!/usr/bin/env bash
#
# InstantGMP - generic Linux / macOS setup helper
#
# Use this on Linux or macOS to set up an MCP-compatible AI client (Claude
# Code, Cursor, Cline, Continue, OpenCode, Qwen, Kimi-CLI, ...) to talk to
# the InstantGMP MCP servers.
#
# What it does:
#   1. Asks you for your InstantGMP server URL, API user, and API password
#      (or reads them from flags).
#   2. Probes the server to confirm it's reachable.
#   3. Appends env-var exports for IGMP_URL, IGMP_API_USER, IGMP_API_PASSWORD
#      to your shell rc file (~/.bashrc, ~/.zshrc, or whichever you point it
#      at) so any client that expands ${VAR} in its MCP config picks them up.
#   4. Writes a literal-value MCP config to ~/.config/instantgmp/mcp-config.json
#      for clients that don't expand env vars.
#
# Usage:
#   ./setup.sh                                  # interactive
#   ./setup.sh --url URL --user USER --pass PW  # non-interactive
#   ./setup.sh --rc ~/.zshrc                    # write env exports to a custom rc
#   ./setup.sh --no-env                         # don't write env vars
#   ./setup.sh --no-probe                       # skip the connectivity probe
#
# Requires: bash, curl. (jq is nice to have but not required.)

set -euo pipefail

URL=""
API_USER=""
API_PASSWORD=""
RC_FILE=""
NO_ENV=0
NO_PROBE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --url)        URL="$2";          shift 2 ;;
        --user)       API_USER="$2";     shift 2 ;;
        --pass)       API_PASSWORD="$2"; shift 2 ;;
        --rc)         RC_FILE="$2";      shift 2 ;;
        --no-env)     NO_ENV=1;          shift   ;;
        --no-probe)   NO_PROBE=1;        shift   ;;
        -h|--help)
            sed -n '2,30p' "$0"
            exit 0 ;;
        *)
            echo "Unknown flag: $1" >&2
            exit 2 ;;
    esac
done

# -- helpers ---------------------------------------------------------

_red()   { printf '\033[31m%s\033[0m' "$*"; }
_grn()   { printf '\033[32m%s\033[0m' "$*"; }
_yel()   { printf '\033[33m%s\033[0m' "$*"; }
_cyan()  { printf '\033[36m%s\033[0m' "$*"; }

prompt_required() {
    local label="$1"
    local value=""
    while [[ -z "$value" ]]; do
        printf '%s: ' "$label"
        IFS= read -r value
        if [[ -z "$value" ]]; then
            _yel "  Value cannot be empty. Try again."; echo
        fi
    done
    printf '%s' "$value"
}

prompt_secret() {
    local label="$1"
    local value=""
    while [[ -z "$value" ]]; do
        printf '%s: ' "$label"
        IFS= read -rs value
        echo
        if [[ -z "$value" ]]; then
            _yel "  Value cannot be empty. Try again."; echo
        fi
    done
    printf '%s' "$value"
}

trim_trailing_slash() {
    local s="$1"
    printf '%s' "${s%/}"
}

is_valid_url() {
    [[ "$1" =~ ^https?://[^/[:space:]]+ ]]
}

# -- header ----------------------------------------------------------

echo
_cyan "================================================================"; echo
_cyan "  InstantGMP MCP - generic Linux/macOS setup helper"; echo
_cyan "================================================================"; echo
echo

# -- collect inputs --------------------------------------------------

if [[ -z "$URL" ]]; then
    URL=$(prompt_required "InstantGMP base URL (e.g. https://yourcompany.igmpapp.com)")
fi
if ! is_valid_url "$URL"; then
    _red "Not a valid URL: $URL"; echo
    exit 1
fi
URL=$(trim_trailing_slash "$URL")

if [[ -z "$API_USER" ]]; then
    API_USER=$(prompt_required "InstantGMP API user (X-Api-User)")
fi

if [[ -z "$API_PASSWORD" ]]; then
    API_PASSWORD=$(prompt_secret "InstantGMP API password (X-Api-Password)")
fi

# -- probe -----------------------------------------------------------

if [[ $NO_PROBE -eq 0 ]]; then
    PROBE_URL="${URL}/rest/mcpservers/setup/mcpsetupserver"
    echo
    echo "Probing $PROBE_URL ..."
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' \
        -X HEAD --max-time 10 \
        -H "X-Api-User: $API_USER" \
        -H "X-Api-Password: $API_PASSWORD" \
        "$PROBE_URL" || echo "000")
    case "$HTTP_CODE" in
        200|204|301|302|404)
            _grn "  Server responded HTTP $HTTP_CODE - URL is reachable."; echo
            ;;
        401|403)
            _grn "  Server responded HTTP $HTTP_CODE - URL is reachable."; echo
            _yel "  (Credentials look wrong - InstantGMP rejected them.)"; echo
            ;;
        000)
            _red "  Could not reach server."; echo
            printf 'Continue anyway? [y/N] '
            IFS= read -r reply
            if [[ "$reply" != "y" && "$reply" != "Y" ]]; then
                _yel "Aborted. No files were written."; echo
                exit 1
            fi
            ;;
        *)
            _yel "  Server responded HTTP $HTTP_CODE."; echo
            ;;
    esac
fi

# -- env vars (rc file) ---------------------------------------------

if [[ $NO_ENV -eq 0 ]]; then
    if [[ -z "$RC_FILE" ]]; then
        # pick the rc file based on the user's login shell
        case "$(basename "${SHELL:-/bin/bash}")" in
            zsh)  RC_FILE="$HOME/.zshrc"  ;;
            bash) RC_FILE="$HOME/.bashrc" ;;
            *)    RC_FILE="$HOME/.profile" ;;
        esac
    fi
    BLOCK_BEGIN="# >>> instantgmp-mcp >>>"
    BLOCK_END="# <<< instantgmp-mcp <<<"
    TMP=$(mktemp)
    if [[ -f "$RC_FILE" ]]; then
        # strip out any previous instantgmp block
        awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" '
            $0 == b {skip=1; next}
            $0 == e {skip=0; next}
            !skip
        ' "$RC_FILE" > "$TMP"
    fi
    {
        cat "$TMP"
        echo "$BLOCK_BEGIN"
        echo "export IGMP_URL='$URL'"
        echo "export IGMP_API_USER='$API_USER'"
        echo "export IGMP_API_PASSWORD='$API_PASSWORD'"
        echo "$BLOCK_END"
    } > "${RC_FILE}.tmp"
    mv "${RC_FILE}.tmp" "$RC_FILE"
    rm -f "$TMP"
    _grn "Wrote env-var exports to $RC_FILE"; echo
    echo "  (Open a new terminal, or run:  source $RC_FILE )"
fi

# -- literal-value JSON for clients that don't expand env vars ------

CONFIG_DIR="$HOME/.config/instantgmp"
CONFIG_FILE="$CONFIG_DIR/mcp-config.json"
mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_FILE" <<JSON
{
  "mcpServers": {
    "instantgmp-inventory": {
      "type": "http",
      "url": "$URL/rest/mcpservers/inventory/mcpinventoryserver",
      "headers": { "X-Api-User": "$API_USER", "X-Api-Password": "$API_PASSWORD" }
    },
    "instantgmp-setup": {
      "type": "http",
      "url": "$URL/rest/mcpservers/setup/mcpsetupserver",
      "headers": { "X-Api-User": "$API_USER", "X-Api-Password": "$API_PASSWORD" }
    },
    "instantgmp-logs": {
      "type": "http",
      "url": "$URL/rest/mcpservers/logs/mcplogsserver",
      "headers": { "X-Api-User": "$API_USER", "X-Api-Password": "$API_PASSWORD" }
    },
    "instantgmp-ebr": {
      "type": "http",
      "url": "$URL/rest/mcpservers/ebr/mcpebrserver",
      "headers": { "X-Api-User": "$API_USER", "X-Api-Password": "$API_PASSWORD" }
    },
    "instantgmp-qms": {
      "type": "http",
      "url": "$URL/rest/mcpservers/qms/mcpqmsserver",
      "headers": { "X-Api-User": "$API_USER", "X-Api-Password": "$API_PASSWORD" }
    },
    "instantgmp-projects": {
      "type": "http",
      "url": "$URL/rest/mcpservers/projects/mcpprojectsserver",
      "headers": { "X-Api-User": "$API_USER", "X-Api-Password": "$API_PASSWORD" }
    },
    "instantgmp-docs": {
      "type": "http",
      "url": "$URL/rest/mcpservers/docs/mcpdocsserver",
      "headers": { "X-Api-User": "$API_USER", "X-Api-Password": "$API_PASSWORD" }
    }
  }
}
JSON

chmod 600 "$CONFIG_FILE"

echo
_grn "Wrote literal-value MCP config to $CONFIG_FILE"; echo
echo
_cyan "Next steps:"; echo
echo "  - For clients that expand env vars (Claude Code, Cursor, ...):"
echo "    open a new terminal so IGMP_URL/IGMP_API_USER/IGMP_API_PASSWORD"
echo "    are set, then start the client."
echo "  - For clients that need literal values (Cline, Windsurf, ...):"
echo "    paste the contents of $CONFIG_FILE into the client's MCP server"
echo "    settings, then restart the client."
echo
echo "Per-client setup notes: docs/clients/*.md"
echo
