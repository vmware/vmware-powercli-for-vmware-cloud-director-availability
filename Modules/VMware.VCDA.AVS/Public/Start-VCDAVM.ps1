<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Start-VCDAVM {
    <#
    .SYNOPSIS
        Power On all or given VCDA virtual machine in AVS environment.
    .DESCRIPTION
        Power On all or given VCDA virtual machine in AVS environment.
        By default all virtual machines that are not in 'PoweredOn' state will be powered on.
    .PARAMETER VMName
        Name of the VCDA Virtual Machine to Power On.
    .EXAMPLE
        Start-VCDAVM
        Will Power On all VCDA virtual machines that are not in 'PoweredOn' state.
    .EXAMPLE
        Start-VCDAVM -VMName 'VCDA_AVS_Replicator_01'
        Will Power on a VCDA virtual machine named 'VCDA_AVS_Replicator_01'.
    #>
    [AVSAttribute(30, UpdatesSDDC = $false)]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Name of the VCDA Virtual Machine to Power On.')]
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
        foreach ($VM in $VCDA_VMs) {
            if ($vm.PowerState -ne 'PoweredOn') {
                Write-Log -message "Power on VM '$($vm.name)'."
                $vm = Start-VM -VM $vm
            }
            Write-Log -message "VM '$($vm.name)' is in '$($vm.PowerState)' State."
        }
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}