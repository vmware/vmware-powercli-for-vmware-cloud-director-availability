<#
Copyright (c) CA, Inc. All rights reserved.
SPDX-License-Identifier: LicenseRef-CA-Inc-Software-License
#>
function Test-IPAddress {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IPAddress
    )
    try {
        $IP = ($IPAddress -split '/')[0]
        $ping = Test-Connection -TargetName $ip -Ping -IPv4 -Count 2 -Quiet
        if (-not $ping) {
            $tcp = Test-Connection -TargetName $ip -TcpPort 443 -TimeoutSeconds 4
        }
        if ($ping -or $tcp){
            Write-Error "IP Address $ip is already in use."
        }
        else {
            return
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}