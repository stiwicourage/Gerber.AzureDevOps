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
}
