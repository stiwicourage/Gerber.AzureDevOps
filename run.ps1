[CmdletBinding()]
param(
    [string]$CoreArtifactRoot = (Join-Path $PSScriptRoot '../GerberCore/dist'),
    [ValidateRange(30, 7200)][int]$SuiteTimeoutSeconds = 1800
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
Import-Module NovaModuleTools -ErrorAction Stop
$sharedCiRoot = if ($env:POWERSHELL_CI_PATH) { $env:POWERSHELL_CI_PATH } else { Join-Path $PSScriptRoot '../powershell-ci' }
$sharedAnalyzer = Join-Path $sharedCiRoot 'actions/script-analyzer/Invoke-ScriptAnalyzerCI.ps1'
if (-not (Test-Path -LiteralPath $sharedAnalyzer -PathType Leaf)) {
    throw "The shared powershell-ci checkout was not found at '$sharedCiRoot'. Clone stiwicourage/powershell-ci next to this repository or set POWERSHELL_CI_PATH."
}
& $sharedAnalyzer -ProjectRoot $PSScriptRoot
Invoke-NovaBuild
Invoke-NovaTest
Test-NovaBuild
& (Join-Path $PSScriptRoot 'scripts/Test-PluginBoundary.ps1') -CoreArtifactRoot $CoreArtifactRoot
& (Join-Path $PSScriptRoot 'scripts/Invoke-TerminalRegressionCI.ps1') -CoreArtifactRoot $CoreArtifactRoot -SuiteTimeoutSeconds $SuiteTimeoutSeconds
