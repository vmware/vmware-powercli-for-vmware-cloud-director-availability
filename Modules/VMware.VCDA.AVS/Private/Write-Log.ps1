<#
Copyright (c) CA, Inc. All rights reserved.
SPDX-License-Identifier: LicenseRef-CA-Inc-Software-License
#>
function Write-Log {
    param (
    [Parameter(Mandatory = $true)]
    [string]
    $message,
    [Parameter(Mandatory = $false)]
    [string]
    $LogPrefix
    )
    if ($LogPrefix){
        $message = $LogPrefix + ": " + $message}
    Write-Host "$(get-date -format "HH:mm:ss"): $message"
}