<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Repair-LocalReplicator {
    <#
    .SYNOPSIS
        Repair all local VCDA replicator VMs in the cloud site with manager services.
    .DESCRIPTION
        Repair all local VCDA replicator VMs in the cloud site with manager services.
        The script will not repair any remote replicators.
    .EXAMPLE
        Repair-LocalReplicator
    #>
    [AVSAttribute(30, UpdatesSDDC = $false)]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Name of the VCDA Replicator VM to Repair.')]
        [ValidateNotNullOrEmpty()]
        [string]
        $VMName
    )
    Try {
        #make sure vc connection is healthy, script will fail if not
        if ($null -eq ((Get-View SessionManager -Server $global:DefaultVIServer).CurrentSession)) {
            Write-Error "vCenter server '$($Global:defaultviserver.Name)' connection is not heathy."
        }
        $manager_vm = Get-VCDAVM -type "cloud"
        $replicator_vms = Get-VCDAVM -type "replicator" -vmname $VMName

        $manager_ip = $manager_vm.ExtensionData.guest.IpAddress
        $manager_service_cert = ($manager_vm.ExtensionData.Config.ExtraConfig | Where-Object { $_.key -eq 'guestinfo.manager.certificate' }).value
        $manager_url = 'https://' + $manager_ip + ':8441'
        #make sure the certificate we see over the network matches the one of the VM.
        $manager_remote_cert = Get-RemoteCert -url  $manager_url -type string
        if ($manager_remote_cert -ne $manager_service_cert) {
            Write-Error "Manager certificate seen on the network differs from the expected one."
        }
        $man_pass = Get-VCDAVMPassword -name $manager_vm.name
        $man_credentials = New-Object System.Management.Automation.PSCredential("root", $man_pass.current)
        $vcda_server = Connect-VCDA -Server $manager_ip -AuthType Local -Credentials $man_credentials -port 8441 -SkipCertificateCheck -NotDefault
        $SSO_domain = (Get-IdentitySource -System).name
        $ssoUser = $Script:vcda_avs_params.vsphere.sa_username + '@' + $SSO_domain
        $ssoPass = $PersistentSecrets[$Script:vcda_avs_params.vsphere['sa_current_password']] | ConvertTo-SecureString -AsPlainText -Force
        Write-Log -message "Found $($replicator_vms.count) replicator VMs."
        foreach ($replicator in $replicator_vms) {
            try {
                if ($replicator.PowerState -ne "PoweredOn") {
                    write-log -message "Replicator VM '$($replicator.name)' cannot be repaired since it's not in 'Powered On' state. Power on the VM and try again."
                    continue
                }
                $replicator_pass = Get-VCDAVMPassword -Name $replicator.name
                $replicator_creds = New-Object System.Management.Automation.PSCredential("root", $replicator_pass.current)
                $replicator_ip = $replicator.ExtensionData.guest.IpAddress
                if ($null -eq $replicator_ip) {
                    Write-Error "Failed to get the IP address of VM $($replicator.name)"
                }
                $replicator_service_cert = ($replicator.ExtensionData.Config.ExtraConfig | Where-Object { $_.key -eq 'guestinfo.replicator.certificate' }).value
                $replicator_remote_cert = Get-RemoteCert -url "https://$replicator_ip" -type string
                if ($replicator_remote_cert -ne $replicator_service_cert) {
                    Write-Error "Replicator certificate seen on the network differs from the expected one."
                }
                $replicator_server = Connect-VCDA -server $replicator_ip -AuthType Local -Credentials $replicator_creds -port 8043 -SkipCertificateCheck -NotDefault
                $id = (Get-Config -Server $replicator_server).id
                $replicator_to_repair = Get-VCDAReplicator -Server $vcda_server | Where-Object { $_.id -eq $id }
                $InvokeParams = @{
                    'apiUrl'        = $replicator_to_repair.apiUrl
                    'apiThumbprint' = ""
                    'rootPassword'  = $replicator_pass.current
                    'ssoUser'       = $ssoUser
                    'ssoPassword'   = $ssoPass
                    'replicatorId'  = $replicator_to_repair.id
                    'server'        = $vcda_server
                }
                Write-Log -message "Repairing Replicator VM '$($replicator.name)' ($replicator_ip)."
                $response = Repair-VCDAReplicator @InvokeParams
            }
            catch {
                Write-Error $_ -ErrorAction Continue
            }
        }
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}