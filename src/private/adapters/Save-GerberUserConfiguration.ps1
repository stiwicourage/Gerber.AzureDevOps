function Save-GerberUserConfiguration {
    param([object]$Configuration)

    $null = Test-GerberAdoUserConfiguration -Configuration $Configuration -Path (Resolve-GerberUserConfigPath)
    & $Gerber.Configuration.Save $Configuration
}
