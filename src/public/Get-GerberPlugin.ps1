function Get-GerberPlugin {
    <#
    .SYNOPSIS
    Registers Gerber.AzureDevOps commands through Gerber Plugin API v1.
    .DESCRIPTION
    Returns the stable plugin identity and nine module-bound command definitions.
    Import and registration do not read configuration, credentials or Azure DevOps.
    Gerber Core supplies and binds the public UI, Configuration, Secrets and Http
    capabilities. Native Azure DevOps operations run only when a handler is invoked.
    .PARAMETER Gerber
    The Plugin API context supplied by Gerber Core.
    .EXAMPLE
    Get-GerberPlugin -Gerber $pluginContext
    Returns command definitions. Gerber supplies the context during discovery.
    .OUTPUTS
    System.Management.Automation.PSCustomObject
    Metadata containing Name, Guid and Commands; this is not an operation result.
    .NOTES
    Requires PowerShell 7.4 and Gerber Core 0.2.1-preview02 or later.
    See docs/commands.md for the retained command paths and configuration behavior.
    #>
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param([Parameter(Mandatory)][pscustomobject]$Gerber)

    return [pscustomobject]@{
        Name = 'Gerber.AzureDevOps'
        Namespace = 'ado'
        Guid = 'a468dee5-c7a0-43e4-ae88-bb19158fe679'
        Commands = @(Get-PluginCommandDefinitionList -Gerber $Gerber)
    }
}
