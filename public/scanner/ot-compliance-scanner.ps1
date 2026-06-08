<#
OT Compliance Scanner v1.0
Read-only Windows configuration collection script.

Safety rules:
- This script does NOT modify system settings.
- This script does NOT create, delete, enable, disable, or reconfigure anything.
- This script only reads configuration data and writes a JSON report to the current user's Desktop.
#>

$ErrorActionPreference = 'Continue'

$results = New-Object System.Collections.Generic.List[object]

function Use-Default {
    param(
        $Value,
        [string]$Fallback = ''
    )

    if ($null -eq $Value) {
        return $Fallback
    }

    return [string]$Value
}

function Add-Result {
    param(
        [string]$Id,
        [string]$Control,
        [string]$ActualValue,
        [string]$ExpectedValue,
        [ValidateSet('pass', 'fail', 'manual_review', 'not_checked', 'error')]
        [string]$Status,
        [string]$Source,
        [string]$Notes = ''
    )

    $results.Add([pscustomobject][ordered]@{
        id            = $Id
        control       = $Control
        actualValue   = Use-Default $ActualValue ''
        expectedValue = Use-Default $ExpectedValue ''
        status        = $Status
        source        = Use-Default $Source ''
        notes         = Use-Default $Notes ''
    }) | Out-Null
}

function Get-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )

    try {
        $item = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        return $item.$Name
    }
    catch {
        return $null
    }
}

function Get-NetAccountsValue {
    param(
        [string]$Text,
        [string]$Label
    )

    $pattern = '(?im)^\s*' + [regex]::Escape($Label) + '\s+(.+?)\s*$'
    $match = [regex]::Match($Text, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }

    return $null
}

function Get-NumericOrUnlimited {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    if ($Value -match 'unlimited|never') {
        return 0
    }

    $digits = [regex]::Match($Value, '(\d+)')
    if ($digits.Success) {
        return [int]$digits.Groups[1].Value
    }

    return $null
}

function Add-ManualReviewResult {
    param(
        [string]$Id,
        [string]$Control,
        [string]$ExpectedValue,
        [string]$Source,
        [string]$Notes
    )

    Add-Result -Id $Id -Control $Control -ActualValue 'Manual verification required' -ExpectedValue $ExpectedValue -Status 'manual_review' -Source $Source -Notes $Notes
}

function Test-RegistryExpectation {
    param(
        [string]$Id,
        [string]$Control,
        [string]$Path,
        [string]$Name,
        [string]$ExpectedValue,
        [scriptblock]$Evaluator,
        [string]$Source,
        [string]$MissingNotes = 'Value not found.'
    )

    try {
        $value = Get-RegistryValue -Path $Path -Name $Name
        $actual = if ($null -eq $value) { 'Not configured / value missing' } else { [string]$value }
        $evaluation = & $Evaluator $value
        Add-Result -Id $Id -Control $Control -ActualValue $actual -ExpectedValue $ExpectedValue -Status $evaluation.Status -Source $Source -Notes $evaluation.Notes
    }
    catch {
        Add-Result -Id $Id -Control $Control -ActualValue '' -ExpectedValue $ExpectedValue -Status 'error' -Source $Source -Notes $_.Exception.Message
    }
}

function Test-OptionalFeatureState {
    param(
        [string]$Id,
        [string]$Control,
        [string]$FeatureName,
        [string]$ExpectedValue,
        [string]$Source
    )

    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction Stop
        $actual = [string]$feature.State
        $status = if ($feature.State -in @('Disabled', 'DisabledWithPayloadRemoved')) { 'pass' } else { 'fail' }
        Add-Result -Id $Id -Control $Control -ActualValue $actual -ExpectedValue $ExpectedValue -Status $status -Source $Source -Notes ''
    }
    catch {
        Add-Result -Id $Id -Control $Control -ActualValue '' -ExpectedValue $ExpectedValue -Status 'error' -Source $Source -Notes $_.Exception.Message
    }
}

function Test-ServiceControl {
    param(
        [pscustomobject]$Mapping
    )

    $source = 'Get-CimInstance Win32_Service'

    try {
        $service = Get-CimInstance Win32_Service -Filter ("Name='{0}'" -f $Mapping.ServiceName) -ErrorAction Stop
    }
    catch {
        if ($_.Exception.Message -match 'No instances available|not found|cannot find') {
            Add-Result -Id $Mapping.Id -Control $Mapping.Control -ActualValue 'Service not installed/present' -ExpectedValue $Mapping.Requirement -Status 'pass' -Source $source -Notes 'Service not installed/present.'
            return
        }

        Add-Result -Id $Mapping.Id -Control $Mapping.Control -ActualValue '' -ExpectedValue $Mapping.Requirement -Status 'error' -Source $source -Notes $_.Exception.Message
        return
    }

    $actual = "StartMode=$($service.StartMode); State=$($service.State)"
    $requirement = [string]$Mapping.Requirement

    if ($requirement -match '3rd Party Used') {
        if ($service.StartMode -eq 'Disabled') {
            Add-Result -Id $Mapping.Id -Control $Mapping.Control -ActualValue $actual -ExpectedValue $requirement -Status 'pass' -Source $source -Notes 'Service is disabled.'
        }
        else {
            Add-Result -Id $Mapping.Id -Control $Mapping.Control -ActualValue $actual -ExpectedValue $requirement -Status 'manual_review' -Source $source -Notes 'Service is enabled. Confirm whether Microsoft Defender is intentionally in use or an approved third-party endpoint protection design applies.'
        }
        return
    }

    if ($requirement -match 'unless explicitly required|unless secure jump host used|non-printing nodes') {
        if ($service.StartMode -eq 'Disabled') {
            Add-Result -Id $Mapping.Id -Control $Mapping.Control -ActualValue $actual -ExpectedValue $requirement -Status 'pass' -Source $source -Notes 'Service is disabled.'
        }
        else {
            Add-Result -Id $Mapping.Id -Control $Mapping.Control -ActualValue $actual -ExpectedValue $requirement -Status 'manual_review' -Source $source -Notes 'Service is enabled. Verify approved business justification or architecture exception.'
        }
        return
    }

    if ($requirement -match 'Disabled') {
        if ($service.StartMode -eq 'Disabled') {
            Add-Result -Id $Mapping.Id -Control $Mapping.Control -ActualValue $actual -ExpectedValue $requirement -Status 'pass' -Source $source -Notes 'Service is disabled.'
        }
        else {
            Add-Result -Id $Mapping.Id -Control $Mapping.Control -ActualValue $actual -ExpectedValue $requirement -Status 'fail' -Source $source -Notes 'Service is installed but not disabled.'
        }
        return
    }

    Add-Result -Id $Mapping.Id -Control $Mapping.Control -ActualValue $actual -ExpectedValue $requirement -Status 'manual_review' -Source $source -Notes 'Requirement requires contextual review.'
}

$isAdministrator = $false
try {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    $isAdministrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
catch {
    $isAdministrator = $false
}

$adminNote = if ($isAdministrator) { '' } else { 'Script was not launched with elevated rights. Some checks may be incomplete.' }

$biosNote = 'BIOS/UEFI settings are OEM-specific and cannot be reliably verified by browser or generic scanner. Check manually or use OEM tools such as Dell Command Configure, HP BIOS Configuration Utility, Lenovo WMI BIOS provider, or enterprise device management.'
Add-ManualReviewResult -Id '2.1.01' -Control 'BIOS Password' -ExpectedValue 'Configured' -Source 'OEM-specific BIOS/UEFI' -Notes $biosNote
Add-ManualReviewResult -Id '2.1.02' -Control 'Boot Sequence' -ExpectedValue 'Internal fixed disk first / approved boot order' -Source 'OEM-specific BIOS/UEFI' -Notes $biosNote
Add-ManualReviewResult -Id '2.1.03' -Control 'Boot from Removable Media' -ExpectedValue 'Disabled unless approved' -Source 'OEM-specific BIOS/UEFI' -Notes $biosNote
Add-ManualReviewResult -Id '2.1.04' -Control 'PXE Boot' -ExpectedValue 'Disabled unless formally required' -Source 'OEM-specific BIOS/UEFI' -Notes $biosNote

try {
    $netAccountsOutput = (cmd /c 'net accounts' 2>&1 | Out-String)

    $minLengthRaw = Get-NetAccountsValue -Text $netAccountsOutput -Label 'Minimum password length'
    $maxAgeRaw = Get-NetAccountsValue -Text $netAccountsOutput -Label 'Maximum password age (days)'
    $minAgeRaw = Get-NetAccountsValue -Text $netAccountsOutput -Label 'Minimum password age (days)'
    $historyRaw = Get-NetAccountsValue -Text $netAccountsOutput -Label 'Length of password history maintained'
    $lockoutThresholdRaw = Get-NetAccountsValue -Text $netAccountsOutput -Label 'Lockout threshold'
    $lockoutDurationRaw = Get-NetAccountsValue -Text $netAccountsOutput -Label 'Lockout duration (minutes)'
    $lockoutWindowRaw = Get-NetAccountsValue -Text $netAccountsOutput -Label 'Lockout observation window (minutes)'

    $minLength = Get-NumericOrUnlimited $minLengthRaw
    if ($null -eq $minLength) {
        Add-Result -Id '2.2.01' -Control 'Password Minimum Length' -ActualValue (Use-Default $minLengthRaw '') -ExpectedValue 'Minimum 8 for standard accounts; 14 for privileged/admin service accounts' -Status 'error' -Source 'net accounts' -Notes 'Unable to parse minimum password length.'
    }
    elseif ($minLength -ge 14) {
        Add-Result -Id '2.2.01' -Control 'Password Minimum Length' -ActualValue [string]$minLength -ExpectedValue 'Minimum 8 for standard accounts; 14 for privileged/admin service accounts' -Status 'pass' -Source 'net accounts' -Notes $adminNote
    }
    elseif ($minLength -ge 8) {
        Add-Result -Id '2.2.01' -Control 'Password Minimum Length' -ActualValue [string]$minLength -ExpectedValue 'Minimum 8 for standard accounts; 14 for privileged/admin service accounts' -Status 'manual_review' -Source 'net accounts' -Notes ('Meets normal account minimum. Review privileged/admin service account requirements separately. ' + $adminNote).Trim()
    }
    else {
        Add-Result -Id '2.2.01' -Control 'Password Minimum Length' -ActualValue [string]$minLength -ExpectedValue 'Minimum 8 for standard accounts; 14 for privileged/admin service accounts' -Status 'fail' -Source 'net accounts' -Notes $adminNote
    }

    $maxAge = Get-NumericOrUnlimited $maxAgeRaw
    if ($null -eq $maxAge) {
        Add-Result -Id '2.2.02' -Control 'Password Maximum Age' -ActualValue (Use-Default $maxAgeRaw '') -ExpectedValue '365 days or lower; documented exception for service accounts only' -Status 'error' -Source 'net accounts' -Notes 'Unable to parse maximum password age.'
    }
    elseif ($maxAge -eq 0) {
        Add-Result -Id '2.2.02' -Control 'Password Maximum Age' -ActualValue 'Unlimited / 0' -ExpectedValue '365 days or lower; documented exception for service accounts only' -Status 'manual_review' -Source 'net accounts' -Notes ('Non-expiring passwords require documented service-account or domain exception. ' + $adminNote).Trim()
    }
    elseif ($maxAge -le 365) {
        Add-Result -Id '2.2.02' -Control 'Password Maximum Age' -ActualValue [string]$maxAge -ExpectedValue '365 days or lower; documented exception for service accounts only' -Status 'pass' -Source 'net accounts' -Notes $adminNote
    }
    else {
        Add-Result -Id '2.2.02' -Control 'Password Maximum Age' -ActualValue [string]$maxAge -ExpectedValue '365 days or lower; documented exception for service accounts only' -Status 'fail' -Source 'net accounts' -Notes $adminNote
    }

    $minAge = Get-NumericOrUnlimited $minAgeRaw
    if ($null -eq $minAge) {
        Add-Result -Id '2.2.03' -Control 'Password Minimum Age' -ActualValue (Use-Default $minAgeRaw '') -ExpectedValue '1 day or more' -Status 'error' -Source 'net accounts' -Notes 'Unable to parse minimum password age.'
    }
    elseif ($minAge -ge 1) {
        Add-Result -Id '2.2.03' -Control 'Password Minimum Age' -ActualValue [string]$minAge -ExpectedValue '1 day or more' -Status 'pass' -Source 'net accounts' -Notes $adminNote
    }
    else {
        Add-Result -Id '2.2.03' -Control 'Password Minimum Age' -ActualValue [string]$minAge -ExpectedValue '1 day or more' -Status 'fail' -Source 'net accounts' -Notes $adminNote
    }

    $history = Get-NumericOrUnlimited $historyRaw
    if ($null -eq $history) {
        Add-Result -Id '2.2.05' -Control 'Password History' -ActualValue (Use-Default $historyRaw '') -ExpectedValue '12 remembered passwords or more' -Status 'error' -Source 'net accounts' -Notes 'Unable to parse password history.'
    }
    elseif ($history -ge 12) {
        Add-Result -Id '2.2.05' -Control 'Password History' -ActualValue [string]$history -ExpectedValue '12 remembered passwords or more' -Status 'pass' -Source 'net accounts' -Notes $adminNote
    }
    else {
        Add-Result -Id '2.2.05' -Control 'Password History' -ActualValue [string]$history -ExpectedValue '12 remembered passwords or more' -Status 'fail' -Source 'net accounts' -Notes $adminNote
    }

    $lockoutThreshold = Get-NumericOrUnlimited $lockoutThresholdRaw
    if ($null -eq $lockoutThreshold) {
        Add-Result -Id '2.3.01' -Control 'Account lockout threshold' -ActualValue (Use-Default $lockoutThresholdRaw '') -ExpectedValue '5 for engineering/privileged, 10 only for approved service/operator accounts' -Status 'error' -Source 'net accounts' -Notes 'Unable to parse lockout threshold.'
    }
    elseif ($lockoutThreshold -eq 5) {
        Add-Result -Id '2.3.01' -Control 'Account lockout threshold' -ActualValue [string]$lockoutThreshold -ExpectedValue '5 for engineering/privileged, 10 only for approved service/operator accounts' -Status 'pass' -Source 'net accounts' -Notes $adminNote
    }
    elseif ($lockoutThreshold -eq 10) {
        Add-Result -Id '2.3.01' -Control 'Account lockout threshold' -ActualValue [string]$lockoutThreshold -ExpectedValue '5 for engineering/privileged, 10 only for approved service/operator accounts' -Status 'manual_review' -Source 'net accounts' -Notes ('Value may be acceptable only for approved service/operator accounts. ' + $adminNote).Trim()
    }
    else {
        Add-Result -Id '2.3.01' -Control 'Account lockout threshold' -ActualValue [string]$lockoutThreshold -ExpectedValue '5 for engineering/privileged, 10 only for approved service/operator accounts' -Status 'fail' -Source 'net accounts' -Notes $adminNote
    }

    $lockoutWindow = Get-NumericOrUnlimited $lockoutWindowRaw
    if ($null -eq $lockoutWindow) {
        Add-Result -Id '2.3.02' -Control 'Reset account lockout counter after' -ActualValue (Use-Default $lockoutWindowRaw '') -ExpectedValue '30 minutes for engineering/privileged/service, 15 for operator accounts' -Status 'error' -Source 'net accounts' -Notes 'Unable to parse lockout observation window.'
    }
    elseif ($lockoutWindow -eq 30) {
        Add-Result -Id '2.3.02' -Control 'Reset account lockout counter after' -ActualValue [string]$lockoutWindow -ExpectedValue '30 minutes for engineering/privileged/service, 15 for operator accounts' -Status 'pass' -Source 'net accounts' -Notes $adminNote
    }
    elseif ($lockoutWindow -eq 15) {
        Add-Result -Id '2.3.02' -Control 'Reset account lockout counter after' -ActualValue [string]$lockoutWindow -ExpectedValue '30 minutes for engineering/privileged/service, 15 for operator accounts' -Status 'manual_review' -Source 'net accounts' -Notes ('Value may be acceptable only for approved operator accounts. ' + $adminNote).Trim()
    }
    else {
        Add-Result -Id '2.3.02' -Control 'Reset account lockout counter after' -ActualValue [string]$lockoutWindow -ExpectedValue '30 minutes for engineering/privileged/service, 15 for operator accounts' -Status 'fail' -Source 'net accounts' -Notes $adminNote
    }

    $lockoutDuration = Get-NumericOrUnlimited $lockoutDurationRaw
    if ($null -eq $lockoutDuration) {
        Add-Result -Id '2.3.03' -Control 'Account lockout duration' -ActualValue (Use-Default $lockoutDurationRaw '') -ExpectedValue '30 minutes' -Status 'error' -Source 'net accounts' -Notes 'Unable to parse lockout duration.'
    }
    elseif ($lockoutDuration -eq 30) {
        Add-Result -Id '2.3.03' -Control 'Account lockout duration' -ActualValue [string]$lockoutDuration -ExpectedValue '30 minutes' -Status 'pass' -Source 'net accounts' -Notes $adminNote
    }
    else {
        Add-Result -Id '2.3.03' -Control 'Account lockout duration' -ActualValue [string]$lockoutDuration -ExpectedValue '30 minutes' -Status 'fail' -Source 'net accounts' -Notes $adminNote
    }
}
catch {
    foreach ($pair in @(
        @{ Id = '2.2.01'; Control = 'Password Minimum Length'; Expected = 'Minimum 8 for standard accounts; 14 for privileged/admin service accounts' },
        @{ Id = '2.2.02'; Control = 'Password Maximum Age'; Expected = '365 days or lower; documented exception for service accounts only' },
        @{ Id = '2.2.03'; Control = 'Password Minimum Age'; Expected = '1 day or more' },
        @{ Id = '2.2.05'; Control = 'Password History'; Expected = '12 remembered passwords or more' },
        @{ Id = '2.3.01'; Control = 'Account lockout threshold'; Expected = '5 for engineering/privileged, 10 only for approved service/operator accounts' },
        @{ Id = '2.3.02'; Control = 'Reset account lockout counter after'; Expected = '30 minutes for engineering/privileged/service, 15 for operator accounts' },
        @{ Id = '2.3.03'; Control = 'Account lockout duration'; Expected = '30 minutes' }
    )) {
        Add-Result -Id $pair.Id -Control $pair.Control -ActualValue '' -ExpectedValue $pair.Expected -Status 'error' -Source 'net accounts' -Notes $_.Exception.Message
    }
}

try {
    $computerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    $isDomainJoined = [bool]$computerSystem.PartOfDomain
}
catch {
    $isDomainJoined = $false
}

try {
    $auditRows = @(auditpol /get /subcategory:* /r 2>$null | ConvertFrom-Csv)

    function Get-AuditInclusionSettings {
        param([string[]]$Names)
        return @($auditRows | Where-Object { $Names -contains $_.Subcategory } | ForEach-Object { $_.'Inclusion Setting' } | Where-Object { $_ })
    }

    $auditChecks = @(
        @{ Id = '2.4.01'; Control = 'Audit Account Logon Events'; Expected = 'Success and Failure'; Names = @('Credential Validation'); Mode = 'success_failure' },
        @{ Id = '2.4.02'; Control = 'Audit Account Management'; Expected = 'Success and Failure'; Names = @('User Account Management', 'Computer Account Management', 'Security Group Management', 'Other Account Management Events'); Mode = 'success_failure_all' },
        @{ Id = '2.4.03'; Control = 'Audit Object Access'; Expected = 'Failure'; Names = @('File System', 'Registry', 'Other Object Access Events'); Mode = 'failure_only' },
        @{ Id = '2.4.04'; Control = 'Audit System Event'; Expected = 'Success and Failure'; Names = @('Security State Change', 'Security System Extension', 'System Integrity', 'Other System Events'); Mode = 'success_failure_all' },
        @{ Id = '2.4.05'; Control = 'Audit Directory Services Access'; Expected = 'Failure'; Names = @('Directory Service Access', 'Directory Service Changes'); Mode = 'directory_service' },
        @{ Id = '2.4.06'; Control = 'Audit Process Tracking'; Expected = 'No Auditing'; Names = @('Process Creation', 'Process Termination', 'DPAPI Activity', 'RPC Events'); Mode = 'no_auditing' },
        @{ Id = '2.4.07'; Control = 'Audit Policy Change'; Expected = 'Success and Failure'; Names = @('Audit Policy Change', 'Authentication Policy Change', 'Authorization Policy Change', 'Other Policy Change Events'); Mode = 'success_failure_all' },
        @{ Id = '2.4.08'; Control = 'Audit Logon Event'; Expected = 'Success and Failure'; Names = @('Logon', 'Logoff', 'Special Logon', 'Other Logon/Logoff Events'); Mode = 'success_failure_all' },
        @{ Id = '2.4.09'; Control = 'Audit Privilege Use'; Expected = 'Success and Failure'; Names = @('Sensitive Privilege Use', 'Other Privilege Use Events'); Mode = 'success_failure_all' }
    )

    foreach ($check in $auditChecks) {
        $settings = Get-AuditInclusionSettings -Names $check.Names
        $actual = if ($settings.Count -gt 0) { ($settings | Select-Object -Unique) -join '; ' } else { 'No matching subcategories found' }

        switch ($check.Mode) {
            'success_failure' {
                $status = if ($settings.Count -gt 0 -and ($settings | Where-Object { $_ -match 'Success' -and $_ -match 'Failure' }).Count -ge 1) { 'pass' } else { 'fail' }
                Add-Result -Id $check.Id -Control $check.Control -ActualValue $actual -ExpectedValue $check.Expected -Status $status -Source 'auditpol /get /subcategory:* /r' -Notes $adminNote
            }
            'success_failure_all' {
                $status = if ($settings.Count -gt 0 -and ($settings | Where-Object { $_ -notmatch 'Success' -or $_ -notmatch 'Failure' }).Count -eq 0) { 'pass' } else { 'fail' }
                Add-Result -Id $check.Id -Control $check.Control -ActualValue $actual -ExpectedValue $check.Expected -Status $status -Source 'auditpol /get /subcategory:* /r' -Notes $adminNote
            }
            'failure_only' {
                $status = if ($settings.Count -gt 0 -and ($settings | Where-Object { $_ -notmatch '^Failure$' }).Count -eq 0) { 'pass' } else { 'fail' }
                Add-Result -Id $check.Id -Control $check.Control -ActualValue $actual -ExpectedValue $check.Expected -Status $status -Source 'auditpol /get /subcategory:* /r' -Notes $adminNote
            }
            'directory_service' {
                if (-not $isDomainJoined) {
                    Add-Result -Id $check.Id -Control $check.Control -ActualValue $actual -ExpectedValue $check.Expected -Status 'manual_review' -Source 'auditpol /get /subcategory:* /r' -Notes 'Device does not appear to be domain joined. Directory Services Access requires contextual review.'
                }
                else {
                    $status = if ($settings.Count -gt 0 -and ($settings | Where-Object { $_ -notmatch '^Failure$' }).Count -eq 0) { 'pass' } else { 'fail' }
                    Add-Result -Id $check.Id -Control $check.Control -ActualValue $actual -ExpectedValue $check.Expected -Status $status -Source 'auditpol /get /subcategory:* /r' -Notes $adminNote
                }
            }
            'no_auditing' {
                $status = if ($settings.Count -gt 0 -and ($settings | Where-Object { $_ -ne 'No Auditing' }).Count -eq 0) { 'pass' } else { 'fail' }
                Add-Result -Id $check.Id -Control $check.Control -ActualValue $actual -ExpectedValue $check.Expected -Status $status -Source 'auditpol /get /subcategory:* /r' -Notes $adminNote
            }
        }
    }
}
catch {
    foreach ($pair in @(
        @{ Id = '2.4.01'; Control = 'Audit Account Logon Events'; Expected = 'Success and Failure' },
        @{ Id = '2.4.02'; Control = 'Audit Account Management'; Expected = 'Success and Failure' },
        @{ Id = '2.4.03'; Control = 'Audit Object Access'; Expected = 'Failure' },
        @{ Id = '2.4.04'; Control = 'Audit System Event'; Expected = 'Success and Failure' },
        @{ Id = '2.4.05'; Control = 'Audit Directory Services Access'; Expected = 'Failure' },
        @{ Id = '2.4.06'; Control = 'Audit Process Tracking'; Expected = 'No Auditing' },
        @{ Id = '2.4.07'; Control = 'Audit Policy Change'; Expected = 'Success and Failure' },
        @{ Id = '2.4.08'; Control = 'Audit Logon Event'; Expected = 'Success and Failure' },
        @{ Id = '2.4.09'; Control = 'Audit Privilege Use'; Expected = 'Success and Failure' }
    )) {
        Add-Result -Id $pair.Id -Control $pair.Control -ActualValue '' -ExpectedValue $pair.Expected -Status 'error' -Source 'auditpol /get /subcategory:* /r' -Notes $_.Exception.Message
    }
}

try {
    $logs = Get-WinEvent -ListLog Security, System, Application -ErrorAction Stop
    $logThresholds = @{
        Security    = 199680
        System      = 99840
        Application = 99840
    }

    $actualParts = foreach ($log in $logs) {
        $sizeKb = [math]::Round($log.MaximumSizeInBytes / 1KB)
        "{0}={1} KB" -f $log.LogName, $sizeKb
    }

    $belowThreshold = @()
    foreach ($log in $logs) {
        $sizeKb = [math]::Round($log.MaximumSizeInBytes / 1KB)
        if ($sizeKb -lt $logThresholds[$log.LogName]) {
            $belowThreshold += "{0} below threshold ({1} < {2})" -f $log.LogName, $sizeKb, $logThresholds[$log.LogName]
        }
    }

    $status = if ($belowThreshold.Count -eq 0) { 'pass' } else { 'fail' }
    Add-Result -Id '2.4.10' -Control 'Management of Audit Logs Storage' -ActualValue ($actualParts -join '; ') -ExpectedValue 'Security >= 199680 KB; System >= 99840 KB; Application >= 99840 KB' -Status $status -Source 'Get-WinEvent -ListLog' -Notes (($belowThreshold -join '; ') + ' ' + $adminNote).Trim()
}
catch {
    Add-Result -Id '2.4.10' -Control 'Management of Audit Logs Storage' -ActualValue '' -ExpectedValue 'Security >= 199680 KB; System >= 99840 KB; Application >= 99840 KB' -Status 'error' -Source 'Get-WinEvent -ListLog' -Notes $_.Exception.Message
}

$localUsers = @()
try {
    if (Get-Command Get-LocalUser -ErrorAction SilentlyContinue) {
        $localUsers = @(Get-LocalUser -ErrorAction Stop)
    }
}
catch {
    $localUsers = @()
}

if ($localUsers.Count -gt 0) {
    $genericShared = @($localUsers | Where-Object { $_.Name -match '^(user|operator|shared|generic|temp|admin1)$' } | Select-Object -ExpandProperty Name)
    if ($genericShared.Count -eq 0) {
        Add-Result -Id '2.5.01' -Control 'Generic / Shared Account' -ActualValue 'No obvious generic/shared local accounts detected' -ExpectedValue 'No obvious generic/shared accounts' -Status 'pass' -Source 'Get-LocalUser' -Notes $adminNote
    }
    else {
        Add-Result -Id '2.5.01' -Control 'Generic / Shared Account' -ActualValue ($genericShared -join ', ') -ExpectedValue 'No obvious generic/shared accounts' -Status 'fail' -Source 'Get-LocalUser' -Notes $adminNote
    }

    $testAccounts = @($localUsers | Where-Object { $_.Name -match '(?i)test|demo|temp' } | Select-Object -ExpandProperty Name)
    if ($testAccounts.Count -eq 0) {
        Add-Result -Id '2.5.02' -Control 'Test Account' -ActualValue 'No obvious test/demo/temp local accounts detected' -ExpectedValue 'No obvious test accounts' -Status 'pass' -Source 'Get-LocalUser' -Notes $adminNote
    }
    else {
        Add-Result -Id '2.5.02' -Control 'Test Account' -ActualValue ($testAccounts -join ', ') -ExpectedValue 'No obvious test accounts' -Status 'fail' -Source 'Get-LocalUser' -Notes $adminNote
    }

    $accountsWithoutPassword = @($localUsers | Where-Object { $_.PasswordRequired -eq $false } | Select-Object -ExpandProperty Name)
    if ($accountsWithoutPassword.Count -eq 0) {
        Add-Result -Id '2.5.08' -Control 'Password Required Status' -ActualValue 'All enumerated local accounts require passwords' -ExpectedValue 'Password required should be true' -Status 'pass' -Source 'Get-LocalUser' -Notes $adminNote
    }
    else {
        Add-Result -Id '2.5.08' -Control 'Password Required Status' -ActualValue ($accountsWithoutPassword -join ', ') -ExpectedValue 'Password required should be true' -Status 'fail' -Source 'Get-LocalUser' -Notes $adminNote
    }

    $guestAccount = $localUsers | Where-Object { $_.SID.Value -match '-501$' } | Select-Object -First 1
    if ($null -eq $guestAccount) {
        Add-Result -Id '2.5.05' -Control 'Default Account' -ActualValue 'Guest account not found; built-in account state unavailable' -ExpectedValue 'Guest disabled; Administrator disabled or renamed/owned' -Status 'manual_review' -Source 'Get-LocalUser' -Notes 'Unable to conclusively evaluate built-in Guest account state.'
    }
    elseif (-not $guestAccount.Enabled) {
        $adminAccount = $localUsers | Where-Object { $_.SID.Value -match '-500$' } | Select-Object -First 1
        if ($null -eq $adminAccount) {
            Add-Result -Id '2.5.05' -Control 'Default Account' -ActualValue ("Guest={0}:Disabled; Administrator=Unavailable" -f $guestAccount.Name) -ExpectedValue 'Guest disabled; Administrator disabled or renamed/owned' -Status 'manual_review' -Source 'Get-LocalUser' -Notes 'Guest is disabled. Review built-in Administrator ownership or rename state manually.'
        }
        elseif (-not $adminAccount.Enabled) {
            Add-Result -Id '2.5.05' -Control 'Default Account' -ActualValue ("Guest={0}:Disabled; Administrator={1}:Disabled" -f $guestAccount.Name, $adminAccount.Name) -ExpectedValue 'Guest disabled; Administrator disabled or renamed/owned' -Status 'pass' -Source 'Get-LocalUser' -Notes $adminNote
        }
        elseif ($adminAccount.Name -ne 'Administrator') {
            Add-Result -Id '2.5.05' -Control 'Default Account' -ActualValue ("Guest={0}:Disabled; AdministratorSID500={1}:Enabled" -f $guestAccount.Name, $adminAccount.Name) -ExpectedValue 'Guest disabled; Administrator disabled or renamed/owned' -Status 'manual_review' -Source 'Get-LocalUser' -Notes 'Built-in Administrator appears renamed but remains enabled. Review ownership and approval.'
        }
        else {
            Add-Result -Id '2.5.05' -Control 'Default Account' -ActualValue ("Guest={0}:Disabled; Administrator={1}:Enabled" -f $guestAccount.Name, $adminAccount.Name) -ExpectedValue 'Guest disabled; Administrator disabled or renamed/owned' -Status 'fail' -Source 'Get-LocalUser' -Notes 'Built-in Administrator remains enabled and unrenamed.'
        }
    }
    else {
        Add-Result -Id '2.5.05' -Control 'Default Account' -ActualValue ("Guest={0}:Enabled" -f $guestAccount.Name) -ExpectedValue 'Guest disabled; Administrator disabled or renamed/owned' -Status 'fail' -Source 'Get-LocalUser' -Notes 'Guest account is enabled.'
    }
}
else {
    Add-Result -Id '2.5.01' -Control 'Generic / Shared Account' -ActualValue '' -ExpectedValue 'No obvious generic/shared accounts' -Status 'error' -Source 'Get-LocalUser' -Notes 'Get-LocalUser was unavailable or returned no data.'
    Add-Result -Id '2.5.02' -Control 'Test Account' -ActualValue '' -ExpectedValue 'No obvious test accounts' -Status 'error' -Source 'Get-LocalUser' -Notes 'Get-LocalUser was unavailable or returned no data.'
    Add-Result -Id '2.5.05' -Control 'Default Account' -ActualValue '' -ExpectedValue 'Guest disabled; Administrator disabled or renamed/owned' -Status 'error' -Source 'Get-LocalUser' -Notes 'Get-LocalUser was unavailable or returned no data.'
    Add-Result -Id '2.5.08' -Control 'Password Required Status' -ActualValue '' -ExpectedValue 'Password required should be true' -Status 'error' -Source 'Get-LocalUser' -Notes 'Get-LocalUser was unavailable or returned no data.'
}

try {
    $adminMembers = @(Get-LocalGroupMember -Group 'Administrators' -ErrorAction Stop | Select-Object -ExpandProperty Name)
    Add-Result -Id '2.5.04' -Control 'Accounts with local admin privileges' -ActualValue ($adminMembers -join ', ') -ExpectedValue 'Only approved local administrators' -Status 'manual_review' -Source 'Get-LocalGroupMember Administrators' -Notes 'Review memberships against the approved admin roster and segregation-of-duties requirements.'
}
catch {
    Add-Result -Id '2.5.04' -Control 'Accounts with local admin privileges' -ActualValue '' -ExpectedValue 'Only approved local administrators' -Status 'error' -Source 'Get-LocalGroupMember Administrators' -Notes $_.Exception.Message
}

$policyReviewNote = 'Requires business approval, role mapping, master-list reconciliation, SoD validation, or MFA validation outside the local scanner.'
Add-ManualReviewResult -Id '2.5.03' -Control 'Assign permissions based on job roles' -ExpectedValue 'Access aligned to approved roles' -Source 'Manual governance review' -Notes $policyReviewNote
Add-ManualReviewResult -Id '2.5.06' -Control 'Newly created accounts with reference to master list by CIP' -ExpectedValue 'Matches approved master list' -Source 'Manual governance review' -Notes $policyReviewNote
Add-ManualReviewResult -Id '2.5.07' -Control 'Revoked accounts with reference to master list by CIP' -ExpectedValue 'Removed or disabled per master list' -Source 'Manual governance review' -Notes $policyReviewNote
Add-ManualReviewResult -Id '2.5.09' -Control 'Custom Created Groups and Their Justification' -ExpectedValue 'Justified and approved' -Source 'Manual governance review' -Notes $policyReviewNote
Add-ManualReviewResult -Id '2.5.10' -Control 'Service accounts' -ExpectedValue 'Denied interactive and RDP logon unless approved' -Source 'Manual governance review' -Notes $policyReviewNote
Add-ManualReviewResult -Id '2.5.11' -Control 'Multi-Factor Authentication (MFA) wherever possible' -ExpectedValue 'Enabled where supported' -Source 'Manual governance review' -Notes $policyReviewNote
Add-ManualReviewResult -Id '2.5.12' -Control 'Segregation of Duties (SoD)' -ExpectedValue 'Critical duties separated' -Source 'Manual governance review' -Notes $policyReviewNote

try {
    $screenPolicyTimeout = Get-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop' -Name 'ScreenSaveTimeOut'
    $screenUserTimeout = Get-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'ScreenSaveTimeOut'
    $screenPolicySecure = Get-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop' -Name 'ScreenSaverIsSecure'
    $screenUserSecure = Get-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'ScreenSaverIsSecure'

    $effectiveTimeout = if ($screenPolicyTimeout) { [int]$screenPolicyTimeout } elseif ($screenUserTimeout) { [int]$screenUserTimeout } else { $null }
    $effectiveSecure = if ($screenPolicySecure) { [string]$screenPolicySecure } elseif ($screenUserSecure) { [string]$screenUserSecure } else { $null }
    $timeoutDisplay = if ($null -ne $effectiveTimeout) { [string]$effectiveTimeout } else { 'Unavailable' }
    $secureDisplay = if ($null -ne $effectiveSecure) { [string]$effectiveSecure } else { 'Unavailable' }
    $actual = "ScreenSaveTimeOut={0}; ScreenSaverIsSecure={1}" -f $timeoutDisplay, $secureDisplay

    if ($null -eq $effectiveTimeout) {
        Add-Result -Id '2.5.13' -Control 'Session Timeout and Lock Controls' -ActualValue $actual -ExpectedValue '15 minutes or less with lock protection' -Status 'manual_review' -Source 'HKCU Desktop / policy registry' -Notes 'Timeout value was not detected.'
    }
    elseif ($effectiveTimeout -le 900 -and $effectiveSecure -eq '1') {
        Add-Result -Id '2.5.13' -Control 'Session Timeout and Lock Controls' -ActualValue $actual -ExpectedValue '15 minutes or less with lock protection' -Status 'pass' -Source 'HKCU Desktop / policy registry' -Notes $adminNote
    }
    else {
        Add-Result -Id '2.5.13' -Control 'Session Timeout and Lock Controls' -ActualValue $actual -ExpectedValue '15 minutes or less with lock protection' -Status 'fail' -Source 'HKCU Desktop / policy registry' -Notes 'Timeout exceeds 15 minutes or secure lock on resume is not enabled.'
    }
}
catch {
    Add-Result -Id '2.5.13' -Control 'Session Timeout and Lock Controls' -ActualValue '' -ExpectedValue '15 minutes or less with lock protection' -Status 'error' -Source 'HKCU Desktop / policy registry' -Notes $_.Exception.Message
}

$serviceMappings = @'
C-038|ActiveX Installer (AxInstSV)|AxInstSV|Startup / configuration settings for ALL: Disabled.
C-039|AllJoyn Router Service|AJRouter|Disabled.
C-040|Application Layer Gateway Service|ALG|Disabled.
C-041|Auto Time Zone Updater|tzautoupdate|Disabled.
C-042|BitLocker Drive Encryption Service|BDESVC|Disabled.
C-043|Bluetooth Handsfree Service|BthHFSrv|Disabled.
C-044|Bluetooth Support Service|bthserv|Disabled.
C-045|Connected Devices Platform Service|CDPSvc|Disabled.
C-046|Connected User Experiences and Telemetry|DiagTrack|Disabled.
C-047|Data Sharing Service|DSSvc|Disabled.
C-048|Data Collecting Publishing Service|DcpSvc|Disabled.
C-049|Delivery Optimization|DoSvc|Disabled.
C-050|Device Setup Manager|DsmSvc|Disabled.
C-051|dmwappushsvc|dmwappushservice|Disabled.
C-052|Downloaded Maps Manager|MapsBroker|Disabled.
C-053|Embedded Mode|embeddedmode|Disabled.
C-054|Enterprise App Management Service|EntAppSvc|Disabled.
C-055|Fax|Fax|Disabled.
C-056|File History Service|fhsvc|Disabled.
C-057|GeoLocation Service|lfsvc|Disabled.
C-058|HomeGroup Listener|HomeGroupListener|Disabled.
C-059|HomeGroup Provider|HomeGroupProvider|Disabled.
C-060|HV Host Service (HVHost)|HvHost|Disabled.
C-061|Hyper-V Data Exchange Service|vmickvpexchange|Disabled.
C-062|Hyper-V Guest Service Interface|vmicguestinterface|Disabled.
C-063|Hyper-V Guest Shutdown Service|vmicshutdown|Disabled.
C-064|Hyper-V Heartbeat Service|vmicheartbeat|Disabled.
C-065|Hyper-V PowerShell Direct Service|vmicvmsession|Disabled.
C-066|Hyper-V Remote Desktop Virtualization Service|vmicrdv|Disabled.
C-067|Hyper-V Time Synchronization Service|vmictimesync|Disabled.
C-068|Hyper-V Volume Shadow Copy Requestor|vmicvss|Disabled.
C-069|Infrared Monitor Service|irmon|Disabled.
C-070|Internet Connection Sharing (ICS)|SharedAccess|Disabled.
C-071|KDC Proxy Server Service|KPSSVC|Disabled.
C-072|Microsoft Account Sign-in Assistant|wlidsvc|Disabled.
C-073|Microsoft App-V Client|AppVClient|Disabled.
C-074|Microsoft Diagnostics Hub Standard Collector Service|diagnosticshub.standardcollector.service|Disabled.
C-075|Microsoft iSCSI Initiator Service|MSiSCSI|Disabled.
C-076|Microsoft Storage Spaces SMP|smphost|Disabled.
C-077|Microsoft Windows SMS Router Service|SmsRouter|Disabled.
C-078|Network Connected Devices Auto-Setup|NcdAutoSetup|Disabled.
C-079|Network Connection Broker|NcbService|Disabled.
C-080|Offline Files|CscService|Disabled.
C-081|Phone Service|PhoneSvc|Disabled.
C-082|PNRP Machine Name Publication Service|PNRPAutoReg|Disabled.
C-083|Quality Windows Audio Video Experience|QWAVE|Disabled.
C-084|Radio Management Service|RmSvc|Disabled.
C-085|Remote Access Connection Manager|RasMan|Disabled.
C-086|Remote Registry Service (RemoteRegistry)|RemoteRegistry|Disabled.
C-087|Resultant Set of Policy Provider|RSoPProv|Disabled.
C-088|Retail Demo Service|RetailDemo|Disabled.
C-089|Sensor Data Service|SensorDataService|Disabled.
C-090|Sensor Monitoring Service|SensrSvc|Disabled.
C-091|Sensor Service|SensorService|Disabled.
C-092|Shared PC Account Manager|shpamsvc|Disabled.
C-093|SNMP Service (SNMP)|SNMP|Disabled.
C-094|SQL Server CEIP Service|SQLTELEMETRY|Disabled.
C-095|Still Image Acquisition Events|WiaRpc|Disabled.
C-096|Storage Service|StorSvc|Disabled.
C-097|Storage Tier Management|TieringEngineService|Disabled.
C-098|Superfetch / SysMain|SysMain|Disabled.
C-099|System Event Notification Service|SENS|Disabled.
C-100|TCP/IP NetBIOS Helper|lmhosts|Disabled.
C-101|Telephony|TapiSrv|Disabled.
C-102|Themes|Themes|Disabled.
C-103|Touch Keyboard and Handwriting Panel|TabletInputService|Disabled.
C-104|Update Orchestrator Service|UsoSvc|Disabled.
C-105|UPnP Device Host|upnphost|Disabled.
C-106|User Experience Virtualization Service|UevAgentService|Disabled.
C-107|Wallet Service|WalletService|Disabled.
C-108|WarpJITSvc|WarpJITSvc|Disabled.
C-109|Windows Biometric Service|WbioSrvc|Disabled.
C-110|Windows Camera Frame Server|FrameServer|Disabled.
C-111|Windows Connection Manager (WcmSvc)|WcmSvc|Disabled.
C-112|Windows Defender Antivirus Antimalware Service|WinDefend|Disabled (* If 3rd Party Used).
C-113|Windows Defender Antivirus Network Inspection|WdNisSvc|Disabled (* If 3rd Party Used).
C-114|Windows Encryption Provider Host Service|WEPHOSTSVC|Disabled.
C-115|Windows Error Reporting Service|WerSvc|Disabled.
C-116|Windows Inside Drive Management Service|wisvc|Disabled.
C-117|Windows Location Framework Service|wlpasvc|Disabled.
C-118|Windows Mobile Broadband SMS Router|SmsRouter|Disabled.
C-119|Windows Media Player Network Sharing Service|WMPNetworkSvc|Disabled.
C-120|Windows Mobile Hotspot Service|icssvc|Disabled.
C-121|Windows Perception Simulation Service|PerceptionSimulation|Disabled.
C-122|Windows Push Notifications System Service|WpnService|Disabled.
C-123|Windows PushToTalk Service|PushToInstall|Disabled.
C-124|Windows Remote Management (WinRM)|WinRM|Disabled (* unless explicitly required).
C-125|Windows Search|WSearch|Disabled.
C-126|Xbox Accessory Management Service|XboxGipSvc|Disabled.
C-127|Xbox Auth Manager|XblAuthManager|Disabled.
C-128|Xbox Live Game Save|XblGameSave|Disabled.
C-129|Xbox Live Networking Service|XboxNetApiSvc|Disabled.
C-133|Disable WNet/Wired AutoConfig|dot3svc|Disabled.
C-148|Disable Windows Remote Registry Service via GPO|RemoteRegistry|Disabled.
C-181|Disable Print Spooler Service (* if print functions not required)|Spooler|Disabled (* on non-printing nodes).
'@ -split "`r?`n" | Where-Object { $_ -and $_.Trim() } | ForEach-Object {
    $parts = $_ -split '\|', 4
    [pscustomobject]@{
        Id          = $parts[0]
        Control     = $parts[1]
        ServiceName = $parts[2]
        Requirement = $parts[3]
    }
}

foreach ($mapping in $serviceMappings) {
    Test-ServiceControl -Mapping $mapping
}

Test-RegistryExpectation -Id '2.6.94' -Control 'Disable SMBv1 Protocol completely' -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name 'SMB1' -ExpectedValue '0 or value absent because SMBv1 is disabled' -Source 'Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'pass'; Notes = 'SMB1 value not present; treated as disabled.' } }
    if ([int]$value -eq 0) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'SMB1 value indicates protocol is enabled.' }
}

Test-RegistryExpectation -Id '2.6.115' -Control 'Disable Insecure Guest Logons' -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters' -Name 'AllowInsecureGuestAuth' -ExpectedValue '0' -Source 'Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'pass'; Notes = 'Value not present; treated as disabled by default.' } }
    if ([int]$value -eq 0) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'Insecure guest logons appear enabled.' }
}

Test-RegistryExpectation -Id '2.6.116' -Control 'Configure LAN Manager Authentication Level' -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LmCompatibilityLevel' -ExpectedValue '5 (Send NTLMv2 response only. Refuse LM & NTLM)' -Source 'Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'fail'; Notes = 'Value not present.' } }
    if ([int]$value -eq 5) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'LM compatibility level is weaker than required.' }
}

Test-RegistryExpectation -Id '2.6.118' -Control 'Enable SMB Server Packet Signing Always' -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name 'RequireSecuritySignature' -ExpectedValue '1' -Source 'Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'fail'; Notes = 'Value not present.' } }
    if ([int]$value -eq 1) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'Server packet signing is not always required.' }
}

Test-RegistryExpectation -Id '2.6.119' -Control 'Enable SMB Client Packet Signing Always' -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters' -Name 'RequireSecuritySignature' -ExpectedValue '1' -Source 'Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'fail'; Notes = 'Value not present.' } }
    if ([int]$value -eq 1) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'Client packet signing is not always required.' }
}

try {
    $consentAdmin = Get-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'ConsentPromptBehaviorAdmin'
    $secureDesktop = Get-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'PromptOnSecureDesktop'
    $consentAdminDisplay = if ($null -ne $consentAdmin) { [string]$consentAdmin } else { 'Missing' }
    $secureDesktopDisplay = if ($null -ne $secureDesktop) { [string]$secureDesktop } else { 'Missing' }
    $actual = "ConsentPromptBehaviorAdmin={0}; PromptOnSecureDesktop={1}" -f $consentAdminDisplay, $secureDesktopDisplay
    $status = if ($consentAdmin -eq 1 -and $secureDesktop -eq 1) { 'pass' } else { 'fail' }
    Add-Result -Id '2.6.121' -Control 'UAC Admin Prompt Behavior' -ActualValue $actual -ExpectedValue 'Prompt for credentials on secure desktop' -Status $status -Source 'Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Notes ''
}
catch {
    Add-Result -Id '2.6.121' -Control 'UAC Admin Prompt Behavior' -ActualValue '' -ExpectedValue 'Prompt for credentials on secure desktop' -Status 'error' -Source 'Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Notes $_.Exception.Message
}

Test-RegistryExpectation -Id '2.6.122' -Control 'UAC for Standard Users' -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'ConsentPromptBehaviorUser' -ExpectedValue '1 (Prompt for credentials)' -Source 'Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'fail'; Notes = 'Value not present.' } }
    if ([int]$value -eq 1) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'Standard users are not prompted for credentials as required.' }
}

Test-RegistryExpectation -Id '2.6.123' -Control 'Disable Virtualization of File/Registry Write Failures' -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableVirtualization' -ExpectedValue '0' -Source 'Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'fail'; Notes = 'Value not present.' } }
    if ([int]$value -eq 0) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'UAC virtualization remains enabled.' }
}

Test-RegistryExpectation -Id '2.6.124' -Control 'Secure CTRL+ALT+DEL' -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DisableCAD' -ExpectedValue '0' -Source 'Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'fail'; Notes = 'Value not present.' } }
    if ([int]$value -eq 0) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'CTRL+ALT+DEL is not enforced for interactive logon.' }
}

Test-RegistryExpectation -Id '2.6.125' -Control 'Do not display last user name' -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'DontDisplayLastUserName' -ExpectedValue '1' -Source 'Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'fail'; Notes = 'Value not present.' } }
    if ([int]$value -eq 1) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'Last signed-in user is still displayed.' }
}

Test-RegistryExpectation -Id '2.6.126' -Control 'Do not display user info when locked' -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'DontDisplayLockedUserId' -ExpectedValue '3' -Source 'Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'fail'; Notes = 'Value not present.' } }
    if ([int]$value -eq 3) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'Locked session still displays user information.' }
}

Test-RegistryExpectation -Id '2.6.127' -Control 'Local Account Token Filter Policy' -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'LocalAccountTokenFilterPolicy' -ExpectedValue '0 or value absent' -Source 'Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'pass'; Notes = 'Value not present; treated as restricted/default.' } }
    if ([int]$value -eq 0) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'Remote local admin token filtering appears relaxed.' }
}

try {
    $denyTs = Get-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections'
    $actual = if ($null -eq $denyTs) { 'Missing' } else { [string]$denyTs }
    if ($denyTs -eq 1) {
        Add-Result -Id '2.6.128' -Control 'Disable Remote Desktop unless justified' -ActualValue $actual -ExpectedValue '1 (disabled) unless justified' -Status 'pass' -Source 'Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Notes ''
    }
    elseif ($denyTs -eq 0) {
        Add-Result -Id '2.6.128' -Control 'Disable Remote Desktop unless justified' -ActualValue $actual -ExpectedValue '1 (disabled) unless justified' -Status 'manual_review' -Source 'Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Notes 'Remote Desktop is enabled. Confirm approved jump-host or business justification.'
    }
    else {
        Add-Result -Id '2.6.128' -Control 'Disable Remote Desktop unless justified' -ActualValue $actual -ExpectedValue '1 (disabled) unless justified' -Status 'fail' -Source 'Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Notes 'Unexpected RDP configuration value.'
    }
}
catch {
    Add-Result -Id '2.6.128' -Control 'Disable Remote Desktop unless justified' -ActualValue '' -ExpectedValue '1 (disabled) unless justified' -Status 'error' -Source 'Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Notes $_.Exception.Message
}

Test-RegistryExpectation -Id '2.6.129' -Control 'Enforce NLA for RDP' -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -ExpectedValue '1' -Source 'Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'fail'; Notes = 'Value not present.' } }
    if ([int]$value -eq 1) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'RDP NLA is not enforced.' }
}

try {
    $rdpEncryption = Get-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'MinEncryptionLevel'
    $actual = if ($null -eq $rdpEncryption) { 'Missing' } else { [string]$rdpEncryption }
    $status = if ($rdpEncryption -in 3, 4) { 'pass' } else { 'fail' }
    Add-Result -Id '2.6.130' -Control 'Configure RDP encryption level' -ActualValue $actual -ExpectedValue '3 or 4 (High / FIPS)' -Status $status -Source 'Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Notes ''
}
catch {
    Add-Result -Id '2.6.130' -Control 'Configure RDP encryption level' -ActualValue '' -ExpectedValue '3 or 4 (High / FIPS)' -Status 'error' -Source 'Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Notes $_.Exception.Message
}

Test-RegistryExpectation -Id '2.6.153' -Control 'Do not store LM hashes' -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'NoLMHash' -ExpectedValue '1' -Source 'Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'fail'; Notes = 'Value not present.' } }
    if ([int]$value -eq 1) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'LM hash storage is not disabled.' }
}

Test-OptionalFeatureState -Id '2.6.133' -Control 'Disable PowerShell 2.0' -FeatureName 'MicrosoftWindowsPowerShellV2' -ExpectedValue 'Disabled' -Source 'Get-WindowsOptionalFeature -Online'

try {
    $policyList = @(Get-ExecutionPolicy -List)
    $policyMap = @{}
    foreach ($entry in $policyList) {
        $policyMap[[string]$entry.Scope] = [string]$entry.ExecutionPolicy
    }

    $effectivePolicy = $null
    foreach ($scope in 'MachinePolicy', 'UserPolicy', 'Process', 'CurrentUser', 'LocalMachine') {
        if ($policyMap.ContainsKey($scope) -and $policyMap[$scope] -and $policyMap[$scope] -ne 'Undefined') {
            $effectivePolicy = $policyMap[$scope]
            break
        }
    }

    $actual = ($policyList | ForEach-Object { "{0}={1}" -f $_.Scope, $_.ExecutionPolicy }) -join '; '
    $status = if ($effectivePolicy -in @('AllSigned', 'RemoteSigned')) { 'pass' } else { 'fail' }
    Add-Result -Id '2.6.134' -Control 'PowerShell Script Execution Policy' -ActualValue $actual -ExpectedValue 'AllSigned or RemoteSigned' -Status $status -Source 'Get-ExecutionPolicy -List' -Notes ''
}
catch {
    Add-Result -Id '2.6.134' -Control 'PowerShell Script Execution Policy' -ActualValue '' -ExpectedValue 'AllSigned or RemoteSigned' -Status 'error' -Source 'Get-ExecutionPolicy -List' -Notes $_.Exception.Message
}

Test-RegistryExpectation -Id '2.6.135' -Control 'PowerShell Transcription Logging' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' -Name 'EnableTranscripting' -ExpectedValue '1' -Source 'Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'fail'; Notes = 'Value not present.' } }
    if ([int]$value -eq 1) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'PowerShell transcription logging is not enabled.' }
}

Test-RegistryExpectation -Id '2.6.136' -Control 'PowerShell Script Block Logging' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -Name 'EnableScriptBlockLogging' -ExpectedValue '1' -Source 'Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -Evaluator {
    param($value)
    if ($null -eq $value) { return @{ Status = 'fail'; Notes = 'Value not present.' } }
    if ([int]$value -eq 1) { return @{ Status = 'pass'; Notes = '' } }
    return @{ Status = 'fail'; Notes = 'PowerShell script block logging is not enabled.' }
}

Test-OptionalFeatureState -Id '2.6.137' -Control 'Disable WSL' -FeatureName 'Microsoft-Windows-Subsystem-Linux' -ExpectedValue 'Disabled' -Source 'Get-WindowsOptionalFeature -Online'
Test-OptionalFeatureState -Id '2.6.138' -Control 'Disable Windows Sandbox' -FeatureName 'Containers-DisposableClientVM' -ExpectedValue 'Disabled' -Source 'Get-WindowsOptionalFeature -Online'

$desktopPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'compliance-results.json'

$output = [pscustomobject][ordered]@{
    scannerVersion = '1.0'
    computerName   = $env:COMPUTERNAME
    userName       = if ($env:USERDOMAIN) { "$($env:USERDOMAIN)\$($env:USERNAME)" } else { $env:USERNAME }
    scanDate       = (Get-Date).ToString('o')
    results        = $results
}

$output | ConvertTo-Json -Depth 6 | Set-Content -Path $desktopPath -Encoding UTF8

Write-Host "Compliance scan complete. Results written to: $desktopPath"