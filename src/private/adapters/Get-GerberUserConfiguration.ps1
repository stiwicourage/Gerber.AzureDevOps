function Get-GerberUserConfiguration {
    $configuration = & $Gerber.Configuration.Read
    if ($null -eq $configuration) {
        return [ordered]@{}
    }
    $null = Test-GerberAdoUserConfiguration -Configuration $configuration -Path (Resolve-GerberUserConfigPath)
    return $configuration
}
