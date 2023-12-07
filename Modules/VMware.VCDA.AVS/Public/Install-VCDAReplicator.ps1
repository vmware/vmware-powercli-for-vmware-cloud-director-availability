<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Install-VCDAReplicator {
    <#
.SYNOPSIS
    Install and configure new VCDA Replicator virtual machine in AVS environment.
.DESCRIPTION
    Install and configure new VCDA Replicator virtual machine in AVS environment.
.PARAMETER Datastore
    Datastore to be used for deployment of the appliance
.PARAMETER Cluster
    Destination vSphere Cluster to be used for deployment of the appliance
.PARAMETER ReplicatorIPAddress
    IPv4 address in CIDR notation (for example 192.168.0.226/24) to be used for deployment of the Replicator appliance
.PARAMETER ReplicatorHostname
    Hostname of the Replicator appliance
.PARAMETER ReplicatorGW
    Gateway IP address for the Replicator appliance
.PARAMETER ReplicatorNetwork
    vSphere network to be used for deployment of the Replicator appliance
.PARAMETER NTPServer
    NTP Server address to be used by the Replicator appliance
.PARAMETER DNSServer
    List of DNS server to be used for the Replicator appliance (for example, "192.168.1.1,192.168.1.2")
.PARAMETER SearchDomain
    List of search domain for all appliances (for example: "domain1.local,domain2.local")
.PARAMETER OVAFilename
    Name of the VCDA .ova file, located in top folder of the same Datastore where appliance will be deployed (for example: "VCDA-4.6.1.ova")
.PARAMETER VMName
    Name of the replicator VM, must match the predefined VM Names.
    ("VCDA_AVS_Replicator_03", "VCDA_AVS_Replicator_04", "VCDA_AVS_Replicator_05", "VCDA_AVS_Replicator_06")
.PARAMETER AcceptEULA
    Accept the End User License Agreement: "https://github.com/vmware/vmware-powercli-for-vmware-cloud-director-availability/blob/c1705a1cf78861e6d65236fc8d6ea6c89f17ec5f/Resources/EULA.txt"'
.EXAMPLE
    $params = @{
        'VMName'              = 'VCDA_AVS_Replicator_03'
        'Datastore'           = 'Datastore01'
        'Cluster'             = 'Cluster01'
        'ReplicatorIPAddress' = '192.168.0.226/24'
        'ReplicatorHostname'   = 'vcda-r03'
        'ReplicatorGW'        = '192.168.0.1'
        'ReplicatorNetwork'   = 'vcda-network'
        'NTPServer'           = 'time.vcda.local'
        'DNSServer'           = '192.168.0.10,192.168.0.11'
        'SearchDomain'        = 'vma.local'
        'OVAFilename'         = 'VMware-Cloud-Director-Availability-Provider-4.6.1.7681624-a5359f8567_OVF10.ova'
        'AcceptEULA'          = $true
    }
    Install-VCDAReplicator @params
#>
    [AVSAttribute(30, UpdatesSDDC = $false)]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Datastore to be used for deployment of the appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Datastore,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Destination vSphere Cluster to be used for deployment of the appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Cluster,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'IPv4 address in CIDR notation (for example 192.168.0.226/24) to be used for deployment of the Replicator appliance')]
        [ValidateScript({
                [System.Net.IPAddress]($_.split("/")[0]) -and 0..32 -contains $_.Split("/")[1]
            }, ErrorMessage = "'{0}' is not valid format, IPv4 address in CIDR notation (for example 192.168.0.226/24)"
        )]
        [string]
        $ReplicatorIPAddress,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Hostname of the Replicator appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ReplicatorHostname,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Gateway IP address for the Replicator appliance')]
        [ValidateScript({ [System.Net.IPAddress]($_) })]
        [string]
        $ReplicatorGW,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'vSphere network to be used for deployment of the Replicator appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ReplicatorNetwork,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'NTP Server address to be used by the Replicator appliance')]
        [ValidateNotNullOrEmpty()]
        [string]
        $NTPServer,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'List of DNS server to be used for the Replicator appliance (for example, "192.168.1.1,192.168.1.2")')]
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
            HelpMessage = 'Name of the VCDA .ova file, located in folder of the same Datastore where appliance will be deployed (for example: "VCDA-4.6.1.ova")')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OVAFilename,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Name of the replicator VM, must match the predefined VM Names')]
        [ValidateSet("VCDA-AVS-Replicator-03", "VCDA-AVS-Replicator-04", "VCDA-AVS-Replicator-05", "VCDA-AVS-Replicator-06")]
        [string]
        $VMName,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Accept the End User License Agreement: "https://github.com/vmware/vmware-powercli-for-vmware-cloud-director-availability/blob/c1705a1cf78861e6d65236fc8d6ea6c89f17ec5f/Resources/EULA.txt"')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $AcceptEULA
    )

    try {
        #make sure vc connection is healthy, script will fail if not
        if ($null -eq ((Get-View SessionManager -Server $global:DefaultVIServer).CurrentSession)) {
            Write-Error "vCenter server '$($Global:defaultviserver.Name)' connection is not heathy."
        }
        if ($AcceptEULA -ne $true) {
            Write-Error 'You must accept the End User License Agreement "https://github.com/vmware/vmware-powercli-for-vmware-cloud-director-availability/blob/c1705a1cf78861e6d65236fc8d6ea6c89f17ec5f/Resources/EULA.txt" to install VCDA. '
        }
        $manager_vm = Get-VCDAVM -type cloud
        if ($null -eq $manager_vm) {
            Write-Error "Manager VM was not found, cannot install replicator without manager."
        }

        #get folder
        $vm_folder = Get-Folder $Script:vcda_avs_params.vsphere.folder -Type VM
        $password = Get-VCDAVMPassword -name $VMName
        $LocalVarCommonParams = @{
            'OVAFilename'       = $OVAFilename
            'password'          = $password.old
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
        $LocalvarReplParams = @{
            'IPAddress' = $ReplicatorIPAddress
            'Gateway'   = $ReplicatorGW
            'hostname'  = $ReplicatorHostname
        }

        #3 deploy replicator
        $repl_vm = Deploy-VCDAOVA @LocalVarCommonParams @LocalvarReplParams -DeploymentOption replicator -Name $VMName -network $ReplicatorNetwork
        [avSSecureFolder]::Secure($vm_folder)

        Initialize-VCDAAppliance -VCDA_VM $repl_vm -IPAddress $LocalvarReplParams.IPAddress
        Register-Replicators -VCDA_Manager_VM $manager_vm -VCDA_replicator_VM $repl_vm
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}