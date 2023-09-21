<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Set-LookupService {
    [CmdletBinding()]
    param (
        # VCDA Server
        [Parameter(Mandatory = $false)]
        [PSTypeName('VCDAServer')]$Server,
        # VCD URL
        [Parameter(Mandatory = $true)]
        [ValidateScript({ [system.uri]::IsWellFormedUriString($_, 'Absolute') -and ([uri]$_).Scheme -in 'https' }, `
                ErrorMessage = "'{0}' is not a lookup service URL, it must be in the format 'https://example.local/lookupservice/sdk/'")]
        [string]
        $url,
        [Parameter(Mandatory = $false)]
        [string]
        $Thumbprint
    )

    process {
        try {
            $LocalvarServer = $Global:DefaultVCDAServer
            if ($null -ne $server) {
                $LocalvarServer = $server
            }
            #if thumbpring is not provided try to get the thumbprint and use it, less secure but more simple way.
            if (-not $Thumbprint) {
                $Thumbprint = (Get-VCDARemoteCert -Server $LocalvarServer -url $url -viaTunnel:$false).certificate.thumbPrint
            }
            $LocalVarBodyParameter = @{
                'url'        = ${url}
                'thumbprint' = ${Thumbprint}
            }
            $LocalVarBodyParameter = $LocalVarBodyParameter | ConvertTo-Json -Depth 100
            $LocalvarInvokeParams = @{
                'path'   = '/config/lookup-service'
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