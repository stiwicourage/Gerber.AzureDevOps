BeforeAll {
    . (Join-Path $PSScriptRoot '../../TestHelpers/GerberAgentUpdateTestSupport.ps1')
}

Describe 'Pool-wide refresh transport' {
    BeforeEach {
        $script:context = New-AgentUpdateTestContext
        $script:pool = New-AgentUpdateTestPool
        Mock Get-GerberHttpConfiguration { [pscustomobject]@{ ConnectionTimeoutSeconds = 5; OperationTimeoutSeconds = 15 } }
        Mock Invoke-RestMethod { (Get-Variable -Name responseStatus).Value = 202 }
    }

    It 'sends one SDK-equivalent JSON null POST using the configured preview API at collection scope' {
        $context.Configuration.PoolApiVersion = '6.0'
        $result = Start-GerberAdoAgentPoolUpdate -Context $context -Pool $pool -Confirm:$false
        $result.State | Should -Be 'RequestAccepted'
        $result.HttpStatus | Should -Be 202
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Post' -and $Uri.AbsoluteUri -eq 'https://ado.example.test/collection/_apis/distributedtask/pools/1/messages?api-version=6.0-preview.1' -and
            $Body -ceq 'null' -and $ContentType -eq 'application/json; charset=utf-8' -and $Headers.Accept -eq 'application/json' -and
            $MaximumRetryCount -eq 0 -and $MaximumRedirection -eq 0
        }
        ($result | ConvertTo-Json -Depth 5) | Should -Not -Match 'synthetic-only-pat|Authorization|Updated'
    }

    It 'uses <Expected> for configured version <Version> without mutating GET configuration' -ForEach @(
        @{ Version = '7.1'; Expected = '7.1-preview.1' }
        @{ Version = '6.0'; Expected = '6.0-preview.1' }
        @{ Version = '7.1-preview.1'; Expected = '7.1-preview.1' }
    ) {
        $context.Configuration.PoolApiVersion = $Version
        $request = Get-GerberAdoAgentRefreshRequest -Context $context -Pool $pool
        $request.Uri.AbsoluteUri | Should -Be "https://ado.example.test/collection/_apis/distributedtask/pools/1/messages?api-version=$Expected"
        $request.Headers.Authorization | Should -Be 'Basic OnN5bnRoZXRpYy1vbmx5LXBhdA=='
        $request.Body | Should -BeExactly 'null'
        $request.ContentType | Should -Be 'application/json; charset=utf-8'
        $context.Configuration.PoolApiVersion | Should -Be $Version
    }

    It 'reports HTTP 400 with only the sanitized JSON message, not raw server diagnostics' {
        Mock Invoke-RestMethod {
            (Get-Variable -Name responseStatus).Value = 400
            [pscustomobject]@{ message = "Preview API required.`r`npat=synthetic-only-pat"; stackTrace = 'private server stack' }
        }
        $result = Start-GerberAdoAgentPoolUpdate -Context $context -Pool $pool -Confirm:$false
        $result.State | Should -Be RequestFailed
        $result.HttpStatus | Should -Be 400
        $result.Message | Should -Match 'Preview API required\.'
        $result.Message | Should -Not -Match 'synthetic-only-pat|private server stack|[\r\n]'
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly
    }

    It 'does not mutate when ShouldProcess declines under WhatIf' {
        $result = Start-GerberAdoAgentPoolUpdate -Context $context -Pool $pool -WhatIf
        $result.State | Should -Be 'CancelledBeforeSend'
        Should -Invoke Invoke-RestMethod -Times 0
    }

    It 'retains HTTP <Code> rejection classification when an empty JSON object has no message' -ForEach @(
        @{ Code = 400 }
        @{ Code = 403 }
    ) {
        Set-StrictMode -Version Latest
        Mock Invoke-RestMethod { (Get-Variable -Name responseStatus).Value = $Code; [pscustomobject]@{} }
        $result = Start-GerberAdoAgentPoolUpdate -Context $context -Pool $pool -Confirm:$false
        $result.State | Should -Be RequestFailed
        $result.HttpStatus | Should -Be $Code
        $result.Message | Should -Not -Match 'Server:'
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly
    }

    It 'classifies HTTP <Code> as <State> without retry or raw server text' -ForEach @(
        @{ Code = 204; State = 'RequestAccepted' }
        @{ Code = 400; State = 'RequestFailed' }
        @{ Code = 401; State = 'RequestFailed' }
        @{ Code = 403; State = 'RequestFailed' }
        @{ Code = 404; State = 'RequestFailed' }
        @{ Code = 429; State = 'RequestFailed' }
        @{ Code = 408; State = 'OutcomeUnknown' }
        @{ Code = 500; State = 'OutcomeUnknown' }
        @{ Code = 302; State = 'OutcomeUnknown' }
    ) {
        Mock Invoke-RestMethod { (Get-Variable -Name responseStatus).Value = $Code; 'raw synthetic-only-pat server body' }
        $result = Start-GerberAdoAgentPoolUpdate -Context $context -Pool $pool -Confirm:$false
        $result.State | Should -Be $State
        $result.HttpStatus | Should -Be $Code
        ($result | ConvertTo-Json) | Should -Not -Match 'synthetic-only-pat|server body'
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly
    }

    It 'treats a timeout or interrupted connection as unknown and never retries' {
        Mock Invoke-RestMethod { throw [System.TimeoutException]::new('synthetic-only-pat') }
        $result = Start-GerberAdoAgentPoolUpdate -Context $context -Pool $pool -Confirm:$false
        $result.State | Should -Be 'OutcomeUnknown'
        $result.HttpStatus | Should -Be 0
        $result.Message | Should -Not -Match 'synthetic-only-pat'
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly
    }
}
