<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Repair-LookupService {
    <#
    .SYNOPSIS
        Repair Lookup service
    .DESCRIPTION
        Repair Lookup service of all VCDA appliances, usually it's required once VC/Lookup service certificate or address is changed.
        By default the lookup service on all VCDA VMs is repaired to repair single VM use 'VMName' parameter.
    .EXAMPLE
        Repair-LookupService
    #>
    [AVSAttribute(30, UpdatesSDDC = $false)]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Name of the VCDA VM.')]
        [ValidateNotNullOrEmpty()]
        [string]
        $VMName
    )
    Try {
        #make sure vc connection is healthy, script will fail if not
        if ($null -eq ((Get-View SessionManager -Server $global:DefaultVIServer).CurrentSession)) {
            Write-Error "vCenter server '$($Global:defaultviserver.Name)' connection is not heathy."
        }
        $vcda_vms = Get-VCDAVM -vmname $VMName
        if ($vcda_vms.count -eq 0){
            Write-log -message "No VCDA VMs found, cannot proceed with repair of lookup service."
            return
        }
        ($lookup_service = New-Object System.UriBuilder $Global:DefaultVIServer.ServiceUri).Path = '/lookupservice/sdk'
        $lookup_service_sha = Get-RemoteCert -url $lookup_service.Uri.AbsoluteUri -type sha256
        foreach ($VM in $vcda_vms) {
            try {
                if ($VM.PowerState -ne "PoweredOn") {
                    write-log -message "Cannot repair the Lookup service of VM '$($VM.name)' since it's not in 'Powered On' state. Power on the VM and try again."
                    continue
                }
                $vm_pass = Get-VCDAVMPassword -Name $vm.name
                $vm_creds = New-Object System.Management.Automation.PSCredential("root", $vm_pass.current)
                $vm_ip = $vm.ExtensionData.guest.IpAddress
                if ($null -eq $vm_ip) {
                    Write-Error "Failed to get the IP address of VM $($vm.name)"
                }
                $role = ($vm.ExtensionData.Config.VAppConfig.Property | Where-Object { $_.id -eq 'guestinfo.cis.appliance.role' }).DefaultValue
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
                $vm_remote_cert = Get-RemoteCert -url "https://$vm_ip" -type string
                if ($vm_remote_cert -ne $service_cert) {
                    Write-Error "VM certificate seen on the network differs from the expected one."
                }
                $vm_server = Connect-VCDA -server $vm_ip -AuthType Local -Credentials $vm_creds -port 443 -SkipCertificateCheck -NotDefault
                Write-Log -message "Repairing Lookup service of $role service - VM '$($vm.name)' ($vm_ip)."
                $response = Set-LookupService -Server $vm_server -url $lookup_service.Uri.AbsoluteUri -Thumbprint $lookup_service_sha
                if ($role -eq 'cloud') {
                    #set manager service lookup service
                    $manager_server = Connect-VCDA -Server $vm_ip -port 8441 -AuthType Local -Credentials $vm_creds -SkipCertificateCheck -NotDefault
                    Write-Log -message "Repairing Lookup service of manager service - VM '$($vm.name)' ($vm_ip)."
                    $response = Set-LookupService -Server $manager_server -url $lookup_service.Uri.AbsoluteUri -Thumbprint $lookup_service_sha
                }
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