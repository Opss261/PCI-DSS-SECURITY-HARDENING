# PCI DSS Security Hardening and Compliance Automation

## What Is This Project?

I built this project to demonstrate how PowerShell can be used to automate PCI DSS compliance checks in a Windows Server environment. Instead of manually checking every account and server setting one by one, which takes hours and is prone to human error, these scripts do it automatically in seconds and produce clean reports that are ready for audit review.

This is the kind of work I do daily as an Infrastructure Engineer and the kind of automation I want to Contribute to your Security Remediation team.

---

## Technologies Used

### Infrastructure
- Windows Server 2022  
- Active Directory Domain Services (AD DS)  
- DNS  
- VMware Workstation  

### Automation & Scripting
- PowerShell  

### Development & Version Control
- Visual Studio Code  
- Git  
- GitHub  

---

## Architecture Overview

This project was built in a virtualised lab environment:

VMware Workstation  
- Windows Server 2022 (Domain Controller)  
- Active Directory (DC.local)  
- PowerShell Security Automation Scripts  
- CSV Compliance & Audit Reports  

The scripts interact directly with Active Directory to enforce PCI DSS–aligned security controls and generate audit-ready evidence.

---

## The Environment

I built this lab from scratch on VMware Workstation running Windows Server 2022. I configured Active Directory, DNS and promoted the server to a Domain Controller. I then created test user accounts with deliberate PCI DSS violations to validate that the scripts were identifying the right issues.

---

## The Scripts

### Script 1 — Disable-InactiveAccounts.ps1
**PCI DSS Requirement 8 — User Access Management**

This script scans Active Directory for any enabled user accounts that haven't logged in for 90 days or more and automatically disables them. Inactive accounts are a serious security risk, an attacker could use a forgotten account to access the network undetected. PCI DSS Requirement 8 is clear — access must be removed when it's no longer needed.

**Result from my lab:** No inactive accounts found, all accounts were recently created and active.

---

### Script 2 — Password-ComplianceReport.ps1
**PCI DSS Requirement 8 — Password Management**

This script scans every enabled account in Active Directory and checks three things, whether the password is set to never expire, whether a password is even required, and whether the password has been changed in the last 90 days. It produces a clean table showing every non-compliant account and exactly what the issue is.

**Result from my lab:**

| Username | Issue | 
|---|---|
| Administrator | Password Never Expires |
| nbottger | Password Never Expires |
| sbanwait | Password Not Required |

Shereen Sembi's account was correctly identified as compliant and excluded from the report.

---

### Script 3 — Security-AuditReport.ps1
**PCI DSS Requirements 6 and 11 — Security Audit**

This script runs a full security audit across the server checking four things — account lockout policy, minimum password length, whether weak protocols like SSL 2.0, SSL 3.0 and TLS 1.0 are enabled, and how many days since the last patch was installed.

**Before remediation — FAIL results:**

| Check | Result |
|---|---|
| Account Lockout | FAIL — Lockout completely disabled |
| Password Length | FAIL — Only 7 characters configured |
| SSL 2.0 | PASS |
| SSL 3.0 | PASS |
| TLS 1.0 | PASS |
| Patch Status | FAIL — Not patched in 1460 days |

**After remediation — PASS results:**

| Check | Result |
|---|---|
| Account Lockout | PASS — Locked after 5 attempts |
| Password Length | PASS — Minimum 12 characters |
| SSL 2.0 | PASS |
| SSL 3.0 | PASS |
| TLS 1.0 | PASS |
| Patch Status | PASS — Patched 0 days ago |

---

## How I Fixed The Findings

**Account Lockout and Password Length** — I used PowerShell to update the Default Domain Password Policy directly, setting the lockout threshold to 5 attempts and the minimum password length to 12 characters, both meeting PCI DSS Requirement 8.

**Patch Status** — I ran Windows Update through the server configuration menu and installed all available updates including the February 2026 cumulative update, bringing the patch status from 1460 days to 0 days.

---

## Why This Matters

In a retail environment like NEXT that processes millions of card transactions, PCI DSS compliance is not optional. A single misconfiguration, an account with no lockout policy, a server running SSL 3.0, a system unpatched for months, can be the entry point for a serious breach. These scripts turn what would be hours of manual checking into an automated process that runs in seconds and produces evidence ready for auditors.

---

## What's Next

In a production environment these scripts would be scheduled as Azure Automation Runbooks to run nightly, continuously checking compliance without manual intervention. Any findings would automatically raise tickets in ServiceNow for the security team to review and remediate.

---

*Built by Opeyemi — Infrastructure Engineer*
*Lab Environment: VMware Workstation | Windows Server 2022 | Active Directory | DC.Local*
