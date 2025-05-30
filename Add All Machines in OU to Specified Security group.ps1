Import-Module ActiveDirectory;

$OU = Read-Host "Please enter your OU DN Path, i.e. OU=Laptops,OU=CONTOSO.COM,OU=Computers,OU=CONTOSO.COMs,DC=CONTOSO,DC=COM"
$SecurityGroup = Read-Host "Please enter your security group name"

Get-ADComputer -SearchBase $OU -Filter * -SearchScope OneLevel | % {Add-ADGroupMember $SecurityGroup -Members $_.DistinguishedName }