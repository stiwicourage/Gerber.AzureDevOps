[CmdletBinding()]
param(
    [string]$CoreArtifactRoot = (Join-Path $PSScriptRoot '../GerberCore/dist'),
    [ValidateRange(30, 7200)][int]$SuiteTimeoutSeconds = 1800
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
Import-Module NovaModuleTools -ErrorAction Stop
& (Join-Path $PSScriptRoot 'scripts/Invoke-ScriptAnalyzerCI.ps1')
Invoke-NovaBuild
Invoke-NovaTest
Test-NovaBuild
& (Join-Path $PSScriptRoot 'scripts/Test-PluginBoundary.ps1') -CoreArtifactRoot $CoreArtifactRoot
& (Join-Path $PSScriptRoot 'scripts/Invoke-TerminalRegressionCI.ps1') -CoreArtifactRoot $CoreArtifactRoot -SuiteTimeoutSeconds $SuiteTimeoutSeconds
