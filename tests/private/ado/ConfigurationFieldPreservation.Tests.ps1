# Configuration copying and profile resolution span two existing domain helpers;
# this regression asserts the same JSON field contract at both boundaries.
BeforeAll {
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'TestHelpers/GerberTestSupport.ps1')
    Import-GerberSource -StartPath $PSScriptRoot
}

Describe 'ADO JSON field preservation' -Tag 'AdoFieldPreservation' {
    It 'preserves case-distinct unknown fields in <CopyCommand>' -ForEach @(
        @{ CopyCommand = 'Copy-GerberUserConfigurationMap'; ParameterName = 'Configuration' }
        @{ CopyCommand = 'Copy-GerberAdoProfilePropertyMap'; ParameterName = 'ProfileValue' }
    ) {
        $value = '{"Future":[1],"future":[]}' | ConvertFrom-Json -AsHashtable
        $copyParameters = @{}
        $copyParameters[$ParameterName] = $value
        $copy = & $CopyCommand @copyParameters
        $copy.Count | Should -Be 2
        @($copy['Future']) | Should -Be @(1)
        @($copy['future']).Count | Should -Be 0
        $copy.Keys | Should -Be @('Future', 'future')
    }

    It 'resolves recognized field casing without rewriting profile metadata' {
        $value = '{"ADO":{"PROFILES":{"Example":{"PROJECTURL":"https://dev.azure.com/example/Sample","Future":1,"future":2}}}}' |
            ConvertFrom-Json -AsHashtable
        $connectionProfile = Get-GerberAdoConnectionProfile -Configuration $value -Name example
        $connectionProfile.Name | Should -Be 'Example'
        $connectionProfile.ProjectUrl | Should -Be 'https://dev.azure.com/example/Sample'
        $connectionProfile.PropertyMap.Keys | Should -Be @('PROJECTURL', 'Future', 'future')
        $connectionProfile.PropertyMap['Future'] | Should -Be 1
        $connectionProfile.PropertyMap['future'] | Should -Be 2
    }

    It 'updates a recognized property using its original casing and preserves unknown fields' {
        $script:caseDocument = '{"ADO":{"PROFILES":{"Example":{"PROJECTURL":"https://dev.azure.com/example/Sample","Future":1,"future":2}}}}' |
            ConvertFrom-Json -AsHashtable
        Mock Get-GerberUserConfiguration { $script:caseDocument }
        Mock Save-GerberUserConfiguration { $script:caseDocument = $Configuration }

        Set-GerberAdoConnectionProfile -Name example -ProjectUrl 'https://dev.azure.com/example/Other'

        $stored = $script:caseDocument['ADO']['PROFILES']['Example']
        $stored.Keys | Should -Be @('PROJECTURL', 'Future', 'future')
        $stored['PROJECTURL'] | Should -Be 'https://dev.azure.com/example/Other'
        $stored['Future'] | Should -Be 1
        $stored['future'] | Should -Be 2
    }
}
