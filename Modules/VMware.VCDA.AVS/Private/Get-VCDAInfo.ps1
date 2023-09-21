<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-VCDAInfo {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSTypeName('VCDAServer')]$Server
    )
    process {
        try {
            $LocalvarServer = $Global:DefaultVCDAServer
            if ($null -ne $server){
                $LocalvarServer = $server
            }
            $LocalvarInvokeParams = @{
                'path'   = "/diagnostics/about"
                'Method' = "GET"
                'client' = $LocalvarServer
            }
            $LocalVarResult = Invoke-VCDARequest @LocalvarInvokeParams
            return $LocalVarResult.response
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}