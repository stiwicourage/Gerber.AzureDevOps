function Get-AdoPolicyTestList {
    return [pscustomobject]@{
        CreateList = [System.Collections.Generic.List[pscustomobject]]::new()
        UpdateList = [System.Collections.Generic.List[pscustomobject]]::new()
        AlignedList = [System.Collections.Generic.List[pscustomobject]]::new()
    }
}

function Get-AdoPolicyTestRecord {
    param([int]$Id, [string]$Branch)
    return [pscustomobject]@{
        id = $Id
        settings = [pscustomobject]@{ searchBranches = @($Branch) }
    }
}
