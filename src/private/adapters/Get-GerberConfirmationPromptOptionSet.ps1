function Get-GerberConfirmationPromptOptionSet {
    param(
        [string]$ActionLabel = 'Continue',
        [string]$ActionPreviewText = 'Continue with this action.',
        [string]$CancelPreviewText = 'Cancel and return to the current menu.',
        [string]$DefaultOption = 'action'
    )
    return [pscustomobject]@{
        ActionLabel = $ActionLabel
        CancelLabel = 'Cancel'
        ActionPreviewText = $ActionPreviewText
        CancelPreviewText = $CancelPreviewText
        DefaultOption = $DefaultOption
    }
}
