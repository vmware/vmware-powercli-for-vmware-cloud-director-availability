<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Add-VCDASSOGroup {
    [CmdletBinding()]
    <#
    .DESCRIPTION
       Create Custom VCDA group, if not already created and add the user as member.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $user,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Domain
    )

    try {
        $username = Get-SsoPersonUser -Name $user -Domain $Domain
        $group = Get-SsoGroup -Domain $Domain -Name $Name
        #create group if it doesn't exists
        if ($null -eq $group) {
            Write-Log -message "Creating SSO Admin group '$name'"
            $group = New-SsoGroup -Name $Name -Description $Description
        }
        #add user to group
        if ($null -ne $username) {
            if (($group | Get-SsoPersonUser) -match $user){
                Write-Log -message "User '$($username.name)' is already member of '$($group.name)'"
            }
            else {
                Write-Log -message "Adding '$($username.name)' to group '$($group.name)'"
                Add-UserToSsoGroup -User $username -TargetGroup $group
            }
        }
        elseif ($null -eq $username) {
            Write-Log -message "User '$User' was not found"
            Write-Warning "User '$user' was not found and not added to group '$name'"
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

}