<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Register-Tunnel {
    [CmdletBinding()]
    param (
        # VCDA Mnager VM
        [Parameter(Mandatory = $false)]
        $VCDA_Manager_VM,
        # VCDA Tunnel VM
        [Parameter(Mandatory = $false)]
        $VCDA_tunnel_vm,
        # log prefix
        [Parameter(Mandatory = $false)]
        [string]$LogPrefix
    )
    process {
        try {
            if ($null -eq $VCDA_Manager_VM.ExtensionData.guest.IpAddress) {
                Write-Error "Failed to get manager IP"
            }
            if ($null -eq $VCDA_tunnel_vm.ExtensionData.guest.IpAddress) {
                Write-Error "Failed to get tunnel IP"
            }
            $manager_ip = $VCDA_Manager_VM.ExtensionData.guest.IpAddress
            $tunnel_ip = $VCDA_tunnel_vm.ExtensionData.guest.IpAddress

            Write-Log -message "Register the Tunnel Service '$($VCDA_tunnel_vm.name)' ($tunnel_ip) with the Cloud Service '$($VCDA_Manager_vm.name)' ($manager_ip)." -LogPrefix $LogPrefix

            $manager_service_cert = ($VCDA_Manager_VM.ExtensionData.Config.ExtraConfig | Where-Object { $_.key -eq 'guestinfo.cloud.certificate' }).value

            $tunnel_service_cert = ($VCDA_tunnel_vm.ExtensionData.Config.ExtraConfig | Where-Object { $_.key -eq 'guestinfo.tunnel.certificate' }).value

            $manager_url = 'https://' + $manager_ip
            $manager_remote_cert = Get-RemoteCert -url  $manager_url -type string
            if ($manager_remote_cert -ne $manager_service_cert) {
                Write-Error "Certificates doesn't match."
            }
            $man_pass = Get-VCDAVMPassword -name $VCDA_Manager_VM.Name
            $tun_pass = Get-VCDAVMPassword -name $VCDA_tunnel_vm.Name
            $man_credentials = New-Object System.Management.Automation.PSCredential("root", $man_pass.current)

            $vcda_server = Connect-VCDA -Server $manager_ip -AuthType Local -Credentials $man_credentials -SkipCertificateCheck -NotDefault
            $url = 'https://' + $tunnel_ip + ':8047'
            $configured_tunnel = Get-Tunnel -url $url -server $vcda_server
            if ($configured_tunnel) {
                Write-Log -message "Tunnel Service already configured." -LogPrefix $LogPrefix
            }
            else {
                $LocalvarInvokeParams = @{
                    'url'          = $url
                    'certificate'  = $tunnel_service_cert
                    'rootPassword' = ($tun_pass.current | ConvertFrom-SecureString -AsPlainText)
                }
                Set-Tunnel @LocalvarInvokeParams -server $vcda_server | Out-Null
                Write-Log -message "Tunnel Service successfully configured." -LogPrefix $LogPrefix
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

    }
}