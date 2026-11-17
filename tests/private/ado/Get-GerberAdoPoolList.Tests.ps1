BeforeAll {
    . (Join-Path $PSScriptRoot '../../TestHelpers/GerberAgentUpdateTestSupport.ps1')
}

Describe 'Shared pool reader ownership' {
    It 'preserves pool identity, requested type and nullable hosting metadata through the GET boundary' {
        $context = New-AgentUpdateTestContext
        Mock Invoke-GerberAdoRestRequest { @{ value = @(@{ id = 11; name = 'Build Pool' }) } }
        $pools = @(Get-GerberAdoPoolList -Configuration $context.Configuration -Pat $context.Pat -PoolType automation)
        $pools[0].Id | Should -Be 11
        $pools[0].PoolType | Should -Be 'automation'
        $pools[0].IsHosted | Should -BeNullOrEmpty
        Should -Invoke Invoke-GerberAdoRestRequest -Times 1 -ParameterFilter { $Uri.Query -match 'poolType=automation' }
    }
}
