<#
Usage:
  .\unpublish.ps1                        -> interactive list, choose by number
  .\unpublish.ps1 -FileName "name.glb"   -> remove a specific file directly

Removes from models/ -> updates manifest.json -> git rm/commit/push
#>
param(
    [string]$FileName
)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot
$manifestPath = Join-Path $repoRoot "models\manifest.json"

if (-not (Test-Path $manifestPath)) {
    Write-Error "manifest.json not found."
    exit 1
}

$parsed = Get-Content $manifestPath -Raw | ConvertFrom-Json
if ($parsed -is [System.Array]) {
    $manifest = $parsed
} else {
    $manifest = @($parsed)
}

if ($manifest.Count -eq 0) {
    Write-Host "No published models."
    exit 0
}

if (-not $FileName) {
    Write-Host ""
    Write-Host "Published models:"
    for ($i = 0; $i -lt $manifest.Count; $i++) {
        Write-Host "  [$($i + 1)] $($manifest[$i].file)  (title: $($manifest[$i].title))"
    }
    Write-Host ""
    $selection = Read-Host "Enter number to remove (or filename)"
    if ($selection -match '^\d+$') {
        $index = [int]$selection - 1
        if ($index -lt 0 -or $index -ge $manifest.Count) {
            Write-Error "Invalid selection."
            exit 1
        }
        $FileName = $manifest[$index].file
    } else {
        $FileName = $selection
    }
}

$target = $manifest | Where-Object { $_.file -eq $FileName }
if (-not $target) {
    Write-Error "File not found in manifest: $FileName"
    exit 1
}

Write-Host ""
Write-Host "About to remove: $FileName (title: $($target.title))"
$confirm = Read-Host "Type 'y' to confirm"
if ($confirm -ne 'y') {
    Write-Host "Cancelled."
    exit 0
}

$manifest = @($manifest | Where-Object { $_.file -ne $FileName })

if ($manifest.Count -eq 0) {
    $json = "[]"
} elseif ($manifest.Count -eq 1) {
    $json = "[`n" + ($manifest | ConvertTo-Json -Depth 3) + "`n]"
} else {
    $json = $manifest | ConvertTo-Json -Depth 3
}
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding($false)))

$glbPath = Join-Path $repoRoot "models\$FileName"

Push-Location $repoRoot
try {
    if (Test-Path $glbPath) {
        git rm --quiet "models/$FileName"
    } else {
        git add "models/manifest.json"
    }
    git commit -m "Remove $FileName"
    git push
} finally {
    Pop-Location
}

$remoteUrl = (git -C $repoRoot remote get-url origin) -replace '\.git$', ''
if ($remoteUrl -match 'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/]+)$') {
    $owner = $Matches.owner
    $repo = $Matches.repo
    $pagesUrl = "https://$owner.github.io/$repo"

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
}

Write-Host ""
Write-Host "Removed. The site will update in a minute or two."
