<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Add-VCDARole {
    [CmdletBinding()]
    <#
    .DESCRIPTION
       Create Custom VCDA role with required privileges
    #>
    param (
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $user
    )

    $Privileges = @(
        "Cryptographer.ManageKeys"
        "Cryptographer.RegisterHost"
        "Datastore.Browse"
        "Datastore.Config"
        "Datastore.FileManagement"
        "Global.DisableMethods"
        "Global.EnableMethods"
        "Host.Config.Connection"
        "Host.Hbr.HbrManagement"
        "StorageProfile.View"
        "Resource.AssignVMToPool"
        "StorageViews.View"
        "VirtualMachine.Config.AddNewDisk"
        "VirtualMachine.Config.Settings"
        "VirtualMachine.Config.RemoveDisk"
        "VirtualMachine.Inventory.Register"
        "VirtualMachine.Inventory.Unregister"
        "VirtualMachine.Interact.PowerOn"
        "VirtualMachine.Interact.PowerOff"
        "VirtualMachine.State.CreateSnapshot"
        "VirtualMachine.State.RemoveSnapshot"
        "VirtualMachine.Hbr.ConfigureReplication"
        "VirtualMachine.Hbr.ReplicaManagement"
        "VirtualMachine.Hbr.MonitorReplication"
    )

    try {
        $rootfolder = Get-Folder -NoRecursion
        $SDDCRole_Privileges = Get-VIPrivilege -Id $Privileges
        #check if role exists
        $vcda_role = Get-VIRole -Name $Name -ErrorAction SilentlyContinue
        if ($vcda_role) {
            Write-Log -message "Role '$name' already exists."
        }
        else {
            Write-Log -message "Creating new vCenter role '$name' with required Privileges."
            $vcda_role =  New-VIRole -Name $Name -Privilege $SDDCRole_Privileges -ErrorAction Stop
        }
        Write-Log -message "Adding permissions to user: '$user' "
        $permissions  = New-VIPermission -Entity $rootfolder -Principal $user -Role $vcda_role
        return $permissions
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

}