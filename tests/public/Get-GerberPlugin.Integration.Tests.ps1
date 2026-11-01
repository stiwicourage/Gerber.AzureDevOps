BeforeAll {
    $root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
    $manifestPath = Join-Path $root 'dist/Gerber.AzureDevOps/Gerber.AzureDevOps.psd1'
    $module = Import-Module $manifestPath -Force -PassThru
    $null = $module
}

Describe 'Get-GerberPlugin public API registration integration' {
    It 'exports the entry point with the project manifest GUID and API metadata' {
        $module.Guid.ToString('D') | Should -Be 'a468dee5-c7a0-43e4-ae88-bb19158fe679'
        $module.PrivateData.Gerber.ApiVersion | Should -Be '1'
        $module.PrivateData.Gerber.Namespace | Should -BeExactly 'ado'
        $module.ExportedFunctions.Keys | Should -Contain 'Get-GerberPlugin'
    }

    It 'provides public help describing passive registration and the runtime minimum' {
        $help = Get-Help 'Gerber.AzureDevOps\Get-GerberPlugin' -Full
        $help.Synopsis | Should -Match 'Plugin API v1'
        ($help.Description.Text -join ' ') | Should -Match 'Import and registration do not read configuration'
        ($help.AlertSet.Alert.Text -join ' ') | Should -Match 'PowerShell 7.4'
    }

    It 'retains module binding and the supplied API when executing the native REST report handler' {
        $script:configurationReads = 0
        $script:secretPaths = @()
        $api = [pscustomobject]@{
            Configuration = @{
                Read = {
                    $script:configurationReads++
                    return @{ ado = @{ defaultProfile = 'terminal'; profiles = @{
                        terminal = @{ projectUrl = 'https://dev.azure.com/terminal/TerminalProject' }
                    } } }
                }
                Save = { throw 'GET report must not save configuration.' }
            }
            Secrets = @{
                GetText = { param($Path) $script:secretPaths += ,$Path; 'synthetic-pat' }
                Test = { $true }
                Set = { throw 'GET report must not mutate secrets.' }
            }
            UI = @{
                StartScreen = {}
                WriteScreenLine = {}
                ShowTextBlock = {}
                WaitForContinue = {}
                WriteStyledPromptText = {}
                GetPromptColorPair = { [pscustomobject]@{ ForegroundColor = 'Gray'; BackgroundColor = 'Black' } }
                IsInteractive = { $false }
                IsEscapeException = { $false }
            }
            Http = @{
                GetConfiguration = { [pscustomobject]@{ ConnectionTimeoutSeconds = 5; OperationTimeoutSeconds = 15 } }
                IsTimeoutFailure = { $false }
                GetTransportFailureHint = { '' }
            }
        }
        Mock Invoke-RestMethod -ModuleName 'Gerber.AzureDevOps' {
            if ($Uri.AbsolutePath.EndsWith('/agents')) {
                return @{ value = @(@{ name = 'build-01'; version = '4.255.0'; status = 'online' }) }
            }
            return @{ value = @(@{ id = 1; name = 'Build Pool' }) }
        }
        $entryPoint = Get-Command Get-GerberPlugin -Module 'Gerber.AzureDevOps'
        $definition = & $entryPoint -Gerber $api
        $definition.Guid | Should -Be $module.Guid.ToString('D')
        $definition.Namespace | Should -BeExactly 'ado'
        $script:configurationReads | Should -Be 0
        $handler = ($definition.Commands | Where-Object Name -EQ 'list ado-agents').Handler
        @(& $handler ([pscustomobject]@{ Arguments = @() })) | Should -Be @($false)
        $script:configurationReads | Should -BeGreaterThan 0
        $script:secretPaths.Count | Should -BeGreaterThan 0
        $script:secretPaths[0] | Should -Be @('ado', 'terminal', 'pat')
        Should -Invoke Invoke-RestMethod -ModuleName 'Gerber.AzureDevOps' -Times 4
    }
}
