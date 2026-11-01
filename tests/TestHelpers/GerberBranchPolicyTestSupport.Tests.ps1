BeforeAll {
    . (Join-Path $PSScriptRoot 'GerberBranchPolicyTestSupport.ps1')
}

Describe 'Branch policy test fixtures' {
    It 'creates independent mutable lists for each scenario' {
        $first = Get-AdoPolicyTestList
        $second = Get-AdoPolicyTestList
        $first.CreateList.Add([pscustomobject]@{ RepoName = 'fixture' })
        $first.CreateList.Count | Should -Be 1
        $second.CreateList.Count | Should -Be 0
        $first.UpdateList.Count | Should -Be 0
        $first.AlignedList.Count | Should -Be 0
    }

    It 'preserves the policy identifier and branch envelope' {
        $record = Get-AdoPolicyTestRecord -Id 99 -Branch 'refs/heads/main'
        $record.id | Should -Be 99
        $record.settings.searchBranches | Should -Be @('refs/heads/main')
    }
}
