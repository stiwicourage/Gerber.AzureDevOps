function Get-GerberReportHandlerTestConfigurationApi {
    param()
    return @{
        Read = {
            $script:configurationReads++
            return @{ ado = @{ defaultProfile = 'terminal'; profiles = @{
                terminal = @{ projectUrl = 'https://dev.azure.com/terminal/TerminalProject' }
            } } }
        }
        Save = { throw 'GET report must not save configuration.' }
    }
}

function Get-GerberReportHandlerTestSecretsApi {
    param()
    return @{
        GetText = { param($Path) $script:secretPaths += ,$Path; 'synthetic-pat' }
        Test = { $true }
        Set = { throw 'GET report must not mutate secrets.' }
    }
}

function Get-GerberReportHandlerTestUiApi {
    param()
    return @{
        StartScreen = {}
        WriteScreenLine = {}
        ShowTextBlock = {}
        WaitForContinue = {}
        WriteStyledPromptText = {}
        GetPromptColorPair = { [pscustomobject]@{ ForegroundColor = 'Gray'; BackgroundColor = 'Black' } }
        IsInteractive = { $false }
        IsEscapeException = { $false }
    }
}

function Get-GerberReportHandlerTestHttpApi {
    param()
    return @{
        GetConfiguration = { [pscustomobject]@{ ConnectionTimeoutSeconds = 5; OperationTimeoutSeconds = 15 } }
        IsTimeoutFailure = { $false }
        GetTransportFailureHint = { '' }
    }
}

function Get-GerberReportHandlerTestApi {
    param()
    return [pscustomobject]@{
        Configuration = Get-GerberReportHandlerTestConfigurationApi
        Secrets = Get-GerberReportHandlerTestSecretsApi
        UI = Get-GerberReportHandlerTestUiApi
        Http = Get-GerberReportHandlerTestHttpApi
    }
}
