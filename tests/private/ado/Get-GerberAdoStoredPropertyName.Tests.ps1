BeforeAll {
    . (Join-Path $PSScriptRoot '../../../src/private/ado/Get-GerberAdoStoredPropertyName.ps1')
}

Describe 'Get-GerberAdoStoredPropertyName' {
    It 'prefers exact names and otherwise preserves stored casing for schema fields' {
        $value = '{"Future":1,"future":2,"PROJECTURL":"fixture"}' | ConvertFrom-Json -AsHashtable
        Get-GerberAdoStoredPropertyName -Map $value -PropertyName future | Should -BeExactly 'future'
        Get-GerberAdoStoredPropertyName -Map $value -PropertyName projectUrl | Should -BeExactly 'PROJECTURL'
        Get-GerberAdoStoredPropertyName -Map $value -PropertyName newField | Should -BeExactly 'newField'
        $value.Count | Should -Be 3
    }
}
