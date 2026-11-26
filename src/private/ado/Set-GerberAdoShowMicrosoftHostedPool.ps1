function Set-GerberAdoShowMicrosoftHostedPool {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [bool]$Value
    )

    $candidateConfiguration = Copy-GerberUserConfigurationMap -Configuration (Get-GerberUserConfiguration)
    $adoConfiguration = Get-GerberOrAddConfigurationSection -Configuration $candidateConfiguration -PropertyName 'ado'
    $settings = Get-GerberOrAddConfigurationSection -Configuration $adoConfiguration -PropertyName 'settings'
    $settings['showMicrosoftHostedPools'] = $Value

    if ($PSCmdlet.ShouldProcess('showMicrosoftHostedPools', 'Save Azure DevOps setting')) {
        Save-GerberUserConfiguration -Configuration $candidateConfiguration
    }
}
