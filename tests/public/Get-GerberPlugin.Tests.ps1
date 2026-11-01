BeforeAll {
    . (Join-Path $PSScriptRoot '../PluginTestSupport.ps1')
    . (Join-Path $PSScriptRoot '../../src/public/Get-GerberPlugin.ps1')
}

Describe 'Get-GerberPlugin' {
    It 'retains ado identity in both the descriptor and manifest metadata without an ado command root' -Tag 'AdoNamespace' {
        $definition = Get-GerberPlugin -Gerber (Get-PluginTestContext)
        $project = Get-Content (Join-Path $PSScriptRoot '../../project.json') -Raw | ConvertFrom-Json
        $definition.Namespace | Should -BeExactly 'ado'
        $project.Manifest.PrivateData.Gerber.Namespace | Should -BeExactly 'ado'
        $definition.Commands.Name | Should -Not -Contain 'ado'
        $definition.Commands.Name | Should -Not -Contain 'ado hello'
    }

    It 'registers Azure DevOps product leaves through Plugin API v1' {
        $api = [pscustomobject]@{ UI = @{
            ShowTextBlock = { param($Title, $Text) "$Title|$Text" }
            WaitForContinue = {}
        } }
        $definition = Get-GerberPlugin -Gerber $api
        $definition.Guid | Should -Be 'a468dee5-c7a0-43e4-ae88-bb19158fe679'
        $definition.Commands.Count | Should -Be 9
        $definition.Commands.Name | Should -Contain 'list ado-agents'
        $definition.Commands.Name | Should -Not -Contain 'ado hello'
    }
}
