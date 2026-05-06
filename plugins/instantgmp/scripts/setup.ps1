# InstantGMP Cowork plugin — interactive setup
#
# Prompts the current Windows user for their InstantGMP server URL,
# API user, and API password, validates the URL, and writes the values
# as User-scope environment variables so that the .mcp.json shipped
# with the plugin (which uses ${IGMP_URL}, ${IGMP_API_USER},
# ${IGMP_API_PASSWORD}) can resolve them on every Cowork launch.
#
# Usage:
#   1. Open a Windows PowerShell window (no admin needed).
#   2. cd into the plugin's scripts folder, or invoke directly:
#        powershell -ExecutionPolicy Bypass -File .\setup.ps1
#   3. Restart Cowork after the script finishes so the new env vars
#      are picked up.

[CmdletBinding()]
param(
    [switch]$NonInteractive,
    [string]$Url,
    [string]$ApiUser,
    [string]$ApiPassword
)

$ErrorActionPreference = 'Stop'

function Write-Header {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  InstantGMP Cowork plugin — per-user setup" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This will save your InstantGMP server URL and API credentials" -ForegroundColor Gray
    Write-Host "as User-scope environment variables on this machine. The MCP" -ForegroundColor Gray
    Write-Host "plugin reads them at launch — your credentials never leave" -ForegroundColor Gray
    Write-Host "this computer and are not committed to the plugin repo." -ForegroundColor Gray
    Write-Host ""
}

function Read-RequiredString {
    param(
        [Parameter(Mandatory)] [string]$Prompt,
        [string]$Default = '',
        [scriptblock]$Validator = $null
    )
    while ($true) {
        $suffix = if ($Default) { " [$Default]" } else { '' }
        $value = Read-Host "$Prompt$suffix"
        if (-not $value -and $Default) { $value = $Default }
        if (-not $value) {
            Write-Host "  Value cannot be empty. Try again." -ForegroundColor Yellow
            continue
        }
        if ($Validator) {
            $err = & $Validator $value
            if ($err) {
                Write-Host "  $err" -ForegroundColor Yellow
                continue
            }
        }
        return $value
    }
}

function Read-RequiredSecret {
    param([Parameter(Mandatory)] [string]$Prompt)
    while ($true) {
        $secure = Read-Host -AsSecureString $Prompt
        if ($secure.Length -eq 0) {
            Write-Host "  Password cannot be empty. Try again." -ForegroundColor Yellow
            continue
        }
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try {
            return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        } finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

function Test-IgmpUrl {
    param([string]$CandidateUrl)
    try {
        $u = [System.Uri]$CandidateUrl
        if (-not ($u.Scheme -eq 'http' -or $u.Scheme -eq 'https')) {
            return "URL must start with http:// or https://"
        }
        if (-not $u.Host) { return "URL is missing a host." }
    } catch {
        return "Not a valid URL: $($_.Exception.Message)"
    }
    return $null
}

function Test-IgmpConnectivity {
    param(
        [string]$BaseUrl,
        [string]$User,
        [string]$Password
    )
    $probeUrl = ($BaseUrl.TrimEnd('/')) + '/rest/mcpservers/setup/mcpsetupserver'
    Write-Host ""
    Write-Host "Probing $probeUrl ..." -ForegroundColor Gray
    try {
        $headers = @{
            'X-Api-User'     = $User
            'X-Api-Password' = $Password
        }
        $resp = Invoke-WebRequest -Uri $probeUrl -Method Head -Headers $headers `
                                  -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        Write-Host "  Server responded: HTTP $($resp.StatusCode)." -ForegroundColor Green
        return $true
    } catch {
        $status = $_.Exception.Response.StatusCode.value__ 2>$null
        if ($status) {
            # 401/403 still means the host is reachable — credentials may be wrong but URL works.
            Write-Host "  Server responded HTTP $status. URL is reachable." -ForegroundColor Green
            if ($status -eq 401 -or $status -eq 403) {
                Write-Host "  (Credentials look wrong — InstantGMP rejected them.)" -ForegroundColor Yellow
            }
            return $true
        }
        Write-Host "  Could not reach server: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Set-UserEnv {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [string]$Value
    )
    [Environment]::SetEnvironmentVariable($Name, $Value, [EnvironmentVariableTarget]::User)
    # Reflect into current session too so the user can sanity-check immediately.
    Set-Item -Path "env:$Name" -Value $Value
}

# ---------------------------------------------------------------- main --

Write-Header

if (-not $NonInteractive) {
    $existingUrl  = [Environment]::GetEnvironmentVariable('IGMP_URL',          'User')
    $existingUser = [Environment]::GetEnvironmentVariable('IGMP_API_USER',     'User')
    $existingPwd  = [Environment]::GetEnvironmentVariable('IGMP_API_PASSWORD', 'User')

    if ($existingUrl -or $existingUser -or $existingPwd) {
        Write-Host "Existing InstantGMP env vars detected for this user:" -ForegroundColor Yellow
        if ($existingUrl)  { Write-Host "  IGMP_URL          = $existingUrl"  -ForegroundColor Yellow }
        if ($existingUser) { Write-Host "  IGMP_API_USER     = $existingUser" -ForegroundColor Yellow }
        if ($existingPwd)  { Write-Host "  IGMP_API_PASSWORD = (set, hidden)" -ForegroundColor Yellow }
        Write-Host ""
    }

    if (-not $Url) {
        $Url = Read-RequiredString -Prompt "InstantGMP base URL (e.g. https://yourcompany.igmpapp.com)" `
                                   -Default $existingUrl `
                                   -Validator { param($v) Test-IgmpUrl $v }
    }
    if (-not $ApiUser) {
        $ApiUser = Read-RequiredString -Prompt "InstantGMP API user (X-Api-User)" `
                                       -Default $existingUser
    }
    if (-not $ApiPassword) {
        $ApiPassword = Read-RequiredSecret -Prompt "InstantGMP API password (X-Api-Password)"
    }
}

# Final validation
$urlError = Test-IgmpUrl $Url
if ($urlError) { Write-Host $urlError -ForegroundColor Red; exit 1 }
if (-not $ApiUser)     { Write-Host "API user is required."     -ForegroundColor Red; exit 1 }
if (-not $ApiPassword) { Write-Host "API password is required." -ForegroundColor Red; exit 1 }

# Strip trailing slash so the .mcp.json template composes URLs cleanly.
$Url = $Url.TrimEnd('/')

# Optional connectivity check
$connOk = Test-IgmpConnectivity -BaseUrl $Url -User $ApiUser -Password $ApiPassword
if (-not $connOk -and -not $NonInteractive) {
    $proceed = Read-Host "Save anyway? (y/N)"
    if ($proceed -ne 'y' -and $proceed -ne 'Y') {
        Write-Host "Aborted. No environment variables were changed." -ForegroundColor Yellow
        exit 1
    }
}

Set-UserEnv -Name 'IGMP_URL'          -Value $Url
Set-UserEnv -Name 'IGMP_API_USER'     -Value $ApiUser
Set-UserEnv -Name 'IGMP_API_PASSWORD' -Value $ApiPassword

Write-Host ""
Write-Host "Saved (User scope):" -ForegroundColor Green
Write-Host "  IGMP_URL          = $Url"
Write-Host "  IGMP_API_USER     = $ApiUser"
Write-Host "  IGMP_API_PASSWORD = (length $($ApiPassword.Length), hidden)"
Write-Host ""
Write-Host "Restart Cowork now so the InstantGMP MCP servers pick up these values." -ForegroundColor Cyan
Write-Host ""
