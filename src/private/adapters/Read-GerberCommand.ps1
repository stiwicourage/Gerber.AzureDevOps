function Read-GerberCommand {
    [CmdletBinding()]
    param(
        [string]$Prompt = [char]0x276F,
        [string]$SuggestionMode = 'Root',
        [string]$InputMode = 'Buffered',
        [pscustomobject]$PromptContext = (ConvertTo-GerberCommandPromptContext),
        [bool]$TrimResult = $true
    )
    return & $Gerber.UI.ReadCommand $Prompt $SuggestionMode $InputMode $PromptContext $TrimResult
}
