<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Set-License {
    [CmdletBinding()]
    param (
        # VCDA Server
        [Parameter(Mandatory = $false)]
        [PSTypeName('VCDAServer')]$Server,
        # License Key
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [string]
        $LicenseKey
    )

    process {
        try {
            $LocalvarServer = $Global:DefaultVCDAServer
            if ($null -ne $server) {
                $LocalvarServer = $server
            }


            $LocalVarBodyParameter = @{
                'key' = ${LicenseKey}
            }
            $LocalVarBodyParameter = $LocalVarBodyParameter | ConvertTo-Json -Depth 100

            $LocalvarInvokeParams = @{
                'path'       = '/license'
                'method'     = 'POST'
                'client'     = $LocalvarServer
                'body'       = $LocalVarBodyParameter
            }
            $LocalVarResponse = Invoke-VCDArequest @LocalvarInvokeParams
            return $LocalVarResponse.Response
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}