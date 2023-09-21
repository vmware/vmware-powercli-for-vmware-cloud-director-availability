<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Add-VCDATag {
    <#
    .DESCRIPTION
    Create VCDA Tag and assign it to VMs.
    #>
    [CmdletBinding()]
    param (
        # VM to assing the TAG to
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VCDA_VM
    )
    begin {
        $TagName = "vmware-avs-vcda-tag"
        $TagDescription = "Tag for VMware VCDA VMs"
        $TagCategoryName = "vmware-avs-vcda-tag-category"
        $TagCategoryDescription = "Tag Category for VMware VCDA"
        try {
            $Tag = Get-Tag -Name $TagName -ErrorAction SilentlyContinue
            $TagCategory = Get-TagCategory -Name $TagCategoryName -ErrorAction SilentlyContinue
            if ($null -eq $TagCategory) {
                Write-Log "Creating VCDA Tag Category '$TagCategoryName'."
                New-TagCategory -Name $TagCategoryName -Description $TagCategoryDescription | Out-Null
            }
            if ($null -eq $Tag) {
                Write-Log -message "Creating VCDA Tag '$TagName'."
                New-Tag -Name $TagName -Category $TagCategoryName -Description $TagDescription | Out-Null
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    PROCESS {
        try {
            $Tag = Get-Tag -Name $TagName -ErrorAction Stop
            if ($VCDA_VM) {
                Write-Log -message "Assigning Tag to VM '$vcda_vm'."
                $VCDA_VM | New-TagAssignment -Tag $tag | Out-Null
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}