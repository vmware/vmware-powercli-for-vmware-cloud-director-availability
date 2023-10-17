<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-VCDAReplicator {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSTypeName('VCDAServer')]$Server
    )
    process {
        try {
            $LocalvarServer = $Global:DefaultVCDAServer
            if ($null -ne $server) {
                $LocalvarServer = $server
            }
            $LocalvarInvokeParams = @{
                'path'   = "/replicators"
                'Method' = "GET"
                'client' = $LocalvarServer
            }
            $LocalVarResponse = Invoke-VCDARequest @LocalvarInvokeParams
            return $LocalVarResponse.response
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}