<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-VCDAVMPassword {
    <#
    .SYNOPSIS
    Get a vm password from persistent secrets
    .DESCRIPTION
    Get a vm password from persistent secrets
    #>
    [CmdletBinding()]


    param (
        [Parameter(Mandatory = $true)]
        [string]$name
    )
    Try {
        $current_password = $persistentSecrets[$name + $Script:vcda_avs_params.vcda.current_password] | ConvertTo-SecureString -AsPlainText -Force -ErrorAction SilentlyContinue
        $old_password = $persistentSecrets[$name + $Script:vcda_avs_params.vcda.old_password] | ConvertTo-SecureString -AsPlainText -Force -ErrorAction SilentlyContinue
        if ($null -eq $current_password){
            Write-Error "Failed to get root password for VM '$Name'."
        }
        return @{
            name    = $name
            current = $current_password
            old     = $old_password
        }
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

