<#
Copyright (c) 2023-2025 Broadcom. All Rights Reserved.
SPDX-License-Identifier: BSD-2-Clause
#>
function Repair-LocalTunnel {
    <#
    .SYNOPSIS
        Repair local tunnel appliance with manager (cloud service).
    .DESCRIPTION
        Repair the local tunnel with cloud service, it's required when tunnel's certificate is changed.
    .EXAMPLE
        Repair-LocalTunnel
    #>
    [AVSAttribute(30, UpdatesSDDC = $false)]
    [CmdletBinding()]
    param ()
    Try {
        #make sure vc connection is healthy, script will fail if not
        if ($null -eq ((Get-View SessionManager -Server $global:DefaultVIServer).CurrentSession)) {
            Write-Error "vCenter server '$($Global:defaultviserver.Name)' connection is not heathy."
        }
        Write-log -message "Starting repairing of local tunnel appliance."
        $manager_vm = Get-VCDAVM -type "cloud"
        if ($null -eq $manager_vm) {
            Write-Log -message "No Manager VM found, cannot repair the tunnel."
            return
        }
        $tunnel_vm = Get-VCDAVM -type "tunnel" -vmname $VMName
        if ($null -eq $tunnel_vm) {
            Write-Log -message "No Tunnel VM found, cannot repair the tunnel."
            return
        }
        $manager_ip = $manager_vm.ExtensionData.guest.IpAddress
        if ($null -eq $manager_ip) {
            Write-Error "Can't find the IP address of VM '$($manager_vm.name)', and cannot proceed with repair of tunnel.'"
        }
        $cloud_service_cert = ($manager_vm.ExtensionData.Config.ExtraConfig | Where-Object { $_.key -eq 'guestinfo.cloud.certificate' }).value
        #make sure the certificate we see over the network matches the one of the VM.
        $manager_url = 'https://' + $manager_ip
        $cloud_remote_cert = Get-RemoteCert -url  $manager_url -type string
        if ($cloud_remote_cert -ne $cloud_service_cert) {
            Write-Error "Manager certificate seen on the network differs from the expected one."
        }
        $man_pass = Get-VCDAVMPassword -name $manager_vm.name
        $man_credentials = New-Object System.Management.Automation.PSCredential("root", $man_pass.current)
        $vcda_server = Connect-VCDA -Server $manager_ip -AuthType Local -Credentials $man_credentials -SkipCertificateCheck -NotDefault
        try {
            if ($tunnel_vm.PowerState -ne "PoweredOn") {
                write-log -message "Tunnel VM '$($tunnel_vm.name)' cannot be repaired since it's not in 'Powered On' state. Power on the VM and try again."
                continue
            }
            $tunnel_pass = Get-VCDAVMPassword -Name $tunnel_vm.name
            $tunnel_creds = New-Object System.Management.Automation.PSCredential("root", $tunnel_pass.current)
            $tunnel_config = Get-Tunnel -server $vcda_server
            $tunnel_update = Update-Tunnel -server $vcda_server -rootPassword ($tunnel_pass.current | ConvertFrom-SecureString -AsPlainText) `
                -id $tunnel_config.id -url $tunnel_config.url
                write-log -message "Tunnel repaired successfully."
        }
        catch {
            Write-Log -message $_ -LogPrefix "[ERROR]"
            Write-Error $_ -ErrorAction Continue
        }

    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}