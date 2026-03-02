<#
Copyright (c) CA, Inc. All rights reserved.
SPDX-License-Identifier: LicenseRef-CA-Inc-Software-License
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