[CmdletBinding()]
param(
    [string]$CoreArtifactRoot = (Join-Path $PSScriptRoot '../../GerberCore/dist')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$env:PSModulePath = @((Join-Path $PSScriptRoot '../dist'), $CoreArtifactRoot, $env:PSModulePath) -join [IO.Path]::PathSeparator
Import-Module (Join-Path $CoreArtifactRoot 'Gerber/Gerber.psd1') -Force -ErrorAction Stop
$result = Test-GerberPluginBoundary -Path (Split-Path -Parent $PSScriptRoot)
if (-not $result.IsValid) {
    $result.Diagnostics | Format-Table File, Line, Dependency, Reason, Resolution -Wrap
    throw 'Fix plugin boundary diagnostics before building. Use public API v1 or request a new capability.'
}
Write-Output "Gerber Plugin API v1 boundary: passed ($($result.FileCount) authored files)."
