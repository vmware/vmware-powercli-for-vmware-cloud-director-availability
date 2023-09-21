<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-Tunnel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        # VCDA Server
        [Parameter(Mandatory = $false)]
        [PSTypeName('VCDAServer')]$Server,
        # tunnel URL
        [Parameter(Mandatory = $false)]
        [ValidateScript({ [system.uri]::IsWellFormedUriString($_, 'Absolute') -and ([system.uri]$_).Scheme -eq 'https' -and ([Uri]$_).Port -eq 8047 }, `
                ErrorMessage = "'{0}' is not a tunnel API endpoint, it must be in the format 'https://tunnel-address:8047'")]
        [string]
        $url

    )

    process {
        try {
            $LocalvarServer = $Global:DefaultVCDAServer
            if ($null -ne $server) {
                $LocalvarServer = $server
            }

            $LocalvarInvokeParams = @{
                'path'   = '/config/tunnels'
                'method' = 'GET'
                'client' = $LocalvarServer
            }
            $LocalVarResponse = Invoke-VCDArequest @LocalvarInvokeParams
            if ($PSBoundParameters['url']) {
                return $LocalVarResponse.response.tunnels | Where-Object { $_.URL -like $url }
            }
            else {
                return $LocalVarResponse.Response.tunnels
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

    }
}