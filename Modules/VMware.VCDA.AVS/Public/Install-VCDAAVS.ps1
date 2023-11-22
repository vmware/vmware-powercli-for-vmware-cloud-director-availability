<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Install-VCDAAVS {
    <#
.SYNOPSIS
   Install and configure VMware Cloud Director Availability instance in AVS.
.DESCRIPTION
    Install and configure VMware Cloud Director Availability instance in AVS.
.PARAMETER License
    Valid License key for VMware Cloud Director Availability.
.PARAMETER SiteName
    Name of the VCDA site, cannot be changed after installation. Only latin alphanumerical characters and "-"  are allowed in site name.
.PARAMETER PublicApiEndpoint
    VCDA Public Service Endpoint address, "https://VCDA-FQDN:443".
.PARAMETER VCDApiEndpoint
    VMware Cloud Director endpoint URL, "https://VMware-Cloud-Director-IP-Address:443/api".
.PARAMETER VCDUser
    Username of a System administrator user in VMware Cloud Director. For example, use administrator@system'.
.PARAMETER VCDPassword
    Password of the VMware Cloud Director System administrator user.
.PARAMETER Datastore
    Datastore to be used for deployment of the appliances
.PARAMETER Cluster
    Destination vSphere Cluster to be used for deployment of the appliances
.PARAMETER ManagerIPAddress
    IPv4 address in CIDR notation (for example 192.168.0.222/24) to be used for deployment of the Manager appliance
.PARAMETER ManagerGW
    Gateway IP address for the Manager Appliance
.PARAMETER ManagerHostname
    Hostname of the Manager appliance
.PARAMETER ManagerNetwork
    vSphere network to be used for deployment of the Manager appliance
.PARAMETER TunnelIPAddress
    IPv4 address in CIDR notation (for example 192.168.0.223/24) to be used for deployment of the Tunnel appliance
.PARAMETER TunnelGW
    Gateway IP address for the Tunnel Appliance
.PARAMETER TunnelHostname
    Hostname of the Tunnel appliance
.PARAMETER TunnelNetwork
    vSphere network to be used for deployment of the Tunnel appliance
.PARAMETER Replicator1IPAddress
    IPv4 address in CIDR notation (for example 192.168.0.224/24) to be used for deployment of the First (1st) Replicator appliance
.PARAMETER Replicator1Hostname
    Hostname of the First (1st) Replicator appliance
.PARAMETER Replicator2IPAddress
    IPv4 address in CIDR notation (for example 192.168.0.225/24) to be used for deployment of the Second (2nd) Replicator appliance
.PARAMETER Replicator2Hostname
    Hostname of the Second (2nd) Replicator appliance
.PARAMETER ReplicatorGW
    Gateway IP address for 1st and 2nd Replicator appliances
.PARAMETER ReplicatorNetwork
    vSphere network to be used for deployment of 1st and 2nd Replicator appliances
.PARAMETER NTPServer
    NTP Server address to be used for all VCDA appliances
.PARAMETER DNSServer
    List of DNS server to be used for all appliances (for example, "192.168.1.1,192.168.1.2"
.PARAMETER SearchDomain
    List of search domain for all appliances (for example: "domain1.local,domain2.local")
.PARAMETER OVAFilename
    Name of the VCDA .ova file, located in top folder of the same Datastore where appliances will be deployed (for example: "VCDA-4.6.1.ova")
.PARAMETER AcceptEULA
    Accept the End User License Agreement: "https://github.com/vmware/vmware-powercli-for-vmware-cloud-director-availability/blob/c1705a1cf78861e6d65236fc8d6ea6c89f17ec5f/Resources/EULA.txt"'
.EXAMPLE
    $params = @{
        'License'              = 'XXXX-XXXX-XXXX-XXXX-XXXX'
        'SiteName'             = 'vcda-demo'
        'PublicApiEndpoint'    = 'https://VCDA-FQDN:443'
        'VCDApiEndpoint'       = "https://VMware-Cloud-Director-IP-Address:443/api"
        'VCDUser'              = 'administrator@system'
        'VCDPassword'          = Read-Host -Prompt "Enter VCDPassword" -AsSecureString
        'Datastore'            = 'Datastore01'
        'Cluster'              = 'Cluster01'
        'ManagerIPAddress'     = '192.168.0.222/24'
        'ManagerGW'            = '192.168.0.1'
        'ManagerHostname'      = 'vcda-m01'
        'ManagerNetwork'       = 'vcda-network'
        'TunnelIPAddress'      = '192.168.0.223/24'
        'TunnelGW'             = '192.168.0.1'
        'TunnelHostname'       = 'vcda-t01'
        'TunnelNetwork'        = 'vcda-network'
        'Replicator1IPAddress' = '192.168.0.224/24'
        'Replicator1Hostname'   = 'vcda-r01'
        'Replicator2IPAddress' = '192.168.0.225/24'
        'Replicator2Hostname'  = 'vcda-r02'
        'ReplicatorGW'         = '192.168.0.1'
        'ReplicatorNetwork'    = 'vcda-network'
        'NTPServer'            = 'time.vcda.local'
        'DNSServer'            = '192.168.0.10,192.168.0.11'
        'SearchDomain'         = 'vcda.local'
        'OVAFilename'          = 'VMware-Cloud-Director-Availability-Provider-4.6.1.7681624-a5359f8567_OVF10.ova'
        'AcceptEULA'           = $true
    }
    Install-VCDAAVS @params
#>
    [AVSAttribute(30, UpdatesSDDC = $false)]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Valid License key for VMware Cloud Director Availability')]
        [ValidateNotNullOrEmpty()]
        [string]
        $License,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Name of the VCDA site, cannot be changed after installation. Only latin alphanumerical characters and "-"  are allowed in site name.')]
        [ValidatePattern('^[a-zA-Z0-9-]+$', ErrorMessage = "'{0}' is not a valid Site name, Only latin alphanumerical characters and '-' are allowed" )]
        [string]
        $SiteName,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'VCDA Public Service Endpoint address, "https://VCDA-FQDN:443"')]
        [ValidateNotNullOrEmpty()]
        [string]
        $PublicApiEndpoint,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'VMware Cloud Director endpoint URL, "https://VMware-Cloud-Director-IP-Address:443/api"')]
        [ValidateNotNullOrEmpty()]
        [string]
        $VCDApiEndpoint,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Enter the user name of a System administrator user in VMware Cloud Director. For example, use administrator@system')]
        [ValidateNotNullOrEmpty()]
        [string]
        $VCDUser,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Enter the password of the VMware Cloud Director System administrator user')]
        [ValidateNotNullOrEmpty()]
        [SecureString]
        $VCDPassword,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Datastore to be used for deployment of the appliances')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Datastore,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Destination vSphere Cluster to be used for deployment of the appliances')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Cluster,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'IPv4 address in CIDR notation (for example 192.168.0.222/24) to be used for deployment of the Manager appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ManagerIPAddress,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Gateway IP address for the Manager Appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ManagerGW,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Hostname of the Manager appliance')]
        [string]
        $ManagerHostname,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'vSphere network to be used for deployment of the Manager appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ManagerNetwork,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'IPv4 address in CIDR notation (for example 192.168.0.223/24) to be used for deployment of the Tunnel appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TunnelIPAddress,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Gateway IP address for the Tunnel Appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TunnelGW,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Hostname of the Tunnel appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TunnelHostname,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'vSphere network to be used for deployment of the Tunnel appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TunnelNetwork,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'IPv4 address in CIDR notation (for example 192.168.0.224/24) to be used for deployment of the First (1st) Replicator appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Replicator1IPAddress,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Hostname of the First (1st) Replicator appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Replicator1Hostname,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'IPv4 address in CIDR notation (for example 192.168.0.225/24) to be used for deployment of the Second (2nd) Replicator appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Replicator2IPAddress,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Hostname of the Second (2nd) Replicator appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Replicator2Hostname,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Gateway IP address for 1st and 2nd Replicator appliances')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ReplicatorGW,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'vSphere network to be used for deployment of 1st and 2nd Replicator appliances')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ReplicatorNetwork,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'NTP Server address to be used for all VCDA appliances')]
        [ValidateNotNullOrEmpty()]
        [string]
        $NTPServer,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'List of DNS server to be used for all appliances (for example, "192.168.1.1,192.168.1.2"')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DNSServer,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'List of search domain for all appliances (for example: "domain1.local,domain2.local")')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SearchDomain,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Named of the VCDA .ova file, located in top folder of the same Datastore where appliances will be deployed (for example: "VCDA-4.6.1.ova")')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OVAFilename,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Accept the End User License Agreement: "https://github.com/vmware/vmware-powercli-for-vmware-cloud-director-availability/blob/c1705a1cf78861e6d65236fc8d6ea6c89f17ec5f/Resources/EULA.txt"')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $AcceptEULA
    )

    try {
        Write-Log -message "Starting 'Deploy-VCDA-AVS'"
        #make sure vc connection is healthy, script will fail if not
        if ($null -eq ((Get-View SessionManager -Server $global:DefaultVIServer).CurrentSession)) {
            Write-Error "vCenter server '$($Global:defaultviserver.Name)' connection is not heathy."
        }
        if ($AcceptEULA -ne $true) {
            Write-Error 'You must accept the End User License Agreement "https://github.com/vmware/vmware-powercli-for-vmware-cloud-director-availability/blob/c1705a1cf78861e6d65236fc8d6ea6c89f17ec5f/Resources/EULA.txt" to install VCDA. '
        }
        #Prepare the SDDC
        Initialize-AVSSite

        #get folder
        $vm_folder = Get-Folder -Name $Script:vcda_avs_params.vsphere.folder -Type VM -Location ([AVSSecureFolder]::root())
        $LocalVarCommonParams = @{
            'OVAFilename'       = $OVAFilename
            'NTP'               = $NTPServer
            'DNS'               = $DNSServer
            'Domains'           = $SearchDomain
            'Datastore'         = $Datastore
            'MTU'               = 1500
            'InventoryLocation' = $Script:vcda_avs_params.vsphere.folder
            'cluster'           = $cluster
        }

        $LocalVarCommonParams.DNS = $DNSServer
        $LocalVarCommonParams.Domains = $SearchDomain

        $LocalvarManagerParams = @{
            'IPAddress' = $ManagerIPAddress
            'Gateway'   = $ManagerGW
            'hostname'  = $ManagerHostname
        }
        $LocalvarTunnelParams = @{
            'IPAddress' = $TunnelIPAddress
            'Gateway'   = $TunnelGW
            'hostname'  = $TunnelHostname
        }
        $LocalvarRepl01Params = @{
            'IPAddress' = $Replicator1IPAddress
            'Gateway'   = $ReplicatorGW
            'hostname'  = $Replicator1Hostname
        }
        $LocalvarRepl02Params = @{
            'IPAddress' = $Replicator2IPAddress
            'Gateway'   = $ReplicatorGW
            'hostname'  = $Replicator2Hostname
        }

        #1 deploy manager
        $man_vm_name = 'VCDA-AVS-Manager-01'
        $man_pass = Get-VCDAVMPassword -name $man_vm_name
        $manager_vm = Deploy-VCDAOVA @LocalVarCommonParams @LocalvarManagerParams -DeploymentOption cloud -Name $man_vm_name `
            -network $ManagerNetwork -password $man_pass.old
        [avSSecureFolder]::Secure($vm_folder)
        #$manager_vm | Add-VCDATag

        #2 deploy tunnel
        $tun_vm_name = 'VCDA-AVS-Tunnel-01'
        $tun_pass = Get-VCDAVMPassword -name $tun_vm_name
        $tunnel_vm = Deploy-VCDAOVA @LocalVarCommonParams @LocalvarTunnelParams -DeploymentOption tunnel -Name $tun_vm_name `
            -network $TunnelNetwork -password $tun_pass.old
        [avSSecureFolder]::Secure($vm_folder)
        #$tunnel_vm | Add-VCDATag

        #3 deploy replicator 1
        $repl1_vm_name = 'VCDA-AVS-Replicator-01'
        $repl1_pass = Get-VCDAVMPassword -name $repl1_vm_name
        $repl1_vm = Deploy-VCDAOVA @LocalVarCommonParams @LocalvarRepl01Params -DeploymentOption replicator -Name $repl1_vm_name `
            -network $ReplicatorNetwork -password $repl1_pass.old
        [avSSecureFolder]::Secure($vm_folder)
        #$repl1_vm | Add-VCDATag

        #4 deploy replicator 2
        $repl2_vm_name = 'VCDA-AVS-Replicator-02'
        $repl2_pass = Get-VCDAVMPassword -name $repl2_vm_name
        $repl2_vm = Deploy-VCDAOVA @LocalVarCommonParams @LocalvarRepl02Params -DeploymentOption replicator -Name $repl2_vm_name `
            -network $ReplicatorNetwork -password $repl2_pass.old
        [avSSecureFolder]::Secure($vm_folder)
        #$repl2_vm | Add-VCDATag

        Initialize-VCDAAppliance -VCDA_VM $manager_vm -LicenseKey $license -SiteName $SiteName -PublicApiEndpoint $PublicApiEndpoint -vcd_api_endpoint $VCDApiEndpoint `
            -vcd_user $VCDUser -vcd_password $VCDPassword -IPAddress $LocalvarManagerParams.IPAddress

        Initialize-VCDAAppliance -VCDA_VM $tunnel_vm -IPAddress $LocalvarTunnelParams.IPAddress

        Initialize-VCDAAppliance -VCDA_VM $repl1_vm -IPAddress $LocalvarRepl01Params.IPAddress
        Initialize-VCDAAppliance -VCDA_VM $repl2_vm -IPAddress $LocalvarRepl02Params.IPAddress


        Register-Replicators -VCDA_Manager_VM $manager_vm -VCDA_replicator_VM $repl1_vm
        Register-Replicators -VCDA_Manager_VM $manager_vm -VCDA_replicator_VM $repl2_vm

        Register-Tunnel -VCDA_Manager_VM $manager_vm -VCDA_tunnel_vm $tunnel_vm

    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}