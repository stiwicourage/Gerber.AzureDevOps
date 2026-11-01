foreach ($file in (Get-ChildItem (Join-Path $PSScriptRoot '../src/private') -Recurse -Filter '*.ps1')) {
    . $file.FullName
}

function Get-PluginTestContext {
    return [pscustomobject]@{ UI = @{
        ShowTextBlock = { param($Title, $Text) "$Title|$Text" }
        WaitForContinue = {}
        ReadSubcommand = { '' }
    } }
}
