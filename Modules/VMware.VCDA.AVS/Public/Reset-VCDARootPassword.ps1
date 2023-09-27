<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Reset-VCDARootPassword {
    <#
    .SYNOPSIS
        Reset the root password of all or any given VCDA virtual machine.
    .DESCRIPTION
        Reset the root password of all or any given VCDA virtual machine, by default password will be changed only if it expires within the next 30 days.
    .PARAMETER VMName
        Name of the VCDA virtual machine on which the password will be reset.
    .PARAMETER force
        Will reset the password anyway, without force option password will be reset only if it expires in the next 30 days.
    .EXAMPLE
        Reset-VCDARootPassword -force
        Resets the root password of all VCDA virtual machines in the environment regardless of the expiration date.
    #>
    [AVSAttribute(30, UpdatesSDDC = $false)]
    [CmdletBinding()]

    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Name of the VCDA virtual machine on which the password will be reset.")]
        [ValidateNotNullOrEmpty()]
        [switch]
        $force,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Reset the password regardless of the expiration date.")]
        [ValidateNotNullOrEmpty()]
        [string]$VMName
    )
    Try {
        #make sure vc connection is healthy, script will fail if not
        if ($null -eq ((Get-View SessionManager -Server $global:DefaultVIServer).CurrentSession)) {
            Write-Error "vCenter server '$($Global:defaultviserver.Name)' connection is not heathy."
        }
        $VCDA_VMs = Get-VCDAVM -VMName $PSBoundParameters.VMName
        foreach ($VM in $VCDA_VMs) {
            $role = ($VM.ExtensionData.Config.VAppConfig.Property | Where-Object { $_.id -eq 'guestinfo.cis.appliance.role' }).DefaultValue
            switch ($role) {
                cloud {
                    $service_cert = ($vm.ExtensionData.Config.ExtraConfig | Where-Object { $_.key -eq 'guestinfo.cloud.certificate' }).value
                }
                tunnel {
                    $service_cert = ($vm.ExtensionData.Config.ExtraConfig | Where-Object { $_.key -eq 'guestinfo.tunnel.certificate' }).value
                }
                replicator {
                    $service_cert = ($vm.ExtensionData.Config.ExtraConfig | Where-Object { $_.key -eq 'guestinfo.replicator.certificate' }).value
                }
            }
            $IP = $VM.guest.ExtensionData.IpAddress
            if ($null -eq $IP){
                Write-Log -message "Can't find IP address of VM $($vm.name), VM power state is: '$($vm.PowerState)'."
                continue
            }
            $remote_cert = Get-RemoteCert -url ('https://' + $IP) -type string
            if ($remote_cert -ne $service_cert) {
                Write-Error "Ceritificates doesn't match."
            }
            $vm_passwords = (Get-VCDAVMPassword -name ($vm.Name))
            $old_creds = New-Object System.Management.Automation.PSCredential("root", $vm_passwords.old)
            $creds = New-Object System.Management.Automation.PSCredential("root", $vm_passwords.current)
            $new_pass = Get-VCDARandomPassword -MinLength 12 -MaxLength 24 -MinNumericCount 2 -MinSpecialCharCount 2 `
                -MinUppercaseCount 2 -MinLowercaseCount 2 -MaxIdenticalAdjacentCharacters 2
            #reset root password if expiration date is within the next 30 days or if force option is used.
            try {
                $vcda_server = Connect-VCDA -Server $ip -AuthType Local -Credentials $creds -SkipCertificateCheck -NotDefault
                $password_status = Get-VCDAPassExp -Server $vcda_server
                $password_exp_date = (get-date).AddSeconds($password_status.secondsUntilExpiration)
                if ($password_exp_date.AddDays(-30) -lt (Get-Date) -or $force -eq $true) {
                    Write-Log -message "Trying to set root password of VM '$($vm.name)' ($IP) using current credentials."
                    #once login is successfull, update current password to old pass in persistentSecrets
                    $persistentSecrets[($vm.Name) + $Script:vcda_avs_params.vcda.old_password] = ($vm_passwords.current | ConvertFrom-SecureString -AsPlainText)
                    #save_new password to persistentSecrets
                    $persistentSecrets[($vm.Name) + $Script:vcda_avs_params.vcda.current_password] = $new_pass
                    Set-VCDAPassword -Server $vcda_server -OldPassword ($vm_passwords.current | ConvertFrom-SecureString -AsPlainText) -NewPassword $new_pass
                }
                else {
                    Write-Log -message "Root password of VM '$($vm.name)' ($IP) will expire on: $password_exp_date, use force option to reset the password anyway. "
                }
            }
            #in case current password is not correct try login with old pass (in case previous run has failed and password was not change successfully)
            #also update persistentSecrets current password to correct one.
            catch {
                if ($_ -match "Unable to connect to VCDA Server '$ip'. The server returned the following: 'Authentication required.'") {
                    $vcda_server = Connect-VCDA -Server $ip -AuthType Local -Credentials $old_creds -SkipCertificateCheck -NotDefault
                    $password_status = Get-VCDAPassExp -Server $vcda_server
                    $password_exp_date = (get-date).AddSeconds($password_status.secondsUntilExpiration)
                    if ($password_exp_date.AddDays(-30) -lt (Get-Date) -or $force -eq $true) {
                        Write-Log -message "Trying to set root password of VM '$($vm.name)' ($IP) using old credentials."
                        #set the current creds to the proper one
                        $persistentSecrets[($vm.Name) + $Script:vcda_avs_params.vcda.current_password] = $new_pass
                        Set-VCDAPassword -Server $vcda_server -OldPassword ($vm_passwords.old | ConvertFrom-SecureString -AsPlainText) -NewPassword $new_pass
                    }
                    else {
                        $persistentSecrets[($vm.Name) + $Script:vcda_avs_params.vcda.current_password] = ($vm_passwords.old | ConvertFrom-SecureString -AsPlainText)
                        #set current password to old password which is the correct one.
                        Write-Log -message "Root password of VM '$($vm.name)' ($IP) will expire on: $password_exp_date, use force option to reset the password anyway. "
                    }
                }
                else {
                    $PSCmdlet.ThrowTerminatingError($_)
                }
            }
        }
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}