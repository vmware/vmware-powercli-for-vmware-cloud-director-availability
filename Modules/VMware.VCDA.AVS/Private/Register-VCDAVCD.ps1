<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Register-VCDAVCD {
    [CmdletBinding()]
    param (
        # VCDA Server
        [Parameter(Mandatory = $false)]
        [PSTypeName('VCDAServer')]$Server,
        # VCD URL
        [Parameter(Mandatory = $true)]
        [ValidateScript({ [system.uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri]$_).Scheme -in 'https' }, `
                ErrorMessage = "'{0}' is not a VCD URL, it must be in the format 'https://example.local/api'")]
        [string]
        $url,
        [Parameter(Mandatory = $true)]
        [string]
        $username,
        [Parameter(Mandatory = $true)]
        [SecureString]
        $password,
        [Parameter(Mandatory = $false)]
        [string]
        $vcdThumbprint
    )

    process {
        try {
            $LocalvarServer = $Global:DefaultVCDAServer
            if ($null -ne $server) {
                $LocalvarServer = $server
            }
            #if thumbpring is not provided try to get the thumbprint and use it, less secure but more simple way.
            if (-not $vcdThumbprint) {
                $vcdThumbprint = (Get-VCDARemoteCert -Server $LocalvarServer -url $url -viaTunnel:$false).certificate.thumbPrint
            }
            $vcd_password = ($password | ConvertFrom-SecureString -AsPlainText)
            $LocalVarBodyParameter = @{
                'vcdUrl'        = ${url}
                'vcdUsername'   = ${username}
                'vcdPassword'   = ${vcd_password}
                'vcdThumbprint' = ${vcdThumbprint}
            }
            $LocalVarBodyParameter = $LocalVarBodyParameter | ConvertTo-Json -Depth 100


            $LocalvarInvokeParams = @{
                'path'   = '/config/vcloud'
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