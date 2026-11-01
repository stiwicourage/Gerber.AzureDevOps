function ConvertTo-GerberPromptLineStyle {
    param([System.ConsoleColor]$ForegroundColor, [System.ConsoleColor]$BackgroundColor)
    return [pscustomobject]@{
        Mode = 'ColorPair'
        ForegroundColor = $ForegroundColor
        BackgroundColor = $BackgroundColor
    }
}
