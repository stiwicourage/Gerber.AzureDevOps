function ConvertTo-GerberSecretText {
    param([object]$Value)
    if ($Value -is [securestring]) {
        return [System.Net.NetworkCredential]::new('', $Value).Password
    }
    return [string]$Value
}
