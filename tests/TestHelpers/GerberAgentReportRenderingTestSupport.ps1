function Get-GerberAgentRenderingTestMember {
    param()
    return [pscustomobject]@{
        Name = 'build-agent-01'
        Version = '3.225.0'
        Status = 'online'
        OperatingSystem = 'Linux'
    }
}

function Get-GerberAgentRenderingTestBuildPoolList {
    param()
    return @(
        [pscustomobject]@{
            Name = 'Alpha Pool'
            AgentList = @()
        }
        [pscustomobject]@{
            Name = 'Build Pool'
            AgentList = @(Get-GerberAgentRenderingTestMember)
        }
    )
}

function Get-GerberAgentRenderingTestSection {
    param([string]$Name, [string]$PoolType, [AllowEmptyCollection()][object[]]$Pools = @())
    return [pscustomobject]@{
        Name = $Name
        PoolType = $PoolType
        PoolList = $Pools
    }
}

function Get-GerberAgentRenderingTestReport {
    param()
    return [pscustomobject]@{
        Configuration = [pscustomobject]@{
            CollectionUri = [uri]'https://ado.example.test/ExampleProject/'
            ProjectName = 'ExampleProject'
        }
        Sections = @(
            Get-GerberAgentRenderingTestSection -Name BUILD -PoolType automation -Pools @(Get-GerberAgentRenderingTestBuildPoolList)
            Get-GerberAgentRenderingTestSection -Name DEPLOY -PoolType deployment
        )
        VersionList = @('3.225.0')
    }
}
