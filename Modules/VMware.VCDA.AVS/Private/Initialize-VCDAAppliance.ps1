<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Initialize-VCDAAppliance {
    <#
    .DESCRIPTION
    Prepare VCDA appliance
    #>
    [CmdletBinding()]
    param (
        # VCDA VM
        [Parameter(Mandatory = $false)]
        $VCDA_VM,
        # VCDA VM IP
        [Parameter(Mandatory = $false)]
        $IPAddress,
        #VCDA Licnse
        [Parameter(Mandatory = $false)]
        $LicenseKey,
        # VCDA Site Name
        [Parameter(Mandatory = $false)]
        [string]$SiteName,
        # VCDA API Public Endpoint 'https://public_api_endpoint:443'
        [Parameter(Mandatory = $false)]
        [string]$PublicApiEndpoint,
        # VCD API  Endpoint 'https://vcd_api_endpoint:443/api'
        [Parameter(Mandatory = $false)]
        [string]$vcd_api_endpoint,
        # VCD UserName
        [Parameter(Mandatory = $false)]
        [string]$vcd_user,
        # VCD password
        [Parameter(Mandatory = $false)]
        [SecureString]$vcd_password

    )
    try {
        #wait 180s for VM tools to start.
        Write-Log -message "Waiting for VM tools to start of VM '$($VCDA_VM.Name)"
        $VCDA_VM = Wait-Tools -vm $VCDA_VM -TimeoutSeconds 180 -ErrorAction Stop
        Write-Log -message "VM tools started succesfully of VM '$($VCDA_VM.Name)"
        $timeout = (Get-Date).AddSeconds(180)
        Write-Log -message "Waiting for VM IP address."
        do {
            $VCDA_VM = get-vm -Id $vcda_vm.Id
            #Start-Sleep 2
        }
        until (
            ($null -ne $VCDA_VM.ExtensionData.guest.IpAddress -or (Get-Date) -gt $timeout)
        )
        if ($null -eq $VCDA_VM.ExtensionData.guest.IpAddress) {
            Write-Error "Can't find the IP address of VM '$($VCDA_VM.name)'"
        }
        $ip = $VCDA_VM.guest.ExtensionData.IpAddress
        if (-not (($IPAddress -split '/')[0] -eq $Ip)) {
            Write-Error "VM IP Address '$ip' doesn't match the provided IP Address '$IPAddress'"
        }
        Write-Log -message "Remote IP Address is $IP"
        $role = ($VCDA_VM.ExtensionData.Config.VAppConfig.Property | Where-Object { $_.id -eq 'guestinfo.cis.appliance.role' }).DefaultValue

        switch ($role) {
            cloud {
                $service_cert = ($vcda_vm.ExtensionData.Config.ExtraConfig | Where-Object { $_.key -eq 'guestinfo.cloud.certificate' }).value

            }
            tunnel {
                $service_cert = ($vcda_vm.ExtensionData.Config.ExtraConfig | Where-Object { $_.key -eq 'guestinfo.tunnel.certificate' }).value

            }
            replicator {
                $service_cert = ($vcda_vm.ExtensionData.Config.ExtraConfig | Where-Object { $_.key -eq 'guestinfo.replicator.certificate' }).value

            }
        }
        #wait for VM service to start
        $boot_timeout = (Get-Date).AddSeconds(600)
        Write-Log -message "VM '$($VCDA_VM.name)' - Waiting for service to start"
        do {
            $boot_wait = $false
            try {
                $wait_boot = Invoke-WebRequest -Uri ('https://'+$IP+'/docs/api-guide.html') -Method GET -SkipCertificateCheck -TimeoutSec 5
                Start-Sleep -Seconds 1
            }
            catch {
                $boot_wait = $true
            }
        } until (
            -not ($boot_wait) -or (Get-Date) -gt $boot_timeout
        )
        if ($null -eq $wait_boot) {
            Write-Error "VM '$($VCDA_VM.name)' - Timed out waiting for service to start'"
        }
        else {
            Write-Log -message "VM '$($VCDA_VM.name)' - Service stated successfully"
        }
        #verify service certificate matches the one we see over the network
        $remote_cert = Get-RemoteCert -url ('https://' + $IP) -type string
        if ($remote_cert -ne $service_cert) {
            Write-Error "Ceritificates doesn't match."
        }

        #get lookup service address
        ($lookup_service = New-Object System.UriBuilder $Global:DefaultVIServer.ServiceUri).Path = '/lookupservice/sdk'
        $vm_credentials = (Get-VCDAVMPassword -name ($VCDA_VM).Name)
        $temp_credentials = New-Object System.Management.Automation.PSCredential("root", $vm_credentials.old)
        $credentials = New-Object System.Management.Automation.PSCredential("root", $vm_credentials.current)

        #reset root password if required
        try {
            $vcda_server = Connect-VCDA -Server $ip -AuthType Local -Credentials $credentials -SkipCertificateCheck -NotDefault
        }
        catch {
            if ($_ -match "Unable to connect to VCDA Server '$ip'. The server returned the following: 'Authentication required.'") {
                $vcda_server = Connect-VCDA -Server $ip -AuthType Local -Credentials $temp_credentials -SkipCertificateCheck -NotDefault
                Write-Log -message "Trying to set root password of server $IP"
                Set-VCDAPassword -Server $vcda_server -OldPassword ($vm_credentials.old | ConvertFrom-SecureString -AsPlainText) `
                -NewPassword ($vm_credentials.current | ConvertFrom-SecureString -AsPlainText)
            }
            else {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
        $vcda_server = Connect-VCDA -Server $ip -AuthType Local -Credentials $credentials -SkipCertificateCheck -NotDefault

        if ($role -eq 'cloud') {
            Write-Log -message "Set License key to server '$($vcda_server.server)'"
            Set-License -Server $vcda_server -LicenseKey $LicenseKey | Out-Null
            Write-Log -message "Set VCDA Site name to '$siteName'"
            Set-VCDASiteName -Server $vcda_server -Name $SiteName | Out-Null
            Write-Log -message "Set Public Endpoint address to '$PublicApiEndpoint'"
            Set-CloudSiteEndpoints -Server $vcda_server -apiPublicAddress $PublicApiEndpoint | Out-Null
            Write-Log -message "Register Cloud Service with VCD."
            Register-VCDAVCD -Server $vcda_server -url $vcd_api_endpoint -username $vcd_user -password $vcd_password | Out-Null

            #set manager service lookup service
            $manager_server = Connect-VCDA -Server $ip -port 8441 -AuthType Local -Credentials $credentials -SkipCertificateCheck -NotDefault
            Set-LookupService -Server $manager_server -url $lookup_service.Uri.AbsoluteUri | Out-Null
            Write-Log -message "Set lookup service of manager service to: '$lookup_service'"
        }
        #Set Lookup service
        Write-Log -message "Set lookup service of cloud service to '$lookup_service'"
        Set-LookupService -Server $vcda_server -url $lookup_service.Uri.AbsoluteUri | Out-Null
        Write-Log -message "Initialize Completed for server '$($vcda_server.server)'"
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}