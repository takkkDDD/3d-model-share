<#
Usage:
  .\publish.ps1 -GlbPath "C:\path\to\model.glb" -Title "Display Name"
  .\publish.ps1 -GlbPath "C:\path\to\model.glb" -Title "Display Name" -FileName "custom_name.glb"

Copies into models/ -> updates manifest.json -> git add/commit/push -> prints share URL
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$GlbPath,

    [string]$Title,

    [string]$FileName
)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot

if (-not (Test-Path $GlbPath)) {
    Write-Error "File not found: $GlbPath"
    exit 1
}

$srcFile = Get-Item $GlbPath
$sizeMB = [math]::Round($srcFile.Length / 1MB, 1)
if ($srcFile.Length -gt 100MB) {
    Write-Error "File exceeds 100MB ($sizeMB MB). Please compress it first (see spec section 8)."
    exit 1
}
if ($sizeMB -gt 50) {
    Write-Warning "File is $sizeMB MB. Consider compressing files over 50MB."
}

if ($FileName) {
    $targetName = $FileName
} else {
    $targetName = $srcFile.Name
}

$normalized = $targetName.ToLower() -replace '\s+', '_'
if ($normalized -ne $targetName) {
    Write-Host "Normalized filename: $targetName -> $normalized"
}
$targetName = $normalized

if (-not $Title) {
    $Title = [System.IO.Path]::GetFileNameWithoutExtension($targetName)
}

$targetPath = Join-Path $repoRoot "models\$targetName"
Copy-Item -Path $srcFile.FullName -Destination $targetPath -Force

$manifestPath = Join-Path $repoRoot "models\manifest.json"
if (Test-Path $manifestPath) {
    $parsed = Get-Content $manifestPath -Raw | ConvertFrom-Json
    if ($parsed -is [System.Array]) {
        $manifest = $parsed
    } else {
        $manifest = @($parsed)
    }
} else {
    $manifest = @()
}

$today = Get-Date -Format "yyyy-MM-dd"
$existing = $manifest | Where-Object { $_.file -eq $targetName }
if ($existing) {
    $existing.title = $Title
    $existing.added = $today
} else {
    $manifest += [PSCustomObject]@{ file = $targetName; title = $Title; added = $today }
}

$manifest | ConvertTo-Json -Depth 3 | Set-Content -Path $manifestPath -Encoding utf8

Push-Location $repoRoot
try {
    git add "models/$targetName" "models/manifest.json"
    git commit -m "Add $targetName"
    git push
} finally {
    Pop-Location
}

$remoteUrl = (git -C $repoRoot remote get-url origin) -replace '\.git$', ''
if ($remoteUrl -match 'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/]+)$') {
    $owner = $Matches.owner
    $repo = $Matches.repo
    $pagesUrl = "https://$owner.github.io/$repo"
    Write-Host ""
    Write-Host "Share URL:"
    Write-Host "  $pagesUrl/?model=$targetName&title=$([uri]::EscapeDataString($Title))"
    Write-Host "  Gallery: $pagesUrl/gallery.html"
}
