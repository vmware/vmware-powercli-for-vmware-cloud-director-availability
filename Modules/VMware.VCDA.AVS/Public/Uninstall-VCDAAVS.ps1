<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Uninstall-VCDAAVS {
    <#
.SYNOPSIS
    Delete all VCDA VMs, any custome roles, folders and accounts used by VCDA.
.DESCRIPTION
    Delete all VCDA VMs, any custome roles, folders and accounts used by VCDA.
    All VMs must be in Powered Off state.
.EXAMPLE
    Uninstall-VCDAAVS -AcceptUninstall
    Will Delete all VCDA VMs, any custome roles, folders and accounts used by VCDA.
#>

    [AVSAttribute(30, UpdatesSDDC = $false)]
    [CmdletBinding()]

    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Accept that All VCDA virtual machines, any custome roles, folders and accounts used by VCDA. will be deleted.')]
        [switch]$AcceptUninstall
    )
    Try {
        #make sure vc connection is healthy, script will fail if not
        if ($null -eq ((Get-View SessionManager -Server $global:DefaultVIServer).CurrentSession)) {
            Write-Error "vCenter server '$($Global:defaultviserver.Name)' connection is not heathy."
        }
        if ($AcceptUninstall -ne $true) {
            Write-Error 'You must accept that All VCDA virtual machines, any custome roles, folders and accounts used by VCDA will be deleted.'
        }
        #get SSO Domain
        $SSO_domain = (Get-IdentitySource -System).name
        $VCDA_VMs = Get-VCDAVM -ErrorAction SilentlyContinue
        if ($null -eq $VCDA_VMs) {
            Write-Log -message "No VCDA VMs found."
        }
        elseif ($VCDA_VMs) {
            #check if all VMs are in powered off state
            $power_on_count = 0
            $VCDA_VMs | Where-Object { $_.PowerState -ne "PoweredOff" } | ForEach-Object {
                Write-Log -message "VM '$($_.name)' is in '$($_.PowerState)' State."
                $power_on_count += 1
            }
            if ($power_on_count -ne 0) {
                Write-Error "Found $power_on_count VCDA VMs not in powered off state. Power off all VMs and try again."
            }
            elseif ($power_on_count -eq 0) {
                foreach ($vm in $VCDA_VMs) {
                    Write-Log -message "Deleting VM '$($vm.name)'"
                    Remove-VM -VM $vm -DeletePermanently -Confirm:$false
                }
            }
        }
        #proceed with clean up if all VMs are removed successfully
        if ($null -eq (Get-VCDAVM)) {
            #remove sso uer
            $sso_user = Get-SsoPersonUser -Name $Script:vcda_avs_params.vsphere.sa_username -Domain $SSO_domain
            if ($null -ne $sso_user) {
                Write-Log -message "Removing VCDA service account user '$($Script:vcda_avs_params.vsphere.sa_username)'"
                Remove-SsoPersonUser -User $sso_user
            }
            else {
                Write-Log -message "VCDA service account '$($Script:vcda_avs_params.vsphere.sa_username)' not found."
            }
            #remove vc role
            $role = Get-VIRole -Name $Script:vcda_avs_params.vsphere.vsphere_role -ErrorAction SilentlyContinue
            if ($null -ne $role) {
                Write-Log -message "Removing vCenter Role '$($Script:vcda_avs_params.vsphere.vsphere_role)'"
                Remove-VIRole -Role $role -Confirm:$false -Force
            }
            else {
                Write-Log -message "vCenter Role '$($Script:vcda_avs_params.vsphere.vsphere_role)' not found."
            }
            #remove the secure folder
            $vm_folder = Get-Folder -Name $Script:vcda_avs_params.vsphere.folder -ErrorAction SilentlyContinue
            if ($null -ne $vm_folder) {
                Write-Log -message "Deleting secure folder '$($Script:vcda_avs_params.vsphere.folder)'"
                Remove-Folder -Folder $vm_folder -Confirm:$false
            }
            else {
                Write-Log -message "Secure folder '$($Script:vcda_avs_params.vsphere.folder)' not found."
            }
        }

    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}