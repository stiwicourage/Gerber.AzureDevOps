BeforeAll {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    . (Join-Path $PSScriptRoot '../../TestHelpers/GerberAgentUpdateTestSupport.ps1')
}

Describe 'Get-GerberAdoRefreshServerMessage' {
    Context 'Sanitized server diagnostics' {
        It 'handles a missing message in the same strict source-module scope as the shipped artifact' {
            $root = Join-Path $PSScriptRoot '../../../src/private/ado'
            $module = New-Module -ArgumentList $root -ScriptBlock {
                param($Root)
                Set-StrictMode -Version Latest
                . (Join-Path $Root 'Get-GerberAdoRefreshServerMessage.ps1')
                . (Join-Path $Root 'Get-GerberAdoRequestHeader.ps1')
            }
            & $module {
                Get-GerberAdoRefreshServerMessage -Response ([pscustomobject]@{}) -Pat 'synthetic-only-pat'
            } | Should -BeNullOrEmpty
        }

        It 'reads only the JSON message from an object, dictionary or serialized JSON' -ForEach @(
            @{ Response = [pscustomobject]@{ message = 'Preview required.'; stackTrace = 'private' } }
            @{ Response = @{ message = 'Preview required.'; stackTrace = 'private' } }
            @{ Response = '{"message":"Preview required.","stackTrace":"private"}' }
        ) {
            Get-GerberAdoRefreshServerMessage -Response $Response -Pat 'synthetic-only-pat' | Should -Be 'Preview required.'
        }

        It 'ignores absent, malformed, HTML and non-string messages rather than echoing bodies' -ForEach @(
            @{ Response = $null }
            @{ Response = '<html>private error</html>' }
            @{ Response = '{invalid JSON private error' }
            @{ Response = @{ stackTrace = 'private' } }
            @{ Response = [pscustomobject]@{ stackTrace = 'private' } }
            @{ Response = [pscustomobject]@{} }
            @{ Response = '{}' }
            @{ Response = @{ message = @{ nested = 'private' } } }
            @{ Response = @{ message = 123 } }
        ) {
            Set-StrictMode -Version Latest
            Get-GerberAdoRefreshServerMessage -Response $Response -Pat 'synthetic-only-pat' | Should -BeNullOrEmpty
        }

        It 'redacts raw and encoded credentials for <Pat> including equal-length encodings' -ForEach @(
            @{ Pat = 'synthetic+only/pat=' }
            @{ Pat = 'abc+def/gh==' }
        ) {
            $basic = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(":$pat"))
            $message = "Denied $pat $([uri]::EscapeDataString($pat)) $basic Authorization: Bearer another-secret password=hidden"
            $safe = Get-GerberAdoRefreshServerMessage -Response @{ message = $message } -Pat $pat
            $safe | Should -Match 'Denied.*\[redacted\]'
            $safe | Should -Not -Match ([regex]::Escape($pat))
            $safe | Should -Not -Match ([regex]::Escape([uri]::EscapeDataString($pat)))
            $safe | Should -Not -Match "$([regex]::Escape($basic))|another-secret|hidden"
        }

        It 'flattens control and Unicode line separators and truncates diagnostics to 160 characters' {
            $message = "Bad`r`nrequest`t$([char]27)$([char]0x2028)$([char]0x202E)" + ('x' * 200)
            $safe = Get-GerberAdoRefreshServerMessage -Response @{ message = $message } -Pat 'synthetic-only-pat'
            $safe.Length | Should -Be 160
            $safe | Should -Match '^Bad request .*\.{3}$'
            $safe | Should -Not -Match '[\p{Cc}\p{Cf}\p{Zl}\p{Zp}]'
        }
    }
}
