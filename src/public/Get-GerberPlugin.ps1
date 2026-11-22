function Get-GerberPlugin {
    <#
    .SYNOPSIS
    Registers Gerber.AzureDevOps commands through Gerber Plugin API v1.
    .DESCRIPTION
    Returns the stable plugin identity and ten module-bound command definitions.
    Import and registration do not read configuration, credentials or Azure DevOps.
    Gerber Core supplies and binds the public UI, Configuration, Secrets and Http
    capabilities. Native Azure DevOps operations run only when a handler is invoked.
    /ado agents list replaces /ado list agents without an alias.
    /ado agents update interactively requests pool-wide asynchronous refresh;
    Azure DevOps chooses the version, which may change major. Cancel is the default.
    Pool selection uses one checkbox row per pool, without status/version sublines.
    Confirmation lists only pools/counts and shared warnings, not individual agents.
    Refresh uses a preview messages API and JSON null, matching the SDK contract.
    Rejected requests retain a sanitized, truncated JSON server message when present.
    Compact receipts share repeated explanations.
    During an applied batch, Ctrl-C stops further requests after the current request
    settles or times out, preserves accepted receipts and returns to Gerber.
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
