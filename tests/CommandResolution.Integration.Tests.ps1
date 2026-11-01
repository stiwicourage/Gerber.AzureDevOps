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
    It 'resolves /<Path> with the original root and arguments' -ForEach @(
        @{ Path = 'list ado-agents'; Root = 'list'; Arguments = @('ado-agents') }
        @{ Path = 'list ado-team-members'; Root = 'list'; Arguments = @('ado-team-members') }
        @{ Path = 'branch find'; Root = 'branch'; Arguments = @('find') }
        @{ Path = 'branch set-default'; Root = 'branch'; Arguments = @('set-default') }
        @{ Path = 'branch set-searchable'; Root = 'branch'; Arguments = @('set-searchable') }
        @{ Path = 'repository create'; Root = 'repository'; Arguments = @('create') }
        @{ Path = 'pipelines tags'; Root = 'pipelines'; Arguments = @('tags') }
        @{ Path = 'pipelines tags delete'; Root = 'pipelines'; Arguments = @('tags', 'delete') }
        @{ Path = 'pipelines tags update'; Root = 'pipelines'; Arguments = @('tags', 'update') }
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
                Tags = Resolve-GerberCommand -InputText '/pipelines tags'
                Create = Resolve-GerberCommand -InputText '/repository create'
                Branch = Resolve-GerberCommand -InputText '/branch'
            }
        }
        $snapshot.Search.Suggestions.DisplayText | Should -Be @('/list ado-agents', '/list ado-team-members')
        $snapshot.Tags.Suggestions.DisplayText | Should -Be @('/pipelines tags delete', '/pipelines tags update')
        $snapshot.Branch.Suggestions.DisplayText | Should -Be @('/branch find', '/branch set-default', '/branch set-searchable')
        $snapshot.Create.Suggestions.DisplayText | Should -Not -Contain '/repository create nuget'
        $snapshot.Create.Suggestions.DisplayText | Should -Not -Contain '/repository create domain'
        $snapshot.Create.Suggestions.DisplayText | Should -Not -Contain '/repository create cdm'
    }
}
