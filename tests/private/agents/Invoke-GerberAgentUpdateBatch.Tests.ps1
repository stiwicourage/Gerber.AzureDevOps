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

    It 'routes batch receipts and cancellation polling to the interactive console helpers' {
        Mock Test-GerberAgentUpdateCancellation { $true }
        Mock Invoke-GerberAdoAgentUpdate {
            $null = & $OnResult 'synthetic-receipt'
            & $CancellationRequested
        }
        $result = Invoke-GerberAgentUpdateBatch -Context (New-AgentUpdateTestContext) -Plan ([pscustomobject]@{})
        $result | Should -BeTrue
        Should -Invoke Write-GerberAgentUpdateReceipt -Times 1 -Exactly -ParameterFilter { $Result -eq 'synthetic-receipt' }
        Should -Invoke Test-GerberAgentUpdateCancellation -Times 1 -Exactly
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

Describe 'Batch cancellation key reading' {
    It 'returns no key without reading when none is waiting' {
        Mock Test-GerberAgentUpdateKeyAvailable { $false }
        Mock Read-GerberAgentUpdateKey { throw 'must not read' }
        Read-GerberAgentUpdateCancellationKey | Should -BeNullOrEmpty
    }

    It 'returns the waiting key character without echoing it' {
        Mock Test-GerberAgentUpdateKeyAvailable { $true }
        Mock Read-GerberAgentUpdateKey { [System.ConsoleKeyInfo]::new([char]3, [System.ConsoleKey]::C, $false, $false, $true) }
        Read-GerberAgentUpdateCancellationKey | Should -Be ([char]3)
    }
}

Describe 'Batch console adapters' {
    It 'reads and restores the current Ctrl-C input mode' -Skip:($IsWindows -and [Console]::IsInputRedirected) {
        $original = Get-GerberAgentUpdateConsoleMode
        $original | Should -Be ([Console]::TreatControlCAsInput)
        Set-GerberAgentUpdateConsoleMode -Enabled $original -Confirm:$false
        [Console]::TreatControlCAsInput | Should -Be $original
    }

    It 'leaves the Ctrl-C input mode unchanged under WhatIf' -Skip:($IsWindows -and [Console]::IsInputRedirected) {
        $original = [Console]::TreatControlCAsInput
        Set-GerberAgentUpdateConsoleMode -Enabled (-not $original) -WhatIf
        [Console]::TreatControlCAsInput | Should -Be $original
    }

    It 'reports key availability from an interactive console' -Skip:([Console]::IsInputRedirected) {
        Test-GerberAgentUpdateKeyAvailable | Should -BeOfType [bool]
    }

    It 'surfaces the console error for <Command> when input is redirected' -Skip:(-not [Console]::IsInputRedirected) -ForEach @(
        @{ Command = 'Test-GerberAgentUpdateKeyAvailable' }
        @{ Command = 'Read-GerberAgentUpdateKey' }
    ) {
        $thrown = { & $Command } | Should -Throw -PassThru
        $thrown.Exception.GetBaseException() | Should -BeOfType [System.InvalidOperationException]
    }
}
