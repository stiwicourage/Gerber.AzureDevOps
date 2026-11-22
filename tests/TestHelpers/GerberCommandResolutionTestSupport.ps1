function Initialize-GerberRoutingTestRegistry {
    [CmdletBinding(SupportsShouldProcess)]
    param([psmoduleinfo]$Core, [string]$PluginRoot)
    if (-not $PSCmdlet.ShouldProcess('Synthetic routing registry', 'Initialize isolated registrations')) { return }
    & $Core {
        param($PluginRoot)
        Clear-GerberCommandRegistry
        $null = Initialize-GerberCommandRegistry -PluginModulePathList @($PluginRoot)
    } $PluginRoot
}

function Get-GerberRoutingTestSnapshot {
    param([psmoduleinfo]$Core)
    return & $Core {
        [pscustomobject]@{
            Search = Resolve-GerberCommand -InputText ado
            Tags = Resolve-GerberCommand -InputText '/ado pipelines tags'
            Create = Resolve-GerberCommand -InputText '/ado repository create'
            Branch = Resolve-GerberCommand -InputText '/ado branch'
            Agents = Resolve-GerberCommand -InputText '/ado agents'
        }
    }
}
