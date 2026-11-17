. (Join-Path $PSScriptRoot '../PluginTestSupport.ps1')

function New-AgentUpdateTestContext {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    if (-not $PSCmdlet.ShouldProcess('Synthetic context', 'Create test fixture')) { return }
    return [pscustomobject]@{
        Configuration = [pscustomobject]@{
            CollectionUri = [uri]'https://ado.example.test/collection/'
            PoolApiVersion = '7.1'
            CredentialIdentifier = 'test-profile'
        }
        Pat = 'synthetic-only-pat'
    }
}

function New-AgentUpdateTestPool {
    [CmdletBinding(SupportsShouldProcess)]
    param([int]$Id = 1, [string]$PoolType = 'automation')
    if (-not $PSCmdlet.ShouldProcess('Synthetic pool', 'Create test fixture')) { return }
    return [pscustomobject]@{
        Id = $Id
        Name = 'Same name'
        PoolType = $PoolType
        IsHosted = $false
        Size = 1
        AgentList = @(Get-AgentUpdateTestMember)
    }
}

function Get-AgentUpdateTestMember {
    return [pscustomobject]@{
        Id = 7
        Name = 'agent'
        Version = '4.250.1'
        Status = 'offline'
        OperatingSystem = 'Linux'
        Enabled = $false
        WorkState = 'unknown'
        PendingUpdate = 'unknown'
    }
}
