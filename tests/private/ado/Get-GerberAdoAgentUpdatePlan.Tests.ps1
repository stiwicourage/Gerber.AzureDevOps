BeforeAll {
    . (Join-Path $PSScriptRoot '../../TestHelpers/GerberAgentUpdateTestSupport.ps1')
}

Describe 'Agent update plan snapshots' {
    BeforeEach {
        $script:context = New-AgentUpdateTestContext
        Mock Get-GerberAdoAgentUpdatePoolList { @((New-AgentUpdateTestPool), (New-AgentUpdateTestPool -Id 2 -PoolType deployment)) }
    }

    It 'contains only selected pools, distinct IDs, collection and no credentials' {
        $plan = Get-GerberAdoAgentUpdatePlan -Context $context -PoolId @(2, 2)
        $plan.Pools.Count | Should -Be 1
        $plan.Pools[0].Id | Should -Be 2
        $plan.CollectionUri | Should -Be $context.Configuration.CollectionUri.AbsoluteUri
        ($plan | ConvertTo-Json -Depth 10) | Should -Not -Match 'synthetic-only-pat|CredentialIdentifier'
    }

    It 'changes the snapshot when membership, eligibility or identity changes' {
        $before = Get-GerberAdoAgentUpdatePlan -Context $context -PoolId 1
        Mock Get-GerberAdoAgentUpdatePoolList { $p = New-AgentUpdateTestPool; $p.AgentList[0].Id = 8; $p }
        $after = Get-GerberAdoAgentUpdatePlan -Context $context -PoolId 1
        $after.Snapshot | Should -Not -Be $before.Snapshot
        Mock Get-GerberAdoAgentUpdatePoolList { @() }
        { Get-GerberAdoAgentUpdatePlan -Context $context -PoolId 1 } | Should -Throw '*no longer eligible*'
    }

    It 'rejects empty scope before reading inventory' {
        { Get-GerberAdoAgentUpdatePlan -Context $context -PoolId @() } | Should -Throw
        Should -Invoke Get-GerberAdoAgentUpdatePoolList -Times 0
    }
}
