function Invoke-GerberAgentUpdateBatch {
    param([pscustomobject]$Context, [pscustomobject]$Plan)
    $originalMode = Get-GerberAgentUpdateConsoleMode
    try {
        Set-GerberAgentUpdateConsoleMode -Enabled $true -Confirm:$false
        Write-GerberScreenLine -Text 'Ctrl-C stops further requests after the current request completes; accepted requests cannot be recalled.'
        return Invoke-GerberAdoAgentUpdate -Context $Context -Plan $Plan `
            -OnResult { param($result) Write-GerberAgentUpdateReceipt $result } `
            -CancellationRequested { Test-GerberAgentUpdateCancellation }
    } finally {
        Complete-GerberAgentUpdateConsoleMode -OriginalMode $originalMode
    }
}

function Complete-GerberAgentUpdateConsoleMode {
    param([bool]$OriginalMode)
    try {
        # Consume queued control bytes before restoring native signal handling, including on the last pool.
        while ($null -ne (Read-GerberAgentUpdateCancellationKey)) {}
    } finally {
        Set-GerberAgentUpdateConsoleMode -Enabled $OriginalMode -Confirm:$false
    }
}

function Get-GerberAgentUpdateConsoleMode {
    param()
    return [Console]::TreatControlCAsInput
}

function Set-GerberAgentUpdateConsoleMode {
    [CmdletBinding(SupportsShouldProcess)]
    param([bool]$Enabled)
    if ($PSCmdlet.ShouldProcess('Interactive batch console', 'Set scoped Ctrl-C input mode')) {
        [Console]::TreatControlCAsInput = $Enabled
    }
}

function Read-GerberAgentUpdateCancellationKey {
    param()
    if (-not (Test-GerberAgentUpdateKeyAvailable)) { return $null }
    return (Read-GerberAgentUpdateKey).KeyChar
}

function Test-GerberAgentUpdateKeyAvailable {
    param()
    return [Console]::KeyAvailable
}

function Read-GerberAgentUpdateKey {
    param()
    return [Console]::ReadKey($true)
}

function Test-GerberAgentUpdateCancellation {
    param()
    while ($null -ne ($key = Read-GerberAgentUpdateCancellationKey)) {
        if ($key -in @([char]3, [char]27)) { return $true }
    }
    return $false
}
