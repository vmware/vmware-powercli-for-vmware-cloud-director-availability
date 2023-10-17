<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Reset-ServiceAccountPassword {
    <#
    .SYNOPSIS
        Reset the password of vSphere service account that is used by VCDA, and repair all replicators using the new password, all Replicator VMs must be in Powered on state.
    .DESCRIPTION
        Reset the password of vSphere service account that is used by VCDA, and repair all replicators using the new password, all Replicator VMs must be in Powered on state.
    .PARAMETER force
        Will reset the Service Account password even if not all replicators are in Powered on state.
    .EXAMPLE
        Reset-ServiceAccountPassword -force
    #>
    [AVSAttribute(30, UpdatesSDDC = $false)]
    [CmdletBinding()]

    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Reset the Service Account password even if not all replicators are in Powered on state")]
        [ValidateNotNullOrEmpty()]
        [switch]
        $force
    )
    Try {
        #make sure vc connection is healthy, script will fail if not
        if ($null -eq ((Get-View SessionManager -Server $global:DefaultVIServer).CurrentSession)) {
            Write-Error "vCenter server '$($Global:defaultviserver.Name)' connection is not heathy."
        }
        $replicator_vms = Get-VCDAVM -type "replicator" -vmname $VMName
        if (($replicator_vms.PowerState -ne "PoweredOn").count -gt 0 -and !$force) {
            return Write-log -message "Not all Replicators are in Powered on state, use 'force' option to reset the password anyway."
        }
        $SSO_domain = (Get-IdentitySource -System).name
        Write-Log -message "Generate random password for service account '$($PersistentSecrets['sa-username'])'."
        $VCDA_AVS_ADMIN_Password = Get-SsoPasswordPolicy | Get-VCDARandomPassword
        #save current password to 'sa_old_password' in PersistentSecrets
        $old_pass = $PersistentSecrets[$Script:vcda_avs_params.vsphere.sa_current_password]
        $PersistentSecrets[$Script:vcda_avs_params.vsphere.sa_old_password] = $old_pass
        $PersistentSecrets[$Script:vcda_avs_params.vsphere.sa_current_password] = $VCDA_AVS_ADMIN_Password

        #reset VCDA SSO user password
        $vcda_avs_admin_creds = New-Object System.Management.Automation.PSCredential($PersistentSecrets['sa-username'], `
            ($PersistentSecrets[$Script:vcda_avs_params.vsphere.sa_current_password] | ConvertTo-SecureString -AsPlainText -Force))
        $vcda_service_account = Add-VCDASSOUser -FirstName "VCDA_AVS" -Lastname "Service_Account" -Credentials $vcda_avs_admin_creds -Domain $SSO_domain -ResetPassword
        Repair-LocalReplicator
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}