<#
Copyright (c) 2023-2025 Broadcom. All Rights Reserved.
SPDX-License-Identifier: BSD-2-Clause
#>
function Set-LocalCertificate {
    [CmdletBinding()]
    param (
        # VCDA Server
        [Parameter(Mandatory = $false)]
        [PSTypeName('VCDAServer')]$Server
    )

    process {
        try {
            $LocalvarServer = $Global:DefaultVCDAServer
            if ($null -ne $server) {
                $LocalvarServer = $server
            }

            $LocalvarInvokeParams = @{
                'path'   = '/config/certificate'
                'method' = 'PUT'
                'client' = $LocalvarServer
            }
            $LocalVarResponse = Invoke-VCDArequest @LocalvarInvokeParams
            return $LocalVarResponse.Response
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

    }
}