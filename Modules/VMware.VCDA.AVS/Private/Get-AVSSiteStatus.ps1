<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-AVSSiteStatus {
    [CmdletBinding()]
    param (
        # log prefix
        [Parameter(Mandatory = $false)]
        [string]$LogPrefix
    )
    process {
        try {
            Write-Log -message "Checking if AVS SDDC is prepared for VCDA installation." -LogPrefix $LogPrefix
            $SSO_domain = (Get-IdentitySource -System).name
            #make sure passwords are present in $PersistentSecrets secrets
            foreach ($appliance in $Script:vcda_avs_params.vcda.vm_name) {
                if ($null -eq $persistentSecrets[$appliance + $Script:vcda_avs_params.vcda.current_password]) {
                    Write-Error "Missing current root passwords in vault."
                }
                if ($null -eq $persistentSecrets[$appliance + $Script:vcda_avs_params.vcda.old_password]) {
                    Write-Error "Missing old root passwords in vault."
                }
            }
            if ($null -eq $PersistentSecrets[$Script:vcda_avs_params.vsphere.sa_current_password]) {
                write-error "Missing service account password in vault."
            }
            if ($null -eq $PersistentSecrets.'sa-username') {
                write-error "Missing service account username in vault."
            }
            #check if vsphere role is created
            $vcda_role = Get-VIRole -Name $Script:vcda_avs_params.vsphere.vsphere_role -ErrorAction SilentlyContinue `
            | Where-Object { $_.Name -eq $Script:vcda_avs_params.vsphere.vsphere_role }
            if ($null -eq $vcda_role) {
                Write-Error "vSphere role required by VCDA not found."
            }
            #check vsphere service account
            $sso_user = Get-SsoPersonUser -Name $Script:vcda_avs_params.vsphere.sa_username -Domain $SSO_domain `
            | Where-Object { $_.name -eq $Script:vcda_avs_params.vsphere.sa_username }
            if ($null -eq $sso_user) {
                write-Error "vSphere service account not found."
            }
            #check vsphere group
            $group = Get-SsoGroup -Domain $SSO_domain -Name 'VrAdministrators' | Where-Object { $_.name -eq 'VrAdministrators' }
            if ($null -eq $group) {
                Write-Error "vSphere group required by VCDA not found."
            }
            #check folder
            $vcda_folder = [AVSSecureFolder]::GetOrCreate($Script:vcda_avs_params.vsphere.folder)
            if ($null -eq $vcda_folder) {
                Write-Error "vSphere secure folder not found."
            }
            Write-Log -message "AVS SDDC is ready for VCDA installation." -LogPrefix $LogPrefix
        }
        catch {
            Write-Log "AVS SDDC is not ready for VCDA installation, prepare the site first by running 'Initialize-AVSSite'.
            Check 'Error' for more information" -LogPrefix $LogPrefix
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}