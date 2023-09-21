<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Deploy-VCDAOVA {
    [CmdletBinding()]
    <#
    .DESCRIPTION
       Deploy VCDA OVA
    #>
    param (
        # Parameter help description
        [Parameter(Mandatory = $false)]
        #[System.IO.FileInfo]
        [string]$OVAFilename,
        # Type of the appliance
        [Parameter(Mandatory = $true)]
        [ValidateSet("vc_combined", "cloud", "replicator", "tunnel", "combined")]
        [string]
        $DeploymentOption,
        # root password
        [Parameter(Mandatory = $true)]
        [SecureString]
        $password,
        # NTP Server
        [Parameter(Mandatory = $true)]
        [string]
        $NTP,
        # Static IP Address CIDR format
        [Parameter(Mandatory = $false)]
        [string]
        $IPAddress,
        # hostname
        [Parameter(Mandatory = $false)]
        [string]
        $hostname,
        # Gateway
        [Parameter(Mandatory = $false)]
        [string]
        $Gateway,
        # MTU
        [Parameter(Mandatory = $false)]
        [int]
        $MTU,
        # DNS Servers
        [Parameter(Mandatory = $false)]
        [string[]]
        $DNS,
        # Search Domains
        [Parameter(Mandatory = $false)]
        [string[]]
        $Domains,
        # Name of the VM
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        # Datastore
        [Parameter(Mandatory = $false)]
        [string]
        $Datastore,
        # DHCP
        [Parameter(Mandatory = $false)]
        [switch]
        $DHCP,
        [Parameter(Mandatory = $false)]
        [string]
        $network,
        [Parameter(Mandatory = $true)]
        [string]
        $InventoryLocation,
        [Parameter(Mandatory = $true)]
        [string]
        $Cluster
    )

    try {
        $vm = Get-VCDAVM -VMName $Name
        if ($null -ne $vm) {
            Write-Log "VM with name '$name' already deployed."
            if ($vm.PowerState -ne 'PoweredOn') {
                Write-Log -message "Power on VM '$($vm.name)'."
                return Start-VM -VM $vm
            }
            else {
                return $vm
            }
        }
        if ($null -eq $script:ova_file){
            $script:ova_file = Get-VCDAOva -Datastore $Datastore -OVAFilename $OVAFilename
        }
        $ovf_config = Get-OvfConfiguration -Ovf $script:ova_file
        $ovf_config.DeploymentOption.Value = $DeploymentOption
        $ovf_config.Common.guestinfo.cis.appliance.root.password.Value = ($password | ConvertFrom-SecureString -AsPlainText)
        $ovf_config.Common.guestinfo.cis.appliance.ssh.enabled.Value = $true
        $ovf_config.Common.guestinfo.cis.appliance.net.ntp.Value = $ntp
        $ovf_config.NetworkMapping.VM_Network.Value = $network
        if (-not $DHCP) {
            $ovf_config.net.address.Value = $IPAddress
            $ovf_config.net.gateway.Value = $Gateway
            $ovf_config.net.dnsServers.Value = $DNS -join ','
            $ovf_config.net.searchDomains.Value = $Domains -join ','
            $ovf_config.net.hostname.Value = $hostname
        }
        $vmhost = Get-Cluster -Name $Cluster | Get-VMHost | Where-Object { $_.ConnectionState -eq 'Connected' } | Get-Random -Count 1
        Write-log -message "Deploying VM '$Name'"
        Test-IPAddress -IPAddress $IPAddress
        $VM = Import-VApp -Source $script:ova_file -Name $Name -Datastore $Datastore -VMHost $vmhost -DiskStorageFormat Thin `
            -OvfConfiguration $ovf_config -InventoryLocation $InventoryLocation
        Write-Log -message "Power on VM '$($vm.name)'."
        return Start-VM -VM $vm
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

}