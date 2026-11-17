function Get-GerberAdoPoolAgentList {
    [OutputType([object[]])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,

        [Parameter(Mandatory)]
        [string]$Pat,

        [Parameter(Mandatory)]
        [pscustomobject]$Pool,

        [switch]$IncludeAssignedRequest
    )

    $request = Get-GerberAdoPoolAgentRequest -Configuration $Configuration -Pool $Pool -IncludeAssignedRequest:$IncludeAssignedRequest
    return Get-GerberAdoPoolResourceList -Configuration $Configuration -Pat $Pat -RequestContext $request
}
