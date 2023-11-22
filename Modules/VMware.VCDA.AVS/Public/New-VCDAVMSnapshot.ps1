<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function New-VCDAVMSnapshot {
    <#
    .SYNOPSIS
        Create a VM Snapshot of VCDA Virtual machine
    .DESCRIPTION
        Create a VM Snapshot of VCDA Virtual machine
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
        $PSBoundParameters.Remove('VMName') | Out-Null
        $snapshot = $VCDA_VMs | New-Snapshot @PSBoundParameters
        write-log -message "Created snapshots:
        $($snapshot | Select-Object vm, name, Id, Created, PowerState, Quiesced, SizeGB | Format-Table -AutoSize | Out-String)"
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}