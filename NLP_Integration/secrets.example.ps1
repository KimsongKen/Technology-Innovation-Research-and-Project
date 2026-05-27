# Copy this file to secrets.ps1 and fill in your real values.
# secrets.ps1 is listed in .gitignore — it will NEVER be committed.
#
# Usage: dot-source before running the API:
#   . .\secrets.ps1
#   .\run_api.ps1

# Groq API key — get one free at https://console.groq.com/keys
$env:SACA_HOSTED_STT_API_KEY = "gsk_REPLACE_WITH_YOUR_KEY"
