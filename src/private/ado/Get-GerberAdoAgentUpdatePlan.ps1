function Get-GerberAdoAgentUpdatePlan {
    param([pscustomobject]$Context, [Parameter(Mandatory)][ValidateNotNullOrEmpty()][int[]]$PoolId)
    $selected = @($PoolId | Sort-Object -Unique)
    $pools = @(Get-GerberAdoAgentUpdatePoolList -Context $Context | Where-Object Id -In $selected)
    if ($pools.Count -ne $selected.Count) {
        throw [System.ArgumentException]::new('A selected pool is no longer eligible. Return to pool selection.')
    }
    $plan = [pscustomobject]@{
        CollectionUri = $Context.Configuration.CollectionUri.AbsoluteUri
        Pools = $pools
    }
    $plan | Add-Member -NotePropertyName Snapshot -NotePropertyValue (ConvertTo-Json -InputObject $plan -Depth 10 -Compress)
    return $plan
}
