BeforeAll {
    . (Join-Path $PSScriptRoot '../../TestHelpers/GerberAgentUpdateTestSupport.ps1')
    . (Join-Path $PSScriptRoot '../../TestHelpers/GerberAgentUpdateFlowTestSupport.ps1')
}

Describe 'Interactive agent update flow' {
    BeforeEach {
        $context = New-AgentUpdateTestContext
        $script:plan = [pscustomobject]@{ CollectionUri = 'https://ado.test/'; Pools = @((New-AgentUpdateTestPool)); Snapshot = 'original' }
        Mock Test-GerberConsoleInputRedirected { $false }
        Mock Get-GerberAdoConfiguration { $context.Configuration }
        Mock Resolve-GerberAdoPat { $context.Pat }
        Mock Get-GerberAdoAgentUpdatePoolList { New-AgentUpdateTestPool }
        Mock Read-GerberCheckboxMenuPrompt { [pscustomobject]@{ SelectedItemList = @([pscustomobject]@{ Value = 1 }) } }
        Mock Get-GerberAdoAgentUpdatePlan { $script:plan }
        Mock Read-GerberConfirmationPrompt { $true }
        Mock Invoke-GerberAdoAgentUpdate { @() }
        Initialize-AgentUpdateTestUi
        Mock Test-GerberMenuEscapeException { $Exception -is [System.OperationCanceledException] }
    }

    It 'rejects noninteractive use before credentials, prompts or mutation' {
        Mock Test-GerberConsoleInputRedirected { $true }
        { Invoke-GerberAgentUpdateFlow } | Should -Throw '*interactive*'
        Should -Invoke Get-GerberAdoConfiguration -Times 0
        Should -Invoke Read-GerberCheckboxMenuPrompt -Times 0
        Should -Invoke Invoke-GerberAdoAgentUpdate -Times 0
    }

    It 'requires explicit selection and Cancel-default confirmation before executing a stable plan' {
        Invoke-GerberAgentUpdateFlow
        Should -Invoke Read-GerberCheckboxMenuPrompt -Times 1 -ParameterFilter {
            $PromptRequest.ItemList[0].IsSelected -eq $false -and $PromptRequest.EmptySelectionMessage -match 'Select at least one'
        }
        Should -Invoke Read-GerberConfirmationPrompt -Times 1 -ParameterFilter {
            $PromptOptionSet.DefaultOption -eq 'cancel' -and $ScreenText -match 'major' -and $ScreenText -match 'asynchronous'
        }
        Should -Invoke Get-GerberAdoAgentUpdatePlan -Times 2 -Exactly
        Should -Invoke Invoke-GerberAdoAgentUpdate -Times 1 -Exactly
    }

    It 'makes no request after empty selection' {
        Mock Read-GerberCheckboxMenuPrompt { [pscustomobject]@{ SelectedItemList = @() } }
        Invoke-GerberAgentUpdateFlow
        Should -Invoke Read-GerberConfirmationPrompt -Times 0
        Should -Invoke Invoke-GerberAdoAgentUpdate -Times 0
    }

    It 'makes no request after Cancel' {
        Mock Read-GerberConfirmationPrompt { $false }
        Invoke-GerberAgentUpdateFlow
        Should -Invoke Invoke-GerberAdoAgentUpdate -Times 0
    }

    It 'returns safely from Esc during selection or confirmation' -ForEach @(
        @{ PromptCommand = 'Read-GerberCheckboxMenuPrompt' }
        @{ PromptCommand = 'Read-GerberConfirmationPrompt' }
    ) {
        Mock $PromptCommand { throw [System.OperationCanceledException]::new() }
        { Invoke-GerberAgentUpdateFlow } | Should -Not -Throw
        Should -Invoke Invoke-GerberAdoAgentUpdate -Times 0
    }

    It 'requires a fresh confirmation when the revalidated scope changes' {
        $script:readCount = 0
        Mock Get-GerberAdoAgentUpdatePlan {
            $script:readCount++
            [pscustomobject]@{ CollectionUri = 'https://ado.test/'; Pools = @((New-AgentUpdateTestPool)); Snapshot = $(if ($script:readCount -eq 1) { 'old' } else { 'new' }) }
        }
        Invoke-GerberAgentUpdateFlow
        Should -Invoke Read-GerberConfirmationPrompt -Times 2 -Exactly
        Should -Invoke Invoke-GerberAdoAgentUpdate -Times 1 -ParameterFilter { $Plan.Snapshot -eq 'new' }
    }

    It 'aborts safely when inventory fails or a pool disappears' {
        Mock Get-GerberAdoAgentUpdatePlan { throw [System.ArgumentException]::new('synthetic-only-pat') }
        Invoke-GerberAgentUpdateFlow
        Should -Invoke Invoke-GerberAdoAgentUpdate -Times 0
        Should -Invoke Show-GerberTextBlock -Times 1 -ParameterFilter { $Text -notmatch 'synthetic-only-pat' }
    }

    It 'does not prompt for an empty inventory' {
        Mock Get-GerberAdoAgentUpdatePoolList { @() }
        Invoke-GerberAgentUpdateFlow
        Should -Invoke Read-GerberCheckboxMenuPrompt -Times 0
        Should -Invoke Invoke-GerberAdoAgentUpdate -Times 0
    }
}

Describe 'Agent update continue prompt' {
    BeforeEach {
        Mock Test-GerberMenuEscapeException { $Exception -is [System.OperationCanceledException] }
    }

    It 'treats Esc at the continue prompt as a normal return' {
        Mock Wait-GerberContinue { throw [System.OperationCanceledException]::new() }
        { Wait-GerberAgentUpdateContinue } | Should -Not -Throw
    }

    It 'propagates unexpected continue prompt failures' {
        Mock Wait-GerberContinue { throw [System.IO.IOException]::new('Synthetic continue failure') }
        { Wait-GerberAgentUpdateContinue } | Should -Throw '*Synthetic continue failure*'
    }
}
