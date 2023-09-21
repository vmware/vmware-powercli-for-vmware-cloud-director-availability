<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Register-Replicators {
    [CmdletBinding()]
    param (
        # VCDA Mnager VM
        [Parameter(Mandatory = $false)]
        $VCDA_Manager_VM,
        # VCDA Mnager VM
        [Parameter(Mandatory = $false)]
        $VCDA_replicator_VM
    )
    process {
        try {
            if ($null -eq $VCDA_Manager_VM.ExtensionData.guest.IpAddress) {
                Write-Error "Failed to get manager IP"
            }
            if ($null -eq $VCDA_replicator_VM.ExtensionData.guest.IpAddress) {
                Write-Error "Failed to get replicator IP"
            }
            $manager_ip = $VCDA_Manager_VM.ExtensionData.guest.IpAddress
            $replicator_ip = $VCDA_replicator_VM.ExtensionData.guest.IpAddress
            Write-Log -message "Registering replicator '$replicator_ip' with manager '$manager_ip'"
            $manager_service_cert = ($VCDA_Manager_VM.ExtensionData.Config.ExtraConfig | Where-Object { $_.key -eq 'guestinfo.manager.certificate' }).value
            $replicator_service_thumbprint = ($VCDA_replicator_VM.ExtensionData.Config.ExtraConfig | Where-Object { $_.key -eq 'guestinfo.replicator.thumbprint' }).value
            $manager_url = 'https://' + $manager_ip + ':8441'
            $manager_remote_cert = Get-RemoteCert -url  $manager_url -type string
            if ($manager_remote_cert -ne $manager_service_cert) {
                Write-Error "Ceritificates doesn't match."
            }
            $man_pass = Get-VCDAVMPassword -name $VCDA_Manager_VM.name
            $man_credentials = New-Object System.Management.Automation.PSCredential("root", $man_pass.current)
            $repl_pass = Get-VCDAVMPassword -name $VCDA_replicator_VM.name

            $vcda_server = Connect-VCDA -Server $manager_ip -AuthType Local -Credentials $man_credentials -port 8441 -SkipCertificateCheck -NotDefault
            $SSO_domain = (Get-IdentitySource -System).name
            $ssoUser = $Script:vcda_avs_params.vsphere.sa_username + '@' + $SSO_domain
            $ssoPass = $PersistentSecrets[$Script:vcda_avs_params.vsphere['sa_current_password']] | ConvertTo-SecureString -AsPlainText -Force
            $LocalvarInvokeParams = @{
                'apiUrl'        = 'https://' + $replicator_ip + ':8043'
                'apiThumbprint' = $replicator_service_thumbprint
                'rootPassword'  = $repl_pass.current
                'ssoUser'       = $ssoUser
                'ssoPassword'   = $ssoPass
            }
            Register-VCDAReplicator @LocalvarInvokeParams -server $vcda_server | Out-Null
            Write-Log -message "Replicator '$replicator_ip' registered successfully with manager '$manager_ip'"
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

    }
}