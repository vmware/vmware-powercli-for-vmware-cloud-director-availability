<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Set-VCDASiteName {
    [CmdletBinding()]
    param (
        # VCDA Server
        [Parameter(Mandatory = $false)]
        [PSTypeName('VCDAServer')]$Server,
        # Site Name
        [Parameter(Mandatory = $true,  HelpMessage = "Only latin alphanumerical characters and '-' are allowed in site name.")]
        [ValidatePattern('^[a-zA-Z0-9-]+$', ErrorMessage = "'{0}' is not a valid Site name, Only latin alphanumerical characters and '-' are allowed" )]
        [string]
        $Name,
        # Site Description
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [string]
        $Description
    )

    process {
        try {
            $LocalvarServer = $Global:DefaultVCDAServer
            if ($null -ne $server) {
                $LocalvarServer = $server
            }
            $LocalVarBodyParameter = @{
                'localSite' = ${Name}
                'localSiteDescription' = ${Description}
            }
            $LocalVarBodyParameter = $LocalVarBodyParameter | ConvertTo-Json -Depth 100

            $LocalvarInvokeParams = @{
                'path'       = '/config/site'
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