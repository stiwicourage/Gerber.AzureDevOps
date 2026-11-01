function Write-GerberStyledPromptText {
    param([string]$Text, [pscustomobject]$Style)
    & $Gerber.UI.WriteStyledPromptText $Text $Style
}
