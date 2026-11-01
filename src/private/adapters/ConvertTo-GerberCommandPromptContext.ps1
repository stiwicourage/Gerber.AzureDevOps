function ConvertTo-GerberCommandPromptContext {
    param(
        [string]$SuggestionCommandName,
        [System.Collections.IDictionary]$SubcommandTable,
        [object[]]$StaticSuggestionList = @(),
        [string]$InitialBuffer = '',
        [int]$InitialCursorIndex = -1,
        [string]$PromptHintText,
        [string]$EmptyStateHintText,
        [bool]$AutoSelectFirstSuggestionOnSubmit = $false
    )
    return [pscustomobject]@{
        SuggestionCommandName = $SuggestionCommandName
        SubcommandTable = $SubcommandTable
        StaticSuggestionList = @($StaticSuggestionList)
        InitialBuffer = $InitialBuffer
        InitialCursorIndex = $InitialCursorIndex
        PromptHintText = $PromptHintText
        EmptyStateHintText = $EmptyStateHintText
        AutoSelectFirstSuggestionOnSubmit = $AutoSelectFirstSuggestionOnSubmit
    }
}
