Write-Host "This will output values on-screen as well as a CSV Export"
$exportpath = Read-Host "Type in export path for CSV, i.e. C:\temp\userlist.csv"
Write-Host "Attempting operation..."

Get-ADUser -Filter 'enabled -eq $true' -Properties ProfilePath, HomeDirectory, HomeDrive | Select Name, SamAccountName, ProfilePath, HomeDirectory, HomeDrive

Write-Host "Attempting export operation..."
Get-ADUser -Filter 'enabled -eq $true' -Properties ProfilePath, HomeDirectory, HomeDrive | Select Name, SamAccountName, ProfilePath, HomeDirectory, HomeDrive | Export-Csv -path $exportpath