function Invoke-GerberPipelineTagUpdate {
    [CmdletBinding()]
    param()

    Invoke-GerberPipelineTagMutation -Operation ([pscustomobject]@{
            Mode        = 'update'
            CommandLabel = '/ado pipelines tags update'
            TracePrefix = 'pipelines-tags-update'
        })
}
