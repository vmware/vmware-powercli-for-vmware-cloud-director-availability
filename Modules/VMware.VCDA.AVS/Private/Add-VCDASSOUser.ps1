<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Add-VCDASSOUser {
    [CmdletBinding()]
    <#
    .DESCRIPTION
       Create Custom VCDA role with required privileges
    #>
    param (
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FirstName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Lastname,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Domain,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]$Credentials,
        [Parameter(Mandatory = $false)]
        [switch]
        $ResetPassword
    )

    try {
        $username = $Credentials.UserName
        $password = $Credentials.GetNetworkCredential().Password
        $sso_user = Get-SsoPersonUser -Name $username -Domain $Domain

        #create user if it doesn't exists
        if ($null -eq $sso_user) {
            Write-Log -message "Addind VCDA Service account '$username'."
            New-SsoPersonUser -UserName $username -Password $password -FirstName $FirstName -LastName $Lastname -Description "VCDA AVS User" -ErrorAction Stop
        }
        #change the password of the user.
        elseif ($ResetPassword.IsPresent)  {
            Write-Log -message "Reseting '$username' password."
            Set-SsoPersonUser -NewPassword $password -User $sso_user -ErrorAction Stop
        }
        else {
            Write-Log -message "User '$username' already exists"
            return $sso_user
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

}