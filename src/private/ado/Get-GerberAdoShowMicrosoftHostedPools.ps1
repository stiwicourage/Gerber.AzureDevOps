function Get-GerberAdoShowMicrosoftHostedPools {
    [OutputType([bool])]
    [CmdletBinding()]
    param()

    $configuration = Get-GerberUserConfiguration
    $adoConfiguration = Get-GerberUserConfigurationPropertyValue -Configuration $configuration -PropertyName 'ado'
    $settings = Get-GerberUserConfigurationPropertyValue -Configuration $adoConfiguration -PropertyName 'settings'
    $value = Get-GerberUserConfigurationPropertyValue -Configuration $settings -PropertyName 'showMicrosoftHostedPools'
    return $value -ne $false
}
