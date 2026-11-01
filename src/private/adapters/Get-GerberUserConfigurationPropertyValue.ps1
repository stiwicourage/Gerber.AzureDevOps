function Get-GerberUserConfigurationPropertyValue {
    param([object]$Configuration, [string]$PropertyName)

    if ($Configuration -is [System.Collections.IDictionary]) {
        $storedKey = Get-GerberAdoStoredPropertyName -Map $Configuration -PropertyName $PropertyName
        return $Configuration[$storedKey]
    }
    if ($null -ne $Configuration -and $Configuration.PSObject.Properties.Match($PropertyName).Count -gt 0) {
        return $Configuration.$PropertyName
    }
    return $null
}
