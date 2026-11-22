function Invoke-GerberAgentUpdateFlow {
    param()
    if (Test-GerberConsoleInputRedirected) {
        throw [System.ArgumentException]::new('/ado agents update requires an interactive terminal; no request was sent.')
    }
    try {
        Invoke-GerberAgentUpdateSelection
    } catch {
        if (Test-GerberMenuEscapeException -Exception $_.Exception) { return }
        Show-GerberTextBlock -Title '/ado agents update' -Text 'Could not prepare agent refresh. Check profile credentials, pool access and current inventory. No further requests will be sent.'
        Wait-GerberAgentUpdateContinue
    }
}

function Invoke-GerberAgentUpdateSelection {
    param()
    $configuration = Get-GerberAdoConfiguration -CommandLabel '/ado agents update'
    $context = [pscustomobject]@{ Configuration = $configuration; Pat = Resolve-GerberAdoPat -Configuration $configuration }
    $ids = @(Read-GerberAgentUpdatePoolSelection -Context $context)
    if ($ids.Count -eq 0) { return }
    $plan = Get-GerberAdoAgentUpdatePlan -Context $context -PoolId $ids
    $confirmed = Confirm-GerberAgentUpdatePlan -Context $context -Plan $plan
    if ($null -eq $confirmed) { return }
    $results = @(Invoke-GerberAgentUpdateBatch -Context $context -Plan $confirmed)
    Show-GerberAgentUpdateView -Results $results
    Wait-GerberAgentUpdateContinue
}

function Read-GerberAgentUpdatePoolSelection {
    param([pscustomobject]$Context)
    $pools = @(Get-GerberAdoAgentUpdatePoolList -Context $Context)
    if ($pools.Count -eq 0) {
        Show-GerberTextBlock -Title '/ado agents update' -Text 'No eligible self-hosted, nonempty BUILD or DEPLOY pools found.'
        Wait-GerberAgentUpdateContinue
        return
    }
    $selection = Read-GerberCheckboxMenuPrompt -PromptRequest (Get-GerberAgentUpdateSelectionRequest -Pools $pools)
    if ($null -eq $selection) { return }
    foreach ($item in @($selection.SelectedItemList)) { $item.Value }
}

function Confirm-GerberAgentUpdatePlan {
    param([pscustomobject]$Context, [pscustomobject]$Plan)
    while (Confirm-GerberAgentUpdatePreview -Plan $Plan) {
        $current = Get-GerberAdoAgentUpdatePlan -Context $Context -PoolId @($Plan.Pools.Id)
        if ($current.Snapshot -ceq $Plan.Snapshot) { return $current }
        Show-GerberTextBlock -Title 'Scope changed' -Text 'Inventory changed since the preview. Review the new snapshot and confirm again.'
        $Plan = $current
    }
    return $null
}

function Wait-GerberAgentUpdateContinue {
    param()
    try { $null = Wait-GerberContinue } catch {
        if (-not (Test-GerberMenuEscapeException -Exception $_.Exception)) { throw }
    }
}
