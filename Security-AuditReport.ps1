# =============================================================
# Security-AuditReport.ps1
# Author: Bravo
# PCI DSS Requirement 6 and 11 - Security Audit
# Purpose: Checks patch status, lockout policy and weak protocols
# =============================================================

Import-Module ActiveDirectory  # Loads the Active Directory module so we can use AD commands

# Display report header
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " PCI DSS - Security Audit Report" -ForegroundColor Cyan
Write-Host " Run Date: $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -ForegroundColor Cyan  # Timestamps the report
Write-Host "==========================================" -ForegroundColor Cyan

# =============================================================
# CHECK 1 - Account Lockout Policy
# PCI DSS Requirement 8 requires lockout after maximum 6 failed attempts
# =============================================================
Write-Host "`n--- Account Lockout Policy ---" -ForegroundColor Yellow

$LockoutPolicy = Get-ADDefaultDomainPasswordPolicy  # Retrieves the current domain password policy
$LockoutThreshold = $LockoutPolicy.LockoutThreshold  # Extracts the lockout threshold value

if ($LockoutThreshold -eq 0) {
    Write-Host "FAIL - Account lockout is DISABLED" -ForegroundColor Red  # Lockout is completely off - critical finding
    Write-Host "PCI DSS Requirement: Maximum 6 attempts before lockout" -ForegroundColor White
} elseif ($LockoutThreshold -le 6) {
    Write-Host "PASS - Lockout threshold: $LockoutThreshold attempts" -ForegroundColor Green  # Meets PCI DSS requirement
} else {
    Write-Host "FAIL - Lockout threshold too high: $LockoutThreshold attempts" -ForegroundColor Red  # Too many attempts allowed
    Write-Host "PCI DSS Requirement: Maximum 6 attempts" -ForegroundColor White
}

# =============================================================
# CHECK 2 - Minimum Password Length
# PCI DSS Requirement 8 requires minimum 12 characters
# =============================================================
Write-Host "`n--- Password Length Policy ---" -ForegroundColor Yellow

$MinPasswordLength = $LockoutPolicy.MinPasswordLength  # Extracts the minimum password length from the policy

if ($MinPasswordLength -ge 12) {
    Write-Host "PASS - Minimum password length: $MinPasswordLength characters" -ForegroundColor Green  # Meets PCI DSS requirement
} else {
    Write-Host "FAIL - Minimum password length too short: $MinPasswordLength characters" -ForegroundColor Red  # Below requirement
    Write-Host "PCI DSS Requirement: Minimum 12 characters" -ForegroundColor White
}

# =============================================================
# CHECK 3 - Weak Protocol Check
# PCI DSS bans SSL 2.0, SSL 3.0 and TLS 1.0 as they are insecure
# =============================================================
Write-Host "`n--- Weak Protocol Check ---" -ForegroundColor Yellow

$SSLPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"  # Registry path where protocol settings are stored

$WeakProtocols = @("SSL 2.0", "SSL 3.0", "TLS 1.0")  # List of protocols banned by PCI DSS

foreach ($Protocol in $WeakProtocols) {  # Checks each weak protocol one by one
    $ProtocolPath = "$SSLPath\$Protocol\Server"  # Builds the full registry path for this protocol
    
    if (Test-Path $ProtocolPath) {  # Checks if this protocol has a registry entry
        $Enabled = (Get-ItemProperty -Path $ProtocolPath -Name "Enabled" -ErrorAction SilentlyContinue).Enabled  # Gets the enabled value
        
        if ($Enabled -eq 0) {
            Write-Host "PASS - $Protocol is DISABLED" -ForegroundColor Green  # Protocol is correctly disabled
        } else {
            Write-Host "FAIL - $Protocol is ENABLED - Disable immediately" -ForegroundColor Red  # Critical security risk
        }
    } else {
        Write-Host "PASS - $Protocol not configured (disabled by default)" -ForegroundColor Green  # Not present means disabled
    }
}

# =============================================================
# CHECK 4 - Patch Status
# PCI DSS Requirement 6 requires critical patches within 30 days
# =============================================================
Write-Host "`n--- Patch Status Check ---" -ForegroundColor Yellow

$LastUpdate = (Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1)  # Gets the most recently installed patch

if ($LastUpdate) {
    $DaysSinceUpdate = (Get-Date) - $LastUpdate.InstalledOn  # Calculates how many days since last patch
    Write-Host "Last patch installed: $($LastUpdate.InstalledOn.ToString('dd/MM/yyyy'))" -ForegroundColor White  # Shows patch date
    Write-Host "Days since last patch: $($DaysSinceUpdate.Days)" -ForegroundColor White  # Shows days since patched
    
    if ($DaysSinceUpdate.Days -le 30) {
        Write-Host "PASS - System patched within last 30 days" -ForegroundColor Green  # Meets PCI DSS requirement
    } else {
        Write-Host "FAIL - System not patched in $($DaysSinceUpdate.Days) days" -ForegroundColor Red  # Critical finding
        Write-Host "PCI DSS Requirement: Critical patches within 30 days" -ForegroundColor White
    }
} else {
    Write-Host "WARNING - Could not retrieve patch information" -ForegroundColor Yellow  # Unable to check patch status
}

# Display report footer
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host " Audit Complete" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan