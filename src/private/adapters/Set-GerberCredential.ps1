function Set-GerberCredential {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Identifier, [object]$Secret)
    if ($PSCmdlet.ShouldProcess($Identifier, 'Store plugin PAT')) {
        return & $Gerber.Secrets.Set (Get-AdoSecretPath -Identifier $Identifier) $Secret
    }
}
