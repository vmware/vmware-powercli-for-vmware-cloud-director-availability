<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Connect-VCDA {
    [CmdletBinding()]
    param (
        #VCDA server address IP or FQDN
        [Parameter(Mandatory = $true )]
        [string]$Server,
        #authentication type
        [parameter(mandatory = $true, HelpMessage = "Local, SSO, VCDCredentials")]
        [ValidateSet("Local", "SSO", "VCDCredentials")]
        [string]$AuthType,
        #VCDA server port, Default 443
        [Parameter(Mandatory = $false)]
        [int]$port = 443,
        #VCDA credential local credentia (root)
        [Parameter(Mandatory = $true)]
        [PSCredential] $Credentials,
        # Specifies that you do not want to save the specified server as default servers.
        [Parameter(Mandatory = $false)]
        [switch] $NotDefault = $false,
        # Parameter help description
        [Parameter(Mandatory = $false)]
        [Switch]
        $SkipCertificateCheck
    )

    process {
        try {
            $LocalVarBodyParameter = @{}
            switch ($PSBoundParameters.AuthType) {
                "local" {
                    $LocalVarBodyParameter["type"] = "localUser"
                    $LocalVarBodyParameter["localUser"] = $Credentials.UserName
                    $LocalVarBodyParameter["localPassword"] = $Credentials.GetNetworkCredential().Password
                }
                "sso" {
                    $LocalVarBodyParameter["type"] = "ssoCredentials"
                    $LocalVarBodyParameter["username"] = $Credentials.UserName
                    $LocalVarBodyParameter["password"] = $Credentials.GetNetworkCredential().Password
                }
                "VCDCredentials" {
                    $LocalVarBodyParameter["type"] = "vcdCredentials"
                    $LocalVarBodyParameter["vcdUser"] = $Credentials.UserName
                    $LocalVarBodyParameter["vcdPassword"] = $Credentials.GetNetworkCredential().Password
                }
            }

            $LocalVarBodyParameter = $LocalVarBodyParameter | ConvertTo-Json -Depth 100
            $LocalVarUri = [System.UriBuilder]::new("https", $server, $port).Uri.ToString()
            $LocalVarheaders = @{
                'Content-Type' = "application/json"
            }
            Write-Verbose "Connecting to $LocalVarUri"
            $LocalvarInvokeParams = @{
                'uri'                  = $LocalVarUri
                'Method'               = "Post"
                'Body'                 = $LocalVarBodyParameter
                'Headers'              = $LocalVarheaders
                'Path'                 = "sessions"
                'SkipCertificateCheck' = $SkipCertificateCheck
            }
            $LocalVarResult = Invoke-VCDARequest @LocalvarInvokeParams

            $VCDAClient = [PSCustomObject]@{
                'PSTypeName'           = "VCDAServer"
                'Server'               = $Server
                'IsConnected'          = $false
                'ServiceUri'           = $LocalVarUri
                'Headers'              = @{
                    'Content-Type' = "application/json";
                    'X-VCAV-Auth'  = [string] $LocalVarResult.headers.'X-VCAV-Auth';
                    'Accept'       = [string] $LocalVarResult.headers.'Content-Type';
                    'operationID'  = ""
                }
                'ServiceType'          = ""
                'BuildVersion'         = ""
                'Client'               = $LocalVarResult.Response
                'UID'                  = ""
                'LocalSite'            = $LocalVarResult.Response.authenticatedSites.site
                'LocalOrg'            = $LocalVarResult.Response.authenticatedSites.org
                'SkipCertificateCheck' = $SkipCertificateCheck
                'Default'              = $false
            }
            $VCDAClient.UID = $LocalVarResult.Response.user, $Server, (New-Guid).Guid -join "/"
            $VCDAClient.Headers.operationID = "VMware.VCDA.AVS", (New-Guid).Guid -join "-"
            #get-product info and add it to connection
            $LocalVarInfo = Get-VCDAInfo -server $VCDAClient
            $VCDAClient.ServiceType = $LocalVarInfo.serviceType
            $VCDAClient.BuildVersion = $LocalVarInfo.buildVersion
            $VCDAClient.IsConnected = $true

            if (-not $NotDefault) {
                $VCDAClient.Default = $true
                Set-Variable -Name DefaultVCDAServer -Value $VCDAClient -Scope Global
            }
            return $VCDAClient

        }
        catch {
            if ($_.TargetObject -match "VCDA_Server_Error" -and $_ -match "Authentication required.") {
                Write-Error "Unable to connect to VCDA Server '$server'. The server returned the following: '$_'"
            }
            if ($_ -match "The remote certificate is invalid according to the validation procedure") {
                Write-Error "The remote certificate is invalid. If you want to connect anyway use '-SkipCertificateCheck' parameter"
            }
            else {
                $psCmdlet.ThrowTerminatingError($_)
            }
        }
    }
}