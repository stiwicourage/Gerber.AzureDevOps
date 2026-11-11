function Invoke-GerberPipelineTagDelete {
    [CmdletBinding()]
    param()

    Invoke-GerberPipelineTagMutation -Operation ([pscustomobject]@{
            Mode         = 'delete'
            CommandLabel = '/ado pipelines tags delete'
            TracePrefix  = 'pipelines-tags-delete'
        })
}
