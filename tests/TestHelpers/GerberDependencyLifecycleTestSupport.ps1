function Set-GerberLifecycleTestConfiguration {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Path, [hashtable]$Plugins)
    if (-not $PSCmdlet.ShouldProcess($Path, 'Write isolated lifecycle configuration')) { return }
    $env:GERBER_CONFIG_PATH = $Path
    $null = New-Item -ItemType Directory -Path (Split-Path $env:GERBER_CONFIG_PATH) -Force
    @{ schemaVersion = 1; plugins = $Plugins } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $env:GERBER_CONFIG_PATH
}

function Initialize-GerberLifecycleTestOperationMock {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    if (-not $PSCmdlet.ShouldProcess('Synthetic lifecycle', 'Initialize passive-operation spies')) { return }
    Mock Invoke-RestMethod { throw 'Registration must not call REST.' } -ModuleName 'Gerber.AzureDevOps'
    Mock Get-GerberCredential { throw 'Registration must not read credentials.' } -ModuleName Gerber
    # Keep spies on the imported dependency; normal forced import is covered by routing integration.
    Mock Import-Module { Get-Module 'Gerber.AzureDevOps' } -ModuleName Gerber -ParameterFilter {
        [string]$Name -like '*Gerber.AzureDevOps*'
    }
}

function Get-GerberLifecycleRegistrationTestSnapshot {
    param([psmoduleinfo]$Core, [string]$PluginDist)
    return & $Core {
        param($PluginDist)
        Clear-GerberCommandRegistry
        $null = Initialize-GerberCommandRegistry -PluginModulePathList @($PluginDist)
        $first = @(Get-GerberCommandRegistry | Where-Object OwnerName -EQ 'Gerber.AzureDevOps')
        $null = Initialize-GerberCommandRegistry -PluginModulePathList @($PluginDist)
        [pscustomobject]@{
            First = $first
            Second = @(Get-GerberCommandRegistry | Where-Object OwnerName -EQ 'Gerber.AzureDevOps')
            Inventory = @(Get-GerberPluginInventory -PluginModulePathList @($PluginDist))
        }

    } $PluginDist
}
