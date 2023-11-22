<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-VCDAReport {
    <#
    .SYNOPSIS
        Get VCDA Status Report
    .DESCRIPTION
        Get VCDA Status Report
    .EXAMPLE
        Get VCDA Status Report
    #>
    [AVSAttribute(30, UpdatesSDDC = $false)]
    [CmdletBinding()]
    param ()
    Try {
        #make sure vc connection is healthy, script will fail if not
        if ($null -eq ((Get-View SessionManager -Server $global:DefaultVIServer).CurrentSession)) {
            Write-Error "vCenter server '$($Global:defaultviserver.Name)' connection is not heathy."
        }
        #get SSO Domain
        $SSO_domain = (Get-IdentitySource -System).name
        #check service account
        $sa_user = Get-SsoPersonUser -Name $PersistentSecrets.'sa-username' -Domain $SSO_domain
        if ($null -eq $sa_user) {
            Write-Host "Service account '$($PersistentSecrets.'sa-username')' was not found"
        }
        else {
            Write-Host "Service Account info:"
            write-host ($sa_user | Select-Object Name, Locked, Disabled, PasswordExpirationRemainingDays | Format-Table | Out-String)
        }

        $vcda_vms = Get-VCDAVM
        Write-Host "Virtual Machines info:"

        Write-Host ($vcda_vms | Select-Object name, PowerState, `
            @{N = "type"; E = { ($_.ExtensionData.Config.VAppConfig.Property | Where-Object { $_.id -eq 'guestinfo.cis.appliance.role' }).DefaultValue } }, `
            @{N = "hostname"; E = { $_.ExtensionData.guest.HostName } }, @{N = "ToolsStatus"; E = { $_.ExtensionData.guest.ToolsStatus } },
            @{N = "IPAddress"; E = { $_.ExtensionData.guest.IpAddress } } | Format-Table -AutoSize | Out-String )

        Write-Host "Snapshots:"
        $snapshots = $vcda_vms | Get-Snapshot
        if ($null -ne $snapshots ){
            Write-Host ($snapshots | Select-Object vm, name, Id, Created, PowerState, Quiesced, SizeGB | Format-Table -AutoSize | Out-String)
        }
        else {

            Write-Host `n "No snapshots found." `n

        }
        ($lookup_service = New-Object System.UriBuilder $Global:DefaultVIServer.ServiceUri).Path = '/lookupservice/sdk'
        $lookup_service_sha = Get-RemoteCert -url $lookup_service.Uri.AbsoluteUri -type sha256

        $result = @{
            "Password_expiration" = @()
            "Certificates"        = @()
            "LookupService"       = @()
        }
        foreach ($vm in $vcda_vms) {
            try {
                $vcda_server = $null
                if ($VM.PowerState -ne "PoweredOn") {
                    write-log -message "Cannot connect to VM '$($VM.name)' since it's not in 'Powered On' state."
                    continue
                }
                $vm_pass = Get-VCDAVMPassword -Name $vm.name
                $vm_creds = New-Object System.Management.Automation.PSCredential("root", $vm_pass.current)
                $vm_ip = $vm.ExtensionData.guest.IpAddress
                if ($null -eq $vm_ip) {
                    Write-Error "Failed to get the IP address of VM $($vm.name)"
                }
                $vcda_server = Connect-VCDA -server $vm_ip -AuthType Local -Credentials $vm_creds -port 443 -SkipCertificateCheck -NotDefault
                $config = get-config -Server $vcda_server

                #check root password expiration
                $pass_exp = Get-VCDAPassExp -server $vcda_server
                $password_expiration = $pass_exp | Select-Object @{N = "VM_Name"; E = { $vm.name } }, rootPasswordExpired, @{N = "ExpirationDate"; E = { (get-date).AddSeconds($_.secondsUntilExpiration) } }
                $result.Password_expiration += $password_expiration

                #check certificate expiration
                $local_cert = Get-LocalCert -server $vcda_server | Select-Object @{N = "VM_Name"; E = { $vm.name } }, @{N = "service"; E = { $vcda_server.ServiceType } }, `
                @{N = "issuedTo"; E = { $_.certificate.issuedTo.CN } }, @{N = "Expires_On"; E = { ([datetime]::UnixEpoch.AddMilliseconds($_.certificate.expiresOn).ToLocalTime()) } },`
                @{N = "expired"; E = {([datetime]::UnixEpoch.AddMilliseconds($_.certificate.expiresOn).ToLocalTime()) -lt (get-date) } }
                $result.Certificates += $local_cert

                #check lookup service thumbprint.
                $result.LookupService += $config | Select-Object @{N = "VM_Name"; E = { $vm.name } }, @{N = "service"; E = { $vcda_server.ServiceType } }, `
                @{N = "ConfiguredThumbprint"; E = { $_.lsThumbprint } }, @{N = "match"; E = { $lookup_service_sha -match $_.lsThumbprint } }

                #if connected to cloud service (aka manager appliance) check manager service as well
                if ($vcda_server.ServiceType -eq "CLOUD") {
                    $vcda_server = Connect-VCDA -server $vm_ip -AuthType Local -Credentials $vm_creds -port 8441 -SkipCertificateCheck -NotDefault
                    $config = get-config -Server $vcda_server
                    #check certificate expiration
                    $local_cert = Get-LocalCert -server $vcda_server | Select-Object @{N = "VM_Name"; E = { $vm.name } }, @{N = "service"; E = { $vcda_server.ServiceType } }, `
                    @{N = "issuedTo"; E = { $_.certificate.issuedTo.CN } }, @{N = "Expires_On"; E = { ([datetime]::UnixEpoch.AddMilliseconds($_.certificate.expiresOn).ToLocalTime()) } },`
                    @{N = "expired"; E = {([datetime]::UnixEpoch.AddMilliseconds($_.certificate.expiresOn).ToLocalTime()) -lt (get-date) } }
                    $result.Certificates += $local_cert

                    #check lookup service thumbprint.
                    $result.LookupService += $config | Select-Object @{N = "VM_Name"; E = { $vm.name } }, @{N = "service"; E = { $vcda_server.ServiceType } }, `
                    @{N = "ConfiguredThumbprint"; E = { $_.lsThumbprint } }, @{N = "match"; E = { $lookup_service_sha -match $_.lsThumbprint } }
                }
            }
            catch {
                Write-Error $_ -ErrorAction Continue
            }
        }
        Write-Host "Root Password Status:"
        Write-Host ($result.Password_expiration | Format-Table -AutoSize | Out-String)
        Write-Host "Certificates Status:"
        Write-Host ($result.Certificates | Format-Table -AutoSize | Out-String)
        Write-Host "Lookup Service Status:
        Server Thumbprint is '$lookup_service_sha',
        If ConfiguredThumbprint doesn't match run the 'Repair-LookupService' command to update the lookup service."
        Write-Host ($result.LookupService | Format-Table -AutoSize | Out-String)
        #Write-Host "The following servers lookup service doesn't match:
        #$($result.LookupService | Where-Object {$_.match -match "False"} | Format-Table -AutoSize | Out-String)" -ForegroundColor Yellow

           #Write-Host "The following servers lookup service doesn't match:
        #$($result.LookupService | Where-Object {$_.match -match "False"} | Format-Table -AutoSize | Out-String) | Write-Host "The following servers lookup service doesn't match:" $_
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}


