function Get-GerberAdoPoolListRequest {
    param([pscustomobject]$Configuration, [string]$PoolType)
    return [pscustomobject]@{
        Uri = Get-GerberAdoPoolResourceUri -Configuration $Configuration -RelativePath '_apis/distributedtask/pools' -QueryParameterMap @{ poolType = $PoolType }
        Label = "$PoolType pools"
        PoolType = $PoolType
        Converter = { param($pool, $request) ConvertTo-GerberAdoPool -Pool $pool -PoolType $request.PoolType }
    }
}

function Get-GerberAdoPoolAgentRequest {
    param([pscustomobject]$Configuration, [pscustomobject]$Pool, [switch]$IncludeAssignedRequest)
    $query = [ordered]@{ includeCapabilities = 'false' }
    if ($IncludeAssignedRequest) { $query['includeAssignedRequest'] = 'true' }
    return [pscustomobject]@{
        Uri = Get-GerberAdoPoolResourceUri -Configuration $Configuration -RelativePath "_apis/distributedtask/pools/$($Pool.Id)/agents" -QueryParameterMap $query
        Label = "agents for pool '$($Pool.Name)'"
        Converter = { param($agent) ConvertTo-GerberAdoUpdateAgent -Agent $agent }
    }
}

function ConvertTo-GerberAdoPool {
    param([object]$Pool, [string]$PoolType)
    return [pscustomobject]@{
        Id = [int]$Pool.id
        Name = [string]$Pool.name
        PoolType = $PoolType
        IsHosted = Get-GerberAdoOptionalProperty -InputObject $Pool -Name 'isHosted'
        Size = Get-GerberAdoOptionalProperty -InputObject $Pool -Name 'size'
    }
}
