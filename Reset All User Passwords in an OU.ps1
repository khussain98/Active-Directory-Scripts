$ouPath = Write-Host "OU DN Path, i.e. OU=Users,DC=domain,DC=com"
$CsvPathWhere = Write-Host "Define the path where the CSV will be saved, i.e. C:\temp\passwords.csv"

# Define the OU where the users are located (e.g., 'OU=Users,DC=domain,DC=com')
$OU = $ouPath

# Define the path where the CSV will be saved
$CsvPath = $CsvPathWhere

# Length of the randomized passwords
$PasswordLength = 12

# Function to generate a random password
function Generate-RandomPassword {
    param ([int]$length = 12)

    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+"
    $password = -join ((1..$length) | ForEach-Object { $chars | Get-Random })
    return $password
}

# Initialize an empty array to store user details
$UserPasswordList = @()

# Import the Active Directory module
Import-Module ActiveDirectory

# Get all users from the specified OU
$Users = Get-ADUser -SearchBase $OU -Filter * -Properties SamAccountName

# Loop through each user and reset their password
foreach ($User in $Users) {
    # Generate a random password
    $NewPassword = Generate-RandomPassword -length $PasswordLength

    # Reset the password and set "change password at next login" option
    Set-ADAccountPassword -Identity $User.SamAccountName -Reset -NewPassword (ConvertTo-SecureString $NewPassword -AsPlainText -Force)
    Set-ADUser -Identity $User.SamAccountName -PasswordNeverExpires $false -ChangePasswordAtLogon $true

    # Collect user details for the CSV
    $UserPasswordList += [PSCustomObject]@{
        Username = $User.SamAccountName
        Password = $NewPassword
    }

    Write-Host "Password for $($User.SamAccountName) has been reset."
}

# Export the list of usernames and passwords to a CSV file
$UserPasswordList | Export-Csv -Path $CsvPath -NoTypeInformation

Write-Host "All passwords have been reset and exported to $CsvPath."
