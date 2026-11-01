[CmdletBinding()]
param(
    [string]$GerberRoot,
    [string]$PluginRoot,
    [string]$SecretStoreStatePath,
    [string]$ClipboardStatePath,
    [string]$HttpFixturePath,
    [string]$HttpStatePath,
    [string]$ModuleStatePath,
    [string]$DiagnosticStatePath,
    [string]$PromptTracePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Reuse only Core's test-owned fake infrastructure; never private Core source.
$support = Join-Path $GerberRoot 'tests/terminal/fixtures'
foreach ($file in @('State', 'ModuleValidation', 'CredentialStore', 'Configuration', 'Environment')) {
    . (Join-Path $support "TestHarness.$file.ps1")
}
$env:PSModulePath = @((Join-Path $PluginRoot 'dist'), (Join-Path $GerberRoot 'dist'), $env:PSModulePath) -join [IO.Path]::PathSeparator
Initialize-GerberTerminalConfigurationEnvironment -PromptTracePath $PromptTracePath
$env:GERBER_CONFIG_PATH = Join-Path (Split-Path -Parent $PromptTracePath) 'GerberCore.json'
Write-GerberTerminalJsonFile -Path $DiagnosticStatePath -Value @{ events = @() }
Write-GerberTerminalJsonFile -Path $ModuleStatePath -Value (Get-GerberTerminalDefaultModuleState)
Initialize-GerberTerminalClipboardShim -Path $ClipboardStatePath
Initialize-GerberTerminalHttpShim -FixturePath $HttpFixturePath -StatePath $HttpStatePath
Initialize-GerberPromptTracePath -Path $PromptTracePath

try {
    $validation = Get-GerberTerminalModuleValidationContext -ModuleStatePath $ModuleStatePath -DiagnosticStatePath $DiagnosticStatePath
    $expected = Get-GerberTerminalExpectedModuleRecord -Name Gerber -ManifestPath (Join-Path $GerberRoot 'dist/Gerber/Gerber.psd1')
    $core = Import-Module $expected.ManifestPath -Force -PassThru
    Assert-GerberTerminalResolvedModule -ValidationContext $validation -Expected $expected -Module $core -ResolutionKind 'explicit import'
    $pluginExpected = Get-GerberTerminalExpectedModuleRecord -Name 'Gerber.AzureDevOps' -ManifestPath (Join-Path $PluginRoot 'dist/Gerber.AzureDevOps/Gerber.AzureDevOps.psd1')
    $plugin = Import-Module $pluginExpected.ManifestPath -Force -PassThru
    Assert-GerberTerminalResolvedModule -ValidationContext $validation -Expected $pluginExpected -Module $plugin -ResolutionKind 'explicit import'
    $env:PSModulePath = @((Join-Path $PluginRoot 'dist'), (Join-Path $GerberRoot 'dist')) -join [IO.Path]::PathSeparator
    & $core {
        param($Path, $TracePath)
        $script:GerberCredentialStore = Get-GerberTerminalCredentialStore -Path $Path
        $script:GerberTerminalPromptTracePath = $TracePath
        function script:Resolve-GerberPromptTracePath {
            return $script:GerberTerminalPromptTracePath
        }
    } $SecretStoreStatePath $PromptTracePath
    Complete-GerberTerminalModuleValidation -Path $ModuleStatePath
    Invoke-Gerber
} catch {
    Write-GerberTerminalModuleValidationFailure -Path $ModuleStatePath -ErrorRecord $_
    throw
}
