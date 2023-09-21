<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Set-CloudSiteEndpoints {
    [CmdletBinding()]
    param (
        # VCDA Server
        [Parameter(Mandatory = $false)]
        [PSTypeName('VCDAServer')]$Server,
        # mgmtAddress
        [Parameter(Mandatory = $false)]
        [string]
        $mgmtAddress,
        # apiPublicAddress
        [Parameter(Mandatory = $true)]
        [string]
        $apiPublicAddress

    )

    process {
        try {
            $LocalvarServer = $Global:DefaultVCDAServer
            if ($null -ne $server) {
                $LocalvarServer = $server
            }
            [system.uri]$apiPublicURI = $apiPublicAddress
            $ConfiguredEndpoint = (Get-CloudSiteEndpoints -Server $LocalvarServer).configured
            $ConfiguredEndpoint.apiPublicAddress = $apiPublicURI.Host
            $ConfiguredEndpoint.apiPublicPort = $apiPublicURI.Port

            $LocalVarBodyParameter = $ConfiguredEndpoint | ConvertTo-Json -Depth 100
            $LocalvarInvokeParams = @{
                'path'   = '/config/endpoints'
                'method' = 'POST'
                'client' = $LocalvarServer
                'body'   = $LocalVarBodyParameter
            }
            $LocalVarResponse = Invoke-VCDArequest @LocalvarInvokeParams
            return $LocalVarResponse.Response
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

    }
}