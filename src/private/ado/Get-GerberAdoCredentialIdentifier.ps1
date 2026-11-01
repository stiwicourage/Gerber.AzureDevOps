function Get-GerberAdoCredentialIdentifier {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName
    )

    return 'gerber:ado:{0}:pat' -f [uri]::EscapeDataString($ProfileName.ToLowerInvariant())
}
