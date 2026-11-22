function ConvertTo-TestGerberSecureValue {
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )
    $secureValue = [System.Security.SecureString]::new()
    foreach ($character in $Text.ToCharArray()) {
        $secureValue.AppendChar($character)
    }
    $secureValue.MakeReadOnly()
    return $secureValue
}

function Get-GerberReadinessRetryTestInput {
    param()
    return @(
        ''
        'not-a-url'
        'https://dev.azure.com/example-org/SampleProject'
        'example'
        'n'
    )
}

function Read-GerberReadinessTestResponse {
    param()
    $response = $script:commandResponses[$script:commandIndex]
    $script:commandIndex++
    return $response
}

function Get-GerberReadinessSingleProfileTestConfiguration {
    param()
    return @{
        schemaVersion = 1
        ado = @{
            profiles = [ordered]@{
                example = @{
                    projectUrl = 'https://dev.azure.com/example-org/SampleProject'
                }
            }
        }
    }
}

function Get-GerberReadinessMissingPatTestConfiguration {
    param()
    return @{
        ado = @{
            defaultProfile = 'example'
            profiles = @{
                example = @{
                    projectUrl = 'https://dev.azure.com/example-org/SampleProject'
                }
            }
        }
    }
}
