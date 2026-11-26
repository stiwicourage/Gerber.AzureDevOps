BeforeAll {
    . (Join-Path $PSScriptRoot '../TestHelpers/GerberReportHandlerIntegrationTestSupport.ps1')
    $root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
    $manifestPath = Join-Path $root 'dist/Gerber.AzureDevOps/Gerber.AzureDevOps.psd1'
    $module = Import-Module $manifestPath -Force -PassThru
    $null = $module
}

Describe 'Get-GerberPlugin public API registration integration' {
    It 'binds the update callback without activation side effects and rejects piped use before HTTP' {
        $api = [pscustomobject]@{
            UI = @{ IsInteractive = { $false } }
            Configuration = @{ Read = { throw 'Registration must be passive.' } }
            Secrets = @{ GetText = { throw 'Must not read secrets.' } }
        }
        Mock Invoke-RestMethod -ModuleName 'Gerber.AzureDevOps' { throw 'No HTTP allowed.' }
        $definition = Get-GerberPlugin -Gerber $api
        $handler = ($definition.Commands | Where-Object Name -EQ 'ado agents update').Handler
        { & $handler ([pscustomobject]@{ Arguments = @() }) } | Should -Throw '*interactive*'
        Should -Invoke Invoke-RestMethod -ModuleName 'Gerber.AzureDevOps' -Times 0
    }

    It 'exports the entry point with the project manifest GUID and API metadata' {
        $module.Guid.ToString('D') | Should -Be 'a468dee5-c7a0-43e4-ae88-bb19158fe679'
        $module.PrivateData.Gerber.ApiVersion | Should -Be '1'
        $module.PrivateData.Gerber.Conformance | Should -Contain 'RootNavigation'
        $module.PrivateData.Gerber.Namespace | Should -BeExactly 'ado'
        $module.ExportedFunctions.Keys | Should -Contain 'Get-GerberPlugin'
    }

    It 'provides public help describing passive registration and the runtime minimum' {
        $help = Get-Help 'Gerber.AzureDevOps\Get-GerberPlugin' -Full
        $help.Synopsis | Should -Match 'Plugin API v1'
        ($help.Description.Text -join ' ') | Should -Match 'Import and registration do not read configuration'
        ($help.AlertSet.Alert.Text -join ' ') | Should -Match 'PowerShell 7.4'
    }

    Context 'Bound native report callback' {
        BeforeEach {
            $script:configurationReads = 0
            $script:secretPaths = @()
            $script:reportApi = Get-GerberReportHandlerTestApi
            Mock Invoke-RestMethod -ModuleName 'Gerber.AzureDevOps' {
                if ($Uri.AbsolutePath.EndsWith('/agents')) {
                    return @{ value = @(@{ name = 'build-01'; version = '4.255.0'; status = 'online' }) }
                }
                return @{ value = @(@{ id = 1; name = 'Build Pool' }) }
            }
        }

        It 'retains module binding and the supplied API when executing the native REST report handler' {
            $entryPoint = Get-Command Get-GerberPlugin -Module 'Gerber.AzureDevOps'
            $definition = & $entryPoint -Gerber $script:reportApi
            $definition.Guid | Should -Be $module.Guid.ToString('D')
            $definition.Namespace | Should -BeExactly 'ado'
            $script:configurationReads | Should -Be 0
            $handler = ($definition.Commands | Where-Object Name -EQ 'ado agents list').Handler
            @(& $handler ([pscustomobject]@{ Arguments = @() })) | Should -Be @($false)
            $script:configurationReads | Should -BeGreaterThan 0
            $script:secretPaths.Count | Should -BeGreaterThan 0
            $script:secretPaths[0] | Should -Be @('ado', 'terminal', 'pat')
            Should -Invoke Invoke-RestMethod -ModuleName 'Gerber.AzureDevOps' -Times 4
        }
    }
}
