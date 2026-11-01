function Test-GerberMenuEscapeException {
    param([System.Exception]$Exception)
    return & $Gerber.UI.IsEscapeException $Exception
}
