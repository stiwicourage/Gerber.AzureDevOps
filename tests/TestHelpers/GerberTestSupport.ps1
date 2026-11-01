function Export-AdoTestSourceFunction {
    param([System.IO.FileInfo]$File)
    foreach ($match in [regex]::Matches((Get-Content -LiteralPath $File.FullName -Raw), '(?m)^function\s+([\w-]+)')) {
        $name = $match.Groups[1].Value
        Set-Item -Path "function:global:$name" -Value (Get-Command $name -CommandType Function).ScriptBlock
    }
}

function Import-GerberSource {
    [CmdletBinding()]
    param([string]$StartPath)
    $null = $StartPath
    $root = Join-Path $PSScriptRoot '../../src'
    foreach ($file in (Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.ps1' | Sort-Object FullName)) {
        . $file.FullName
        Export-AdoTestSourceFunction -File $file
    }
    $script:Gerber = Get-AdoUnitApiFixture
}

function Get-AdoUnitApiFixture {
            return [pscustomobject]@{
                UI = @{
                    StartScreen = {}
                    WriteScreenLine = {}
                    ShowTextBlock = {}
                    ShowMenuError = {}
                    WritePromptTrace = {}
                    WriteStyledPromptText = {}
                    WriteProgressBar = {}
                    WaitForContinue = {}
                    IsInteractive = { $false }
                    GetPromptColorPair = { [pscustomobject]@{ ForegroundColor = 'Gray'; BackgroundColor = 'Black' } }
                    GetEscapeException = {
                        $exception = [System.InvalidOperationException]::new('Go back to the previous Gerber menu.')
                        $exception.Data['GerberMenuEscape'] = $true
                        return $exception
                    }
                    IsEscapeException = {
                        param($Exception)
                        while ($null -ne $Exception) {
                            if ($Exception.Data.Contains('GerberMenuEscape')) {
                                return [bool]$Exception.Data['GerberMenuEscape']
                            }
                            $Exception = $Exception.InnerException
                        }
                        return $false
                    }
                }
                Http = @{
                    GetConfiguration = { [pscustomobject]@{ ConnectionTimeoutSeconds = 5; OperationTimeoutSeconds = 15 } }
                    GetTransportFailureHint = {
                        param($Exception)
                        if ($Exception -is [System.Threading.Tasks.TaskCanceledException]) { return 'Try again in a moment.' }
                        return ''
                    }
                    IsTimeoutFailure = { param($Exception) $Exception -is [System.Threading.Tasks.TaskCanceledException] }
                }
            }
}
