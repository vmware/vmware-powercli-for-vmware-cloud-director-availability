<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-VCDARemoteCert {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        # VCDA Server
        [Parameter(Mandatory = $false)]
        [PSTypeName('VCDAServer')]$Server,
        # URL
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [string]
        $url,
        [Parameter(Mandatory = $false)]
        [bool]
        $viaTunnel = $false

    )

    process {
        try {
            $LocalvarServer = $Global:DefaultVCDAServer
            if ($null -ne $server) {
                $LocalvarServer = $server
            }

            $LocalVarQueryParams = @{
                url       = $url
                viaTunnel = $viaTunnel
            }

            $LocalvarInvokeParams = @{
                'path'        = '/config/remote-certificate'
                'method'      = 'GET'
                'client'      = $LocalvarServer
                'QueryParams' = $LocalVarQueryParams
            }
            $LocalVarResponse = Invoke-VCDARequest @LocalvarInvokeParams
            return $LocalVarResponse.Response
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

    }
}