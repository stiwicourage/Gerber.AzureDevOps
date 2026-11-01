[CmdletBinding()]
param(
    [string]$CoreArtifactRoot = (Join-Path $PSScriptRoot '../../GerberCore/dist'),
    [ValidateRange(30, 7200)][int]$SuiteTimeoutSeconds = 1800,
    [string]$ScenarioId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$python = Join-Path (Split-Path -Parent $CoreArtifactRoot) 'artifacts/terminal/.venv/bin/python'
if (-not (Test-Path -LiteralPath $python -PathType Leaf)) {
    throw 'The authorized Core terminal test environment is missing; run its configured terminal wrapper first.'
}
$arguments = @(
    (Join-Path $root 'tests/terminal/run_terminal_tests.py'),
    '--core-artifact-root', $CoreArtifactRoot,
    '--suite-timeout-seconds', $SuiteTimeoutSeconds
)
& $python -m unittest discover -s (Join-Path $root 'tests/terminal/selftests') -p 'test_*.py'
if ($LASTEXITCODE -ne 0) { throw "Product terminal self-tests failed with exit code $LASTEXITCODE." }
if ($ScenarioId) { $arguments += @('--scenario-id', $ScenarioId) }
& $python @arguments
if ($LASTEXITCODE -ne 0) { throw "Product terminal regression failed with exit code $LASTEXITCODE." }
