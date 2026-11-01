function Get-GerberPipelinesTagsCommandCatalog {
    return [ordered]@{
        delete = [pscustomobject]@{ Description = 'Delete one build tag across selected tagged pipeline runs'; Subcommands = [ordered]@{} }
        update = [pscustomobject]@{ Description = 'Replace one build tag with another across selected tagged pipeline runs'; Subcommands = [ordered]@{} }
    }
}
