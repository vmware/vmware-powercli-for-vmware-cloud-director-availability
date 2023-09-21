<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Invoke-VCDARequest {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory = $true, ParameterSetName = "uri")]
        [string]
        $uri,
        [Parameter(Mandatory = $false, ParameterSetName = "connection")]
        #[ValidateVCDAID()]
        #[PSTypeName('VCDAServer')]
        $client,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Get", "Put", "Post", "Delete", "Patch")]
        [string]
        $method,
        [Parameter(Mandatory = $false, ParameterSetName = "uri")]
        [hashtable]
        $headers,
        # Query Parameters used in the reuest
        [Parameter(mandatory = $false)]
        [System.Collections.IDictionary]
        $QueryParams,
        # SkipCertificateCheck
        [Parameter(Mandatory = $false)]
        [switch]
        $SkipCertificateCheck,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $path,
        [Parameter(Mandatory = $false)]
        [string]
        $body,
        # override content type headers
        [Parameter(Mandatory = $false, ParameterSetName = "connection")]
        [string]
        $ContentType,
        # override accept headers
        [Parameter(Mandatory = $false, ParameterSetName = "connection")]
        [string]
        $Accept,
        # additional headers
        [Parameter(Mandatory = $false, ParameterSetName = "connection")]
        [hashtable]
        $AddHeaders

    )

    process {
        switch ($psCmdlet.ParameterSetName) {
            "uri" {
                #use the uri param as is
                $Requesturi = New-Object System.UriBuilder $uri
                if ($path) {
                    $Requesturi.Path = $path
                }
                $RequestHeaders = $headers
            }
            "connection" {
                $Requesturi = New-Object System.UriBuilder $client.ServiceUri
                $Requesturi.path = $path
                $RequestHeaders = ($client.Headers.clone())
                if ($Accept) {
                    $RequestHeaders['Accept'] = $Accept
                }
                if ($ContentType) {
                    $RequestHeaders['Content-Type'] = $ContentType
                }
                if ($AddHeaders) {
                    $RequestHeaders += $AddHeaders
                }
                $clientId = New-Object PSObject -Property @{
                    'uid'  = $client.uid
                    'site' = $client.LocalSite
                }
                $SkipCertificateCheck = $client.SkipCertificateCheck

            }
        }
        if ($PSBoundParameters.ContainsKey("QueryParams")) {
            $collection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            foreach ($key in $QueryParams.Keys ) {
                if ($QueryParams.$Key.Length -ne 0 ) {
                    $collection.add($key, $QueryParams.$key)
                }
                $Requesturi.Query = $collection.ToString()
            }
            if ($clientId) {
                if ([bool]$QueryParams['site']) {
                    $clientId.site = $QueryParams['site']
                }
            }
        }


        try {
            # create custom user agent in format "Powershell/version module_name/module_version"
            if (-not $Script:useragent) {
                $module = $ExecutionContext.SessionState.Module
                $script:user_agent = (("Powershell", $PSVersionTable.PSVersion.ToString() -join "/"), ($module.Name.ToString(), $module.Version.ToString() -join "/") -join " " )
            }
            Write-Debug $script:user_agent
            $LocalvarInvokeParams = @{
                'uri'                  = $Requesturi.Uri
                'headers'              = $RequestHeaders
                'method'               = $method
                'body'                 = $body
                'SkipCertificateCheck' = $SkipCertificateCheck
                'UserAgent'            = $script:user_agent
            }
            Write-debug "$($LocalvarInvokeParams.method) $($LocalvarInvokeParams.uri)"
            $LocalVarResult = Invoke-WebRequest @LocalvarInvokeParams
            if ($LocalVarResult.Headers.'Content-Type' -match "(?i)^(application/json|[^;/ \t]+/[^;/ \t]+[+]json)[ \t]*(;.*)?$") {
                $LocalVarResponse = ConvertFrom-Json $LocalVarResult
                if ([bool]$LocalVarResponse.psobject.Properties['items']) {
                    foreach ($item in $LocalVarResponse.items) {
                        $item | Add-Member -MemberType NoteProperty -Name "ClientId" -Value $clientId
                    }
                }
                else {
                    foreach ($item in $LocalVarResponse) {
                        $item | Add-Member -MemberType NoteProperty -Name "ClientId" -Value $clientId
                    }
                }
            }
            else {
                $LocalVarResponse = $LocalVarResult
            }

            return @{
                Response   = $LocalVarResponse
                StatusCode = $LocalVarResult.StatusCode
                Headers    = $LocalVarResult.Headers
                ClientId   = $clientId
            }
        }
        catch [System.Net.Http.HttpRequestException] {
            if ($_.Exception.Response.StatusCode -eq 'Unauthorized') {
                if ($_.Exception.Response.Headers.WwwAuthenticate -contains "Authentication Token Required") {
                    #mark server as disconnected
                    if ($client) {
                        $client.IsConnected = $false
                    }
                    Write-Error "The connection to server '$($client.server)' was disconnected or lost." `
                        -TargetObject "VCDA_Server_Error" `
                        -Category AuthenticationError `
                        -CategoryReason "session_expired"


                }
                elseif ($QueryParams.Site -and !$client.Client.authenticatedSites.site.contains($QueryParams.site)) {
                    #Write-Error "Remote site '$($Queryparams.site)' is not authenticated"
                    Write-Error "Remote site '$($Queryparams.site)' is Not Authenticated, use 'Connect-VCDARemoteSite -site $($Queryparams.site)' to connect."`
                        -TargetObject "VCDA_Server_Error"
                }
                elseif ($_.Exception.Response -and $null -ne $_.ErrorDetails.Message) {
                    if ($client) {
                        $client.IsConnected = $false
                    }
                    Write-Error "$(($_ | ConvertFrom-Json).msg)" -TargetObject "VCDA_Server_Error"
                }
            }
            #return server message wichc might have more meaningful information.
            elseif ($_.Exception.Response -and $null -ne $_.ErrorDetails.Message) {
                Write-Debug "$_"
                Write-Error "$(($_ | ConvertFrom-Json).msg)" -TargetObject "VCDA_Server_Error"

            }
            else {
                Write-Error $_ -TargetObject "VCDA_Server_Error"
            }
        }
        catch {
            #unusual exeption
            Write-Error $_
        }

    }
}