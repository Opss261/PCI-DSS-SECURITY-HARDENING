# =============================================================
# Disable-InactiveAccounts.ps1
# Author: Bravo
# PCI DSS Requirement 8 - User Access Management
# Purpose: Finds and disables AD accounts inactive for 90+ days
# =============================================================

Import-Module ActiveDirectory  # Loads the Active Directory module so we can use AD commands

$InactiveDays = 90  # Sets the threshold to 90 days as required by PCI DSS Requirement 8
$CutoffDate = (Get-Date).AddDays(-$InactiveDays)  # Calculates the date 90 days ago from today

# Display report header
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " PCI DSS - Inactive Account Report" -ForegroundColor Cyan
Write-Host " Accounts inactive for $InactiveDays+ days" -ForegroundColor Cyan  # Shows the threshold used
Write-Host " Run Date: $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -ForegroundColor Cyan  # Timestamps the report
Write-Host "==========================================" -ForegroundColor Cyan

# Search Active Directory for enabled accounts that haven't logged in since the cutoff date
$InactiveAccounts = Get-ADUser -Filter {
    LastLogonDate -lt $CutoffDate -and Enabled -eq $true  # Only finds accounts still enabled but inactive
} -Properties LastLogonDate, DisplayName, SamAccountName  # Retrieves these specific properties for each account

if ($InactiveAccounts.Count -eq 0) {
    Write-Host "`nNo inactive accounts found." -ForegroundColor Green  # All accounts are active - compliant
} else {
    Write-Host "`nInactive accounts found: $($InactiveAccounts.Count)" -ForegroundColor Yellow  # Shows how many were found
    
    foreach ($Account in $InactiveAccounts) {  # Loops through each inactive account one by one
        Write-Host "`nDisabling: $($Account.DisplayName) ($($Account.SamAccountName))" -ForegroundColor Red  # Shows full name and username of account being disabled  # Shows which account is being disabled
        Write-Host "  Last Logon: $($Account.LastLogonDate)" -ForegroundColor White  # Shows when they last logged in
        
        Disable-ADAccount -Identity $Account.SamAccountName  # Disables the account in Active Directory
        Write-Host "  Status: DISABLED" -ForegroundColor Red  # Confirms the account has been disabled
    }
}

# Display report footer
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host " Report Complete" -ForegroundColor Cyan

Write-Host "==========================================" -ForegroundColor Cyan

