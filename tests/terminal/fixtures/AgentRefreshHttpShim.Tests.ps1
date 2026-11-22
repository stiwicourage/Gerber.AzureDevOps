BeforeAll {
    # Test-owned stand-ins for the Gerber Core harness boundary; every test mocks them, so no sibling checkout is needed.
    function Write-GerberTerminalHttpResponseHeader {
        param([AllowEmptyString()][string]$VariableName, [AllowNull()][object]$MatchingEntry)
        throw "Unmocked Core boundary call for '$VariableName' with entry '$MatchingEntry'."
    }

    function Resolve-GerberTerminalHttpFixtureResponse {
        param([Parameter(Mandatory)][hashtable]$Fixture, [AllowNull()][object]$MatchingEntry)
        throw "Unmocked Core boundary call for $($Fixture.Count) fixture key(s) with entry '$MatchingEntry'."
    }

    . (Join-Path -Path $PSScriptRoot -ChildPath 'AgentRefreshHttpShim.ps1')
}

Describe 'Terminal HTTP fixture adapter characterization' {
    BeforeEach {
        Mock Get-AdoTerminalHttpResolution { [pscustomobject]@{ Fixture = @{}; MatchingEntry = @{ statusCode = 202 } } }
        Mock Write-GerberTerminalHttpResponseHeader {}
        Mock Set-AdoTerminalResponseStatus {}
        Mock Resolve-GerberTerminalHttpFixtureResponse { @{ accepted = $true } }
    }

    It 'preserves native request binding, status capture and the fixture response without network access' {
        $shim = Get-AdoTerminalRestMethodShim
        $result = & $shim -Method Post -Uri https://ado.test/pools/1/messages -Headers @{ safe = 'fixture' } `
            -ConnectionTimeoutSeconds 5 -OperationTimeoutSeconds 15 -StatusCodeVariable code `
            -MaximumRetryCount 0 -MaximumRedirection 0 -SkipHttpErrorCheck
        $result.accepted | Should -BeTrue
        Should -Invoke Get-AdoTerminalHttpResolution -Times 1 -ParameterFilter {
            $Request['Method'] -eq 'Post' -and $Request['Uri'].AbsoluteUri -eq 'https://ado.test/pools/1/messages' -and
            $Request['ConnectionTimeoutSeconds'] -eq 5 -and $Request['OperationTimeoutSeconds'] -eq 15
        }
        Should -Invoke Set-AdoTerminalResponseStatus -Times 1 -ParameterFilter { $Name -eq 'code' -and $Entry.statusCode -eq 202 }
    }

    It 'retains ordinary GET response-header forwarding without inventing a status destination' {
        $shim = Get-AdoTerminalRestMethodShim
        $null = & $shim -Method Get -Uri https://ado.test/pools -ResponseHeadersVariable pageHeaders
        Should -Invoke Write-GerberTerminalHttpResponseHeader -Times 1 -ParameterFilter { $VariableName -eq 'pageHeaders' }
        Should -Invoke Set-AdoTerminalResponseStatus -Times 0
    }

    It 'propagates a fixture timeout exactly once without using a real transport' {
        Mock Resolve-GerberTerminalHttpFixtureResponse { throw [System.TimeoutException]::new('Synthetic timeout') }
        $shim = Get-AdoTerminalRestMethodShim
        { & $shim -Method Post -Uri https://ado.test/pools/1/messages } | Should -Throw '*Synthetic timeout*'
        Should -Invoke Resolve-GerberTerminalHttpFixtureResponse -Times 1 -Exactly
    }

    It 'holds an in-flight synthetic refresh long enough to send a real terminal Ctrl-C byte' {
        Mock Get-AdoTerminalHttpResolution { [pscustomobject]@{ Fixture = @{}; MatchingEntry = @{ holdForInterrupt = $true } } }
        Mock Start-Sleep {}
        Mock Write-Information {}
        $shim = Get-AdoTerminalRestMethodShim
        $null = & $shim -Method Post -Uri https://ado.test/pools/1/messages
        Should -Invoke Start-Sleep -Times 1 -ParameterFilter { $Seconds -eq 3 }
        Should -Invoke Write-Information -Times 1 -ParameterFilter { $MessageData -eq 'Synthetic refresh in progress' }
    }
}
