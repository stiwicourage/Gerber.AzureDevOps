function Get-GerberAdoAgentReport {
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param()

    Write-GerberScreenLine -Text 'Connecting to Azure DevOps...'
    $configuration = Get-GerberAdoConfiguration
    $pat = Resolve-GerberAdoPat -Configuration $configuration
    $context = [pscustomobject]@{
        Configuration = $configuration
        Pat = $pat
        IncludeHosted = Get-GerberAdoShowMicrosoftHostedPools
    }
    $sectionList = @(
        Get-GerberAdoAgentSection -Context $context -SectionName 'BUILD' -PoolType 'automation'
        Get-GerberAdoAgentSection -Context $context -SectionName 'DEPLOY' -PoolType 'deployment'
    )

    return [pscustomobject]@{
        Configuration = $configuration
        Sections = $sectionList
        VersionList = Get-GerberAdoVersionList -SectionList $sectionList
    }
}

function Get-GerberAdoAgentSection {
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context,

        [Parameter(Mandatory)]
        [string]$SectionName,

        [Parameter(Mandatory)]
        [string]$PoolType
    )

    $Configuration = $Context.Configuration
    $Pat = $Context.Pat
    $poolList = @(Get-GerberAdoPoolList -Configuration $Configuration -Pat $Pat -PoolType $PoolType)
    $poolList = @(Select-GerberAdoVisiblePool -PoolList $poolList -IncludeHosted:$Context.IncludeHosted)
    $sortedPoolList = @($poolList | Sort-Object -Property @{ Expression = { $_.Name.ToLowerInvariant() } }, Name)
    $resolvedPoolList = @(
        foreach ($pool in $sortedPoolList) {
            $agentList = @(Get-GerberAdoPoolAgentList -Configuration $Configuration -Pat $Pat -Pool $pool)
            [pscustomobject]@{
                Id = $pool.Id
                Name = $pool.Name
                AgentList = @($agentList | Sort-Object -Property @{ Expression = { $_.Name.ToLowerInvariant() } }, Name)
            }
        }
    )

    return [pscustomobject]@{
        Name = $SectionName
        PoolType = $PoolType
        PoolList = $resolvedPoolList
    }
}

function Select-GerberAdoVisiblePool {
    [OutputType([object[]])]
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()]
        [object[]]$PoolList,

        [switch]$IncludeHosted
    )

    if ($IncludeHosted) { return $PoolList }
    return @($PoolList | Where-Object { (Get-GerberAdoOptionalProperty -InputObject $_ -Name 'IsHosted') -ne $true })
}

function Get-GerberAdoPoolResourceList {
    [OutputType([object[]])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,

        [Parameter(Mandatory)]
        [string]$Pat,

        [Parameter(Mandatory)]
        [pscustomobject]$RequestContext
    )

    $response = Get-GerberAdoPoolResourceResponse -Configuration $Configuration -Pat $Pat -RequestContext $RequestContext
    return ConvertTo-GerberAdoPoolResourceList -Response $response -RequestContext $RequestContext
}

function Get-GerberAdoPoolResourceResponse {
    param([pscustomobject]$Configuration, [string]$Pat, [pscustomobject]$RequestContext)
    return Invoke-GerberAdoRestRequest `
        -Uri $RequestContext.Uri `
        -Pat $Pat `
        -RequestLabel $RequestContext.Label `
        -CredentialIdentifier $Configuration.CredentialIdentifier
}

function ConvertTo-GerberAdoPoolResourceList {
    param([AllowNull()][object]$Response, [pscustomobject]$RequestContext)
    return @(
        foreach ($item in @(Get-GerberAdoResponseValueList -Response $Response)) {
            & $RequestContext.Converter $item $RequestContext
        }
    )
}

function Get-GerberAdoPoolResourceUri {
    [OutputType([uri])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,

        [Parameter(Mandatory)]
        [string]$RelativePath,

        [Parameter(Mandatory)]
        [hashtable]$QueryParameterMap
    )

    $resolvedQueryParameterMap = [ordered]@{}
    foreach ($name in $QueryParameterMap.Keys) {
        $resolvedQueryParameterMap[$name] = $QueryParameterMap[$name]
    }

    $resolvedQueryParameterMap['api-version'] = $Configuration.PoolApiVersion
    return Get-GerberAdoApiUri `
        -BaseUri ([System.Uri]::new($Configuration.CollectionUri, $RelativePath)) `
        -QueryParameterMap $resolvedQueryParameterMap
}

function Get-GerberAdoAgentPropertyText {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Agent,

        [Parameter(Mandatory)]
        [string]$PropertyName
    )

    $property = $Agent.PSObject.Properties[$PropertyName]
    $value = if ($property) { [string]$property.Value }
    elseif ($Agent -is [System.Collections.IDictionary]) { [string]$Agent[$PropertyName] }
    else { '' }
    if ([string]::IsNullOrWhiteSpace($value)) {
        return 'unknown'
    }

    return $value.Trim()
}

function Get-GerberAdoVersionList {
    [OutputType([object[]])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject[]]$SectionList
    )

    $versionSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($section in $SectionList) {
        foreach ($pool in @($section.PoolList)) {
            foreach ($agent in @($pool.AgentList)) {
                $null = $versionSet.Add($agent.Version)
            }
        }
    }

    return @($versionSet | Sort-Object)
}
