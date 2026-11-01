[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module PSScriptAnalyzer -ErrorAction Stop
$root = Split-Path -Parent $PSScriptRoot
$findings = @(
    foreach ($directory in @('src', 'tests', 'scripts')) {
        Invoke-ScriptAnalyzer -Path (Join-Path $root $directory) -Recurse
    }
    Invoke-ScriptAnalyzer -Path (Join-Path $root 'run.ps1')
)
if ($findings.Count -gt 0) {
    $findings | Format-Table ScriptName, Line, RuleName, Message -Wrap
    throw "Azure DevOps ScriptAnalyzer reported $($findings.Count) findings."
}
Write-Output 'Azure DevOps ScriptAnalyzer: 0 findings.'
