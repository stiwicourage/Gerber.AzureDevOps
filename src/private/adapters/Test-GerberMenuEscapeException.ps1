function Test-GerberMenuEscapeException {
    param([System.Exception]$Exception)
    if (Test-GerberRootNavigationException -Exception $Exception) { return $true }
    return & $Gerber.UI.IsEscapeException $Exception
}

# A quick second Escape asks Core to return to the root menu; flows must unwind quietly.
function Test-GerberRootNavigationException {
    param([System.Exception]$Exception)
    if ($null -eq $Exception) { return $false }
    if ($Exception.Data.Contains('GerberRootNavigation')) { return [bool]$Exception.Data['GerberRootNavigation'] }
    return Test-GerberRootNavigationException -Exception $Exception.InnerException
}
