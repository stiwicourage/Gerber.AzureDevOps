function Get-GerberAdoPoolList {
    [OutputType([object[]])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,

        [Parameter(Mandatory)]
        [string]$Pat,

        [Parameter(Mandatory)]
        [string]$PoolType
    )

    $request = Get-GerberAdoPoolListRequest -Configuration $Configuration -PoolType $PoolType
    return Get-GerberAdoPoolResourceList -Configuration $Configuration -Pat $Pat -RequestContext $request
}
