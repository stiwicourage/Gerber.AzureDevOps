function Test-GerberHttpTimeoutFailure {
    param([System.Exception]$Exception)
    return & $Gerber.Http.IsTimeoutFailure $Exception
}
