BeforeAll {
    . (Join-Path $PSScriptRoot '../../PluginTestSupport.ps1')
}

Describe 'Safe update agent metadata' {
    It 'distinguishes known idle, busy and absent work without exposing raw assigned data' -ForEach @(
        @{ Work = @{ assignedRequest = $null }; Expected = 'idle' }
        @{ Work = @{ assignedRequest = @{ authorization = 'do-not-render' } }; Expected = 'busy' }
        @{ Work = @{}; Expected = 'unknown' }
    ) {
        $agent = ConvertTo-GerberAdoUpdateAgent -Agent $Work
        $agent.WorkState | Should -Be $Expected
        ($agent | ConvertTo-Json -Depth 5) | Should -Not -Match 'do-not-render|authorization'
    }

    It 'reads pending currentState and preserves missing values as unknown for objects and dictionaries' {
        Set-StrictMode -Version Latest
        $agent = ConvertTo-GerberAdoUpdateAgent -Agent ([pscustomobject]@{
            id = 4; name = 'agent'; enabled = $true; pendingUpdate = [pscustomobject]@{ currentState = 'downloading' }
        })
        $agent.Id | Should -Be 4
        $agent.Enabled | Should -BeTrue
        $agent.PendingUpdate | Should -Be 'downloading'
        (Get-GerberAdoOptionalProperty -InputObject $null -Name 'missing') | Should -BeNullOrEmpty
        (Get-GerberAdoOptionalProperty -InputObject @{} -Name 'missing') | Should -BeNullOrEmpty
    }
}
