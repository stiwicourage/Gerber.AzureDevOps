BeforeAll {
    . (Join-Path $PSScriptRoot '../PluginTestSupport.ps1')
    $script:expectedPaths = @(
        'ado agents list'
        'ado agents update'
        'ado list team-members'
        'ado repository create'
        'ado branch find'
        'ado branch set-searchable'
        'ado branch set-default'
        'ado pipelines tags'
        'ado pipelines tags delete'
        'ado pipelines tags update'
    )
}

Describe 'Azure DevOps extraction command ownership' {
    It 'registers the existing command paths without hello scaffolding or reading configuration' {
        $api = Get-PluginTestContext
        $api | Add-Member -NotePropertyName Configuration -NotePropertyValue @{
            Read = { throw 'Registration must not read configuration.' }
            Save = { throw 'Registration must not save configuration.' }
        }
        $definitions = @(Get-PluginCommandDefinitionList -Gerber $api)
        $definitions.Name | Should -Be $script:expectedPaths
        $definitions.Name | Should -Not -Contain 'ado hello'
        $definitions.Name | Should -Not -Contain 'ado list agents'
    }
}
