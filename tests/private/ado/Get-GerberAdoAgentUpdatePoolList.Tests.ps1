BeforeAll {
    . (Join-Path $PSScriptRoot '../../TestHelpers/GerberAgentUpdateTestSupport.ps1')
}

Describe 'Agent update inventory' {
    BeforeEach {
        $script:context = New-AgentUpdateTestContext
        Mock Get-GerberAdoPoolList { New-AgentUpdateTestPool -Id $(if ($PoolType -eq 'automation') { 1 } else { 2 }) -PoolType $PoolType }
        Mock Get-GerberAdoPoolAgentList { (New-AgentUpdateTestPool).AgentList }
    }

    It 'keeps distinct same-name registrations across both pool types in deterministic order' {
        $pools = @(Get-GerberAdoAgentUpdatePoolList -Context $context)
        $pools.Id | Should -Be @(1, 2)
        $pools.PoolType | Should -Be @('automation', 'deployment')
        $pools[0].AgentList[0].Enabled | Should -BeFalse
        Should -Invoke Get-GerberAdoPoolList -Times 1 -Exactly -ParameterFilter { $PoolType -eq 'deployment' }
    }

    It 'excludes hosted, unknown hosting, and empty pools without inferring self-hosted' {
        Mock Get-GerberAdoPoolList {
            $hosted = New-AgentUpdateTestPool -Id 3
            $hosted.IsHosted = $true
            $unknown = New-AgentUpdateTestPool -Id 4
            $unknown.IsHosted = $null
            @($hosted, $unknown, (New-AgentUpdateTestPool -Id 5))
        }
        Mock Get-GerberAdoPoolAgentList { @() }
        @(Get-GerberAdoAgentUpdatePoolList -Context $context).Count | Should -Be 0
        Should -Invoke Get-GerberAdoPoolAgentList -Times 0 -ParameterFilter { $Pool.Id -in @(3, 4) }
    }

    It 'deduplicates pool IDs but never agent names' {
        Mock Get-GerberAdoPoolList { New-AgentUpdateTestPool }
        Mock Get-GerberAdoPoolAgentList { @((New-AgentUpdateTestPool).AgentList[0], (New-AgentUpdateTestPool).AgentList[0]) }
        $pools = @(Get-GerberAdoAgentUpdatePoolList -Context $context)
        $pools.Count | Should -Be 1
        $pools[0].AgentList.Count | Should -Be 2
    }

    It 'rejects invalid IDs, unknown pool types and nonboolean hosting metadata' {
        $pool = New-AgentUpdateTestPool
        $pool.Id = 0
        Test-GerberAdoUpdatePoolEligibility $pool | Should -BeFalse
        $pool.Id = 1
        $pool.PoolType = 'unknown'
        Test-GerberAdoUpdatePoolEligibility $pool | Should -BeFalse
        $pool.PoolType = 'automation'
        $pool.IsHosted = 'false'
        Test-GerberAdoUpdatePoolEligibility $pool | Should -BeFalse
    }
}
