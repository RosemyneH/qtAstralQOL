param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"
$tag = if ($Version -match '^v') { $Version } else { "v$Version" }
$out = "dist/qtAstralQOL-$tag.zip"

New-Item -ItemType Directory -Force -Path dist | Out-Null
if (Test-Path $out) { Remove-Item $out }

git archive --format=zip --output $out $tag qtAstralQOL LICENSE README.md CHANGELOG.md
Write-Host "Wrote $out (unix path separators via git archive)"
