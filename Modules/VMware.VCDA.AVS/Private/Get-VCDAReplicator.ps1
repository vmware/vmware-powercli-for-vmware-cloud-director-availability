<#
Copyright (c) CA, Inc. All rights reserved.
SPDX-License-Identifier: LicenseRef-CA-Inc-Software-License
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