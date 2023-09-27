<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Write-Log {
    param (
    [Parameter(Mandatory = $true)]
    [string]
    $message
    )
    Write-Host "$(get-date -format "dd-MM-yyyy-HH:mm:ss K"): $message"
}