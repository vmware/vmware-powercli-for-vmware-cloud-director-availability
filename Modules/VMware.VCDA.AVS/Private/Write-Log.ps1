<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
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