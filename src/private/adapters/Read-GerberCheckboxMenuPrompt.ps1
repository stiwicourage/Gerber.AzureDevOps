function Read-GerberCheckboxMenuPrompt {
    param([pscustomobject]$PromptRequest)
    return & $Gerber.UI.ReadCheckboxMenuPrompt $PromptRequest
}
