function Get-GerberAdoOptionalProperty {
    param([object]$InputObject, [string]$Name)
    if ($InputObject -is [System.Collections.IDictionary]) { return $InputObject[$Name] }
    if ($null -eq $InputObject) { return $null }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -ne $property) { return $property.Value }
    return $null
}

function Get-GerberAdoAgentWorkState {
    param([object]$Agent)
    $fields = @($Agent.PSObject.Properties.Name)
    if ($Agent -is [System.Collections.IDictionary]) { $fields = @($Agent.Keys) }
    if ('assignedRequest' -notin $fields) { return 'unknown' }
    if ($null -eq (Get-GerberAdoOptionalProperty $Agent 'assignedRequest')) { return 'idle' }
    return 'busy'
}

function Get-GerberAdoPendingUpdateText {
    param([object]$Agent)
    $pending = Get-GerberAdoOptionalProperty $Agent 'pendingUpdate'
    if ($null -eq $pending) { return 'unknown' }
    return Get-GerberAdoAgentPropertyText -Agent $pending -PropertyName 'currentState'
}

function ConvertTo-GerberAdoUpdateAgent {
    param([object]$Agent)
    return [pscustomobject]@{
        Id = Get-GerberAdoOptionalProperty $Agent 'id'
        Name = Get-GerberAdoAgentPropertyText $Agent 'name'
        Version = Get-GerberAdoAgentPropertyText $Agent 'version'
        Status = Get-GerberAdoAgentPropertyText $Agent 'status'
        OperatingSystem = Get-GerberAdoAgentOperatingSystemName (Get-GerberAdoAgentPropertyText $Agent 'osDescription')
        Enabled = Get-GerberAdoOptionalProperty $Agent 'enabled'
        WorkState = Get-GerberAdoAgentWorkState $Agent
        PendingUpdate = Get-GerberAdoPendingUpdateText $Agent
    }
}
