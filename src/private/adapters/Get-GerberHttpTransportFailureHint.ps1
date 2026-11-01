function Get-GerberHttpTransportFailureHint {
    param([System.Exception]$Exception)
    return & $Gerber.Http.GetTransportFailureHint $Exception
}
