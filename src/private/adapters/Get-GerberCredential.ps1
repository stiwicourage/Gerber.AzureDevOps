function Get-GerberCredential {
    param([string]$Identifier)
    return & $Gerber.Secrets.GetText (Get-AdoSecretPath -Identifier $Identifier)
}
