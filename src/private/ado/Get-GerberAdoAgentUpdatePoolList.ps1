function Get-GerberAdoAgentUpdatePoolList {
    param([pscustomobject]$Context)
    $seen = [System.Collections.Generic.HashSet[int]]::new()
    $pools = foreach ($type in @('automation', 'deployment')) {
        foreach ($pool in @(Get-GerberAdoPoolList -Configuration $Context.Configuration -Pat $Context.Pat -PoolType $type)) {
            if (-not $seen.Add($pool.Id)) { continue }
            Resolve-GerberAdoUpdatePoolInventory -Context $Context -Pool $pool
        }
    }
    return @($pools | Sort-Object PoolType, Name, Id)
}

function Resolve-GerberAdoUpdatePoolInventory {
    param([pscustomobject]$Context, [pscustomobject]$Pool)
    if (-not (Test-GerberAdoUpdatePoolEligibility $Pool)) { return }
    $members = @(Get-GerberAdoPoolAgentList -Configuration $Context.Configuration -Pat $Context.Pat -Pool $Pool -IncludeAssignedRequest)
    if ($members.Count -eq 0) { return }
    return Copy-GerberAdoUpdatePool -Pool $Pool -Members $members
}

function Test-GerberAdoUpdatePoolEligibility {
    param([pscustomobject]$Pool)
    if ((Get-GerberAdoOptionalProperty $Pool 'IsHosted') -isnot [bool]) { return $false }
    if ($Pool.IsHosted) { return $false }
    if ($Pool.Id -le 0) { return $false }
    return $Pool.PoolType -in @('automation', 'deployment')
}

function Copy-GerberAdoUpdatePool {
    param([pscustomobject]$Pool, [object[]]$Members)
    return [pscustomobject]@{
        Id = $Pool.Id
        Name = $Pool.Name
        PoolType = $Pool.PoolType
        IsHosted = $Pool.IsHosted
        AgentList = @($Members | Sort-Object Id, Name)
    }
}
