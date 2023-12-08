<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function New-VCDAVMSnapshot {
    <#
    .SYNOPSIS
        Create a VM Snapshot of VCDA Virtual machine.
    .DESCRIPTION
        Create a VM Snapshot of VCDA Virtual machine.
        If no VMName is provided it will take snapshots of all VCDA VMs.
        There is a limit of 2 snapshots, if a VM already have 2 snapshots no new snapshots will be created.
    .PARAMETER VMName
        Name of the VCDA Virtual Machine to snapshot.
    .PARAMETER Name
        Provide a name for the new snapshot.
    .PARAMETER Quiesce
        If the value is $true and the virtual machine is powered on, VMware Tools are used to quiesce the file system of the virtual machine.
            This assures that a disk snapshot represents a consistent state of the guest file systems. If the virtual machine is powered
            off or VMware Tools are not available, the Quiesce parameter is ignored.
    .PARAMETER Memory
        If the value is $true and if the virtual machine is powered on, the virtual machine's memory state is preserved with the snapshot.
    .EXAMPLE
        New-VCDAVMSnapshot -name "BeforePatch"
        Creates a new snapshot of all VCDA VMs named "BeforePatch"
    .EXAMPLE
        New-VCDAVMSnapshot -VMName "VCDA-AVS-Tunnel-01" -Name "BeforePatch" -Quiesce -Memory
        Creates a new snapshot of the "VCDA-AVS-Tunnel-01" powered-on virtual machine and preserves its memory state.

    #>
    [AVSAttribute(30, UpdatesSDDC = $false)]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Name of the VCDA Virtual Machine to snapshot.')]
        [ValidateNotNullOrEmpty()]
        [string]
        $VMName,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Provide a name for the new snapshot.'
        )]
        [string]
        $Name,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'If the value is $true and the virtual machine is powered on, VMware Tools are used to quiesce the file system of the virtual machine.
            This assures that a disk snapshot represents a consistent state of the guest file systems. If the virtual machine is powered
            off or VMware Tools are not available, the Quiesce parameter is ignored.'
        )]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Quiesce,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "If the value is `$true and if the virtual machine is powered on, the virtual machine's memory state is preserved with the snapshot."
        )]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Memory

    )
    Try {
        #make sure vc connection is healthy, script will fail if not
        if ($null -eq ((Get-View SessionManager -Server $global:DefaultVIServer).CurrentSession)) {
            Write-Error "vCenter server '$($Global:defaultviserver.Name)' connection is not heathy."
        }
        $VCDA_VMs = Get-VCDAVM -VMName $PSBoundParameters.VMName
        if ($VCDA_VMs.count -eq 0) {
            Write-Log -message "No VCDA VMs found."
            return
        }
        $PSBoundParameters.Remove('VMName') | Out-Null
        $snapshots = @()
        foreach ($vm in $VCDA_VMs) {
            if (($vm | Get-Snapshot).count -cge 2 ) {
                Write-log -message "$($vm.name) have more than 2 snapshots, first delete older snapshot(s) and try again. "
            }
            else {
                try {
                    Write-log -message "Creating snapshot of VM $($vm.name)."
                    $snapshot = $vm | New-Snapshot @PSBoundParameters
                    $snapshots += $snapshot
                }
                catch {
                    Write-log -message "There was an error while creating a snapshot of '$vm': $_"
                    Write-Error $_ -ErrorAction Continue
                }
            }
        }
        if ($snapshots.count -gt 0) {
            write-log -message "Created snapshots:
            $($snapshots | Select-Object vm, name, Id, Created, PowerState,  @{N = "Quiesced"; E = { $_.ExtensionData.Quiesced } }, SizeGB | Format-Table -AutoSize | Out-String)"
        }
        elseif ($snapshots.count -eq 0) {
            Write-log -message "No snapshots created."
        }
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}