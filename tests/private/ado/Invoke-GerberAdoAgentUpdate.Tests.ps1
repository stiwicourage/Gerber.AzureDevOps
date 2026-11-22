BeforeAll {
    . (Join-Path $PSScriptRoot '../../TestHelpers/GerberAgentUpdateTestSupport.ps1')
}

Describe 'Sequential agent refresh batch' {
    BeforeEach {
        $script:context = New-AgentUpdateTestContext
        $script:plan = [pscustomobject]@{ Pools = @((New-AgentUpdateTestPool), (New-AgentUpdateTestPool -Id 2)) }
        Mock Write-GerberProgressBar {}
        Mock Write-GerberScreenLine {}
        Mock Start-GerberAdoAgentPoolUpdate {
            [pscustomobject]@{ PoolId = $Pool.Id; State = 'RequestAccepted'; HttpStatus = 202; Message = 'Accepted' }
        }
    }

    It 'sends once per distinct confirmed pool and reports each acceptance before proceeding' {
        $plan.Pools += $plan.Pools[0]
        $script:receipts = @()
        $results = @(Invoke-GerberAdoAgentUpdate -Context $context -Plan $plan -OnResult { param($r) $script:receipts += $r.PoolId })
        $results.PoolId | Should -Be @(1, 2)
        $script:receipts | Should -Be @(1, 2)
        Should -Invoke Start-GerberAdoAgentPoolUpdate -Times 2 -Exactly
    }

    It 'uses append-only step feedback so advancing progress cannot overwrite an accepted receipt' {
        $script:feedback = @()
        Mock Write-GerberScreenLine { $script:feedback += $Text }
        $null = @(Invoke-GerberAdoAgentUpdate -Context $context -Plan $plan `
            -OnResult { param($result) $script:feedback += "accepted:$($result.PoolId)" })
        $script:feedback | Should -Be @('Agent refresh 1/2', 'accepted:1', 'Agent refresh 2/2', 'accepted:2')
        Should -Invoke Write-GerberProgressBar -Times 0
    }

    It 'continues after pool-local HTTP <Code> rejection' -ForEach @(@{ Code = 403 }, @{ Code = 404 }) {
        Mock Start-GerberAdoAgentPoolUpdate {
            [pscustomobject]@{ PoolId = $Pool.Id; State = 'RequestFailed'; HttpStatus = $Code; Message = 'Rejected' }
        } -ParameterFilter { $Pool.Id -eq 1 }
        @(Invoke-GerberAdoAgentUpdate -Context $context -Plan $plan).State | Should -Be @('RequestFailed', 'RequestAccepted')
        Should -Invoke Start-GerberAdoAgentPoolUpdate -Times 2 -Exactly
    }

    It 'stops after <State> HTTP <Code> and marks the remainder NotAttempted' -ForEach @(
        @{ State = 'RequestFailed'; Code = 401 }
        @{ State = 'OutcomeUnknown'; Code = 0 }
        @{ State = 'OutcomeUnknown'; Code = 503 }
        @{ State = 'CancelledBeforeSend'; Code = 0 }
    ) {
        Mock Start-GerberAdoAgentPoolUpdate { [pscustomobject]@{ PoolId = 1; State = $State; HttpStatus = $Code; Message = 'Stopped' } }
        $results = @(Invoke-GerberAdoAgentUpdate -Context $context -Plan $plan)
        $results.State | Should -Be @($State, 'NotAttempted')
        Should -Invoke Start-GerberAdoAgentPoolUpdate -Times 1 -Exactly
    }

    It 'preserves accepted receipts when the next request is interrupted' {
        $plan.Pools += New-AgentUpdateTestPool -Id 3
        Mock Start-GerberAdoAgentPoolUpdate { throw [System.OperationCanceledException]::new() } -ParameterFilter { $Pool.Id -eq 2 }
        $results = @(Invoke-GerberAdoAgentUpdate -Context $context -Plan $plan)
        $results.State | Should -Be @('RequestAccepted', 'OutcomeUnknown', 'NotAttempted')
        Should -Invoke Start-GerberAdoAgentPoolUpdate -Times 0 -ParameterFilter { $Pool.Id -eq 3 }
    }

    It 'stops cooperatively after an accepted request and preserves its receipt without another POST' {
        $plan.Pools += New-AgentUpdateTestPool -Id 3
        $script:receiptCount = 0
        $results = @(Invoke-GerberAdoAgentUpdate -Context $context -Plan $plan `
            -OnResult { $script:receiptCount++ } -CancellationRequested { $script:receiptCount -ge 1 })
        $results.State | Should -Be @('RequestAccepted', 'CancelledBeforeSend', 'NotAttempted')
        Should -Invoke Start-GerberAdoAgentPoolUpdate -Times 1 -Exactly
    }

    It 'sends nothing when cancellation is already pending at the batch boundary' {
        $results = @(Invoke-GerberAdoAgentUpdate -Context $context -Plan $plan -CancellationRequested { $true })
        $results.State | Should -Be @('CancelledBeforeSend', 'NotAttempted')
        Should -Invoke Start-GerberAdoAgentPoolUpdate -Times 0
    }

    It 'preserves an ordinary attempt call that omits the optional cancellation predicate' {
        $result = Get-GerberAdoAgentUpdateAttempt -Context $context -Pool $plan.Pools[0] -Stopped $false
        $result.State | Should -Be 'RequestAccepted'
        Should -Invoke Start-GerberAdoAgentPoolUpdate -Times 1 -Exactly
    }
}
