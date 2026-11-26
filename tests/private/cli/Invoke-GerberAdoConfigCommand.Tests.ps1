BeforeAll {
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'TestHelpers/GerberTestSupport.ps1')
    Import-GerberSource -StartPath $PSScriptRoot
}

Describe 'Invoke-GerberAdoConfigCommand' {
    BeforeEach {
        $script:current = $true
        $script:prompts = [System.Collections.Generic.List[object]]::new()
        $script:answers = [System.Collections.Generic.Queue[string]]::new()
        Mock Start-GerberScreen {}
        Mock Write-GerberScreenLine {}
        Mock Get-GerberAdoShowMicrosoftHostedPools { $script:current }
        Mock Set-GerberAdoShowMicrosoftHostedPools { $script:current = $Value }
        Mock Read-GerberNumberedMenuPrompt {
            $script:prompts.Add($MenuItemList)
            $answer = $script:answers.Dequeue()
            if ($answer -eq 'ESC') { throw [System.OperationCanceledException]::new('esc') }
            return $answer
        }
        Mock Test-GerberMenuEscapeException { $Exception -is [System.OperationCanceledException] }
    }

    It 'shows the current value and leaves without saving on Esc' {
        $script:answers.Enqueue('ESC')

        Invoke-GerberAdoConfigCommand

        $script:prompts[0].Label | Should -Match 'Microsoft-hosted pools: shown'
        Should -Invoke Set-GerberAdoShowMicrosoftHostedPools -Times 0
    }

    It 'toggles the setting off and reflects the new value on the next prompt' {
        $script:answers.Enqueue('showMicrosoftHostedPools')
        $script:answers.Enqueue('ESC')

        Invoke-GerberAdoConfigCommand

        Should -Invoke Set-GerberAdoShowMicrosoftHostedPools -Times 1 -ParameterFilter { $Value -eq $false }
        $script:prompts[1].Label | Should -Match 'Microsoft-hosted pools: hidden'
    }

    It 'toggles a hidden setting back on' {
        $script:current = $false
        $script:answers.Enqueue('showMicrosoftHostedPools')
        $script:answers.Enqueue('ESC')

        Invoke-GerberAdoConfigCommand

        Should -Invoke Set-GerberAdoShowMicrosoftHostedPools -Times 1 -ParameterFilter { $Value -eq $true }
    }

    It 'shows an error and returns to Gerber when the configuration cannot be saved' {
        Mock Set-GerberAdoShowMicrosoftHostedPools { throw [System.IO.InvalidDataException]::new('bad config') }
        Mock Show-GerberTextBlock {}
        Mock Wait-GerberContinue {}
        $script:answers.Enqueue('showMicrosoftHostedPools')

        { Invoke-GerberAdoConfigCommand } | Should -Not -Throw

        Should -Invoke Show-GerberTextBlock -Times 1 -ParameterFilter { $Text -match 'bad config' }
    }
}
