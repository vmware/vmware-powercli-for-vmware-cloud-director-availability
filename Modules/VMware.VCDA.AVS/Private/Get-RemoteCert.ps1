<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-RemoteCert {
    [CmdletBinding()]
    param (
        # VCDA Server
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$url,
        # type
        [Parameter(Mandatory = $true)]
        [ValidateSet("certificate", "string", "sha256")]
        [string]$type
    )
    process {
        try {
            $uri = New-Object System.UriBuilder $url
            $tcp_Client = [System.Net.Sockets.TcpClient]::new()
            $tcp_Client.Connect($Uri.Host, $Uri.Port)
            $tcp_Stream = $tcp_Client.GetStream()
            $ssl_Stream = [System.Net.Security.SslStream]::new($tcp_Stream, $false, { return $true }, $null)
            $ssl_Stream.AuthenticateAsClient($Uri.Host)
            $Certificate = $ssl_Stream.RemoteCertificate
            $ssl_Stream.Dispose()
            switch ($type) {
                'certificate' {
                    return $Certificate
                }
                'string' {
                    return [System.Convert]::ToBase64String($Certificate.RawData)
                }
                'sha256' {
                    return "SHA-256:" + ([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($Certificate.GetRawCertData())) -replace "-", ":")
                }
            }
        }
        catch {
            Write-Log "Failed to get a certificate from remote address: '$url'." -LogPrefix "[ERROR]"
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}