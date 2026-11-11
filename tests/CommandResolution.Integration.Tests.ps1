# Routing spans built Core registry/resolver and the built product module.
# No private Core source is loaded; the module-session probe is test-owned.
BeforeAll {
    $root = Split-Path -Parent $PSScriptRoot
    $coreDist = Join-Path $root '../GerberCore/dist'
    $originalModulePath = $env:PSModulePath
    $script:originalConfigPath = $env:GERBER_CONFIG_PATH
    $env:PSModulePath = @((Join-Path $root 'dist'), $coreDist, $originalModulePath) -join [IO.Path]::PathSeparator
    $env:GERBER_CONFIG_PATH = Join-Path $TestDrive 'GerberCore.json'
    @{ schemaVersion = 1; plugins = @{ approved = @('a468dee5-c7a0-43e4-ae88-bb19158fe679') } } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $env:GERBER_CONFIG_PATH
    $core = Import-Module (Join-Path $coreDist 'Gerber/Gerber.psd1') -Force -PassThru
    & $core {
        param($PluginRoot)
        Clear-GerberCommandRegistry
        $null = Initialize-GerberCommandRegistry -PluginModulePathList @($PluginRoot)
    } (Join-Path $root 'dist')
}

AfterAll {
    $env:PSModulePath = $originalModulePath
    $env:GERBER_CONFIG_PATH = $script:originalConfigPath
}

Describe 'Extracted product command routing' {
    It 'resolves /<Path> under the ado namespace root with its arguments' -ForEach @(
        @{ Path = 'ado list agents'; Root = 'ado'; Arguments = @('list', 'agents') }
        @{ Path = 'ado list team-members'; Root = 'ado'; Arguments = @('list', 'team-members') }
        @{ Path = 'ado branch find'; Root = 'ado'; Arguments = @('branch', 'find') }
        @{ Path = 'ado branch set-default'; Root = 'ado'; Arguments = @('branch', 'set-default') }
        @{ Path = 'ado branch set-searchable'; Root = 'ado'; Arguments = @('branch', 'set-searchable') }
        @{ Path = 'ado repository create'; Root = 'ado'; Arguments = @('repository', 'create') }
        @{ Path = 'ado pipelines tags'; Root = 'ado'; Arguments = @('pipelines', 'tags') }
        @{ Path = 'ado pipelines tags delete'; Root = 'ado'; Arguments = @('pipelines', 'tags', 'delete') }
        @{ Path = 'ado pipelines tags update'; Root = 'ado'; Arguments = @('pipelines', 'tags', 'update') }
    ) {
        $resolved = & $core { param($InputText) Resolve-GerberCommand -InputText $InputText } "/$Path"
        $resolved.IsValid | Should -BeTrue
        $resolved.Name | Should -Be $Root
        $resolved.Arguments | Should -Be $Arguments
    }

    It 'preserves sorted suggestions, descriptions and absence of template subcommands' {
        $snapshot = & $core {
            [pscustomobject]@{
                Search = Resolve-GerberCommand -InputText ado
                Tags = Resolve-GerberCommand -InputText '/ado pipelines tags'
                Create = Resolve-GerberCommand -InputText '/ado repository create'
                Branch = Resolve-GerberCommand -InputText '/ado branch'
            }
        }
        $snapshot.Search.Suggestions.DisplayText | Should -Be @('/ado branch find', '/ado branch set-default', '/ado branch set-searchable', '/ado list agents', '/ado list team-members', '/ado pipelines tags delete', '/ado pipelines tags update', '/ado repository create')
        $snapshot.Tags.Suggestions.DisplayText | Should -Be @('/ado pipelines tags delete', '/ado pipelines tags update')
        $snapshot.Branch.Suggestions.DisplayText | Should -Be @('/ado branch find', '/ado branch set-default', '/ado branch set-searchable')
        $snapshot.Create.Suggestions.DisplayText | Should -Not -Contain '/ado repository create nuget'
        $snapshot.Create.Suggestions.DisplayText | Should -Not -Contain '/ado repository create domain'
        $snapshot.Create.Suggestions.DisplayText | Should -Not -Contain '/ado repository create cdm'
    }

    It 'no longer resolves the former top-level path /<Path>' -ForEach @(
        @{ Path = 'list ado-agents' }
        @{ Path = 'list ado-team-members' }
        @{ Path = 'repository create' }
        @{ Path = 'branch find' }
        @{ Path = 'pipelines tags' }
    ) {
        $resolved = & $core { param($InputText) Resolve-GerberCommand -InputText $InputText } "/$Path"
        $resolved.IsValid | Should -BeFalse
    }
}
