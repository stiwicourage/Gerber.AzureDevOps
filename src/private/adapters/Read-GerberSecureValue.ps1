function Read-GerberSecureValue {
    param([string]$Prompt)
    return & $Gerber.UI.ReadSecureValue $Prompt
}
