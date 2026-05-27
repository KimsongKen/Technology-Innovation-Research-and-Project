# Prefer `run_api.cmd` from Explorer or cmd if PowerShell blocks script execution (no ExecutionPolicy changes needed).
#
# Default: English STT (Groq cloud -> faster-whisper fallback) AND Warlpiri voice (Meta MMS 300M).
# -EnglishOnly          Skip MMS; lighter startup. wbp *voice* returns 503.
# -WarlpiriDevFallback  English Whisper for wbp (dev only); MMS off.
# -WarlpiriMms          Optional; MMS is already default (backward compat for scripts).
# -NoGroq               Disable Groq cloud STT; use local faster-whisper only.
Param(
    [switch]$NoReload,
    [int]$PreferredPort = 8000,
    [switch]$EnglishOnly,
    [switch]$WarlpiriMms,
    [switch]$WarlpiriDevFallback,
    [switch]$NoGroq
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$venvPython = Join-Path $projectRoot ".venv\Scripts\python.exe"

if (-not (Test-Path $venvPython)) {
    Write-Host "Creating .venv with Python launcher..."
    py -3.12 -m venv .venv
}

Write-Host "Ensuring API dependencies are installed..."
& $venvPython -m pip install -q -r requirements.txt

# This project always runs real STT now (mock mode removed).
Write-Host "STT mode: REAL"

# --- Option 1: Groq cloud STT (primary English path - sub-1-second turnaround) ---
# Groq provides OpenAI-compatible Whisper Large v3. Falls back to local faster-whisper
# automatically if Groq is unavailable. Disable with -NoGroq flag.
if ($NoGroq) {
    $env:SACA_USE_HOSTED_STT = "0"
    Write-Host "Groq STT: DISABLED (-NoGroq flag set)"
} else {
    if (-not $env:SACA_USE_HOSTED_STT)             { $env:SACA_USE_HOSTED_STT             = "1" }
    if (-not $env:SACA_HOSTED_STT_PROVIDER)        { $env:SACA_HOSTED_STT_PROVIDER        = "openai" }
    if (-not $env:SACA_HOSTED_STT_BASE_URL)        { $env:SACA_HOSTED_STT_BASE_URL        = "https://api.groq.com/openai/v1" }
    if (-not $env:SACA_HOSTED_STT_MODEL)           { $env:SACA_HOSTED_STT_MODEL           = "whisper-large-v3" }
    if (-not $env:SACA_HOSTED_STT_API_KEY) {
        Write-Error "SACA_HOSTED_STT_API_KEY is not set. Set it in secrets.ps1 (see secrets.example.ps1) or as a system env var. Use -NoGroq to skip."
        exit 1
    }
    if (-not $env:SACA_HOSTED_STT_TIMEOUT_SECONDS) { $env:SACA_HOSTED_STT_TIMEOUT_SECONDS = "30" }
    Write-Host "Groq STT: ENABLED (whisper-large-v3 via api.groq.com) -- use -NoGroq to disable"
}

# --- Option 2: Local faster-whisper (offline fallback when Groq is unavailable) ---
# Uses tiny.en (fastest CPU model) with greedy decoding and no VAD retry loop.
# With Groq as primary this path is only hit on network failure.
# Model size guide for offline-only deployments (override SACA_WHISPER_MODEL before running):
#   tiny.en  - fastest, ~400 MB RAM, good for short clinical phrases (default fallback)
#   small    - balanced, ~1 GB RAM
#   medium   - good accuracy, ~3 GB RAM
#   large-v3 - best accuracy, ~6 GB RAM (use with -NoGroq on a powerful machine)
if (-not $env:SACA_USE_FASTER_WHISPER)        { $env:SACA_USE_FASTER_WHISPER        = "1" }
if (-not $env:SACA_WHISPER_MODEL)             { $env:SACA_WHISPER_MODEL             = "tiny.en" }
if (-not $env:SACA_WHISPER_BEAM_SIZE)         { $env:SACA_WHISPER_BEAM_SIZE         = "1" }
if (-not $env:SACA_WHISPER_VAD_FILTER)        { $env:SACA_WHISPER_VAD_FILTER        = "0" }
if (-not $env:SACA_WHISPER_COMPUTE_TYPE)      { $env:SACA_WHISPER_COMPUTE_TYPE      = "int8" }
if (-not $env:SACA_USE_WHISPER_TINY_FALLBACK) { $env:SACA_USE_WHISPER_TINY_FALLBACK = "0" }
if (-not $env:SACA_WHISPER_TINY_MODEL)        { $env:SACA_WHISPER_TINY_MODEL        = "tiny" }

# --- Option 4: Warlpiri MMS model ---
# facebook/mms-1b-all: confirmed to carry pjt (Pitjantjatjara) and 1000+ language adapters.
#   Warlpiri (wbp) is not in the public adapter list, so the backend falls back to pjt.
#   First run downloads ~4 GB; cached afterwards.
# facebook/mms-300m: 3x smaller but does NOT carry the pjt/wbp adapters needed here.
#   If you override with mms-300m, the adapter load will fail and the server auto-falls back
#   to English Whisper for Warlpiri requests (app stays functional, accuracy reduced).
# For a custom fine-tuned Warlpiri checkpoint: set SACA_MMS_MODEL_ID to your HuggingFace repo ID.
if (-not $env:SACA_MMS_MODEL_ID)            { $env:SACA_MMS_MODEL_ID            = "facebook/mms-1b-all" }
if (-not $env:SACA_MMS_STT_TIMEOUT_SECONDS) { $env:SACA_MMS_STT_TIMEOUT_SECONDS = "120" }

if ($WarlpiriDevFallback) {
    $env:SACA_WARLPIRI_STT_DEV_FALLBACK = "1"
    $env:SACA_USE_MMS_WARLPIRI_STT = "0"
    Write-Host "Warlpiri DEV: SACA_WARLPIRI_STT_DEV_FALLBACK=1 (English Whisper for wbp - UI testing only); MMS off."
} elseif ($EnglishOnly) {
    $env:SACA_USE_MMS_WARLPIRI_STT = "0"
    $env:SACA_WARLPIRI_STT_DEV_FALLBACK = "0"
    Write-Host "English-only: MMS disabled. wbp voice returns 503; JSON triage with language=wbp still works."
} else {
    $env:SACA_USE_MMS_WARLPIRI_STT = "1"
    $env:SACA_WARLPIRI_STT_DEV_FALLBACK = "0"
    Write-Host "Warlpiri: MMS enabled (facebook/mms-300m). First run downloads the model; use -EnglishOnly to skip."
}

if ($WarlpiriMms -and -not $EnglishOnly -and -not $WarlpiriDevFallback) {
    $env:SACA_USE_MMS_WARLPIRI_STT = "1"
}

Write-Host "STT backend flags:"
Write-Host "  English  : GROQ=$($env:SACA_USE_HOSTED_STT) MODEL=$($env:SACA_HOSTED_STT_MODEL) | Fallback: FASTER_WHISPER=$($env:SACA_USE_FASTER_WHISPER) MODEL=$($env:SACA_WHISPER_MODEL) BEAM=$($env:SACA_WHISPER_BEAM_SIZE) VAD=$($env:SACA_WHISPER_VAD_FILTER)"
Write-Host "  Warlpiri : MMS=$($env:SACA_USE_MMS_WARLPIRI_STT) MMS_MODEL=$($env:SACA_MMS_MODEL_ID) TIMEOUT=$($env:SACA_MMS_STT_TIMEOUT_SECONDS)s DEV_FB=$($env:SACA_WARLPIRI_STT_DEV_FALLBACK)"

$uvicornArgs = @("api.main:app")
if (-not $NoReload) {
    # Restrict reload watching to the api/ source tree only.
    # Without this, uvicorn --reload watches the entire project directory and
    # restarts the worker mid-request whenever HuggingFace downloads model
    # weight files (*.bin, *.safetensors) into a cache folder inside the project.
    $uvicornArgs += "--reload"
    $uvicornArgs += "--reload-dir"
    $uvicornArgs += "api"
}

function Test-PortBindable {
    param(
        [int]$Port
    )
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse("127.0.0.1"), $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    } catch {
        return $false
    }
}

$candidatePorts = New-Object 'System.Collections.Generic.List[int]'
foreach ($x in @($PreferredPort) + @(8000..8010)) {
    if (-not $candidatePorts.Contains($x)) {
        [void]$candidatePorts.Add($x)
    }
}
$selectedPort = $null
foreach ($p in $candidatePorts) {
    if (Test-PortBindable -Port $p) {
        $selectedPort = $p
        break
    }
}
if ($null -eq $selectedPort) {
    $busy = @()
    try {
        $busy = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
            Where-Object { $_.LocalPort -in 8000..8010 -and $_.LocalAddress -match '^(127\.0\.0\.1|0\.0\.0\.0)$' } |
            Select-Object LocalPort, OwningProcess -Unique
    } catch { }
    $hint = if ($busy) {
        ($busy | ForEach-Object { "port $($_.LocalPort) -> PID $($_.OwningProcess) (taskkill /PID $($_.OwningProcess) /F)" }) -join "`n"
    } else { "(could not list listeners; run as admin or check Task Manager for python/uvicorn)" }
    throw @"
No free port found among candidates starting with $PreferredPort then 8000-8010 (127.0.0.1). Stop the existing SACA API (uvicorn) or other app using these ports.

Likely listeners:
$hint

Or start with a custom port:  .\run_api.ps1 -PreferredPort 8765
"@
}

Write-Host "API port: $selectedPort"
if ($selectedPort -ne 8000) {
    Write-Host "NOTE: Update Flutter base URL to port $selectedPort if needed."
}

Write-Host "Starting Swin SACA API..."
& $venvPython -m uvicorn @uvicornArgs --host 127.0.0.1 --port $selectedPort
