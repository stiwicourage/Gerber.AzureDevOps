BeforeAll {
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'TestHelpers/GerberTestSupport.ps1')
    Import-GerberSource -StartPath $PSScriptRoot
}

Describe 'Get-GerberAdoAgentReport' {
    Context 'Optional pool and member metadata' {
        BeforeEach {
            $script:metadataConfiguration = [pscustomobject]@{ CollectionUri = [uri]'https://ado.test/'; PoolApiVersion = '7.1'; CredentialIdentifier = 'test' }
            Mock Invoke-GerberAdoRestRequest {
                @{ value = @(@{ id = 12; name = 'item'; poolType = 'automation'; isHosted = $false
                    size = 1; enabled = $false; assignedRequest = $null; pendingUpdate = @{ currentState = 'queued' } }) }
            }
        }

        It 'preserves optional pool metadata' {
            $pool = @(Get-GerberAdoPoolList -Configuration $script:metadataConfiguration -Pat 'pat' -PoolType automation)[0]
            $pool.IsHosted | Should -BeFalse
            $pool.PoolType | Should -Be 'automation'
            $pool.Size | Should -Be 1
        }

        It 'preserves optional update metadata and requests work only when explicitly selected' {
            $pool = @(Get-GerberAdoPoolList -Configuration $script:metadataConfiguration -Pat 'pat' -PoolType automation)[0]
            $agent = @(Get-GerberAdoPoolAgentList -Configuration $script:metadataConfiguration -Pat 'pat' -Pool $pool -IncludeAssignedRequest)[0]
            $agent.Id | Should -Be 12
            $agent.Enabled | Should -BeFalse
            $agent.WorkState | Should -Be 'idle'
            $agent.PendingUpdate | Should -Be 'queued'
            Should -Invoke Invoke-GerberAdoRestRequest -Times 1 -ParameterFilter { $Uri.Query -match 'includeAssignedRequest=true' }
        }
    }

    Context 'Microsoft-hosted pool setting' {
        BeforeEach {
            Mock Get-GerberAdoConfiguration { [pscustomobject]@{ CredentialIdentifier = 'gerber:ado:example:pat' } }
            Mock Resolve-GerberAdoPat { 'pat-value' }
            Mock Get-GerberAdoPoolAgentList { @() }
            Mock Get-GerberAdoPoolList {
                @(
                    [pscustomobject]@{ Id = 1; Name = 'Self'; IsHosted = $false }
                    [pscustomobject]@{ Id = 2; Name = 'Azure Pipelines'; IsHosted = $true }
                    [pscustomobject]@{ Id = 3; Name = 'Unknown'; IsHosted = $null }
                )
            }
        }

        It 'omits Microsoft-hosted pools when the setting is off' {
            Mock Get-GerberAdoShowMicrosoftHostedPool { $false }
            $result = Get-GerberAdoAgentReport
            $result.Sections[0].PoolList.Name | Should -Be @('Self', 'Unknown')
        }

        It 'includes Microsoft-hosted pools sorted with the others when the setting is on' {
            Mock Get-GerberAdoShowMicrosoftHostedPool { $true }
            $result = Get-GerberAdoAgentReport
            $result.Sections[0].PoolList.Name | Should -Be @('Azure Pipelines', 'Self', 'Unknown')
        }
    }

    Context 'Get-GerberAdoShowMicrosoftHostedPool' {
        It 'defaults to true when configuration or setting is absent' {
            Mock Get-GerberUserConfiguration { [ordered]@{} }
            Get-GerberAdoShowMicrosoftHostedPool | Should -BeTrue
            Mock Get-GerberUserConfiguration { @{ ado = @{ profiles = @{} } } }
            Get-GerberAdoShowMicrosoftHostedPool | Should -BeTrue
        }

        It 'returns the configured value case-insensitively' {
            Mock Get-GerberUserConfiguration { @{ ADO = @{ settings = @{ showMicrosoftHostedPools = $false } } } }
            Get-GerberAdoShowMicrosoftHostedPool | Should -BeFalse
        }
    }

    It 'keeps absent optional metadata unknown under StrictMode' {
        Set-StrictMode -Version Latest
        $agent = ConvertTo-GerberAdoUpdateAgent -Agent ([pscustomobject]@{ name = 'minimal' })
        $agent.Id | Should -BeNullOrEmpty
        $agent.Enabled | Should -BeNullOrEmpty
        $agent.WorkState | Should -Be 'unknown'
        $agent.PendingUpdate | Should -Be 'unknown'
        $agent.Version | Should -Be 'unknown'
    }

    It 'writes Connecting status message before making HTTP calls' {
        Mock Write-GerberScreenLine {}
        Mock Get-GerberAdoConfiguration {
            [pscustomobject]@{
                CredentialIdentifier = 'gerber:ado:example:pat'
            }
        }
        Mock Resolve-GerberAdoPat { 'pat-value' }
        Mock Get-GerberAdoShowMicrosoftHostedPool { $false }
        Mock Get-GerberAdoPoolList { @() }

        Get-GerberAdoAgentReport

        Should -Invoke Write-GerberScreenLine -Times 1 -ParameterFilter {
            $Text -eq 'Connecting to Azure DevOps...'
        }
    }

    It 'orders sections, pools, agents, and unique versions' {
        Mock Get-GerberAdoConfiguration {
            [pscustomobject]@{
                CredentialIdentifier = 'gerber:ado:example:pat'
            }
        }
        Mock Resolve-GerberAdoPat { 'pat-value' }
        Mock Get-GerberAdoShowMicrosoftHostedPool { $false }
        Mock Get-GerberAdoPoolList {
            if ($PoolType -eq 'automation') {
                return @(
                    [pscustomobject]@{ Id = 2; Name = 'Zulu Pool' }
                    [pscustomobject]@{ Id = 1; Name = 'Alpha Pool' }
                )
            }

            return @(
                [pscustomobject]@{ Id = 3; Name = 'Deploy Pool' }
            )
        }
        Mock Get-GerberAdoPoolAgentList {
            switch ($Pool.Name) {
                'Alpha Pool' {
                    return @(
                        [pscustomobject]@{ Name = 'z-agent'; Version = '3.225.0'; Status = 'online' }
                        [pscustomobject]@{ Name = 'a-agent'; Version = '3.224.1'; Status = 'offline' }
                    )
                }
                'Zulu Pool' {
                    return @()
                }
                default {
                    return @(
                        [pscustomobject]@{ Name = 'deploy-agent'; Version = '3.225.0'; Status = 'online' }
                    )
                }
            }
        }

        $result = Get-GerberAdoAgentReport

        $result.Sections.Name | Should -Be @('BUILD', 'DEPLOY')
        $result.Sections[0].PoolList.Name | Should -Be @('Alpha Pool', 'Zulu Pool')
        $result.Sections[0].PoolList[0].AgentList.Name | Should -Be @('a-agent', 'z-agent')
        $result.Sections[0].PoolList[1].AgentList | Should -BeNullOrEmpty
        $result.VersionList | Should -Be @('3.224.1', '3.225.0')
    }

    It 'parses pool and agent responses through the shared response helpers' {
        $configuration = [pscustomobject]@{
            CollectionUri = [uri]'https://ado.example.test/ExampleProject/'
            PoolApiVersion = '7.1'
            CredentialIdentifier = 'gerber:ado:example:pat'
        }

        Mock Invoke-GerberAdoRestRequest {
            if ($RequestLabel -eq 'automation pools') {
                return @{
                    value = @(
                        @{ id = 10; name = 'Build Pool' }
                    )
                }
            }

            return @{
                value = @(
                    @{ name = 'agent-01'; version = '3.225.0'; status = 'online'; osDescription = 'Linux 5.15.0-1057-azure #65-Ubuntu SMP' }
                    @{ name = 'agent-02'; version = '3.225.0'; status = 'online' }
                )
            }
        }

        $poolList = Get-GerberAdoPoolList -Configuration $configuration -Pat 'pat' -PoolType 'automation'
        $agentList = Get-GerberAdoPoolAgentList -Configuration $configuration -Pat 'pat' -Pool ([pscustomobject]@{ Id = 10; Name = 'Build Pool' })

        $poolList[0].Name | Should -Be 'Build Pool'
        $agentList[0].Version | Should -Be '3.225.0'
        $agentList[0].Status | Should -Be 'online'
        $agentList[0].OperatingSystem | Should -Be 'Linux'
        $agentList[1].OperatingSystem | Should -Be 'unknown'
    }

    It 'builds the expected Azure DevOps pool and agent URIs' {
        $configuration = [pscustomobject]@{
            CollectionUri = [uri]'https://ado.example.test/ExampleProject/'
            PoolApiVersion = '7.1'
        }

        $poolUri = (Get-GerberAdoPoolResourceUri `
                -Configuration $configuration `
                -RelativePath '_apis/distributedtask/pools' `
                -QueryParameterMap ([ordered]@{ poolType = 'automation' })).AbsoluteUri
        $agentUri = (Get-GerberAdoPoolResourceUri `
                -Configuration $configuration `
                -RelativePath '_apis/distributedtask/pools/12/agents' `
                -QueryParameterMap ([ordered]@{ includeCapabilities = 'false' })).AbsoluteUri

        $poolUri | Should -Match '^https://ado\.example\.test/ExampleProject/_apis/distributedtask/pools\?'
        $poolUri | Should -Match 'poolType=automation'
        $poolUri | Should -Match 'api-version=7.1'
        $agentUri | Should -Match '^https://ado\.example\.test/ExampleProject/_apis/distributedtask/pools/12/agents\?'
        $agentUri | Should -Match 'includeCapabilities=false'
        $agentUri | Should -Match 'api-version=7.1'
    }

    It 'normalizes response value lists and missing agent metadata' {
        (Get-GerberAdoResponseValueList -Response $null) | Should -BeNullOrEmpty
        (Get-GerberAdoResponseValueList -Response @{ value = @('a', 'b') }) | Should -Be @('a', 'b')
        (Get-GerberAdoResponseValueList -Response ([pscustomobject]@{ other = 1 })) | Should -BeNullOrEmpty
        (Get-GerberAdoAgentPropertyText -Agent ([pscustomobject]@{ version = '' }) -PropertyName 'version') | Should -Be 'unknown'
        (Get-GerberAdoAgentPropertyText -Agent ([pscustomobject]@{ status = '' }) -PropertyName 'status') | Should -Be 'unknown'
        (Get-GerberAdoAgentPropertyText -Agent ([pscustomobject]@{ version = '1' }) -PropertyName 'osDescription') | Should -Be 'unknown'
        (Get-GerberAdoAgentPropertyText -Agent @{ osDescription = 'Linux' } -PropertyName 'osDescription') | Should -Be 'Linux'
    }
}
