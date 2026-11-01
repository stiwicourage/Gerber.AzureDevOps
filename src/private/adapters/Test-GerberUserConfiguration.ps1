function Test-GerberUserConfiguration {
    param([object]$Configuration, [string]$Path)
    return Test-GerberAdoUserConfiguration -Configuration $Configuration -Path $Path
}

function Test-GerberUserConfigurationRootObject {
    param([object]$Configuration)
    return $Configuration -is [System.Collections.IDictionary] -or $Configuration -is [pscustomobject]
}
