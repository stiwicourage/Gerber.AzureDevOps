function Get-GerberAdoStoredPropertyName {
    param([System.Collections.IDictionary]$Map, [string]$PropertyName)
    if ($Map.Contains($PropertyName)) { return $PropertyName }
    foreach ($key in $Map.Keys) {
        if ([string]::Equals([string]$key, $PropertyName, [System.StringComparison]::OrdinalIgnoreCase)) {
            return [string]$key
        }
    }
    return $PropertyName
}
