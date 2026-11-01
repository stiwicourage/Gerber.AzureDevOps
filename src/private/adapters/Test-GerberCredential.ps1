function Test-GerberCredential {
    param([string]$Identifier)
    return & $Gerber.Secrets.Test (Get-AdoSecretPath -Identifier $Identifier)
}
