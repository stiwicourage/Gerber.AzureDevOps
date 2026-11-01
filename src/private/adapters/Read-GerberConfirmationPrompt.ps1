function Read-GerberConfirmationPrompt {
    param([string]$Prompt, [string]$ScreenTitle, [string]$ScreenText, [pscustomobject]$PromptOptionSet)
    return & $Gerber.UI.ReadConfirmationPrompt $Prompt $ScreenTitle $ScreenText $PromptOptionSet
}
