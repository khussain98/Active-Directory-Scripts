# Store the domain information retrieved
$domain = Get-ADDomain

# Get the KRBTGT account
$krbtgt = Get-ADUser -Filter { SamAccountName -eq 'krbtgt' }

# Confirm action with the user
Write-Host "You are about to reset the KRBTGT password for domain: $($domain.Name)" -ForegroundColor Yellow
$confirmation = Read-Host "Type 'YES' to proceed"

if ($confirmation -ne 'YES') {
    Write-Host "Operation cancelled." -ForegroundColor Red
    return
}

# Generate a secure random password
$securePassword = [System.Web.Security.Membership]::GeneratePassword(32, 5) | ConvertTo-SecureString -AsPlainText -Force

# Reset the password for the KRBTGT account
Write-Host "Resetting KRBTGT password..." -ForegroundColor Cyan
Set-ADAccountPassword -Identity $krbtgt -NewPassword $securePassword -Reset

if ($?) {
    Write-Host "KRBTGT password reset successfully!" -ForegroundColor Green
} else {
    Write-Host "Failed to reset KRBTGT password." -ForegroundColor Red
    return
}

# Force immediate replication to all domain controllers
Write-Host "Forcing replication to all domain controllers..." -ForegroundColor Cyan
(Get-ADDomainController -Filter *).Name | ForEach-Object {
    Write-Host "Replicating changes to: $_" -ForegroundColor Yellow
    repadmin /syncall $_ /APed
}

Write-Host "KRBTGT password reset and replication completed." -ForegroundColor Green