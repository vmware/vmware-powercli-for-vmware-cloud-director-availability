using module Microsoft.AVS.Management
<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
$ErrorActionPreference = 'Stop'

#script variables with default values, if required change names only here:
$Script:vcda_avs_params = [ordered]@{
    'vsphere' = @{
        'sa_username'         = 'vcda_avs_admin' #service account username
        'sa_current_password' = 'sa_current_password' #name of the persistent secret key with the current password
        'sa_old_password'     = 'sa_old_password' #name of the persistent secret key with the current password
        'vsphere_role'        = 'VCDA_AVS_ADMIN' #name of  vsphere role
        'folder'              = 'vmware-avs-vcda' #name of vsphere folder to be create/used as secure folder
        'tag_name'            = 'vmware-avs-vcda-tag' #name of vsphere tag to be created used by VCDA VMs
    }
    #vcda vms and related persistent secrets names
    'vcda'    = [ordered]@{
        'vm_name'          = @(
            'VCDA_AVS_Manager_01',
            'VCDA_AVS_Tunnel_01',
            'VCDA_AVS_Replicator_01',
            'VCDA_AVS_Replicator_02',
            'VCDA_AVS_Replicator_03',
            'VCDA_AVS_Replicator_04',
            'VCDA_AVS_Replicator_05',
            'VCDA_AVS_Replicator_06'
        )
        'current_password' = '_current_pass'
        'old_password'     = '_old_pass'

    }
    'ova'     = @{
        'vcda_ova_sha256' = @{
            #list of the supported VCDA version, sha256 of the provided OVA should match or deployment will fail.
            '4.6'   = 'dde22a058c367360fec0c2d79b31d4ffb13d41a61e6a376d107ea89a1e6ee348' #build 21891963
            '4.6.1' = 'ced17c2c6326a207ce7ac926990c679a8a66da455fa192c061c40d794aa255a7' #build 22347688
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