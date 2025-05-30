$importpath = Read-Host "Type in import path for CSV, i.e. C:\temp\userlist.csv"

$Groups = Get-ADGroup -Filter * -SearchBase 'OU=,DC=,DC='
$Results = foreach( $Group in $Groups ){
    Get-ADGroupMember -Identity $Group | foreach {
        [pscustomobject]@{
            GroupName = $Group.Name
            Name = $_.Name
            }
        }
    }

$Results | Export-Csv -path "C:\SecurityGroupPermissions.csv"