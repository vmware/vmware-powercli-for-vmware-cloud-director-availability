<#
Copyright (c) CA, Inc. All rights reserved.
SPDX-License-Identifier: LicenseRef-CA-Inc-Software-License
#>

function Update-VCDALocalCertificate {
    <#
    .SYNOPSIS
        Regenerate the self signed certificate of the VCDA appliance.
    .DESCRIPTION
        Regenerate the self signed certificate of the VCDA appliance.
        When manager vm certificate is regenerated only the manager Service certificate will be regenerate.
    .PARAMETER VMName
        Name of the VCDA Virtual Machine regenerate the self signed certificate.
        When 'VCDA-AVS-Manager-01' is provided only the manager service self signed certificate will be regenerated,
        to regenerate the cloud service certificate use the UI.
    .EXAMPLE
        Update-VCDALocalCertificate -VMName 'VCDA-AVS-Replicator-01'
        will regenerate the self certificate of VM named 'VCDA-AVS-Replicator-01'.
    #>
    [AVSAttribute(30, UpdatesSDDC = $false)]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Name of the VCDA Virtual Machine regenerate the certificate')]
        [ValidateNotNullOrEmpty()]
        [string]
        $VMName
    )
    Try {
        #make sure vc connection is healthy, script will fail if not
        if ($null -eq ((Get-View SessionManager -Server $global:DefaultVIServer).CurrentSession)) {
            Write-Error "vCenter server '$($Global:defaultviserver.Name)' connection is not heathy."
        }
        $VCDA_VMs = Get-VCDAVM -VMName $PSBoundParameters.VMName
        if ($VCDA_VMs.count -eq 0) {
            Write-Log -message "No VCDA VMs found using the specified filter."
            return
        }
        foreach ($VM in $VCDA_VMs) {
            try {
                if ($VM.PowerState -ne "PoweredOn") {
                    write-log -message "Cannot regenerate the certificate of a '$($VM.name)' since it's not in 'Powered On' state. Power on the VM and try again."
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
                if ($role -eq 'cloud') {
                    $port = 8441
                    $role = 'manager'
                }
                else {
                    $port = 443
                }
                $vm_server = Connect-VCDA -server $vm_ip -AuthType Local -Credentials $vm_creds -port $port -SkipCertificateCheck -NotDefault
                Write-Log -message "Regenerating the certificate of $role service - VM '$($vm.name)' ($vm_ip)."
                $response = Set-LocalCertificate -server $vm_server
                Write-Log -message "Operation initiated successfully '$($vm.name)', service will restart."
                Write-Log -message "VM '$($vm.name)' - Waiting for service to start, timeout is 600s."
                #wait 45s for the service to become offline
                Start-Sleep -Seconds 45
                #wait for VM service to start
                $url = [System.UriBuilder]::new("https", $vm_ip, $port, "/docs/api-guide.html").Uri.AbsoluteUri
                $boot_timeout = (Get-Date).AddSeconds(600)
                do {
                    $boot_wait = $false
                    try {
                        Start-Sleep -Seconds 10
                        $wait_boot = Invoke-WebRequest -Uri $url -Method GET -SkipCertificateCheck -TimeoutSec 5
                    }
                    catch {
                        $boot_wait = $true
                    }
                } until (
                    -not ($boot_wait) -or (Get-Date) -gt $boot_timeout
                )
                if ($null -eq $wait_boot) {
                    Write-Error "VM '$($vm.name)' - Timed out waiting for service to start'."
                }
                else {
                    Write-Log -message "VM '$($vm.name)' - Service stated successfully."
                }

                switch ($role){
                    manager {
                        Repair-LocalReplicator
                    }
                    replicator{
                        Repair-LocalReplicator -VMName $VMName
                    }
                    tunnel{
                        Repair-LocalTunnel
                    }
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