<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Set-VCDAPassword {
    [CmdletBinding()]
    param (
        # VCDA Server
        [Parameter(Mandatory = $false)]
        [PSTypeName('VCDAServer')]$Server,
        # new password
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [string]
        $NewPassword,
        # old password
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [string]
        $OldPassword
    )

    process {
        try {
            $LocalvarServer = $Global:DefaultVCDAServer
            if ($null -ne $server) {
                $LocalvarServer = $server
            }

            $Config_Secret = @{
                'Config-Secret' = $OldPassword
            }
            $LocalVarBodyParameter = @{
                'rootPassword' = $NewPassword
            }
            $LocalVarBodyParameter = $LocalVarBodyParameter | ConvertTo-Json -Depth 100

            $LocalvarInvokeParams = @{
                'path'       = '/config/root-password'
                'method'     = 'POST'
                'client'     = $LocalvarServer
                'AddHeaders' = $Config_Secret
                'body'       = $LocalVarBodyParameter
            }
            $LocalVarResponse = Invoke-VCDARequest @LocalvarInvokeParams
            if ($LocalVarResponse.StatusCode -eq 204 ) {
                Write-Log -message 'Root Password Changed Successfully'
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}