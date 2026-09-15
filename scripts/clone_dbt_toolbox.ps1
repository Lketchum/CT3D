# Clone LAVI-USP DBT-Reconstruction into vendor/ (not committed).
$ErrorActionPreference = "Stop"
$dest = Join-Path $PSScriptRoot "..\vendor\DBT-Reconstruction"
$dest = [System.IO.Path]::GetFullPath($dest)

if (Test-Path (Join-Path $dest "FBP.m")) {
    Write-Host "Already present: $dest"
    exit 0
}

New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
git clone --depth 1 https://github.com/LAVI-USP/DBT-Reconstruction.git $dest
Write-Host "Cloned to $dest"
