# =============================================================================
# run-local.ps1
# Wrapper for `docker run` that mounts GCP Application Default Credentials
# so any container using google-cloud-* SDKs authenticates automatically.
#
# Usage:
#   .\run-local.ps1 -Image docker.io/tnmurthy/default:latest
#   .\run-local.ps1 -Image myproject -Port 8080 -Env @("DEBUG=true","DB_URL=...")
#   .\run-local.ps1 -Image myproject -Command "python manage.py migrate"
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$Image,

    [string]$Port = "8000",

    [string[]]$Env = @(),

    [string]$Command = "",

    [switch]$Detach
)

$GCP_ADC   = "$env:APPDATA\gcloud"
$GCP_MOUNT = "/root/.config/gcloud"
$PROJECT   = (gcloud config get-value project 2>$null).Trim()

$args = @(
    "run", "--rm",
    "-v", "${GCP_ADC}:${GCP_MOUNT}:ro",
    "-e", "GOOGLE_CLOUD_PROJECT=$PROJECT",
    "-e", "GCLOUD_PROJECT=$PROJECT",
    "-p", "${Port}:${Port}"
)

foreach ($e in $Env) {
    $args += @("-e", $e)
}

if ($Detach) { $args += "-d" }

$args += $Image

if ($Command -ne "") {
    $args += ("bash", "-c", $Command)
}

Write-Host "docker $($args -join ' ')"
docker @args