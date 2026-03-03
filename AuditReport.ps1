# =============================================================
# Password-ComplianceReport.ps1
# Author: Opeyemi
# PCI DSS Requirement 8 - Password Management
# Purpose: Scans AD accounts for password compliance issues
# =============================================================

Import-Module ActiveDirectory  # Loads the Active Directory module so we can use AD commands

# Display report header
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " PCI DSS - Password Compliance Report" -ForegroundColor Cyan
Write-Host " Run Date: $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -ForegroundColor Cyan  # Timestamps the report
Write-Host "==========================================" -ForegroundColor Cyan

# Get all enabled user accounts from Active Directory with the properties we need to check
# Properties retrieved: PasswordNeverExpires, PasswordNotRequired, PasswordLastSet, SamAccountName, DisplayName
$AllUsers = Get-ADUser -Filter {Enabled -eq $true} -Properties `
    PasswordNeverExpires, `
    PasswordNotRequired, `
    PasswordLastSet, `
    SamAccountName, `
    DisplayName

$NonCompliant = @()  # Creates an empty list to store non-compliant accounts

foreach ($User in $AllUsers) {  # Loops through every enabled account one by one
    $Issues = @()  # Creates an empty list to store issues found for this specific account

    # Check 1 - Password never expires
    # PCI DSS Requirement 8 requires passwords to be changed regularly
    if ($User.PasswordNeverExpires -eq $true) {
        $Issues += "Password Never Expires"  # Adds this issue to the list if found
    }

    # Check 2 - Password not required
    # Every account must have a password per PCI DSS Requirement 8
    if ($User.PasswordNotRequired -eq $true) {
        $Issues += "Password Not Required"  # Adds this issue to the list if found
    }

    # Check 3 - Password not changed in 90 days
    # PCI DSS requires regular password changes
    if ($User.PasswordLastSet -lt (Get-Date).AddDays(-90)) {
        $Issues += "Password Not Changed in 90+ Days"  # Adds this issue to the list if found
    }

    # If any issues were found for this account add it to the non-compliant list
    if ($Issues.Count -gt 0) {
        $NonCompliant += [PSCustomObject]@{
            Username     = $User.DisplayName  # The account username
            Issues       = ($Issues -join " | ")  # Joins multiple issues into one readable string
            LastChanged  = $User.PasswordLastSet  # When the password was last changed
        }
    }
}

# Display results
if ($NonCompliant.Count -eq 0) {
    Write-Host "`nAll accounts are PCI DSS compliant." -ForegroundColor Green  # No issues found
} else {
    Write-Host "`nNon-compliant accounts found: $($NonCompliant.Count)" -ForegroundColor Yellow  # Shows total count
    Write-Host ""
    $NonCompliant | Format-Table -AutoSize  # Displays results in a clean table format
}

# Display report footer
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Report Complete" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
