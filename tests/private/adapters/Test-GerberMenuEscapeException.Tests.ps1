BeforeAll {
    . (Join-Path $PSScriptRoot '../../TestHelpers/GerberTestSupport.ps1')
    Import-GerberSource -StartPath $PSScriptRoot
}

Describe 'Test-GerberMenuEscapeException' {
    BeforeEach {
        $script:Gerber = [pscustomobject]@{ UI = @{ IsEscapeException = { param($Exception) $Exception.Data.Contains('GerberMenuEscape') } } }
    }

    It 'recognizes the Core menu escape exception' {
        $exception = [System.InvalidOperationException]::new('back')
        $exception.Data['GerberMenuEscape'] = $true
        Test-GerberMenuEscapeException -Exception $exception | Should -BeTrue
    }

    It 'treats a root navigation request as an escape so flows return instead of reporting an error' {
        $exception = [System.InvalidOperationException]::new('Return to the Gerber root menu.')
        $exception.Data['GerberRootNavigation'] = $true
        Test-GerberMenuEscapeException -Exception $exception | Should -BeTrue
    }

    It 'treats a wrapped root navigation request as an escape' {
        $inner = [System.InvalidOperationException]::new('Return to the Gerber root menu.')
        $inner.Data['GerberRootNavigation'] = $true
        Test-GerberMenuEscapeException -Exception ([System.Exception]::new('wrapped', $inner)) | Should -BeTrue
    }

    It 'does not treat an ordinary failure as an escape' {
        Test-GerberMenuEscapeException -Exception ([System.InvalidOperationException]::new('boom')) | Should -BeFalse
    }
}
