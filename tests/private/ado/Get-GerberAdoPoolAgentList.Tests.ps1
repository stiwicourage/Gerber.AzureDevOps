BeforeAll {
    . (Join-Path $PSScriptRoot '../../TestHelpers/GerberAgentUpdateTestSupport.ps1')
}

Describe 'Shared pool member reader ownership' {
    It 'retains the report query and preserves unknown optional member data' {
        $context = New-AgentUpdateTestContext
        Mock Invoke-GerberAdoRestRequest { @{ value = @(@{ name = 'agent'; version = '4.250.1' }) } }
        $members = @(Get-GerberAdoPoolAgentList -Configuration $context.Configuration -Pat $context.Pat -Pool (New-AgentUpdateTestPool))
        $members[0].Version | Should -Be '4.250.1'
        $members[0].WorkState | Should -Be 'unknown'
        Should -Invoke Invoke-GerberAdoRestRequest -Times 1 -ParameterFilter {
            $Uri.Query -match 'includeCapabilities=false' -and $Uri.Query -notmatch 'includeAssignedRequest'
        }
    }
}
