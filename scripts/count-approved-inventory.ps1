# Count approved inventory items in InstantGMP — direct MCP smoke test.
#
# Talks to the InstantGMP MCP servers over HTTP using the JSON-RPC
# transport, with no Cowork involvement. Prints the count of inventory
# rows whose status is an "Approved" status.
#
# Usage (PowerShell, no admin needed):
#
#   .\count-approved-inventory.ps1
#
# Falls back to the sample server / sample credentials if you don't
# pass anything. Override on the command line if you want to point it
# at your real server:
#
#   .\count-approved-inventory.ps1 `
#       -BaseUrl "https://yourcompany.igmpapp.com" `
#       -ApiUser "api-user" `
#       -ApiPassword "..."
#
# Or, if you already ran setup.ps1 and saved a profile, the script
# will read IGMP_URL / IGMP_API_USER / IGMP_API_PASSWORD env vars.

[CmdletBinding()]
param(
    [string]$BaseUrl    = $env:IGMP_URL,
    [string]$ApiUser    = $env:IGMP_API_USER,
    [string]$ApiPassword = $env:IGMP_API_PASSWORD
)

# Sample-server fallbacks if no env vars and no flags
if (-not $BaseUrl)     { $BaseUrl     = 'http://trunk_test_prod.igmpapp.com' }
if (-not $ApiUser)     { $ApiUser     = 'api01' }
if (-not $ApiPassword) { $ApiPassword = 'pass1233' }

$BaseUrl = $BaseUrl.TrimEnd('/')

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Script:RpcId = 0
function Invoke-Mcp {
    param(
        [Parameter(Mandatory)] [string]$Server,   # e.g. 'inventory/mcpinventoryserver'
        [Parameter(Mandatory)] [string]$Method,
        $Params = @{}
    )
    $Script:RpcId++
    $body = @{
        jsonrpc = '2.0'
        method  = $Method
        params  = $Params
        id      = $Script:RpcId
    } | ConvertTo-Json -Depth 8 -Compress
    $headers = @{
        'Content-Type'   = 'application/json'
        'Accept'         = 'application/json, text/event-stream'
        'X-Api-User'     = $ApiUser
        'X-Api-Password' = $ApiPassword
    }
    $url = "$BaseUrl/rest/mcpservers/$Server"
    try {
        $resp = Invoke-WebRequest -Uri $url -Method Post -Headers $headers `
                                  -Body $body -UseBasicParsing -TimeoutSec 30
    } catch {
        $msg = $_.Exception.Message
        $status = $null
        try { $status = $_.Exception.Response.StatusCode.value__ } catch {}
        if ($status) { throw "HTTP $status from $url -- $msg" }
        else         { throw "Network error talking to $url -- $msg" }
    }

    # Server-Sent Events frames: parse lines like 'data: { ... }'
    $text = $resp.Content
    if ($text -match '(?ms)^data:\s*(\{.*?\})\s*$') {
        $text = $Matches[1]
    }
    try {
        return ($text | ConvertFrom-Json)
    } catch {
        throw "Could not parse JSON from $url -- $($_.Exception.Message). Body was: $text"
    }
}

function Mcp-CallTool {
    param(
        [Parameter(Mandatory)] [string]$Server,
        [Parameter(Mandatory)] [string]$ToolName,
        $Arguments = @{}
    )
    $resp = Invoke-Mcp -Server $Server -Method 'tools/call' `
                       -Params @{ name = $ToolName; arguments = $Arguments }
    if ($resp.error) {
        throw "Tool $ToolName on $Server failed: $($resp.error.message)"
    }
    # MCP convention: result.content[0].text for text/json payloads
    if ($resp.result.content) {
        $first = $resp.result.content | Select-Object -First 1
        if ($first.type -eq 'text' -or $first.type -eq 'json') {
            try {
                return ($first.text | ConvertFrom-Json -ErrorAction Stop)
            } catch {
                return $first.text
            }
        }
    }
    return $resp.result
}

Write-Host ""
Write-Host "InstantGMP — counting approved inventory items" -ForegroundColor Cyan
Write-Host "  Server : $BaseUrl"
Write-Host "  User   : $ApiUser"
Write-Host ""

# 1. Initialize each server we'll talk to
foreach ($srv in @('setup/mcpsetupserver','inventory/mcpinventoryserver')) {
    [void] (Invoke-Mcp -Server $srv -Method 'initialize' `
        -Params @{
            protocolVersion = '2024-11-05'
            capabilities    = @{}
            clientInfo      = @{ name = 'count-approved-inventory'; version = '1.0' }
        })
}

# 2. Find which material-status IDs are "Approved" (IsApproved = 1)
Write-Host "Looking up approved material-status IDs ..." -ForegroundColor Gray
$statusResp = Mcp-CallTool -Server 'setup/mcpsetupserver' -ToolName 'query_material_status' -Arguments @{ page = 1 }
$rows = if ($statusResp.records) { $statusResp.records }
        elseif ($statusResp.data) { $statusResp.data }
        else { $statusResp }
$approvedIds = @()
foreach ($r in $rows) {
    $isApp = $r.IsApproved -or $r.isApproved -or $r.is_approved
    if ($isApp -eq 1 -or $isApp -eq $true) {
        $idVal = $r.MaterialStatusId; if (-not $idVal) { $idVal = $r.id }
        if ($idVal) { $approvedIds += [int]$idVal }
    }
}
if (-not $approvedIds) {
    Write-Host "Could not identify any 'Approved' status IDs from query_material_status." -ForegroundColor Yellow
    Write-Host "Raw response (first row):" -ForegroundColor Yellow
    if ($rows) { $rows | Select-Object -First 1 | ConvertTo-Json -Depth 5 | Write-Host }
    exit 1
}
Write-Host "  Approved status IDs: $($approvedIds -join ', ')" -ForegroundColor Green

# 3. Page through query_inventory, count rows whose status is approved
Write-Host "Paging through inventory ..." -ForegroundColor Gray
$total = 0
$page  = 1
while ($true) {
    $resp = Mcp-CallTool -Server 'inventory/mcpinventoryserver' -ToolName 'query_inventory' `
                         -Arguments @{ page = $page }
    $rows = if ($resp.records) { $resp.records }
            elseif ($resp.data) { $resp.data }
            else { $resp }
    if (-not $rows) { break }
    foreach ($r in $rows) {
        $sid = $r.MaterialStatusId; if (-not $sid) { $sid = $r.statusId }
        if ($sid -and ([int]$sid -in $approvedIds)) { $total++ }
    }
    $isLast = $resp.IsLastPage; if ($null -eq $isLast) { $isLast = $resp.isLastPage }
    if ($isLast -eq $true) { break }
    if ($rows.Count -eq 0) { break }
    $page++
    if ($page -gt 200) { Write-Host "  (stopping at page 200 to avoid runaway)" -ForegroundColor Yellow; break }
}

Write-Host ""
Write-Host "Approved inventory items: $total" -ForegroundColor Green
Write-Host ""
