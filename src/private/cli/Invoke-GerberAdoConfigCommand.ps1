function Invoke-GerberAdoConfigCommand {
    [CmdletBinding()]
    param()

    try {
        while ($true) {
            $choice = Read-GerberAdoConfigChoice
            if ($choice -ne 'showMicrosoftHostedPools') { return }
            Set-GerberAdoShowMicrosoftHostedPool -Value (-not (Get-GerberAdoShowMicrosoftHostedPool))
        }
    } catch {
        if (Test-GerberMenuEscapeException -Exception $_.Exception) { return }
        Show-GerberTextBlock -Title '/ado config' -Text "Could not update the setting: $($_.Exception.Message)"
        try { $null = Wait-GerberContinue } catch {
            if (-not (Test-GerberMenuEscapeException -Exception $_.Exception)) { throw }
        }
    }
}

function Read-GerberAdoConfigChoice {
    [CmdletBinding()]
    param()

    Start-GerberScreen -Name '/ado config'
    Write-GerberScreenLine -Text '/ado config'
    Write-GerberScreenLine
    $state = if (Get-GerberAdoShowMicrosoftHostedPool) { 'shown' } else { 'hidden' }
    $menuItems = @(
        [pscustomobject]@{
            Number      = 1
            Label       = "Microsoft-hosted pools: $state"
            Value       = 'showMicrosoftHostedPools'
            PreviewText = 'Select to toggle whether Microsoft-hosted pools are listed by /ado agents list.'
        }
    )
    return Read-GerberNumberedMenuPrompt -Prompt 'Setting (Esc to go back)' -MenuItemList $menuItems
}
