function Write-GerberPromptTrace {
    param([string]$EventName, [hashtable]$Data)
    & $Gerber.UI.WritePromptTrace $EventName $Data
}
