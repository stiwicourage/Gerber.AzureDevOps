BeforeAll {
    . (Join-Path $PSScriptRoot '../PluginTestSupport.ps1')
}

Describe 'Get-PluginCommandDefinitionList' {
    It 'declares product-only leaves under the existing generic roots' {
        $commands = @(Get-PluginCommandDefinitionList -Gerber (Get-PluginTestContext))
        $commands.Count | Should -Be 9
        $commands.Name | Should -Contain 'repository create'
        $commands.Name | Should -Contain 'pipelines tags update'
        $commands[0].Handler | Should -BeOfType ([scriptblock])
    }
}
