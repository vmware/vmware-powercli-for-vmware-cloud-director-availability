<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Stop-VCDAVM {
    <#
    .SYNOPSIS
        Stop All (Default) or given VCDA VM in AVS environment.
    .DESCRIPTION
        Stop All (Default) or given VCDA VM in AVS environment. Without any parameter all VCDA VMs will be shutdown gracefully.
    .PARAMETER force
        Will Power off the VM, without 'force'  option VMs will be shutdown gracefully.
    .PARAMETER VMName
        Name of the VCDA Virtual Machine to shutdown.
    .EXAMPLE
        Stop-VCDAVM -VMName 'VCDA_AVS_Replicator_01'
        Graceful Shutdown a VM name 'VCDA_AVS_Replicator_01'.
    .EXAMPLE
        Stop-VCDAVM -force
        Power Off all VCDA VMs in the environment.
    #>
    [AVSAttribute(30, UpdatesSDDC = $false)]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Will Power off the VM, without 'force' option VMs will be shutdown gracefully.")]
        [ValidateNotNullOrEmpty()]
        [switch]
        $force,

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Name of the VCDA Virtual Machine to shutdown.")]
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
            if ($vm.PowerState -eq 'PoweredOff') {
                Write-Log -message "VM '$($vm.name)' is already powered off."
            }
            elseif ($force) {
                Write-Log -message "Power off VM '$($vm.name)'."
                $vm = Stop-VM -VM $vm -Confirm:$false
                Write-Log -message "VM '$($vm.name)' is in '$($vm.PowerState)' State."
            }
            elseif ($vm.ExtensionData.Guest.ToolsRunningStatus -ne 'guestToolsRunning' ) {
                Write-Log -message "Cannot shut down guest OS of VM '$($vm.name)' since VMware tools is not running, use 'force' option to Power Off the VM."
            }
            else {
                $time_out_sec = 180
                $timeout = (Get-Date).AddSeconds($time_out_sec)
                Write-Log -message "Shutting down Guest OS of VM '$($vm.name)'."
                Stop-VMGuest -VM $vm -Confirm:$false | Out-Null
                do {
                    $vm = get-vm $VM
                    Start-Sleep 5
                }
                until (
                    ($vm.PowerState -eq 'PoweredOff' -or (Get-Date) -gt $timeout)
                )
                if ($vm.PowerState -ne 'PoweredOff') {
                    Write-Log -message "Failed to shut down guest OS of VM '$($vm.name)' within $time_out_sec seconds, use 'force' option to Power Off the VM."
                }
                else {
                    Write-Log -message "VM '$($vm.name)' is in '$($vm.PowerState)' State."
                }
            }
        }
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

