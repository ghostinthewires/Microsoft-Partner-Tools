<#
    .SYNOPSIS
    This script will gather the MPN ID that you enter and then assign this to the user in the Azure AD tenant you are logged in as.
       
    .DESCRIPTION
    keywords: Azure, Partner, PAL
    Prerequisites: This script requires the following modules to be installed: 'Az' & 'Az.ManagementPartner'. The script will fail if neither of these modules are installed.
    Makes changes: Yes
    Assigns the MPN ID to the user logged into an Azure AD Tenant 
    .EXAMPLE
    Full command: .\LinkPALtoAzure.ps1
 
    .NOTES
    Version Table:
    Version :: Author             :: Live Date   :: JIRA     :: QC          :: Description
    -----------------------------------------------------------------------------------------------------------
    1.0     :: Andrew Urwin       :: 14-Oct-2019 ::          ::             :: Release
#>

# Creating Log File & Starting Transcript

$DateTime = Get-Date -Format dd-MM-yyyy-HHmm
$LogFileName = 'LinkPALtoAzure-Log-' +$DateTime+ '.txt'

$LogFile = New-Item -Name "$LogFileName" -ItemType File -ErrorAction Stop
Start-Transcript -Path $LogFile -ErrorAction Stop

Write-Host "Logging started and will be stored in this file:" $LogFile.FullName -ForegroundColor Yellow
Write-Host ""

# Check Required Modules Are Installed, if not, install them

Write-Host "Checking for required PowerShell modules..." -ForegroundColor Cyan
Write-Host ""

if (Get-InstalledModule -Name 'Az' -ErrorAction SilentlyContinue) {
    Write-Host "Az PowerShell Module Installed" -ForegroundColor Green
    Write-Host ""
}
else {
    Install-Module -Name Az -AllowClobber -Force -Verbose -Scope CurrentUser
    Write-Host ""
    Write-Host "Az PowerShell Module Installed" -ForegroundColor Green
    Write-Host ""
}

if (Get-InstalledModule -Name 'Az.ManagementPartner' -ErrorAction SilentlyContinue) {
    Write-Host "Az.ManagementPartner PowerShell Module Installed" -ForegroundColor Green
    Write-Host ""
}
else {
    Install-Module -Name Az.ManagementPartner -AllowClobber -Force -Verbose -Scope CurrentUser
    Write-Host ""
    Write-Host "Az.ManagementPartner PowerShell Module Installed" -ForegroundColor Green
    Write-Host ""
}

# Connect To Azure Account

Write-Host "Logging In To The Azure Management Plane (ARM)..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Please login with the account you wish to link your Partner ID." -ForegroundColor Cyan
Write-Host "This account must have permissions on the customers Azure platform." -ForegroundColor Yellow
Write-Host ""

Connect-AzAccount

# Collect Tenant ID

$subscription = Get-AzSubscription | Select-Object Name, TenantId | Group-Object TenantId  | Out-GridView -Title "Pick your Tenant Id" -OutputMode Single
$tenantId = $subscription.name

Set-AzContext -TenantId $tenantId

Write-Host ""
Write-Host "Azure AD Tenant/Directory ID selected:" $tenantId -ForegroundColor Yellow
Write-Host ""

# Collect New MPN Partner ID 

$MPNPartnerID = "$null"
$defaultValue = "1234567"

Write-Host "Please enter the MPN Partner ID you wish to link this customers Azure too, followed by pressing the 'Enter/Return' key:" -ForegroundColor Cyan
$MPNPartnerID = Read-Host "Press enter to accept the default [$($defaultValue)]"
$MPNPartnerID = ($defaultValue,$MPNPartnerID)[[bool]$MPNPartnerID]

Write-Host "MPN Partner ID Captured:"$MPNPartnerID -ForegroundColor Green
Write-Host ""

# Collect Azure Existing MPN Partner ID Info

Write-Host "Checking if existing MPN Partner ID is set to any value"
Write-Host ""

$existingMPNPartnerIdInfo = $null

$existingMPNPartnerIdInfo = Get-AzManagementPartner -ErrorAction SilentlyContinue -ErrorVariable noExistingMPNPartnerId;

If ($noExistingMPNPartnerId) {

Write-Host "MPN Partner ID Not Currently Set To Any Value" -ForegroundColor Green
Write-Host ""

}

else {
    Write-Host "MPN Partner ID already set to:" $existingMPNPartnerIdInfo.PartnerId -ForegroundColor Yellow
    Write-Host "The exisiting MPN Partner name is:" $existingMPNPartnerIdInfo.PartnerName -ForegroundColor Yellow
    Write-Host ""
}

# Check if Azure MPN Partner IDs Are The Same

if ($noExistingMPNPartnerId) {
    Write-Host ""
}

elseif ($existingMPNPartnerIdInfo.PartnerId -eq $MPNPartnerID) {
    Write-Host "The MPN Partner ID you wish to set is already set as the MPN Partner ID for this customers Azure Tenant" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "No action is required. This script will close when any key is pressed." -ForegroundColor Green
    Read-Host
    Stop-Transcript
    exit
}
else {
    Write-Host "The MPN Partner ID you wish to set is different to what is already set." -ForegroundColor Red
    Write-Host ""
    Write-Host "The MPN Partner ID you wish to set is:" $MPNPartnerID -ForegroundColor Yellow
    Write-Host "The MPN Partner ID that is currently set is:" $existingMPNPartnerIdInfo.PartnerId -ForegroundColor Yellow
    Write-Host "The MPN Partner name that is currently set are:" $existingMPNPartnerIdInfo.PartnerName -ForegroundColor Yellow
    Write-Host ""
}

# Check If New Azure MPN Partner ID Should Be Set

$setNewMPNPartnerId = 'n'

Write-Host "Do you wish to set/replace the specified MPN Partner ID for this customers Azure Tenant? `nPlease enter 'y' or 'n' followed by the 'Enter/Return' key. (The default is 'n'):" -ForegroundColor Cyan
$setNewMPNPartnerId = Read-Host

if ($setNewMPNPartnerId -eq 'n') {
    if ($noExistingMPNPartnerId) {
        Write-Host ""
        Write-Host "You have chosen not to change/set the MPN Partner ID for this customers Azure Tenant." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "The MPN Partner ID will remain not currently set to any value." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "This script will close when any key is pressed." -ForegroundColor Red
        Read-Host
        Stop-Transcript
        exit
    }
    else {
    Write-Host ""
    Write-Host "You have chosen not to change/set the MPN Partner ID for this customers Azure Tenant." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The MPN Partner ID will remain set as:" $existingMPNPartnerIdInfo.PartnerId -ForegroundColor Cyan
    Write-Host "Which is for the MPN Partner named:" $existingMPNPartnerIdInfo.PartnerName -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This script will close when any key is pressed." -ForegroundColor Red
    Read-Host
    Stop-Transcript
    exit
    }
}

if ($setNewMPNPartnerId -eq 'y') {
    if ($noExistingMPNPartnerId) {
        Write-Host ""
        Write-Host "You have chosen to set the MPN Partner ID for this customers Azure Tenant to:" $MPNPartnerID -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Press the 'Enter/Return' key to set the new MPN Partner ID for this customers Azure Tenant." -ForegroundColor Cyan
        Read-Host
        Write-Host ""
        Write-Host "Setting the MPN Parter ID..." -ForegroundColor Cyan
        New-AzManagementPartner -PartnerId $MPNPartnerID -ErrorAction SilentlyContinue
        Write-Host ""
        Write-Host "MPN Partner ID set!" -ForegroundColor Green
    }
    else {
        Write-Host ""
        Write-Host "You have chosen to update the MPN Partner ID for this customers Azure Tenant to:" $MPNPartnerID -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Press the 'Enter/Return' key to set the new MPN Partner ID for this customers Azure Tenant." -ForegroundColor Cyan
        Read-Host
        Write-Host ""
        Write-Host "Updating the MPN Parter ID..." -ForegroundColor Cyan
        Update-AzManagementPartner -PartnerId $MPNPartnerID -ErrorAction SilentlyContinue
        Write-Host ""
        Write-Host "MPN Partner ID Updated!" -ForegroundColor Green
    }
    
}

# Check if New Azure MPN Partner ID Has Been Set Correctly

Write-Host ""
Write-Host "Checking MPN Partner ID set correctly..." -ForegroundColor Cyan
Write-Host ""

$newMPNPartnerIdInfo = $null

$newMPNPartnerIdInfo = Get-AzManagementPartner -ErrorAction SilentlyContinue

if ($newMPNPartnerIdInfo.PartnerId -eq $MPNPartnerID) {
    Write-Host "MPN Partner ID Set Correctly!" -ForegroundColor Green
    Write-Host ""
    Write-Host "MPN Partner ID currently set to:" $newMPNPartnerIdInfo.PartnerId -ForegroundColor Yellow
    Write-Host "Which is for the MPN Partner named:" $newMPNPartnerIdInfo.PartnerName -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Script complete and will therefore close when any key is pressed" -ForegroundColor Green
    Read-Host
}
else {
    Write-Host "MPN Partner ID Not Set Correctly. Please Check Log File To Investigate" -ForegroundColor Red
    Write-Host ""
    Write-Host "MPN Partner ID currently set to:" $newMPNPartnerIdInfo.PartnerId -ForegroundColor Yellow
    Write-Host "Which is for the MPN Partner named:" $newMPNPartnerIdInfo.PartnerName -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This script will now close when any key is pressed" -ForegroundColor Cyan
    Read-Host
    exit
}

Stop-Transcript