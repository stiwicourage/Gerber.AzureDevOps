function Get-GerberAdoAgentOperatingSystemName {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Description
    )

    if ([string]::IsNullOrWhiteSpace($Description)) {
        return 'unknown'
    }

    $knownNameMap = [ordered]@{
        'windows' = 'Windows'
        'linux' = 'Linux'
        'darwin|mac\s?os' = 'macOS'
    }
    foreach ($pattern in $knownNameMap.Keys) {
        if ($Description -match $pattern) {
            return $knownNameMap[$pattern]
        }
    }

    return $Description.Trim()
}
