function Initialize-AgentUpdateTestUi {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    if (-not $PSCmdlet.ShouldProcess('Synthetic flow UI', 'Initialize isolated UI mocks')) { return }
    Mock Get-GerberAgentUpdateConsoleMode { $false }
    Mock Set-GerberAgentUpdateConsoleMode {}
    Mock Write-GerberScreenLine {}
    Mock Read-GerberAgentUpdateCancellationKey { $null }
    Mock Show-GerberTextBlock {}
    Mock Wait-GerberContinue {}
}
