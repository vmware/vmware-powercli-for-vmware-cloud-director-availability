<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Initialize-AVSSite {
    <#
    .DESCRIPTION
    Prepare AVS Site for VCDA deployment
    #>
    [CmdletBinding()]
    param ()

    try {
        Write-Log -message "Starting Initialize-AVSSite"
        #get SSO Domain
        $SSO_domain = (Get-IdentitySource -System).name
        Write-Log -message "SSO Domain is $SSO_Domain"
        #create secure folder
        Write-Log -message "Create secure folder '$($Script:vcda_avs_params.vsphere.folder)'"
        $vcda_secure_folder = [AVSSecureFolder]::GetOrCreate($Script:vcda_avs_params.vsphere.folder)

        #Generate VCDA Service account password and store it in $PersistentSecrets
        if ($null -eq $PersistentSecrets[$Script:vcda_avs_params.vsphere.sa_current_password]) {
            Write-Log -message "Generating Service account password."
            $VCDA_AVS_ADMIN_Password = Get-SsoPasswordPolicy | Get-VCDARandomPassword
            #save password to PersistentSecrets
            $PersistentSecrets.'sa-username' = $Script:vcda_avs_params.vsphere.sa_username
            $PersistentSecrets[$Script:vcda_avs_params.vsphere.sa_current_password] = ${VCDA_AVS_ADMIN_Password}
        }

        #Create VCDA SSO user
        $vcda_avs_admin_creds = New-Object System.Management.Automation.PSCredential($PersistentSecrets.'sa-username', `
            ($PersistentSecrets[$Script:vcda_avs_params.vsphere.sa_current_password] | ConvertTo-SecureString -AsPlainText -Force))
        $vcda_service_account = Add-VCDASSOUser -FirstName "VCDA_AVS" -Lastname "Service_Account" -Credentials $vcda_avs_admin_creds -Domain $SSO_domain

        #Add_VCDA_Role
        $vcda_role = Add-VCDARole -Name $Script:vcda_avs_params.vsphere.vsphere_role -user ($SSO_domain + "\" + $PersistentSecrets.'sa-username')

        #create "VR_ADMINISTRATORS" group and add "cloudadmin" user to it. This will give admin access to vcda appliances.
        Add-VCDASSOGroup -Name "VrAdministrators" -Description "vcda admins group" -user "cloudadmin" -Domain $SSO_domain

        #generate appliance initial root password to be changed during config
        foreach ($appliance in $Script:vcda_avs_params.vcda.vm_name) {
            if ($null -eq $persistentSecrets[$appliance + $Script:vcda_avs_params.vcda.old_password]) {
                Write-Log -message "Generating initial root password for $appliance"
                $temp_root_password = Get-VCDARandomPassword -MinLength 12 -MaxLength 24 -MinNumericCount 2 -MinSpecialCharCount 2 `
                    -MinUppercaseCount 2 -MinLowercaseCount 2 -MaxIdenticalAdjacentCharacters 2
                $persistentSecrets[$appliance + $Script:vcda_avs_params.vcda.old_password] = $temp_root_password
            }
        }

        #generate appliance root password
        foreach ($appliance in $Script:vcda_avs_params.vcda.vm_name) {
            if ($null -eq $persistentSecrets[$appliance + $Script:vcda_avs_params.vcda.current_password]) {
                Write-Log -message "Generating root password for $appliance"
                $root_password = Get-VCDARandomPassword -MinLength 12 -MaxLength 24 -MinNumericCount 2 -MinSpecialCharCount 2 `
                    -MinUppercaseCount 2 -MinLowercaseCount 2 -MaxIdenticalAdjacentCharacters 2
                $persistentSecrets[$appliance + $Script:vcda_avs_params.vcda.current_password] = $root_password
            }
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}