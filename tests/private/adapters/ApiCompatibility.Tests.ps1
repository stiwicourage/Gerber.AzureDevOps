# The former-name adapters are a cross-cutting translation seam rather than new
# Core infrastructure. Native flow tests and built/PTY integration cover their
# UI/error routing; these focused cases assert JSON, secret and default arguments.
BeforeAll {
    . (Join-Path $PSScriptRoot '../../TestHelpers/GerberTestSupport.ps1')
    Import-GerberSource -StartPath $PSScriptRoot
}

Describe 'Plugin-local public API compatibility adapters' {
    It 'reads absent configuration without creating a document' {
        $script:Gerber = [pscustomobject]@{
            Configuration = @{ Read = { $null }; Save = { throw 'Read must not save.' } }
        }
        (Get-GerberUserConfiguration).Count | Should -Be 0
    }

    It 'saves a valid document including unknown scalar and array data without supplying a path' {
        $script:document = $null
        $script:Gerber = [pscustomobject]@{
            Configuration = @{
                Save = { param($Value) $script:document = $Value }
                Read = { $script:document }
            }
        }
        $value = '{"future":[1],"empty":[],"enabled":false}' | ConvertFrom-Json -AsHashtable
        Save-GerberUserConfiguration -Configuration $value
        $result = Get-GerberUserConfiguration
        $result.Keys | Should -Be @('future', 'empty', 'enabled')
        @($result.future) | Should -Be @(1)
        @($result.empty).Count | Should -Be 0
        $result.enabled | Should -BeFalse
    }

    It 'forwards <Command> to one logical Secrets path rather than a legacy store identifier' -ForEach @(
        @{ Command = 'Get-GerberCredential' }
        @{ Command = 'Test-GerberCredential' }
        @{ Command = 'Set-GerberCredential' }
    ) {
        $script:logicalPath = $null
        $capture = { param($Path) $script:logicalPath = $Path; $true }
        $script:Gerber = [pscustomobject]@{ Secrets = @{ GetText = $capture; Test = $capture; Set = $capture } }
        & $Command -Identifier 'gerber:ado:Team%3AOne:pat' | Should -BeTrue
        $script:logicalPath | Should -Be @('ado', 'Team:One', 'pat')
    }

    It 'preserves the five legacy command prompt defaults through the public UI callback' {
        $script:Gerber = [pscustomobject]@{ UI = @{
            ReadCommand = {
                param($Prompt, $Mode, $InputMode, $Context, $Trim)
                [pscustomobject]@{ Prompt = $Prompt; Mode = $Mode; InputMode = $InputMode; Context = $Context; Trim = $Trim }
            }
        } }
        $request = Read-GerberCommand
        $request.Prompt | Should -Be ([string][char]0x276F)
        $request.Mode | Should -Be 'Root'
        $request.InputMode | Should -Be 'Buffered'
        $request.Trim | Should -BeTrue
        $request.Context.InitialCursorIndex | Should -Be -1
        $request.Context.StaticSuggestionList.Count | Should -Be 0
    }
}
