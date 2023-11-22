<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-VCDAVM {
    <#
    .SYNOPSIS
    Get all VCDA VMs
    .DESCRIPTION
    Get all VCDA VM filter by type.
    #>
    [CmdletBinding()]


    param (
        # Type of the appliance
        [Parameter(Mandatory = $false)]
        [ValidateSet("cloud", "replicator", "tunnel", "combined")]
        [string]$type,
        [Parameter(Mandatory = $false)]
        [string]$VMName
    )
    Try {

        $vm_folder = Get-Folder -Name $Script:vcda_avs_params.vsphere.folder -Type VM -Location ([AVSSecureFolder]::root()) -ErrorAction SilentlyContinue
        if ($null -eq $vm_folder) {
            #Write-log "VM folder '$($Script:vcda_avs_params.vsphere.folder)' not found, VCDA is not deployed."
            return
        }
        $vms = get-vm -Location $vm_folder | Where-Object { $_.ExtensionData.Config.VAppConfig.Product.name -eq 'VMware Cloud Director Availability' }

        switch ($type) {
            'cloud' {
                $vms = $vms  | Where-Object { $_.extensionData.Config.vappConfig.Property.id -eq "guestinfo.cis.appliance.role" `
                        -and $_.extensionData.Config.vappConfig.Property.DefaultValue -eq "cloud" }
            }
            'replicator' {
                $vms = $vms  | Where-Object { $_.extensionData.Config.vappConfig.Property.id -eq "guestinfo.cis.appliance.role" `
                        -and $_.extensionData.Config.vappConfig.Property.DefaultValue -eq "replicator" }
            }
            'tunnel' {
                $vms = $vms  | Where-Object { $_.extensionData.Config.vappConfig.Property.id -eq "guestinfo.cis.appliance.role" `
                        -and $_.extensionData.Config.vappConfig.Property.DefaultValue -eq "tunnel" }
            }
        }
        #filter results based on the VM name
        if ($PSBoundParameters['VMName']) {
            $Vms = $VMs | Where-Object { $_.Name -eq $VMName }
        }

        return $vms | Sort-Object
    }
    Catch {
        write-error -Message $_.exception.Message -ErrorAction Stop
    }
}

