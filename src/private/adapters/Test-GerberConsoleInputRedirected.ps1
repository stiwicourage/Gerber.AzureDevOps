function Test-GerberConsoleInputRedirected {
    return -not (& $Gerber.UI.IsInteractive)
}
