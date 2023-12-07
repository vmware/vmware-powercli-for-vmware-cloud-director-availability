<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-VCDAPassExp {
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
                'path'   = '/config/root-password-expired'
                'method' = 'GET'
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