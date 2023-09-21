<#
Copyright 2023 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-VCDARandomPassword {
    <#
    .DESCRIPTION
    Generate Random password to be used by VCDA
    .EXAMPLE
    Get-VCDARandomPassword
    Generate Random Password between 8-16 characters long.
    .EXAMPLE
    Get-SsoPasswordPolicy | Get-VCDARandomPassword
    Generate password based on the configured SSO Password Policy.
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [int]$MinLength = 8,
        [Parameter()]
        [int]$MaxLength = 16,
        [Parameter()]
        [int]$MinNumericCount,
        [Parameter()]
        [int]$MinSpecialCharCount,
        [Parameter()]
        [int]$MinAlphabeticCount,
        [Parameter()]
        [int]$MinUppercaseCount,
        [Parameter()]
        [int]$MinLowercaseCount,
        [Parameter()]
        [int]$MaxIdenticalAdjacentCharacters,
        [Parameter(Mandatory = $false, ValueFromPipeline)]
        [VMware.vSphere.SsoAdminClient.DataTypes.PasswordPolicy]$SsoPasswordPolicy
    )

    try {
        if ($null -ne $SsoPasswordPolicy) {
            $MinLength = $SsoPasswordPolicy.MinLength
            $MaxLength = $SsoPasswordPolicy.MaxLength
            $MinNumericCount = $SsoPasswordPolicy.MinNumericCount
            $MinSpecialCharCount = $SsoPasswordPolicy.MinSpecialCharCount
            $MinAlphabeticCount = $SsoPasswordPolicy.MinAlphabeticCount
            $MinUppercaseCount = $SsoPasswordPolicy.MinUppercaseCount
            $MinLowercaseCount = $SsoPasswordPolicy.MinLowercaseCount
            $MaxIdenticalAdjacentCharacters = $SsoPasswordPolicy.MaxIdenticalAdjacentCharacters
        }

        $password_lenght = ($MinLength..$MaxLength) | Get-Random
        $password = @()
        $all_chars = @{
            Lowercase   = (97..122) | ForEach-Object { [char]$_ }
            Upperase    = (65..90) | ForEach-Object { [char]$_ }
            Numeric     = (48..57) | ForEach-Object { [char]$_ }
            SpecialChar = ,33 + (35..47) + (58..64) + (91..95) + (123..126) | ForEach-Object { [char]$_ }
        }

        if ($MinLowercaseCount) {
            $password += 1..$MinLowercaseCount | ForEach-Object { $all_chars.Lowercase | Get-Random }
        }
        if ($MinUppercaseCount) {
            $password += 1..$MinUppercaseCount | ForEach-Object { $all_chars.Upperase | Get-Random }
        }
        if ($MinNumericCount) {
            $password += 1..$MinNumericCount | ForEach-Object { $all_chars.Numeric | Get-Random }
        }
        if ($MinSpecialCharCount) {
            $password += 1..$MinSpecialCharCount | ForEach-Object { $all_chars.SpecialChar | Get-Random }
        }
        if ($MinAlphabeticCount -gt 0) {
            $extra_Alphabetic = $MinAlphabeticCount - $MinLowercaseCount - $MinUppercaseCount
        }
        if ($extra_Alphabetic -gt 0) {
            $password += 1..$extra_Alphabetic | ForEach-Object { ($all_chars.Lowercase + $all_chars.Upperase) | Get-Random }
        }
        if ($password.Count -lt $password_lenght) {
            $extra_chars = $password_lenght - $password.Count
            $password += 1..$extra_chars `
            | ForEach-Object { ($all_chars.Lowercase + $all_chars.Upperase + $all_chars.Numeric + $all_chars.SpecialChar) | Get-Random }

        }
        $password = -join ($password | Get-Random -Shuffle )
        if ($MaxIdenticalAdjacentCharacters -gt 0) {
            $final_password = @()
            $prev_char = ""
            $count = 1
            foreach ($char in $password.ToCharArray()) {
                if ($prev_char -ceq $char) {
                    $count ++
                }
                elseif ($prev_char -cne $char) {
                    $count = 1
                }
                if ($count -gt $MaxIdenticalAdjacentCharacters) {
                    #find what type is the charecter to replace it with same type.
                    switch ($char) {
                        #Lowercase
                        { 97..122 -contains $_ } { $char_type = $all_chars.Lowercase }
                        #Upperase
                        { 65..90 -contains $_ } { $char_type = $all_chars.Upperase }
                        #Numeric
                        { 48..57 -contains $_ } { $char_type = $all_chars.Numeric }
                        #SpecialChar
                        { (33..47) + (58..64) + (91..96) + (123..126) -contains $_ } { $char_type = $all_chars.SpecialChar }
                    }
                    $char = $char_type | Where-Object { $_ -notcontains $char } | Get-Random
                }
                $final_password += $char
                $prev_char = $char
            }
            $password = $final_password
        }

        $password = -join $password
        return $password
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

}