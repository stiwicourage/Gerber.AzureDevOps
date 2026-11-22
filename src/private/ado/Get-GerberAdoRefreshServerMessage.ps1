function Get-GerberAdoRefreshServerMessage {
    param([AllowNull()][object]$Response, [string]$Pat)
    $message = Get-GerberAdoRefreshResponseMessage -Response $Response
    if ([string]::IsNullOrWhiteSpace($message)) { return '' }
    $message = Protect-GerberAdoRefreshMessage -Message $message -Pat $Pat
    $message = [regex]::Replace($message, '[\p{Cc}\p{Cf}\p{Zl}\p{Zp}\s]+', ' ').Trim()
    if ($message.Length -gt 160) { return $message.Substring(0, 157) + '...' }
    return $message
}

function Get-GerberAdoRefreshResponseMessage {
    param([AllowNull()][object]$Response)
    $Response = ConvertFrom-GerberAdoRefreshResponse -Response $Response
    if ($null -eq $Response) { return '' }
    $message = if ($Response -is [System.Collections.IDictionary]) { $Response['message'] }
    else { $Response.PSObject.Properties.Match('message') | ForEach-Object Value }
    if ($message -isnot [string]) { return '' }
    return $message
}

function ConvertFrom-GerberAdoRefreshResponse {
    param([AllowNull()][object]$Response)
    if ($Response -isnot [string]) { return $Response }
    try { return ConvertFrom-Json -InputObject $Response -ErrorAction Stop }
    catch { return $null }
}

function Protect-GerberAdoRefreshMessage {
    param([string]$Message, [string]$Pat)
    $credential = (Get-GerberAdoRequestHeader -Pat $Pat).Authorization.Substring(6)
    $secrets = @($Pat, [uri]::EscapeDataString($Pat), $credential) | Sort-Object Length -Descending
    foreach ($secret in $secrets) { $Message = $Message.Replace($secret, '[redacted]') }
    $Message = [regex]::Replace($Message, '(?i)\b(?:Basic|Bearer)\s+[a-z0-9._~+/%=-]+', '[redacted]')
    $field = '(?i)\b(?:authorization|pat|password|access[_-]?token|token)\s*[:=]\s*("[^"]*"|''[^'']*''|[^\s,;]+)'
    return [regex]::Replace($Message, $field, '[redacted]')
}
