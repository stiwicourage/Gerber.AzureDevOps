# Repository-owned CI wiring; reusable workflow implementation belongs upstream.
BeforeAll {
    $workflowRoot = Join-Path (Split-Path -Parent $PSScriptRoot) '.github/workflows'
    $script:testsCaller = Get-Content -LiteralPath (Join-Path $workflowRoot 'Tests.yml') -Raw
    $script:publishCaller = Get-Content -LiteralPath (Join-Path $workflowRoot 'Publish.yml') -Raw
}

Describe 'Gerber.AzureDevOps reference caller contracts' {
    It 'pins the shared test analyzer to the common required version 1.25.0' {
        $script:testsCaller | Should -Match "(?m)^      script-analyzer-required-version: '1\.25\.0'$"
    }

    It 'schedules the shared tests daily at 03:00 UTC' {
        $script:testsCaller | Should -Match "(?m)^  schedule:\r?\n    - cron: '0 3 \* \* \*'$"
    }

    It 'validates both release files through the shared tests caller' {
        $script:testsCaller | Should -Match '(?m)^      changelog-files: ./CHANGELOG\.md ./RELEASE_NOTE\.md$'
    }

    It 'keeps build validation disabled in the shared tests caller' {
        $script:testsCaller | Should -Match '(?m)^      build-validation: false$'
    }

    It 'retains the tagged publish default without enabling Test-NovaBuild' {
        $script:publishCaller | Should -Not -Match '(?m)^\s+test-command:'
        $script:publishCaller | Should -Match '(?m)^      release-continuous-integration: true$'
    }

    It 'retains the shared <Workflow> <Shared> caller at tag 0.1.0' -ForEach @(
        @{ Workflow = 'Tests'; Shared = 'tests' }
        @{ Workflow = 'Publish'; Shared = 'publish' }
        @{ Workflow = 'Security'; Shared = 'codeql' }
        @{ Workflow = 'Security'; Shared = 'powershell-analyzer' }
        @{ Workflow = 'Security'; Shared = 'dependency-review' }
    ) {
        $caller = Get-Content -LiteralPath (Join-Path $workflowRoot "$Workflow.yml") -Raw
        $reference = [regex]::Escape("stiwicourage/powershell-ci/.github/workflows/$Shared.yml@0.1.0")
        $caller | Should -Match "(?m)^    uses: $reference$"
    }
}
