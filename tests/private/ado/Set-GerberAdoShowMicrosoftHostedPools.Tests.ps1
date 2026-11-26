BeforeAll {
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'TestHelpers/GerberTestSupport.ps1')
    Import-GerberSource -StartPath $PSScriptRoot
}

Describe 'Set-GerberAdoShowMicrosoftHostedPools' {
    BeforeEach {
        $script:savedConfiguration = $null
        Mock Resolve-GerberUserConfigPath { '/tmp/gerber/config.json' }
        Mock Save-GerberUserConfiguration { $script:savedConfiguration = $Configuration }
    }

    It 'creates the settings section and preserves unrelated configuration' {
        Mock Get-GerberUserConfiguration { @{ schemaVersion = 1; ado = @{ defaultProfile = 'example'; profiles = @{} } } }

        Set-GerberAdoShowMicrosoftHostedPools -Value $false

        $script:savedConfiguration.schemaVersion | Should -Be 1
        $script:savedConfiguration.ado.defaultProfile | Should -Be 'example'
        $script:savedConfiguration.ado.settings.showMicrosoftHostedPools | Should -BeFalse
    }

    It 'creates the ado section for an empty configuration' {
        Mock Get-GerberUserConfiguration { [ordered]@{} }

        Set-GerberAdoShowMicrosoftHostedPools -Value $true

        $script:savedConfiguration.ado.settings.showMicrosoftHostedPools | Should -BeTrue
    }

    It 'updates the stored setting and keeps unknown settings' {
        Mock Get-GerberUserConfiguration { @{ ado = @{ settings = @{ showMicrosoftHostedPools = $true; other = 'keep' } } } }

        Set-GerberAdoShowMicrosoftHostedPools -Value $false

        $script:savedConfiguration.ado.settings.showMicrosoftHostedPools | Should -BeFalse
        $script:savedConfiguration.ado.settings.other | Should -Be 'keep'
    }
}
