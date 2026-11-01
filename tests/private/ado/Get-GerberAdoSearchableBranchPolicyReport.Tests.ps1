BeforeAll {
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'TestHelpers/GerberTestSupport.ps1')
    Import-GerberSource -StartPath $PSScriptRoot
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'TestHelpers/GerberBranchPolicyTestSupport.ps1')
}

Describe 'Get-GerberSearchableBranchPolicyTypeId' {
    It 'returns the correct searchable-branch policy type GUID' {
        $result = Get-GerberSearchableBranchPolicyTypeId

        $result | Should -Be '0517f88d-4ec5-4343-9d26-9930ebd53069'
    }
}

Describe 'Get-GerberAdoSearchableBranchPolicyReport' {
    It 'returns a report with RepoList, CreateList, UpdateList, and AlreadyAlignedList' {
        Mock Get-GerberAdoRepositoryList { @() }
        Mock Get-GerberAdoSearchableBranchPolicyMap { @{} }
        Mock Invoke-GerberSearchableBranchRepoScan {
            [pscustomobject]@{
                CreateList  = [System.Collections.Generic.List[pscustomobject]]::new()
                UpdateList  = [System.Collections.Generic.List[pscustomobject]]::new()
                AlignedList = [System.Collections.Generic.List[pscustomobject]]::new()
            }
        }

        $context = [pscustomobject]@{
            Configuration     = [pscustomobject]@{ CredentialIdentifier = 'PAT' }
            Pat               = 'test-pat'
            DesiredBranchList = @('refs/heads/main')
            Mode              = 'Replace'
        }
        $result = Get-GerberAdoSearchableBranchPolicyReport -Context $context

        $result.PSObject.Properties.Name | Should -Contain 'RepoList'
        $result.PSObject.Properties.Name | Should -Contain 'CreateList'
        $result.PSObject.Properties.Name | Should -Contain 'UpdateList'
        $result.PSObject.Properties.Name | Should -Contain 'AlreadyAlignedList'
    }

    It 'passes the policy map and repo list to scan and surfaces the scan categorization' {
        Mock Get-GerberAdoRepositoryList {
            @([pscustomobject]@{ Id = 'r1'; Name = 'Alpha' })
        }
        Mock Get-GerberAdoSearchableBranchPolicyMap { @{ 'r1' = [pscustomobject]@{ id = 10 } } }
        $createList = [System.Collections.Generic.List[pscustomobject]]::new()
        $null = $createList.Add([pscustomobject]@{ RepoId = 'r1'; RepoName = 'Alpha' })
        Mock Invoke-GerberSearchableBranchRepoScan {
            [pscustomobject]@{
                CreateList  = $createList
                UpdateList  = [System.Collections.Generic.List[pscustomobject]]::new()
                AlignedList = [System.Collections.Generic.List[pscustomobject]]::new()
            }
        }

        $context = [pscustomobject]@{
            Configuration     = [pscustomobject]@{ CredentialIdentifier = 'PAT' }
            Pat               = 'test-pat'
            DesiredBranchList = @('refs/heads/main')
            Mode              = 'Replace'
        }
        $result = Get-GerberAdoSearchableBranchPolicyReport -Context $context

        $result.RepoList.Count | Should -Be 1
        $result.CreateList.Count | Should -Be 1
        $result.CreateList[0].RepoName | Should -Be 'Alpha'
    }
}

Describe 'Get-GerberAdoSearchableBranchPolicyMap' {
    It 'builds a repositoryId-to-policy map from a matching policy list' {
        $policyTypeId = Get-GerberSearchableBranchPolicyTypeId
        $scope = @([pscustomobject]@{ repositoryId = 'repo-1' })
        Mock Invoke-GerberAdoRestRequest {
            [pscustomobject]@{
                value = @([pscustomobject]@{
                    id       = 42
                    type     = [pscustomobject]@{ id = $policyTypeId }
                    settings = [pscustomobject]@{
                        scope          = $scope
                        searchBranches = @('refs/heads/main')
                    }
                })
            }
        }

        $context = [pscustomobject]@{
            Configuration = [pscustomobject]@{
                ProjectName            = 'MyProject'
                DefaultApiVersion      = '7.1'
                CredentialIdentifier = 'PAT'
                CollectionUri          = [uri]'https://ado.example.com/org/'
            }
            Pat = 'test-pat'
        }
        $result = Get-GerberAdoSearchableBranchPolicyMap -Context $context

        $result.Count | Should -Be 1
        $result['repo-1'] | Should -Not -BeNull
        $result['repo-1'].id | Should -Be 42
    }

    It 'returns an empty hashtable when the policy list is empty' {
        Mock Invoke-GerberAdoRestRequest { [pscustomobject]@{ value = @() } }

        $context = [pscustomobject]@{
            Configuration = [pscustomobject]@{
                ProjectName            = 'MyProject'
                DefaultApiVersion      = '7.1'
                CredentialIdentifier = 'PAT'
                CollectionUri          = [uri]'https://ado.example.com/org/'
            }
            Pat = 'test-pat'
        }
        $result = Get-GerberAdoSearchableBranchPolicyMap -Context $context

        $result.Count | Should -Be 0
    }

    It 'filters out policies whose type ID does not match the searchable-branch type' {
        $policyTypeId = Get-GerberSearchableBranchPolicyTypeId
        Mock Invoke-GerberAdoRestRequest {
            [pscustomobject]@{
                value = @(
                    [pscustomobject]@{
                        id       = 1
                        type     = [pscustomobject]@{ id = 'other-type-id' }
                        settings = [pscustomobject]@{ scope = @([pscustomobject]@{ repositoryId = 'repo-x' }); searchBranches = @() }
                    },
                    [pscustomobject]@{
                        id       = 2
                        type     = [pscustomobject]@{ id = $policyTypeId }
                        settings = [pscustomobject]@{ scope = @([pscustomobject]@{ repositoryId = 'repo-y' }); searchBranches = @('refs/heads/main') }
                    }
                )
            }
        }

        $context = [pscustomobject]@{
            Configuration = [pscustomobject]@{
                ProjectName            = 'P'
                DefaultApiVersion      = '7.1'
                CredentialIdentifier = 'PAT'
                CollectionUri          = [uri]'https://ado.example.com/org/'
            }
            Pat = 'test-pat'
        }
        $result = Get-GerberAdoSearchableBranchPolicyMap -Context $context

        $result.Count | Should -Be 1
        $result.ContainsKey('repo-x') | Should -BeFalse
        $result.ContainsKey('repo-y') | Should -BeTrue
    }
}

Describe 'Get-GerberSearchableBranchCurrentBranchList' {
    It 'returns the searchBranches strings from the policy when policy is not null' {
        $policy = [pscustomobject]@{
            settings = [pscustomobject]@{ searchBranches = @('refs/heads/main', 'refs/heads/develop') }
        }

        $result = Get-GerberSearchableBranchCurrentBranchList -Policy $policy

        @($result).Count | Should -Be 2
        $result | Should -Contain 'refs/heads/main'
        $result | Should -Contain 'refs/heads/develop'
    }

    It 'returns an empty array when policy is null' {
        $result = Get-GerberSearchableBranchCurrentBranchList -Policy $null

        @($result).Count | Should -Be 0
    }

    It 'returns an empty array when searchBranches is null' {
        $policy = [pscustomobject]@{
            settings = [pscustomobject]@{ searchBranches = $null }
        }

        $result = @(Get-GerberSearchableBranchCurrentBranchList -Policy $policy)

        $result.Count | Should -Be 0
    }

    It 'returns an empty array when settings is null' {
        $policy = [pscustomobject]@{ settings = $null }

        $result = @(Get-GerberSearchableBranchCurrentBranchList -Policy $policy)

        $result.Count | Should -Be 0
    }
}

Describe 'Get-GerberAdoSearchableBranchAllPoliciesUri' {
    BeforeEach {
        $script:config = [pscustomobject]@{
            ProjectName = 'MyProject'
            DefaultApiVersion = '7.1'
            CollectionUri = [uri]'https://ado.example.com/org/'
        }
    }
    It 'includes policyType and api-version in the query string' {
        $config = [pscustomobject]@{
            ProjectName       = 'MyProject'
            DefaultApiVersion = '7.1'
            CollectionUri     = [uri]'https://ado.example.com/org/'
        }
        $uri = Get-GerberAdoSearchableBranchAllPoliciesUri -Configuration $config

        $uri.AbsoluteUri | Should -BeLike '*policyType=0517f88d*'
        $uri.AbsoluteUri | Should -BeLike '*api-version=7.1*'
    }

    It 'includes the project name in the path' {
        $uri = Get-GerberAdoSearchableBranchAllPoliciesUri -Configuration $config

        $uri.AbsoluteUri | Should -BeLike '*MyProject/_apis/policy/configurations*'
    }

    It 'does not include a repositoryId in the query string' {
        $config.ProjectName = 'P'
        $uri = Get-GerberAdoSearchableBranchAllPoliciesUri -Configuration $config

        $uri.AbsoluteUri | Should -Not -BeLike '*repositoryId*'
    }
}

Describe 'Invoke-GerberSearchableBranchRepoScan' {
    BeforeEach {
        $script:context = [pscustomobject]@{
            Configuration = [pscustomobject]@{ CredentialIdentifier = 'PAT' }
            Pat = 'test-pat'
            DesiredBranchList = @('refs/heads/main')
            Mode = 'Replace'
        }
    }
    It 'returns empty lists when repo list is empty' {
        Mock Write-GerberProgressBar {}

        $context = [pscustomobject]@{
            Configuration     = [pscustomobject]@{ CredentialIdentifier = 'PAT' }
            Pat               = 'test-pat'
            DesiredBranchList = @('refs/heads/main')
            Mode              = 'Replace'
        }
        $result = Invoke-GerberSearchableBranchRepoScan -Context $context -RepoList @() -PolicyMap @{}

        @($result.CreateList).Count | Should -Be 0
        @($result.UpdateList).Count | Should -Be 0
        @($result.AlignedList).Count | Should -Be 0
    }

    It 'routes <Case> plan items into the expected scan list' -ForEach @(
        @{ Case = 'aligned'; NeedsChange = $false; PolicyId = $null; Aligned = 1; Create = 0; Update = 0 }
        @{ Case = 'new'; NeedsChange = $true; PolicyId = $null; Aligned = 0; Create = 1; Update = 0 }
        @{ Case = 'existing'; NeedsChange = $true; PolicyId = '42'; Aligned = 0; Create = 0; Update = 1 }
    ) {
        Mock Write-GerberProgressBar {}
        $script:scanPlanItem = [pscustomobject]@{
            RepoId = 'r1'; RepoName = 'Alpha'; PolicyId = $PolicyId; NewScope = @(); NeedsChange = $NeedsChange
        }
        Mock Get-GerberSearchableBranchPlanItem {
            $script:scanPlanItem
        }

        $result = Invoke-GerberSearchableBranchRepoScan `
            -Context $context `
            -RepoList @([pscustomobject]@{ Id = 'r1'; Name = 'Alpha' }) `
            -PolicyMap @{}

        @($result.AlignedList).Count | Should -Be $Aligned
        @($result.CreateList).Count | Should -Be $Create
        @($result.UpdateList).Count | Should -Be $Update
    }
}

Describe 'Get-GerberSearchableBranchPlanItem' {
    BeforeEach {
        $script:context = [pscustomobject]@{
            DesiredBranchList = @('refs/heads/main')
            Mode = 'Replace'
        }
        $script:repo = [pscustomobject]@{ Id = 'r1'; Name = 'Alpha' }
    }
    It 'returns NeedsChange=<NeedsChange> and PolicyId=<PolicyId> for <Case> policies' -ForEach @(
        @{ Case = 'absent'; PolicyId = $null; Branch = ''; Aligned = $false; NeedsChange = $true }
        @{ Case = 'aligned'; PolicyId = '99'; Branch = 'refs/heads/main'; Aligned = $true; NeedsChange = $false }
        @{ Case = 'different'; PolicyId = '55'; Branch = 'refs/heads/old'; Aligned = $false; NeedsChange = $true }
    ) {
        Mock Build-GerberSearchableBranchNewScope { @('refs/heads/main') }
        $script:scopeAligned = $Aligned
        Mock Test-GerberSearchableBranchScopeAligned { $script:scopeAligned }
        $policyMap = @{}
        if ($null -ne $PolicyId) {
            $policyMap.r1 = Get-AdoPolicyTestRecord -Id $PolicyId -Branch $Branch
        }
        $result = Get-GerberSearchableBranchPlanItem -Context $context -Repo $repo -PolicyMap $policyMap

        $result.NeedsChange | Should -Be $NeedsChange
        $result.PolicyId | Should -Be $PolicyId
    }

    It 'returns NewScope as an array even when only one branch is in scope' {
        $context = [pscustomobject]@{
            DesiredBranchList = @('refs/heads/develop')
            Mode              = 'Merge'
        }
        $repo = [pscustomobject]@{ Id = 'r1'; Name = 'Alpha'; DefaultBranch = '' }

        $result = Get-GerberSearchableBranchPlanItem -Context $context -Repo $repo -PolicyMap @{}

        @($result.NewScope).Count | Should -Be 1
        $result.NewScope | Should -Contain 'refs/heads/develop'
    }

    It 'returns NeedsChange=false and empty NewScope when desired branch is the repo default branch and no policy exists' {
        $context = [pscustomobject]@{
            DesiredBranchList = @('refs/heads/develop')
            Mode              = 'Merge'
        }
        $repo = [pscustomobject]@{ Id = 'r1'; Name = 'Alpha'; DefaultBranch = 'refs/heads/develop' }

        $result = Get-GerberSearchableBranchPlanItem -Context $context -Repo $repo -PolicyMap @{}

        $result.NeedsChange | Should -BeFalse
        @($result.NewScope).Count | Should -Be 0
    }
}

Describe 'Build-GerberSearchableBranchNewScope' {
    It 'returns the <Mode> scope preserving desired branches and deduplication' -ForEach @(
        @{ Mode = 'Replace'; Current = @('refs/heads/old'); Count = 2; Included = @('refs/heads/main', 'refs/heads/dev'); Excluded = @('refs/heads/old') }
        @{ Mode = 'Merge'; Current = @('refs/heads/main', 'refs/heads/release'); Count = 3; Included = @('refs/heads/main', 'refs/heads/dev', 'refs/heads/release'); Excluded = @() }
    ) {
        $result = Build-GerberSearchableBranchNewScope `
            -DesiredBranchList @('refs/heads/main', 'refs/heads/dev') `
            -CurrentBranches $Current `
            -Mode $Mode

        @($result).Count | Should -Be $Count
        foreach ($branch in $Included) { $result | Should -Contain $branch }
        foreach ($branch in $Excluded) { $result | Should -Not -Contain $branch }
    }

    It 'deduplicates case-insensitively in Merge mode' {
        $result = Build-GerberSearchableBranchNewScope `
            -DesiredBranchList @('refs/heads/main') `
            -CurrentBranches @('refs/heads/Main') `
            -Mode 'Merge'

        @($result).Count | Should -Be 1
    }

    It 'returns an empty array when DesiredBranchList is empty in Replace mode' {
        $result = Build-GerberSearchableBranchNewScope `
            -DesiredBranchList @() `
            -CurrentBranches @() `
            -Mode 'Replace'

        @($result).Count | Should -Be 0
    }

    It 'strips the default branch from the <Mode> scope' -ForEach @(
        @{ Mode = 'Replace'; Current = @(); Included = @('refs/heads/main'); Count = 1 }
        @{ Mode = 'Merge'; Current = @('refs/heads/release'); Included = @('refs/heads/main', 'refs/heads/release'); Count = 2 }
    ) {
        $result = Build-GerberSearchableBranchNewScope `
            -DesiredBranchList @('refs/heads/develop', 'refs/heads/main') `
            -CurrentBranches $Current `
            -Mode $Mode `
            -DefaultBranch 'refs/heads/develop'

        @($result).Count | Should -Be $Count
        foreach ($branch in $Included) { $result | Should -Contain $branch }
        $result | Should -Not -Contain 'refs/heads/develop'
    }

    It 'returns an empty array when the only desired branch equals the default branch' {
        $result = Build-GerberSearchableBranchNewScope `
            -DesiredBranchList @('refs/heads/develop') `
            -CurrentBranches @() `
            -Mode 'Replace' `
            -DefaultBranch 'refs/heads/develop'

        @($result).Count | Should -Be 0
    }
}

Describe 'Get-GerberExplicitBranchScope' {
    It 'returns scope unchanged when DefaultBranch is empty' {
        $result = Get-GerberExplicitBranchScope `
            -Scope @('refs/heads/main', 'refs/heads/develop') `
            -DefaultBranch ''

        @($result).Count | Should -Be 2
    }

    It 'removes the default branch case-insensitively' {
        $result = Get-GerberExplicitBranchScope `
            -Scope @('refs/heads/Main', 'refs/heads/develop') `
            -DefaultBranch 'refs/heads/main'

        @($result).Count | Should -Be 1
        $result | Should -Contain 'refs/heads/develop'
        $result | Should -Not -Contain 'refs/heads/Main'
    }

    It 'returns an empty array when the scope contains only the default branch' {
        $result = Get-GerberExplicitBranchScope `
            -Scope @('refs/heads/develop') `
            -DefaultBranch 'refs/heads/develop'

        @($result).Count | Should -Be 0
    }
}

Describe 'Test-GerberSearchableBranchScopeAligned' {
    It 'returns true when both string arrays contain the same branches regardless of order' {
        $result = Test-GerberSearchableBranchScopeAligned `
            -NewScope @('refs/heads/main', 'refs/heads/dev') `
            -CurrentScope @('refs/heads/dev', 'refs/heads/main')

        $result | Should -BeTrue
    }

    It 'returns false when counts differ' {
        $result = Test-GerberSearchableBranchScopeAligned `
            -NewScope @('refs/heads/main', 'refs/heads/dev') `
            -CurrentScope @('refs/heads/main')

        $result | Should -BeFalse
    }

    It 'returns false when a branch in NewScope is missing from CurrentScope' {
        $result = Test-GerberSearchableBranchScopeAligned `
            -NewScope @('refs/heads/feature') `
            -CurrentScope @('refs/heads/main')

        $result | Should -BeFalse
    }

    It 'returns true for two empty arrays' {
        $result = Test-GerberSearchableBranchScopeAligned -NewScope @() -CurrentScope @()

        $result | Should -BeTrue
    }

    It 'compares branch strings case-insensitively' {
        $result = Test-GerberSearchableBranchScopeAligned `
            -NewScope @('refs/heads/Main') `
            -CurrentScope @('refs/heads/main')

        $result | Should -BeTrue
    }
}

Describe 'Add-GerberSearchableBranchPlanItem' {
    It 'adds <Case> items to the expected plan list' -ForEach @(
        @{ Case = 'aligned'; RepoName = 'Alpha'; PolicyId = $null; NeedsChange = $false; Aligned = 1; Create = 0; Update = 0 }
        @{ Case = 'new'; RepoName = 'Beta'; PolicyId = $null; NeedsChange = $true; Aligned = 0; Create = 1; Update = 0 }
        @{ Case = 'existing'; RepoName = 'Gamma'; PolicyId = '77'; NeedsChange = $true; Aligned = 0; Create = 0; Update = 1 }
    ) {
        $lists = Get-AdoPolicyTestList
        $item = [pscustomobject]@{ RepoName = $RepoName; PolicyId = $PolicyId; NeedsChange = $NeedsChange }

        Add-GerberSearchableBranchPlanItem -Item $item -Lists $lists

        $lists.AlignedList.Count | Should -Be $Aligned
        $lists.CreateList.Count | Should -Be $Create
        $lists.UpdateList.Count | Should -Be $Update
    }
}
