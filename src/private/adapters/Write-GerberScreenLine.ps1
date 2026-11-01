function Write-GerberScreenLine {
    param([string]$Text = '')
    & $Gerber.UI.WriteScreenLine $Text
}
