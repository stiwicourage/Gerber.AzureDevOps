# Lifecycle acceptance uses the actual built Core dependency and registry boundary,
# not an injected API or private Core source. Module-session probes are test-owned.
BeforeAll {
    $root = Split-Path -Parent $PSScriptRoot
    $script:lifecycleOriginalModulePath = $env:PSModulePath
    $script:lifecycleOriginalConfigPath = $env:GERBER_CONFIG_PATH
    $pluginDist = Join-Path $root 'dist'
    $coreManifest = Join-Path $root '../GerberCore/dist/Gerber/Gerber.psd1'
    $env:PSModulePath = @($pluginDist, (Join-Path $root '../GerberCore/dist'), $env:PSModulePath) -join [IO.Path]::PathSeparator
    $env:GERBER_CONFIG_PATH = Join-Path $TestDrive 'import/GerberCore.json'
    $script:core = Import-Module $coreManifest -Force -PassThru
    $script:pluginId = 'a468dee5-c7a0-43e4-ae88-bb19158fe679'
}

AfterAll {
    $env:PSModulePath = $script:lifecycleOriginalModulePath
    $env:GERBER_CONFIG_PATH = $script:lifecycleOriginalConfigPath
}

Describe 'Required dependency import versus plugin activation' {
    It 'imports the declared dependency without configuration, credentials or registration operations' {
        $dependency = Get-Module 'Gerber.AzureDevOps'
        $dependency.Guid.ToString('D') | Should -Be $pluginId
        Test-Path -LiteralPath $env:GERBER_CONFIG_PATH | Should -BeFalse
        Test-Path -LiteralPath (Join-Path (Split-Path $env:GERBER_CONFIG_PATH) 'Gerber.AzureDevOps.json') | Should -BeFalse
        $state = & $core {
            [pscustomobject]@{
                Registry = Get-Variable GerberCommandRegistryState -Scope Script -ValueOnly -ErrorAction SilentlyContinue
                Credentials = Get-Variable GerberCredentialStore -Scope Script -ValueOnly -ErrorAction SilentlyContinue
            }
        }
        $state.Registry | Should -BeNullOrEmpty
        $state.Credentials | Should -BeNullOrEmpty
    }

    It 'keeps an imported <Decision> dependency inactive and product paths unavailable' -ForEach @(
        @{ Decision = 'unknown'; Plugins = @{}; Approval = 'Unknown' }
        @{ Decision = 'declined'; Plugins = @{ declined = @('a468dee5-c7a0-43e4-ae88-bb19158fe679') }; Approval = 'Declined' }
        @{ Decision = 'disabled'; Plugins = @{
            approved = @('a468dee5-c7a0-43e4-ae88-bb19158fe679')
            associated = @{ 'a468dee5-c7a0-43e4-ae88-bb19158fe679' = @{ enabled = $false } }
        }; Approval = 'Approved' }
    ) {
        $env:GERBER_CONFIG_PATH = Join-Path $TestDrive "$Decision/GerberCore.json"
        $null = New-Item -ItemType Directory -Path (Split-Path $env:GERBER_CONFIG_PATH) -Force
        @{ schemaVersion = 1; plugins = $Plugins } | ConvertTo-Json -Depth 8 |
            Set-Content -LiteralPath $env:GERBER_CONFIG_PATH
        Mock Test-GerberInteractivePromptAvailable { $false } -ModuleName Gerber
        Mock Invoke-RestMethod { throw 'Passive lifecycle must not call REST.' } -ModuleName 'Gerber.AzureDevOps'
        Mock Get-GerberCredential { throw 'Passive lifecycle must not read credentials.' } -ModuleName Gerber

        $snapshot = & $core {
            param($PluginDist)
            Clear-GerberCommandRegistry
            $null = Initialize-GerberCommandRegistry -PluginModulePathList @($PluginDist)
            [pscustomobject]@{
                Resolution = Resolve-GerberCommand -InputText '/repository create'
                Inventory = @(Get-GerberPluginInventory -PluginModulePathList @($PluginDist))
                ProductCommands = @(Get-GerberCommandRegistry | Where-Object OwnerName -EQ 'Gerber.AzureDevOps')
            }
        } $pluginDist

        Get-Module 'Gerber.AzureDevOps' | Should -Not -BeNullOrEmpty
        $snapshot.Resolution.IsValid | Should -BeFalse
        $snapshot.ProductCommands.Count | Should -Be 0
        $entry = $snapshot.Inventory | Where-Object Guid -EQ $pluginId
        $entry.ApprovalStatus | Should -Be $Approval
        $entry.Loaded | Should -BeFalse
        $entry.RegisteredCommandList.Count | Should -Be 0
        Test-Path -LiteralPath (Join-Path (Split-Path $env:GERBER_CONFIG_PATH) 'Gerber.AzureDevOps.json') | Should -BeFalse
        Should -Invoke Invoke-RestMethod -ModuleName 'Gerber.AzureDevOps' -Times 0
        Should -Invoke Get-GerberCredential -ModuleName Gerber -Times 0
    }

    It 'registers the approved enabled dependency once without running product operations' {
        $env:GERBER_CONFIG_PATH = Join-Path $TestDrive 'approved/GerberCore.json'
        $null = New-Item -ItemType Directory -Path (Split-Path $env:GERBER_CONFIG_PATH) -Force
        @{ schemaVersion = 1; plugins = @{ approved = @($pluginId) } } |
            ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $env:GERBER_CONFIG_PATH
        Mock Invoke-RestMethod { throw 'Registration must not call REST.' } -ModuleName 'Gerber.AzureDevOps'
        Mock Get-GerberCredential { throw 'Registration must not read credentials.' } -ModuleName Gerber
        # Retain operation spies on the actual already-imported dependency.
        # Normal forced-import callback binding is covered by CommandResolution integration.
        Mock Import-Module { Get-Module 'Gerber.AzureDevOps' } -ModuleName Gerber -ParameterFilter {
            [string]$Name -like '*Gerber.AzureDevOps*'
        }
        $snapshot = & $core {
            param($PluginDist)
            Clear-GerberCommandRegistry
            $null = Initialize-GerberCommandRegistry -PluginModulePathList @($PluginDist)
            $first = @(Get-GerberCommandRegistry | Where-Object OwnerName -EQ 'Gerber.AzureDevOps')
            $null = Initialize-GerberCommandRegistry -PluginModulePathList @($PluginDist)
            [pscustomobject]@{
                First = $first
                Second = @(Get-GerberCommandRegistry | Where-Object OwnerName -EQ 'Gerber.AzureDevOps')
                Inventory = @(Get-GerberPluginInventory -PluginModulePathList @($PluginDist))
            }
        } $pluginDist
        $snapshot.First.Count | Should -Be 9
        $snapshot.Second.Name | Should -Be $snapshot.First.Name
        @($snapshot.Second.Name | Select-Object -Unique).Count | Should -Be 9
        ($snapshot.Inventory | Where-Object Guid -EQ $pluginId).Loaded | Should -BeTrue
        Test-Path -LiteralPath (Join-Path (Split-Path $env:GERBER_CONFIG_PATH) 'Gerber.AzureDevOps.json') | Should -BeFalse
        Should -Invoke Invoke-RestMethod -ModuleName 'Gerber.AzureDevOps' -Times 0
        Should -Invoke Get-GerberCredential -ModuleName Gerber -Times 0
    }
}
