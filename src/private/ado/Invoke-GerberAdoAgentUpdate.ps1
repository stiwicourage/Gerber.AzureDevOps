function Invoke-GerberAdoAgentUpdate {
    param([pscustomobject]$Context, [pscustomobject]$Plan, [scriptblock]$OnResult = {}, [scriptblock]$CancellationRequested = { $false })
    $pools = @($Plan.Pools | Group-Object Id | ForEach-Object { $_.Group[0] })
    $stopped = $false
    $index = 0
    foreach ($pool in $pools) {
        $index++
        Write-GerberScreenLine -Text "Agent refresh $index/$($pools.Count)"
        $result = Get-GerberAdoAgentUpdateAttempt -Context $Context -Pool $pool -Stopped $stopped -CancellationRequested $CancellationRequested
        $null = & $OnResult $result
        $result
        $stopped = Test-GerberAdoAgentUpdateStop -Result $result
    }
}

function Get-GerberAdoAgentUpdateAttempt {
    param([pscustomobject]$Context, [pscustomobject]$Pool, [bool]$Stopped, [scriptblock]$CancellationRequested = { $false })
    if ($Stopped) { return Get-GerberAdoAgentUpdateResult -Pool $Pool -State 'NotAttempted' }
    if (& $CancellationRequested) { return Get-GerberAdoAgentUpdateResult -Pool $Pool -State 'CancelledBeforeSend' }
    try {
        return Start-GerberAdoAgentPoolUpdate -Context $Context -Pool $Pool -Confirm:$false
    } catch [System.OperationCanceledException] {
        return Get-GerberAdoAgentUpdateResult -Pool $Pool -State 'OutcomeUnknown'
    } catch [System.Management.Automation.PipelineStoppedException] {
        return Get-GerberAdoAgentUpdateResult -Pool $Pool -State 'OutcomeUnknown'
    }
}

function Test-GerberAdoAgentUpdateStop {
    param([pscustomobject]$Result)
    if ($Result.HttpStatus -eq 401) { return $true }
    return $Result.State -in @('OutcomeUnknown', 'CancelledBeforeSend', 'NotAttempted')
}
