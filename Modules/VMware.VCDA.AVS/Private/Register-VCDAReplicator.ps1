<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Register-VCDAreplicator {
    [CmdletBinding()]
    param (
        # VCDA Server
        [Parameter(Mandatory = $false)]
        [PSTypeName('VCDAServer')]$Server,
        # replicator apiUrl
        [Parameter(Mandatory = $true)]
        [ValidateScript({ [system.uri]::IsWellFormedUriString($_, 'Absolute') -and ([system.uri]$_).Scheme -eq 'https' -and ([Uri]$_).Port -eq 8043}, `
                ErrorMessage = "'{0}' is not a Replicator API endpoint, it must be in the format 'https://replicator-address:8043'")]
        [string]
        $apiUrl,
        [Parameter(Mandatory = $false)]
        [string]
        $apiThumbprint,
        [Parameter(Mandatory = $true)]
        [SecureString]
        $rootPassword,
        [Parameter(Mandatory = $true)]
        [string]
        $ssoUser,
        [Parameter(Mandatory = $true)]
        [SecureString]
        $ssoPassword
    )

    process {
        try {
            $LocalvarServer = $Global:DefaultVCDAServer
            if ($null -ne $server) {
                $LocalvarServer = $server
            }
            if ($LocalvarServer.ServiceType -ne "MANAGER"){
                Write-Error "You are not connected to a Manager service, current server '$($localvarServer.Server)' is '$($LocalvarServer.ServiceType)' service. "
            }
            $site = (Get-Config -server $LocalvarServer).site
            #if thumbpring is not provided try to get the thumbprint and use it, less secure but more simple way.
            if (-not $apiThumbprint) {
                $apiThumbprint = (Get-VCDARemoteCert -Server $LocalvarServer -url $apiUrl -viaTunnel:$false).certificate.thumbPrint
            }
            $root_pass = $rootPassword | ConvertFrom-SecureString -AsPlainText
            $sso_pass = $ssoPassword | ConvertFrom-SecureString -AsPlainText
            $LocalVarBodyParameter = [ordered]@{
                'replicatorId' = $null
                'owner'        = '*'
                'site'         = ${site}
                'description'  = ''
                'details'      = @{
                    'apiUrl'        = ${apiUrl}
                    'apiThumbprint' = ${apiThumbprint}
                    'rootPassword'  = ${root_pass}
                    'ssoUser'       = ${ssoUser}
                    'ssoPassword'   = ${sso_pass}
                }
            }
            $LocalVarBodyParameter = $LocalVarBodyParameter | ConvertTo-Json -Depth 100
            $LocalvarInvokeParams = @{
                'path'   = '/replicators'
                'method' = 'POST'
                'client' = $LocalvarServer
                'body'   = $LocalVarBodyParameter
            }
            $LocalVarResponse = Invoke-VCDArequest @LocalvarInvokeParams
            return $LocalVarResponse.Response
        }
        catch {
            if ($_.TargetObject -eq 'VCDA_Server_Error' -and $_.Exception.Message -match 'The replicator is already paired to the manager.'){
                return "Replicator is already registered"
            }
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}