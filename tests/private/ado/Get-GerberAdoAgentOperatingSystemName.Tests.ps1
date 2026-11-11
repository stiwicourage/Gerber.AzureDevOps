BeforeAll {
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'TestHelpers/GerberTestSupport.ps1')
    Import-GerberSource -StartPath $PSScriptRoot
}

Describe 'Get-GerberAdoAgentOperatingSystemName' {
    It 'maps <Description> to <Expected>' -TestCases @(
        @{ Description = 'a Linux kernel string'; Text = 'Linux 5.15.0-1057-azure #65-Ubuntu SMP'; Expected = 'Linux' }
        @{ Description = 'a Windows version string'; Text = 'Microsoft Windows 10.0.20348'; Expected = 'Windows' }
        @{ Description = 'a Darwin kernel string'; Text = 'Darwin 23.4.0 Darwin Kernel Version 23.4.0'; Expected = 'macOS' }
        @{ Description = 'a macOS name'; Text = 'macOS 14.4'; Expected = 'macOS' }
        @{ Description = 'an unrecognized description'; Text = '  FreeBSD 14.0  '; Expected = 'FreeBSD 14.0' }
        @{ Description = 'an empty description'; Text = ''; Expected = 'unknown' }
        @{ Description = 'a missing description'; Text = $null; Expected = 'unknown' }
    ) {
        param($Text, $Expected)

        Get-GerberAdoAgentOperatingSystemName -Description $Text | Should -Be $Expected
    }
}
