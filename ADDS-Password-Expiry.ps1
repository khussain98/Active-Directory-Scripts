# GitHub: https://github.com/khussain98
# Requires: ActiveDirectory module
# Purpose: Send email notifications to users about upcoming password expirations

# --- Configuration Parameters ---
$SearchBase = "DC=CONTOSO,DC=com"
$SMTPServer = "smtp.office365.com"
$SMTPPort = 587
$SMTPUsername = "reminders@mydomain.com"
$CredentialPath = "C:\Secure\SMTP_Cred.xml" # Encrypted credential file
$ExpireInDays = 10
$NegativeDays = -1
$From = "Password Expiry <reminders@mydomain.com>"
$LogFile = "C:\Logs\PS-pwd-expiry.csv"
$Testing = $true
$AdminEmailAddr = "Admin@mydomain.com"
$SampleEmails = 1
$TextEncoding = [System.Text.Encoding]::UTF8

# --- Load Credentials ---
if (Test-Path $CredentialPath) {
    $SMTPPassword = Import-Clixml -Path $CredentialPath
    $SMTPCredentials = New-Object System.Management.Automation.PSCredential ($SMTPUsername, $SMTPPassword)
} else {
    Write-Error "Credential file not found at $CredentialPath"
    exit
}

# --- Import Active Directory Module ---
Import-Module ActiveDirectory

# --- Retrieve Users ---
$Users = Get-ADUser -SearchBase $SearchBase -Filter {
    Enabled -eq $true -and PasswordNeverExpires -eq $false
} -Properties SamAccountName, DisplayName, PasswordLastSet, EmailAddress

# --- Get Domain Password Policy ---
$DefaultMaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

# --- Initialize Counters ---
$CountProcessed = 0
$CountSent = 0
$CountSkipped = 0
$CountFailed = 0
$SamplesSent = 0

# --- Prepare Log File ---
if (Test-Path $LogFile) { Remove-Item $LogFile }
"Date,SamAccountName,DisplayName,PasswordLastSet,DaysToExpire,ExpiresOn,EmailAddress,Status" | Out-File -FilePath $LogFile -Encoding UTF8

# --- Process Each User ---
foreach ($User in $Users) {
    $CountProcessed++
    $SamAccountName = $User.SamAccountName
    $DisplayName = $User.DisplayName
    $EmailAddress = $User.EmailAddress
    $PasswordLastSet = $User.PasswordLastSet

    if (-not $PasswordLastSet) {
        $Status = "PasswordNeverSet"
        $CountSkipped++
        Add-Content -Path $LogFile -Value "$(Get-Date),$SamAccountName,$DisplayName,N/A,N/A,N/A,$EmailAddress,$Status"
        continue
    }

    # Determine Password Expiration
    $ExpiresOn = $PasswordLastSet + $DefaultMaxPasswordAge
    $DaysToExpire = ($ExpiresOn - (Get-Date)).Days

    # Determine if Notification Should Be Sent
    if ($DaysToExpire -le $ExpireInDays -and $DaysToExpire -ge $NegativeDays) {
        $Status = "Pending"

        # Prepare Email
        $Subject = "$SamAccountName - Password Expiry Notification"
        $Body = @"
<p>Dear $DisplayName,</p>
<p>Your password is set to expire on <strong>$($ExpiresOn.ToShortDateString())</strong>, which is in <strong>$DaysToExpire days</strong>.</p>
<p>Please change your password before it expires to avoid any disruption.</p>
<p>Thank you,<br/>IT Support Team</p>
"@

        # Determine Recipient
        if ($Testing -and $SamplesSent -lt $SampleEmails) {
            $Recipient = $AdminEmailAddr
            $SamplesSent++
        } elseif (-not $Testing) {
            $Recipient = $EmailAddress
        } else {
            $Status = "TestingModeSkipped"
            $CountSkipped++
            Add-Content -Path $LogFile -Value "$(Get-Date),$SamAccountName,$DisplayName,$PasswordLastSet,$DaysToExpire,$ExpiresOn,$EmailAddress,$Status"
            continue
        }

        # Send Email
        try {
            Send-MailMessage -From $From -To $Recipient -Subject $Subject -Body $Body -BodyAsHtml -SmtpServer $SMTPServer -Port $SMTPPort -UseSsl -Credential $SMTPCredentials -Encoding $TextEncoding
            $Status = "EmailSent"
            $CountSent++
        } catch {
            $Status = "EmailFailed"
            $CountFailed++
        }
    } else {
        $Status = "NotInNotificationWindow"
        $CountSkipped++
    }

    # Log Entry
    Add-Content -Path $LogFile -Value "$(Get-Date),$SamAccountName,$DisplayName,$PasswordLastSet,$DaysToExpire,$ExpiresOn,$EmailAddress,$Status"
}

# --- Summary ---
Write-Host "Processed: $CountProcessed users"
Write-Host "Emails Sent: $CountSent"
Write-Host "Skipped: $CountSkipped"
Write-Host "Failed: $CountFailed"
Write-Host "Log File: $LogFile"
