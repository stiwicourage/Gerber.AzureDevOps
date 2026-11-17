BeforeAll {
    . (Join-Path $PSScriptRoot '../../TestHelpers/GerberAgentUpdateTestSupport.ps1')
}

Describe 'Agent update views' {
    It 'previews only pool identities and counts with the shared safety explanations once' {
        $pool = New-AgentUpdateTestPool
        $pool.AgentList += $pool.AgentList[0]
        $plan = [pscustomobject]@{ CollectionUri = 'https://ado.test/'; Pools = @($pool) }
        $text = Get-GerberAgentUpdatePreviewText -Plan $plan
        $text | Should -Match 'https://ado.test/|BUILD'
        $text | Should -Match 'BUILD \| Same name #1 \| 2 agent registrations'
        $text | Should -Not -Match 'agent #7|4\.250\.1|enabled=|work=|pending=|Linux'
        ([regex]::Matches($text, 'ADO chooses version')).Count | Should -Be 1
        $text | Should -Match 'whole pool|entire pool'
        $text | Should -Match 'major'
        $text | Should -Match 'asynchronous'
        $text | Should -Match 'snapshot'
    }

    It 'marks all menu items unselected with pool identity and count only' {
        $items = @(Get-GerberAgentUpdatePoolItemList -Pools @((New-AgentUpdateTestPool), (New-AgentUpdateTestPool -Id 2 -PoolType deployment)))
        $items.Value | Should -Be @(1, 2)
        $items.IsSelected | Should -Be @($false, $false)
        $items[0].Label | Should -Match 'BUILD.*#1.*1 agent'
        $items[1].Label | Should -Match 'DEPLOY.*#2'
        $items.Description | Should -Be @('', '')
    }

    It 'shows the reported BUILD pool as one label without a status or version description' {
        $pool = New-AgentUpdateTestPool -Id 51
        $pool.Name = 'EESSIBuild'
        $pool.AgentList = @($pool.AgentList[0]) * 11
        $item = @(Get-GerberAgentUpdatePoolItemList -Pools @($pool))[0]
        $item.Label | Should -Be 'BUILD | EESSIBuild #51 | 11 agent registrations'
        $item.Description | Should -BeNullOrEmpty
        $item.Value | Should -Be 51
        $item.IsSelected | Should -BeFalse
    }

    It 'keeps external pool names on one logical line without changing the pool identity' {
        $pool = New-AgentUpdateTestPool
        $pool.Name = "Pool`r`nName`tZ$([char]0x2028)Unit"
        $item = @(Get-GerberAgentUpdatePoolItemList -Pools @($pool))[0]
        $item.Label | Should -Be 'BUILD | Pool Name Z Unit #1 | 1 agent registrations'
        $item.Value | Should -Be 1
        $pool.Name | Should -Match '[\r\n\t]'
    }

    It 'shows each DEPLOY pool on one preview row without rendering its registrations' {
        $pool = New-AgentUpdateTestPool -Id 38 -PoolType deployment
        $pool.Name = 'eessi-autotest'
        $pool.AgentList = @($pool.AgentList[0]) * 17
        $plan = [pscustomobject]@{ CollectionUri = 'https://ado.test/'; Pools = @($pool) }
        $text = Get-GerberAgentUpdatePreviewText -Plan $plan
        $row = @($text -split '\r?\n' | Where-Object { $_ -match '^DEPLOY' })[0]
        $row | Should -Be 'DEPLOY | eessi-autotest #38 | 17 agent registrations'
        $row.Length | Should -BeLessOrEqual 79
        @($text -split '\r?\n').Count | Should -Be 5
        $text | Should -Not -Match 'agent #7|4\.250\.1|enabled=|work=|pending=|Linux'
    }

    It 'streams a compact receipt rather than appending a repeated explanation to the pool row' {
        Mock Write-GerberScreenLine {}
        $result = Get-GerberAdoAgentUpdateResult -Pool (New-AgentUpdateTestPool) -State RequestAccepted -HttpStatus 202
        Write-GerberAgentUpdateReceipt -Result $result
        Should -Invoke Write-GerberScreenLine -Times 1 -ParameterFilter {
            $Text -eq 'Pool #1 Same name: RequestAccepted (HTTP 202).'
        }
    }

    It 'keeps result rows compact and displays shared request guidance only once' {
        Mock Show-GerberTextBlock { $script:summaryText = $Text }
        $result = Get-GerberAdoAgentUpdateResult -Pool (New-AgentUpdateTestPool) -State RequestAccepted -HttpStatus 202
        Show-GerberAgentUpdateView -Results @($result, $result)
        $rows = @($script:summaryText -split '\r?\n' | Where-Object { $_ -match '^Pool #' })
        $rows.Count | Should -Be 2
        $rows | ForEach-Object { $_.Length | Should -BeLessOrEqual 79 }
        ([regex]::Matches($script:summaryText, [regex]::Escape($result.Message))).Count | Should -Be 1
        $script:summaryText | Should -Match 'RequestAccepted: 2'
    }

    It 'retains each distinct rejection and unknown-outcome explanation in the result view' {
        Mock Show-GerberTextBlock { $script:summaryText = $Text }
        $failed = Get-GerberAdoAgentUpdateResult -Pool (New-AgentUpdateTestPool) -State RequestFailed -HttpStatus 403
        $unknown = Get-GerberAdoAgentUpdateResult -Pool (New-AgentUpdateTestPool -Id 2) -State OutcomeUnknown
        Show-GerberAgentUpdateView -Results @($failed, $unknown)
        $script:summaryText | Should -Match ([regex]::Escape($failed.Message))
        $script:summaryText | Should -Match ([regex]::Escape($unknown.Message))
    }

    It 'renders acceptance and totals as requests, never completed installations' {
        Mock Show-GerberTextBlock {}
        $result = [pscustomobject]@{ PoolId = 1; PoolName = 'pool'; State = 'RequestAccepted'; HttpStatus = 202; Message = 'Request accepted' }
        Show-GerberAgentUpdateView -Results @($result)
        Should -Invoke Show-GerberTextBlock -Times 1 -ParameterFilter {
            $Text -match 'RequestAccepted: 1' -and $Text -match '/ado agents list' -and $Text -notmatch 'agents updated'
        }
    }
}
