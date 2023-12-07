<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-VCDAOva {
    [CmdletBinding()]
    param (
        # Datastore
        [Parameter(Mandatory = $true)]
        [string]$Datastore,
        # type
        [Parameter(Mandatory = $true)]
        [string]$OVAFilename,
        # log prefix
        [Parameter(Mandatory = $false)]
        [string]$LogPrefix
    )
    process {
        try {
            $localVarDatastore = Get-Datastore -Name $datastore
            if ($localVarDatastore.count -gt 1) {
                Write-Error "More than one datastore was found using the specified filter(s)."
            }
            $psdrive = New-PSDrive -Location $localVarDatastore -Name dsova -PSProvider VimDatastore -Root "\"
            $location = get-item (Get-Location)
            $ova = Get-ChildItem "dsova:\$ovafilename"
            Write-log -message "Downloading VCDA OVA from Datastore." -LogPrefix $LogPrefix
            $download_ova = Copy-DatastoreItem -Item $ova -Destination $location -PassThru
            #$download_ova = Copy-DatastoreItem -Item $ova -Destination '~/Downloads' -PassThru
            Remove-PSDrive $psdrive -Force
            $file_sha = Get-FileHash $download_ova -Algorithm SHA256
            if ($Script:vcda_avs_params.ova.vcda_ova_sha256.ContainsValue($file_sha.Hash.ToLower())) {
                Write-Log "File downloaded successfully to '$($download_ova.FullName)'" -LogPrefix $LogPrefix
                return $download_ova
            }
            else {
                Write-Error "The provided file '$($download_ova.name)' is wrong or not supported."
            }
        }
        catch {
            if (Get-PSDrive -Name "dsova" -PSProvider VimDatastore -ErrorAction SilentlyContinue) {
                Remove-PSDrive -Name "dsova" -PSProvider VimDatastore
            }
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}






