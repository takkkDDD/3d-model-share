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
    if (Test-Path "$GlbPath.glb") {
        Write-Host "Note: appended missing .glb extension"
        $GlbPath = "$GlbPath.glb"
    } else {
        Write-Error "File not found: $GlbPath"
        exit 1
    }
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

if ($manifest.Count -eq 0) {
    $json = "[]"
} elseif ($manifest.Count -eq 1) {
    $json = "[`n" + ($manifest | ConvertTo-Json -Depth 3) + "`n]"
} else {
    $json = $manifest | ConvertTo-Json -Depth 3
}
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding($false)))

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
    $shareUrl = "$pagesUrl/?model=$targetName&title=$([uri]::EscapeDataString($Title))"
    Write-Host ""
    Write-Host "Share URL:"
    Write-Host "  $shareUrl"
    Write-Host "  Gallery: $pagesUrl/gallery.html"

    try {
        Set-Clipboard -Value $shareUrl
        Write-Host "  (copied to clipboard)"
    } catch {
        Write-Warning "Could not copy to clipboard."
    }

    $linksPath = Join-Path $repoRoot "links.html"
    $rows = ($manifest | ForEach-Object {
        $u = "$pagesUrl/?model=$($_.file)&title=$([uri]::EscapeDataString($_.title))"
        "<li><a href=`"$u`" target=`"_blank`">$($_.title)</a> <span class=`"date`">($($_.added))</span><br><code>$u</code></li>"
    }) -join "`n"
    $html = @"
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>Published Links</title>
<style>
  body { background:#1a1a1a; color:#eee; font-family:system-ui,sans-serif; padding:24px; }
  a { color:#8ab4f8; }
  li { margin-bottom:16px; }
  .date { opacity:.6; font-size:13px; }
  code { font-size:12px; opacity:.7; word-break:break-all; }
</style>
</head>
<body>
<h1>Published Models (local reference)</h1>
<p><a href="$pagesUrl/gallery.html" target="_blank">Gallery</a></p>
<ul>
$rows
</ul>
</body>
</html>
"@
    [System.IO.File]::WriteAllText($linksPath, $html, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "  Local link list: $linksPath"
}
