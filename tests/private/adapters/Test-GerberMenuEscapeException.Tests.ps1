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

    It 'rethrows a root navigation request so Core returns to the root menu instead of the flow handling it' {
        $exception = [System.InvalidOperationException]::new('Return to the Gerber root menu.')
        $exception.Data['GerberRootNavigation'] = $true
        { Test-GerberMenuEscapeException -Exception $exception } | Should -Throw 'Return to the Gerber root menu.'
    }

    It 'rethrows a wrapped root navigation request' {
        $inner = [System.InvalidOperationException]::new('Return to the Gerber root menu.')
        $inner.Data['GerberRootNavigation'] = $true
        { Test-GerberMenuEscapeException -Exception ([System.Exception]::new('wrapped', $inner)) } | Should -Throw 'wrapped'
    }

    It 'does not treat an ordinary failure as an escape' {
        Test-GerberMenuEscapeException -Exception ([System.InvalidOperationException]::new('boom')) | Should -BeFalse
    }
}
