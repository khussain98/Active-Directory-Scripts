$importpath = Read-Host "Type in import path for CSV, i.e. C:\temp\userlist.csv"

$users = Import-Csv -Path $importpath
foreach ($user in $users) {
    $aduser = Get-ADUser -Filter "SamAccountName -eq '$($user.SamAccountName)'" -Properties ProfilePath, HomeDirectory, HomeDrive
    if ($aduser) {
        Set-ADUser -Identity $aduser -Clear ProfilePath, HomeDirectory, HomeDrive
        Set-ADUser -Identity $aduser -Add @{ProfilePath=$user.ProfilePath; HomeDirectory=$user.HomeDirectory; HomeDrive=$user.HomeDrive}
    }
    else {
        Write-Warning "User $($user.SamAccountName) not found in Active Directory."
    }
}