function Write-GerberProgressBar {
    param([int]$Current, [int]$Total, [string]$Prefix, [switch]$OverwritePreviousRender)
    & $Gerber.UI.WriteProgressBar $Current $Total $Prefix $OverwritePreviousRender
}
