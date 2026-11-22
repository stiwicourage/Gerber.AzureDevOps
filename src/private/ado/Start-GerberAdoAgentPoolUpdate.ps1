function Start-GerberAdoAgentPoolUpdate {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param([pscustomobject]$Context, [pscustomobject]$Pool)
    if (-not $PSCmdlet.ShouldProcess("Pool $($Pool.Id): $($Pool.Name)", 'Request pool-wide agent refresh')) {
        return Get-GerberAdoAgentUpdateResult -Pool $Pool -State 'CancelledBeforeSend'
    }
    try {
        $request = Get-GerberAdoAgentRefreshRequest -Context $Context -Pool $Pool
        $responseStatus = 0
        $response = Invoke-RestMethod @request -StatusCodeVariable responseStatus
        return Get-GerberAdoAgentRefreshResponseResult -Pool $Pool -Status $responseStatus -Response $response -Pat $Context.Pat
    } catch {
        return Get-GerberAdoAgentUpdateResult -Pool $Pool -State 'OutcomeUnknown' -HttpStatus (Get-GerberAdoHttpStatusCode $_.Exception)
    }
}

function Get-GerberAdoAgentRefreshRequest {
    param([pscustomobject]$Context, [pscustomobject]$Pool)
    $request = Get-GerberAdoAgentRefreshTransportOptionSet
    $request.Method = 'Post'
    $request.Uri = Get-GerberAdoAgentRefreshUri -Configuration $Context.Configuration -Pool $Pool
    $request.Headers = Get-GerberAdoRequestHeader -Pat $Context.Pat
    $request.Headers.Accept = 'application/json'
    $request.ContentType = 'application/json; charset=utf-8'
    $request.Body = 'null'
    return $request
}

function Get-GerberAdoAgentRefreshUri {
    param([pscustomobject]$Configuration, [pscustomobject]$Pool)
    $version = $Configuration.PoolApiVersion
    if ($version -notmatch '-preview(?:\.\d+)?$') { $version += '-preview.1' }
    $uri = [uri]::new($Configuration.CollectionUri, "_apis/distributedtask/pools/$($Pool.Id)/messages")
    return Get-GerberAdoApiUri -BaseUri $uri -QueryParameterMap @{ 'api-version' = $version }
}

function Get-GerberAdoAgentRefreshTransportOptionSet {
    param()
    $http = Get-GerberHttpConfiguration
    return @{
        ConnectionTimeoutSeconds = $http.ConnectionTimeoutSeconds
        OperationTimeoutSeconds = $http.OperationTimeoutSeconds
        MaximumRetryCount = 0
        MaximumRedirection = 0
        SkipHttpErrorCheck = $true
        ErrorAction = 'Stop'
    }
}

function Get-GerberAdoAgentRefreshResponseResult {
    param([pscustomobject]$Pool, [int]$Status, [AllowNull()][object]$Response, [string]$Pat)
    $result = Get-GerberAdoAgentUpdateResult -Pool $Pool -State (Get-GerberAdoRefreshState $Status) -HttpStatus $Status
    if ($result.State -ne 'RequestFailed') { return $result }
    $message = Get-GerberAdoRefreshServerMessage -Response $Response -Pat $Pat
    if ($message) { $result.Message += " Server: $message" }
    return $result
}

function Get-GerberAdoRefreshState {
    param([int]$Status)
    if ($Status -ge 200 -and $Status -lt 300) { return 'RequestAccepted' }
    if ($Status -in @(400, 401, 403, 404, 405, 409, 410, 413, 415, 422, 429)) { return 'RequestFailed' }
    return 'OutcomeUnknown'
}

function Get-GerberAdoAgentUpdateResult {
    param([pscustomobject]$Pool, [string]$State, [int]$HttpStatus = 0)
    return [pscustomobject]@{
        PoolId = $Pool.Id
        PoolName = $Pool.Name
        PoolType = $Pool.PoolType
        State = $State
        HttpStatus = $HttpStatus
        Message = Get-GerberAdoRefreshMessage -State $State -HttpStatus $HttpStatus
    }
}

function Get-GerberAdoRefreshMessage {
    param([string]$State, [int]$HttpStatus)
    if ($HttpStatus -eq 401) { return 'Credential rejected; batch stopped. Check the configured PAT without sharing it.' }
    if ($HttpStatus -eq 403) { return 'Access denied. Check Agent Pools management permissions and the pool role for this profile.' }
    $messages = @{
        RequestAccepted = 'Request accepted; installation is asynchronous and is not verified.'
        RequestFailed = 'Request rejected. Check pool access and the HTTP status; no fallback or retry was sent.'
        OutcomeUnknown = 'Outcome unknown; the server may have received the request. Batch stopped; do not blindly retry.'
        NotAttempted = 'Not attempted because the batch stopped.'
        CancelledBeforeSend = 'Cancelled before sending.'
    }
    return $messages[$State]
}
