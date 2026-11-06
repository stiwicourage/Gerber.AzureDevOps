function New-AdoModuleHandler {
    [CmdletBinding(SupportsShouldProcess)]
    param([pscustomobject]$Gerber, [string]$HandlerName)
    $null = $Gerber
    if (-not $PSCmdlet.ShouldProcess($HandlerName, 'Create module-bound handler')) { return }

    $invocation = [scriptblock]::Create("param(`$Gerber, `$Command) Invoke-AdoCommandHandler '$HandlerName' `$Command")
    $module = $ExecutionContext.SessionState.Module
    if ($null -ne $module) {
        $invocation = $module.NewBoundScriptBlock($invocation)
    }
    return {
        param($Command)
        & $invocation $Gerber $Command
    }.GetNewClosure()
}

function Invoke-AdoCommandHandler {
    param([string]$HandlerName, [pscustomobject]$Command)

    if ($HandlerName -in @('Show-GerberRepositoryCreateView', 'Show-GerberPipelinesTagsView')) {
        $null = & $HandlerName -Command $Command
    } else {
        $null = & $HandlerName
    }
    return $false
}
