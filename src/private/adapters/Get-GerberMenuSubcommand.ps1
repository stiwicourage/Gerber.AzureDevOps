function Get-GerberMenuSubcommand {
    param(
        [string]$CommandName,
        [pscustomobject]$Command,
        [System.Collections.IDictionary]$SubcommandTable,
        [switch]$AutoSelectFirstSuggestionOnSubmit
    )
    return & $Gerber.UI.ReadSubcommand $CommandName $Command $SubcommandTable ([bool]$AutoSelectFirstSuggestionOnSubmit)
}
