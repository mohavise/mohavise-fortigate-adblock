param(
    [string]$CoreUrl = "https://raw.githubusercontent.com/mohavise/mohavise-adblock-core/main/core-domains.txt",
    [string]$DomainOutputFile = "..\fortigate-domains.txt"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptRoot

if (Test-Path -LiteralPath $CoreUrl) {
    $coreLines = Get-Content -LiteralPath $CoreUrl
} else {
    $content = Invoke-WebRequest -Uri $CoreUrl -UseBasicParsing
    $coreLines = $content.Content -split "`r?`n"
}

$final = $coreLines |
    ForEach-Object { $_.Trim().ToLowerInvariant() } |
    Where-Object { $_ -ne "" -and !$_.StartsWith("#") } |
    Sort-Object -Unique

$domainLines = [System.Collections.Generic.List[string]]::new()
$final | ForEach-Object { [void]$domainLines.Add($_) }

Set-Content -LiteralPath $DomainOutputFile -Value $domainLines -Encoding ASCII

Write-Host "Generated $DomainOutputFile with $($final.Count) blocked domains."
