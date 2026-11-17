# Extends only the test-owned HTTP boundary; never delegates to a live transport.
function Get-AdoTerminalRestMethodShim {
    param()
    # Let PowerShell own its native parameter contract instead of maintaining a partial replica.
    $metadata = [System.Management.Automation.CommandMetadata]::new((Get-Command Invoke-RestMethod -CommandType Cmdlet))
    $binding = [System.Management.Automation.ProxyCommand]::GetCmdletBindingAttribute($metadata)
    $parameters = [System.Management.Automation.ProxyCommand]::GetParamBlock($metadata)
    return [scriptblock]::Create("$binding param($parameters) Invoke-AdoTerminalRestMethod -Request `$PSBoundParameters")
}

function Invoke-AdoTerminalRestMethod {
    param([System.Collections.IDictionary]$Request)
    $resolution = Get-AdoTerminalHttpResolution -Request $Request
    Write-GerberTerminalHttpResponseHeader -VariableName $Request['ResponseHeadersVariable'] -MatchingEntry $resolution.MatchingEntry
    if ($Request['StatusCodeVariable']) {
        Set-AdoTerminalResponseStatus -Name $Request['StatusCodeVariable'] -Entry $resolution.MatchingEntry
    }
    Wait-AdoTerminalRefreshFixture -Entry $resolution.MatchingEntry
    return Resolve-GerberTerminalHttpFixtureResponse -Fixture $resolution.Fixture -MatchingEntry $resolution.MatchingEntry
}

function Wait-AdoTerminalRefreshFixture {
    param([AllowNull()][object]$Entry)
    if ($null -eq $Entry) { return }
    if (-not $Entry.ContainsKey('holdForInterrupt')) { return }
    if (-not $Entry.holdForInterrupt) { return }
    Write-Information -MessageData 'Synthetic refresh in progress' -InformationAction Continue
    Start-Sleep -Seconds 3
}

function Set-AdoTerminalResponseStatus {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Name, [AllowNull()][object]$Entry)
    if (-not $PSCmdlet.ShouldProcess('Synthetic transport caller', 'Set HTTP status')) { return }
    # Resolve the active callback frame, not a separately imported module instance.
    $frame = Get-PSCallStack | Where-Object FunctionName -EQ 'Start-GerberAdoAgentPoolUpdate' | Select-Object -First 1
    $frame.GetFrameVariables()[$Name].Value = Get-AdoTerminalResponseStatus -Entry $Entry
}

function Get-AdoTerminalHttpResolution {
    param([System.Collections.IDictionary]$Request)
    return Resolve-GerberTerminalHttpInvocation -RequestContext ([pscustomobject]@{
        Method = $(if ($Request['Method']) { [string]$Request['Method'] } else { 'Get' })
        Uri = $Request['Uri'].AbsoluteUri
        Headers = ConvertTo-GerberTerminalSafeHeaderMap -Headers $Request['Headers']
        Body = ConvertTo-GerberTerminalHttpBodyMap -Body $Request['Body']
        Transport = 'Invoke-RestMethod'
        ConnectionTimeoutSeconds = $Request['ConnectionTimeoutSeconds']
        OperationTimeoutSeconds = $Request['OperationTimeoutSeconds']
        ContentType = $Request['ContentType']
    })
}

function Get-AdoTerminalResponseStatus {
    param([AllowNull()][object]$Entry)
    if ($null -eq $Entry) { return 0 }
    if ($Entry.ContainsKey('statusCode')) { return [int]$Entry.statusCode }
    return 200
}
