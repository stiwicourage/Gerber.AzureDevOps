function Get-AdoSecretPath {
    param([string]$Identifier)
    if ($Identifier -notmatch '\Agerber:ado:([^:]*):pat\z') {
        throw [System.ArgumentException]::new('Expected an Azure DevOps profile PAT logical identifier.')
    }
    return @('ado', [uri]::UnescapeDataString($Matches[1]), 'pat')
}
