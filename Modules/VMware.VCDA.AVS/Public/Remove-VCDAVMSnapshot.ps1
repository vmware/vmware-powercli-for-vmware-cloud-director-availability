<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Remove-VCDAVMSnapshot {
    <#
    .SYNOPSIS
        Remove a VM Snapshot of VCDA Virtual machine.
    .DESCRIPTION
        Remove a VM Snapshot of VCDA Virtual machine, to get list of snapshots run "Get-VCDAReport".
        By default all snapshots from all VMs will be deleted.
        You can filter which snapshots will be removed ny using a combination of different parameter.
        Running the command without 'Confirm' parameter will list snapshot that will be deleted but will not delete them.
    .PARAMETER VMName
        Name of the VCDA Virtual Machine
    .PARAMETER Name
        Name of the snapshots that you want to delete
    .PARAMETER Id
        Id of the snapshots that you want to delete
    .PARAMETER Confirm
        Confirm that snapshots of the VCDA VMs will be deleted.
        Without the confirm option the command will list the snapshots that will be deleted but will not delete any snapshots.
    .EXAMPLE
        Remove-VCDAVMSnapshot
        Will remove all snapshots from all VCDA VMs.
    .EXAMPLE
        Remove-VCDAVMSnapshot -name "BeforePatch" -Confirm
        Will remove snapshots named "BeforePatch" from all VCDA VMs.
    .EXAMPLE
        Remove-VCDAVMSnapshot -VMName "VCDA-AVS-Tunnel-01" -id "VirtualMachineSnapshot-snapshot-1032"
        Will remove snapshot with id "VirtualMachineSnapshot-snapshot-1032" from VCDA VM "VCDA-AVS-Tunnel-01"
    #>
    [AVSAttribute(180, UpdatesSDDC = $false)]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Name of the VCDA Virtual Machine to snapshot.')]
        [ValidateNotNullOrEmpty()]
        [string]
        $VMName,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Provide the name for the snapshot.'
        )]
        [string]
        $Name,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Provide the Id for the snapshot.'
        )]
        [string]
        $Id,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Confirm that snapshots of the VCDA VMs will be deleted."
        )]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Confirm

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
        $PSBoundParameters.Remove('Confirm') | Out-Null

        $snapshot = $VCDA_VMs | Get-Snapshot @PSBoundParameters
        if ($null -ne $snapshot) {
            if ($Confirm -ne $true) {
                Write-Log -message "The following snapshots will be deleted, to proceed please run again and select 'confirm':
                $($snapshot | Select-Object vm, name, Id, Created, PowerState,  @{N = "Quiesced"; E = { $_.ExtensionData.Quiesced } }, SizeGB | Format-Table -AutoSize | Out-String)"
                Write-Error 'You must confirm that VCDA VM snapshots will be deleted.'
            }
            else {
                Write-Log -message "Removing following snapshots:
            $($snapshot | Select-Object vm, name, Id, Created, PowerState,  @{N = "Quiesced"; E = { $_.ExtensionData.Quiesced } }, SizeGB | Format-Table -AutoSize | Out-String)"
                $snapshot | Remove-Snapshot -Confirm:$false
            }
        }
        if ($null -eq $snapshot) {
            Write-Log -message "No snapshots found."
        }
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}