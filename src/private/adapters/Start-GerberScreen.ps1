function Start-GerberScreen {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Name)
    if ($PSCmdlet.ShouldProcess($Name, 'Start screen')) { & $Gerber.UI.StartScreen $Name }
}
