using module @{ ModuleName = 'Microsoft.AVS.Management'; RequiredVersion = '5.3.99' }
<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
$ErrorActionPreference = 'Stop'

#script variables with default values, if required change names only here:
$Script:vcda_avs_params = [ordered]@{
    'vsphere' = @{
        'sa_username'         = 'vcda-avs-admin' #service account username
        'sa_current_password' = 'sa-current-password' #name of the persistent secret key with the current password
        'sa_old_password'     = 'sa-old-password' #name of the persistent secret key with the current password
        'vsphere_role'        = 'VCDA_AVS_ADMIN' #name of  vsphere role
        'folder'              = 'vmware-avs-vcda' #name of vsphere folder to be create/used as secure folder
        'tag_name'            = 'vmware-avs-vcda-tag' #name of vsphere tag to be created used by VCDA VMs
    }
    #vcda vms and related persistent secrets names
    'vcda'    = [ordered]@{
        'vm_name'          = @(
            'VCDA-AVS-Manager-01',
            'VCDA-AVS-Tunnel-01',
            'VCDA-AVS-Replicator-01',
            'VCDA-AVS-Replicator-02',
            'VCDA-AVS-Replicator-03',
            'VCDA-AVS-Replicator-04',
            'VCDA-AVS-Replicator-05',
            'VCDA-AVS-Replicator-06'
        )
        'current_password' = '-current-pass'
        'old_password'     = '-old-pass'

    }
    'ova'     = @{
        'vcda_ova_sha256' = @{
            #list of the supported VCDA version, sha256 of the provided OVA should match or deployment will fail.
            '4.7.0' = 'b84cd7ec170cec17bcd002c7471b28b457319b2260fdc7608e8fcae244809289' #build 22817906
        }
    }
}

$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )
#Dot source the files
Foreach ($import in @($Public + $Private)) {
    Try {
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}