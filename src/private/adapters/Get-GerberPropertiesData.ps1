function Get-GerberPropertiesData {
    return Get-Content -LiteralPath (Get-GerberPropertiesPath) -Raw | ConvertFrom-Json -AsHashtable
}

function Get-GerberPropertiesPath {
    foreach ($candidate in @(
        (Join-Path $PSScriptRoot 'resources/Properties.json')
        (Join-Path $PSScriptRoot '../../resources/Properties.json')
    )) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return [System.IO.Path]::GetFullPath($candidate)
        }
    }
    throw [System.IO.FileNotFoundException]::new('Azure DevOps defaults Properties.json was not found.')
}
