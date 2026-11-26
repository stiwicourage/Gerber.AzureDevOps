function Test-GerberMenuEscapeException {
    param([System.Exception]$Exception)
    # A quick second Escape asks Core to return to the root menu. Core owns that navigation,
    # so it must escape every flow's catch block instead of being handled as a local back.
    if (Test-GerberRootNavigationException -Exception $Exception) { throw $Exception }
    return & $Gerber.UI.IsEscapeException $Exception
}

function Test-GerberRootNavigationException {
    param([System.Exception]$Exception)
    if ($null -eq $Exception) { return $false }
    if ($Exception.Data.Contains('GerberRootNavigation')) { return [bool]$Exception.Data['GerberRootNavigation'] }
    return Test-GerberRootNavigationException -Exception $Exception.InnerException
}
