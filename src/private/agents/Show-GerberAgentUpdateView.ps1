function Get-GerberAgentUpdateSelectionRequest {
    param([object[]]$Pools)
    return [pscustomobject]@{
        Prompt = 'Agent pools'
        ScreenTitle = '/ado agents update'
        ScreenText = 'Select self-hosted BUILD and DEPLOY pools. Nothing is selected initially.'
        ItemList = @(Get-GerberAgentUpdatePoolItemList -Pools $Pools)
        EmptySelectionMessage = 'Select at least one pool before Apply.'
    }
}

function Get-GerberAgentUpdatePoolItemList {
    param([object[]]$Pools)
    foreach ($pool in $Pools) {
        [pscustomobject]@{
            Label = Get-GerberAgentUpdatePoolLabel $pool
            Description = ''
            Value = $pool.Id
            IsSelected = $false
        }
    }
}

function Get-GerberAgentUpdatePoolLabel {
    param([pscustomobject]$Pool)
    $type = if ($Pool.PoolType -eq 'automation') { 'BUILD' } else { 'DEPLOY' }
    return ConvertTo-GerberAgentUpdateSingleLine -Text "$type | $($Pool.Name) #$($Pool.Id) | $($Pool.AgentList.Count) agent registrations"
}

function ConvertTo-GerberAgentUpdateSingleLine {
    param([AllowEmptyString()][string]$Text)
    return [regex]::Replace($Text, '[\p{Cc}\p{Zl}\p{Zp}]+', ' ')
}

function Get-GerberAgentUpdatePreviewText {
    param([pscustomobject]$Plan)
    $lines = @(
        "Collection: $($Plan.CollectionUri)"
        'Entire pool, offline/disabled included. ADO chooses version; may change major.'
        'Asynchronous; normally after current jobs. Offline updates not guaranteed.'
        'Snapshot only; pool membership cannot be locked atomically.'
        foreach ($pool in $Plan.Pools) { Get-GerberAgentUpdatePoolLabel $pool }
    )
    return $lines -join [Environment]::NewLine
}

function Confirm-GerberAgentUpdatePreview {
    param([pscustomobject]$Plan)
    $options = Get-GerberConfirmationPromptOptionSet -ActionLabel 'Apply' -DefaultOption 'cancel' `
        -ActionPreviewText 'Request pool-wide refresh to the ADO-selected version.' `
        -CancelPreviewText 'Cancel without sending any refresh request.'
    return Read-GerberConfirmationPrompt -Prompt 'Confirm' -ScreenTitle '/ado agents update' `
        -ScreenText (Get-GerberAgentUpdatePreviewText -Plan $Plan) -PromptOptionSet $options
}

function Write-GerberAgentUpdateReceipt {
    param([pscustomobject]$Result)
    Write-GerberScreenLine -Text (Get-GerberAgentUpdateReceiptText -Result $Result)
}

function Get-GerberAgentUpdateReceiptText {
    param([pscustomobject]$Result)
    return ConvertTo-GerberAgentUpdateSingleLine -Text "Pool #$($Result.PoolId) $($Result.PoolName): $($Result.State) (HTTP $($Result.HttpStatus))."
}

function Get-GerberAgentUpdateResultMessageList {
    param([AllowEmptyCollection()][object[]]$Results)
    return @($Results | ForEach-Object { ConvertTo-GerberAgentUpdateSingleLine -Text $_.Message } | Sort-Object -Unique)
}

function Show-GerberAgentUpdateView {
    param([AllowEmptyCollection()][object[]]$Results)
    $lines = @(
        foreach ($result in $Results) { Get-GerberAgentUpdateReceiptText -Result $result }
        foreach ($group in @($Results | Group-Object State)) { "$($group.Name): $($group.Count)" }
        Get-GerberAgentUpdateResultMessageList -Results $Results
        'Request results, not installations. Check versions: /ado agents list.'
    )
    Show-GerberTextBlock -Title '/ado agents update' -Text ($lines -join [Environment]::NewLine)
}
