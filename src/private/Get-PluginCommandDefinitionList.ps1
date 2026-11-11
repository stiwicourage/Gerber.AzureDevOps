function Get-PluginCommandDefinitionList {
    param([pscustomobject]$Gerber)

    return @(
        New-AdoCommandDefinition -Gerber $Gerber -Name 'ado list agents' -Description 'List Azure DevOps BUILD and DEPLOY agents' -HandlerName 'Invoke-GerberListAdoAgentsCommand'
        New-AdoCommandDefinition -Gerber $Gerber -Name 'ado list team-members' -Description 'List Azure DevOps teams and members' -HandlerName 'Invoke-GerberListAdoTeamMembersCommand'
        New-AdoCommandDefinition -Gerber $Gerber -Name 'ado repository create' -Description 'Create a new repository from template' -HandlerName 'Show-GerberRepositoryCreateView'
        New-AdoCommandDefinition -Gerber $Gerber -Name 'ado branch find' -Description 'Search all repositories for a branch path' -HandlerName 'Invoke-GerberBranchFindFlow'
        New-AdoCommandDefinition -Gerber $Gerber -Name 'ado branch set-searchable' -Description 'Standardize searchable-branches policies across all repositories' -HandlerName 'Invoke-GerberBranchSetSearchableFlow'
        New-AdoCommandDefinition -Gerber $Gerber -Name 'ado branch set-default' -Description 'Standardize the default branch across all repositories' -HandlerName 'Invoke-GerberBranchSetDefaultFlow'
        New-AdoCommandDefinition -Gerber $Gerber -Name 'ado pipelines tags' -Description 'Open the pipeline tag submenu' -HandlerName 'Show-GerberPipelinesTagsView'
        New-AdoCommandDefinition -Gerber $Gerber -Name 'ado pipelines tags delete' -Description 'Delete one build tag across selected tagged pipeline runs' -HandlerName 'Invoke-GerberPipelineTagDelete'
        New-AdoCommandDefinition -Gerber $Gerber -Name 'ado pipelines tags update' -Description 'Replace one build tag with another across selected tagged pipeline runs' -HandlerName 'Invoke-GerberPipelineTagUpdate'
    )
}

function New-AdoCommandDefinition {
    [CmdletBinding(SupportsShouldProcess)]
    param([pscustomobject]$Gerber, [string]$Name, [string]$Description, [string]$HandlerName)
    if (-not $PSCmdlet.ShouldProcess($Name, 'Create command definition')) { return }
    return [pscustomobject]@{
        Name = $Name
        Description = $Description
        Handler = New-AdoModuleHandler -Gerber $Gerber -HandlerName $HandlerName
        Subcommands = [ordered]@{}
    }
}
