function Read-GerberNumberedMenuPrompt {
    param([string]$Prompt, [string]$ScreenTitle, [string]$ScreenText, [object[]]$MenuItemList)
    return & $Gerber.UI.ReadNumberedMenuPrompt $Prompt $ScreenTitle $ScreenText $MenuItemList
}
