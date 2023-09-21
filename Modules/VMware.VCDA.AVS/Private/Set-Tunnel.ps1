<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Set-Tunnel {
    [CmdletBinding()]
    param (
        # VCDA Server
        [Parameter(Mandatory = $false)]
        [PSTypeName('VCDAServer')]$Server,
        # tunnel URL
        [Parameter(Mandatory = $true)]
        [ValidateScript({[system.uri]::IsWellFormedUriString($_, 'Absolute') -and ([system.uri]$_).Scheme -eq 'https' -and ([Uri]$_).Port -eq 8047 }, `
                ErrorMessage = "'{0}' is not a tunnel API endpoint, it must be in the format 'https://tunnel-address:8047'")]
        [string]
        $url,
        [Parameter(Mandatory = $false)]
        [string]
        $certificate,
        [Parameter(Mandatory = $true)]
        [string]
        $rootPassword


    )

    process {
        try {
            $LocalvarServer = $Global:DefaultVCDAServer
            if ($null -ne $server) {
                $LocalvarServer = $server
            }
            #if thumbpring is not provided try to get the thumbprint and use it, less secure but more simple way.
            if (-not $certificate) {
                $certificate = (Get-VCDARemoteCert -Server $LocalvarServer -url $url -viaTunnel:$false).encoded
            }
            $LocalVarBodyParameter = [ordered]@{
                'url'          = ${url}
                'rootPassword' = ${rootPassword}
                'certificate'  = ${certificate}
            }
            $LocalVarBodyParameter = $LocalVarBodyParameter | ConvertTo-Json -Depth 100

            $LocalvarInvokeParams = @{
                'path'   = '/config/tunnels'
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