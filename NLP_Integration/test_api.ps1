param(
    [string]$BaseUrl = "http://localhost:8000",
    [string]$AuthToken = "dev-token"
)

$ErrorActionPreference = "Stop"

function Run-Test {
    param(
        [string]$Name,
        [scriptblock]$Body
    )

    try {
        & $Body
        [pscustomobject]@{
            Test   = $Name
            Status = "PASS"
            Detail = ""
        }
    }
    catch {
        [pscustomobject]@{
            Test   = $Name
            Status = "FAIL"
            Detail = $_.Exception.Message
        }
    }
}

function Assert-HasFields {
    param(
        [object]$Object,
        [string[]]$Fields
    )

    foreach ($field in $Fields) {
        if (-not ($Object.PSObject.Properties.Name -contains $field)) {
            throw "Missing response field: $field"
        }
    }
}

$requiredResponseFields = @(
    "triage_level",
    "top_condition",
    "confidence",
    "top_3_symptoms",
    "recommendation",
    "escalation_triggered"
)

$results = @()
$authHeaders = @{ Authorization = "Bearer $AuthToken" }

# 1) Health check
$results += Run-Test -Name "GET /health returns status ok" -Body {
    $res = Invoke-RestMethod -Method Get -Uri "$BaseUrl/health"
    if ($res.status -ne "ok") {
        throw "Expected status=ok, got '$($res.status)'"
    }
}

# 2) JSON contract check
$results += Run-Test -Name "POST /triage/predict contract fields" -Body {
    $payload = @{
        raw_transcript      = "patient says chest pan and cant breath"
        verified_transcript = "patient has chest pain and can't breathe"
        language            = "en"
    } | ConvertTo-Json

    $res = Invoke-RestMethod -Method Post -Uri "$BaseUrl/triage/predict" -ContentType "application/json" -Headers $authHeaders -Body $payload
    Assert-HasFields -Object $res -Fields $requiredResponseFields
}

# 3) Emergency keyword escalation gate
$results += Run-Test -Name "Keyword escalation forces Severe" -Body {
    $payload = @{
        raw_transcript      = "patient has pain"
        verified_transcript = "patient has chest pain and can't breathe"
        language            = "en"
    } | ConvertTo-Json

    $res = Invoke-RestMethod -Method Post -Uri "$BaseUrl/triage/predict" -ContentType "application/json" -Headers $authHeaders -Body $payload
    Assert-HasFields -Object $res -Fields $requiredResponseFields

    if ($res.triage_level -ne "Severe") {
        throw "Expected triage_level=Severe, got '$($res.triage_level)'"
    }
    if (-not $res.escalation_triggered) {
        throw "Expected escalation_triggered=true, got false"
    }
}

# 4) Warlpiri language path
$results += Run-Test -Name "Warlpiri path accepts language=wbp" -Body {
    $payload = @{
        raw_transcript      = "yapa kurrunpa watiya"
        verified_transcript = "yapa kurrunpa watiya"
        language            = "wbp"
    } | ConvertTo-Json

    $res = Invoke-RestMethod -Method Post -Uri "$BaseUrl/triage/predict" -ContentType "application/json" -Headers $authHeaders -Body $payload
    Assert-HasFields -Object $res -Fields $requiredResponseFields
}

# 5) Multipart endpoint parity
$results += Run-Test -Name "POST /triage/predict-multipart works" -Body {
    $form = @{
        raw_transcript      = "patient says chest pan"
        verified_transcript = "patient has chest pain"
        language            = "en"
    }
    if ((Get-Command Invoke-RestMethod).Parameters.ContainsKey('Form')) {
        $res = Invoke-RestMethod -Method Post -Uri "$BaseUrl/triage/predict-multipart" -Headers $authHeaders -Form $form
    } else {
        $curlOutput = curl.exe -s -X POST "$BaseUrl/triage/predict-multipart" `
          -H "Authorization: Bearer $AuthToken" `
          -F "raw_transcript=patient says chest pan" `
          -F "verified_transcript=patient has chest pain" `
          -F "language=en"
        $res = $curlOutput | ConvertFrom-Json
    }
    Assert-HasFields -Object $res -Fields $requiredResponseFields
}

Write-Host ""
Write-Host "SACA API Test Results"
Write-Host "====================="
$results | Format-Table -AutoSize

$passCount = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count

Write-Host ""
Write-Host "Summary: PASS=$passCount FAIL=$failCount"

if ($failCount -gt 0) {
    exit 1
}
exit 0
