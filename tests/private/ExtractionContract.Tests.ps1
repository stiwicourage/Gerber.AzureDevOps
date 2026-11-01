BeforeAll {
    . (Join-Path $PSScriptRoot '../PluginTestSupport.ps1')
}

Describe 'Azure DevOps extraction command ownership' {
    It 'registers the existing command paths without hello scaffolding or reading configuration' {
        $api = Get-PluginTestContext
        $api | Add-Member -NotePropertyName Configuration -NotePropertyValue @{
            Read = { throw 'Registration must not read configuration.' }
            Save = { throw 'Registration must not save configuration.' }
        }
        $definitions = @(Get-PluginCommandDefinitionList -Gerber $api)
        $definitions.Name | Should -Be @(
            'list ado-agents'
            'list ado-team-members'
            'repository create'
            'branch find'
            'branch set-searchable'
            'branch set-default'
            'pipelines tags'
            'pipelines tags delete'
            'pipelines tags update'
        )
        $definitions.Name | Should -Not -Contain 'ado hello'
    }
}
