BeforeAll {
    . (Join-Path $PSScriptRoot '../../TestHelpers/GerberAgentUpdateTestSupport.ps1')
}

Describe 'Scoped interactive batch cancellation' {
    BeforeEach {
        $script:modes = @()
        Mock Get-GerberAgentUpdateConsoleMode { $false }
        Mock Set-GerberAgentUpdateConsoleMode { $script:modes += $Enabled }
        Mock Write-GerberAgentUpdateReceipt {}
        Mock Write-GerberScreenLine {}
        Mock Invoke-GerberAdoAgentUpdate { 'synthetic-result' }
        Mock Read-GerberAgentUpdateCancellationKey { $null }
    }

    It 'captures Ctrl-C only around the batch and restores the original console mode' {
        $result = Invoke-GerberAgentUpdateBatch -Context (New-AgentUpdateTestContext) -Plan ([pscustomobject]@{})
        $result | Should -Be 'synthetic-result'
        $script:modes | Should -Be @($true, $false)
        Should -Invoke Invoke-GerberAdoAgentUpdate -Times 1 -ParameterFilter { $CancellationRequested -is [scriptblock] }
    }

    It 'preserves a previously enabled console mode' {
        Mock Get-GerberAgentUpdateConsoleMode { $true }
        $null = Invoke-GerberAgentUpdateBatch -Context (New-AgentUpdateTestContext) -Plan ([pscustomobject]@{})
        $script:modes | Should -Be @($true, $true)
    }

    It 'restores console mode even when the batch throws' {
        Mock Invoke-GerberAdoAgentUpdate { throw [System.InvalidOperationException]::new('Synthetic batch failure') }
        { Invoke-GerberAgentUpdateBatch -Context (New-AgentUpdateTestContext) -Plan ([pscustomobject]@{}) } | Should -Throw '*Synthetic batch failure*'
        $script:modes | Should -Be @($true, $false)
    }

    It 'consumes pending cancellation even when no further pool remains to poll it' {
        $script:keyReads = 0
        Mock Read-GerberAgentUpdateCancellationKey {
            if (++$script:keyReads -eq 1) { return [char]3 }
            return $null
        }
        $null = Invoke-GerberAgentUpdateBatch -Context (New-AgentUpdateTestContext) -Plan ([pscustomobject]@{})
        Should -Invoke Read-GerberAgentUpdateCancellationKey -Times 2 -Exactly
        $script:modes | Should -Be @($true, $false)
    }

    It 'restores console mode even if final key consumption fails' {
        Mock Read-GerberAgentUpdateCancellationKey { throw [System.IO.IOException]::new('Synthetic console failure') }
        { Invoke-GerberAgentUpdateBatch -Context (New-AgentUpdateTestContext) -Plan ([pscustomobject]@{}) } | Should -Throw '*Synthetic console failure*'
        $script:modes | Should -Be @($true, $false)
    }
}

Describe 'Batch key cancellation policy' {
    It 'treats a consumed <Code> key as cancellation without a pipeline-stop exception' -ForEach @(@{ Code = 3 }, @{ Code = 27 }) {
        Mock Read-GerberAgentUpdateCancellationKey { [char]$Code }
        Test-GerberAgentUpdateCancellation | Should -BeTrue
        Should -Invoke Read-GerberAgentUpdateCancellationKey -Times 1 -Exactly
    }

    It 'does not cancel when no key is available' {
        Mock Read-GerberAgentUpdateCancellationKey { $null }
        Test-GerberAgentUpdateCancellation | Should -BeFalse
    }

    It 'discards unrelated keys without cancelling the batch' {
        $script:keyReads = 0
        Mock Read-GerberAgentUpdateCancellationKey {
            if (++$script:keyReads -eq 1) { return [char]'x' }
            return $null
        }
        Test-GerberAgentUpdateCancellation | Should -BeFalse
        Should -Invoke Read-GerberAgentUpdateCancellationKey -Times 2 -Exactly
    }
}
