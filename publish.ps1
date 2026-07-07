<#
使い方:
  .\publish.ps1 -GlbPath "C:\path\to\model.glb" -Title "表示名"
  .\publish.ps1 -GlbPath "C:\path\to\model.glb" -Title "表示名" -FileName "custom_name.glb"

models/ にコピー -> manifest.json 更新 -> git add/commit/push -> 共有URLを表示
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
    Write-Error "ファイルが見つかりません: $GlbPath"
    exit 1
}

$srcFile = Get-Item $GlbPath
$sizeMB = [math]::Round($srcFile.Length / 1MB, 1)
if ($srcFile.Length -gt 100MB) {
    Write-Error "100MBを超えています ($sizeMB MB)。gltf-transform で圧縮してください(仕様書 8章参照)。"
    exit 1
}
if ($sizeMB -gt 50) {
    Write-Warning "$sizeMB MB あります。50MBを超えているため圧縮を検討してください。"
}

if ($FileName) {
    $targetName = $FileName
} else {
    $targetName = $srcFile.Name
}

$normalized = $targetName.ToLower() -replace '\s+', '_'
if ($normalized -ne $targetName) {
    Write-Host "ファイル名を正規化しました: $targetName -> $normalized"
}
$targetName = $normalized

if (-not $Title) {
    $Title = [System.IO.Path]::GetFileNameWithoutExtension($targetName)
}

$targetPath = Join-Path $repoRoot "models\$targetName"
Copy-Item -Path $srcFile.FullName -Destination $targetPath -Force

$manifestPath = Join-Path $repoRoot "models\manifest.json"
if (Test-Path $manifestPath) {
    $manifest = @(Get-Content $manifestPath -Raw | ConvertFrom-Json)
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
    Write-Host "公開URL:"
    Write-Host "  $pagesUrl/?model=$targetName&title=$([uri]::EscapeDataString($Title))"
    Write-Host "  一覧: $pagesUrl/gallery.html"
}
