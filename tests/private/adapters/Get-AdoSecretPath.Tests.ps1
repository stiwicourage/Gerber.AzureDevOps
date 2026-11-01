BeforeAll {
    . (Join-Path $PSScriptRoot '../../../src/private/adapters/Get-AdoSecretPath.ps1')
}

Describe 'Get-AdoSecretPath' {
    It 'preserves profile escaping and maps only the domain logical path' {
        Get-AdoSecretPath 'gerber:ado:team%3Aone:pat' | Should -Be @('ado', 'team:one', 'pat')
    }

    It 'rejects malformed identifiers: <Identifier>' -ForEach @(
        @{ Identifier = 'gerber:core:team:pat' }
        @{ Identifier = 'gerber:ado:team:token' }
        @{ Identifier = 'gerber:ado:team:pat:extra' }
        @{ Identifier = "gerber:ado:team:pat`n" }
    ) {
        { Get-AdoSecretPath $Identifier } | Should -Throw 'Expected an Azure DevOps profile PAT logical identifier.'
    }
}
