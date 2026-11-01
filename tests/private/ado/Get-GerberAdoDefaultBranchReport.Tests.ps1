BeforeAll {
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'TestHelpers/GerberTestSupport.ps1')
    Import-GerberSource -StartPath $PSScriptRoot
}

Describe 'Get-GerberAdoDefaultBranchReport' {
    It 'calls Get-GerberAdoRepositoryList and Invoke-GerberDefaultBranchRepoScan and returns expected structure' {
        $config = [pscustomobject]@{
            ProjectName             = 'P'
            DefaultApiVersion       = '7.0'
            CredentialIdentifier  = 'PAT'
            CollectionUri           = [uri]'https://ado.example.com/org/'
        }
        $context = [pscustomobject]@{ Configuration = $config; Pat = 'p'; TargetBranch = 'refs/heads/main' }
        $repoList = @([pscustomobject]@{ Id = 'r1'; Name = 'Alpha'; DefaultBranch = 'refs/heads/dev' })
        Mock Get-GerberAdoRepositoryList { $repoList }
        Mock Invoke-GerberDefaultBranchRepoScan {
            [pscustomobject]@{
                ToUpdateList = [System.Collections.Generic.List[pscustomobject]]::new()
                AlignedList  = [System.Collections.Generic.List[pscustomobject]]::new()
                NotFoundList = [System.Collections.Generic.List[pscustomobject]]::new()
            }
        }
        Mock Write-GerberPromptTrace {}

        $result = Get-GerberAdoDefaultBranchReport -Context $context

        Should -Invoke Get-GerberAdoRepositoryList -Times 1
        Should -Invoke Invoke-GerberDefaultBranchRepoScan -Times 1
        $result.PSObject.Properties.Name | Should -Contain 'ToUpdateList'
        $result.PSObject.Properties.Name | Should -Contain 'AlreadyAlignedList'
        $result.PSObject.Properties.Name | Should -Contain 'NotFoundList'
    }

    It 'emits set-default-scan trace event with counts' {
        $context = [pscustomobject]@{
            Configuration = [pscustomobject]@{
                ProjectName             = 'P'
                DefaultApiVersion       = '7.0'
                CredentialIdentifier  = 'PAT'
                CollectionUri           = [uri]'https://ado.example.com/org/'
            }
            Pat          = 'p'
            TargetBranch = 'refs/heads/main'
        }
        Mock Get-GerberAdoRepositoryList { @() }
        $toUpdate = [System.Collections.Generic.List[pscustomobject]]::new()
        $aligned  = [System.Collections.Generic.List[pscustomobject]]::new()
        $notFound = [System.Collections.Generic.List[pscustomobject]]::new()
        $null = $toUpdate.Add([pscustomobject]@{ RepoName = 'A' })
        Mock Invoke-GerberDefaultBranchRepoScan {
            [pscustomobject]@{ ToUpdateList = $toUpdate; AlignedList = $aligned; NotFoundList = $notFound }
        }
        Mock Write-GerberPromptTrace {}

        Get-GerberAdoDefaultBranchReport -Context $context

        Should -Invoke Write-GerberPromptTrace -Times 1 -ParameterFilter { $EventName -eq 'set-default-scan' }
    }
}

Describe 'Get-GerberDefaultBranchPlanItem' {
    BeforeEach {
        $script:context = [pscustomobject]@{
            Configuration = [pscustomobject]@{
                ProjectName = 'P'; DefaultApiVersion = '7.0'; CredentialIdentifier = 'PAT'
                CollectionUri = [uri]'https://ado.example.com/org/'
            }
            Pat = 'p'; TargetBranch = 'refs/heads/main'
        }
    }
    It 'returns Aligned classification when repo DefaultBranch equals TargetBranch (case-insensitive)' {
        $context = [pscustomobject]@{
            Configuration = [pscustomobject]@{ CredentialIdentifier = 'PAT' }
            Pat           = 'p'
            TargetBranch  = 'refs/heads/main'
        }
        $repo = [pscustomobject]@{ Id = 'r1'; Name = 'Alpha'; DefaultBranch = 'refs/heads/MAIN' }
        Mock Write-GerberPromptTrace {}

        $result = Get-GerberDefaultBranchPlanItem -Context $context -Repo $repo

        $result.Classification | Should -Be 'Aligned'
    }

    It 'returns ToUpdate classification when branch exists and DefaultBranch differs' {
        $repo = [pscustomobject]@{ Id = 'r1'; Name = 'Alpha'; DefaultBranch = 'refs/heads/dev' }
        Mock Test-GerberAdoRepoBranchPresence { $true }
        Mock Write-GerberPromptTrace {}

        $result = Get-GerberDefaultBranchPlanItem -Context $context -Repo $repo

        $result.Classification | Should -Be 'ToUpdate'
    }

    It 'returns NotFound classification when branch does not exist' {
        $repo = [pscustomobject]@{ Id = 'r1'; Name = 'Alpha'; DefaultBranch = 'refs/heads/dev' }
        Mock Test-GerberAdoRepoBranchPresence { $false }
        Mock Write-GerberPromptTrace {}

        $result = Get-GerberDefaultBranchPlanItem -Context $context -Repo $repo

        $result.Classification | Should -Be 'NotFound'
    }

    It 'emits set-default-plan-item trace event' {
        $context = [pscustomobject]@{
            Configuration = [pscustomobject]@{
                ProjectName             = 'P'
                DefaultApiVersion       = '7.0'
                CredentialIdentifier  = 'PAT'
                CollectionUri           = [uri]'https://ado.example.com/org/'
            }
            Pat          = 'p'
            TargetBranch = 'refs/heads/main'
        }
        $repo = [pscustomobject]@{ Id = 'r1'; Name = 'Beta'; DefaultBranch = 'refs/heads/main' }
        Mock Write-GerberPromptTrace {}

        Get-GerberDefaultBranchPlanItem -Context $context -Repo $repo

        Should -Invoke Write-GerberPromptTrace -Times 1 -ParameterFilter { $EventName -eq 'set-default-plan-item' }
    }
}

Describe 'Add-GerberDefaultBranchPlanItem' {
    It 'adds <Classification> item to its list only' -ForEach @(
        @{ Classification = 'Aligned'; RepoName = 'Alpha'; Aligned = 1; Update = 0; Missing = 0 }
        @{ Classification = 'ToUpdate'; RepoName = 'Beta'; Aligned = 0; Update = 1; Missing = 0 }
        @{ Classification = 'NotFound'; RepoName = 'Gamma'; Aligned = 0; Update = 0; Missing = 1 }
    ) {
        $lists = [pscustomobject]@{
            ToUpdateList = [System.Collections.Generic.List[pscustomobject]]::new()
            AlignedList  = [System.Collections.Generic.List[pscustomobject]]::new()
            NotFoundList = [System.Collections.Generic.List[pscustomobject]]::new()
        }
        $item = [pscustomobject]@{ RepoId = 'r1'; RepoName = $RepoName; Classification = $Classification }

        Add-GerberDefaultBranchPlanItem -Item $item -Lists $lists

        $lists.AlignedList.Count | Should -Be $Aligned
        $lists.ToUpdateList.Count | Should -Be $Update
        $lists.NotFoundList.Count | Should -Be $Missing
    }
}

Describe 'Invoke-GerberDefaultBranchRepoScan' {
    It 'calls Get-GerberDefaultBranchPlanItem and Add-GerberDefaultBranchPlanItem for each repo' {
        $context = [pscustomobject]@{
            Configuration = [pscustomobject]@{ CredentialIdentifier = 'PAT' }
            Pat           = 'p'
            TargetBranch  = 'refs/heads/main'
        }
        $repoList = @(
            [pscustomobject]@{ Id = 'r1'; Name = 'Alpha'; DefaultBranch = 'refs/heads/main' }
            [pscustomobject]@{ Id = 'r2'; Name = 'Beta';  DefaultBranch = 'refs/heads/dev' }
        )
        Mock Write-GerberProgressBar {}
        Mock Get-GerberDefaultBranchPlanItem {
            [pscustomobject]@{ RepoId = $Repo.Id; RepoName = $Repo.Name; Classification = 'Aligned' }
        }
        Mock Add-GerberDefaultBranchPlanItem {}

        $result = Invoke-GerberDefaultBranchRepoScan -Context $context -RepoList $repoList

        Should -Invoke Get-GerberDefaultBranchPlanItem -Times 2
        Should -Invoke Add-GerberDefaultBranchPlanItem -Times 2
        Should -Invoke Write-GerberProgressBar -Times 2
        $result.PSObject.Properties.Name | Should -Contain 'ToUpdateList'
    }

    It 'returns empty lists when RepoList is empty' {
        $context = [pscustomobject]@{
            Configuration = [pscustomobject]@{ CredentialIdentifier = 'PAT' }
            Pat           = 'p'
            TargetBranch  = 'refs/heads/main'
        }
        Mock Write-GerberProgressBar {}

        $result = Invoke-GerberDefaultBranchRepoScan -Context $context -RepoList @()

        $result.ToUpdateList.Count | Should -Be 0
        $result.AlignedList.Count | Should -Be 0
        $result.NotFoundList.Count | Should -Be 0
    }
}
