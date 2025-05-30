$searchpath = Read-Host "Type in search path, i.e. "\\alt-fs\contoso.com-IT"
$exportpath = Read-Host "Type in export path for CSV, i.e. C:\temp\FolderPermissions.csv"

$FolderPath = dir -Directory -Path $searchpath" -Recurse -Force
$Report = @()
Foreach ($Folder in $FolderPath) {
    $Acl = Get-Acl -Path $Folder.FullName
    foreach ($Access in $acl.Access)
        {
            $Properties = [ordered]@{'FolderName'=$Folder.FullName;'AD
Group or
User'=$Access.IdentityReference;'Permissions'=$Access.FileSystemRights;'Inherited'=$Access.IsInherited}
            $Report += New-Object -TypeName PSObject -Property $Properties
        }
}
$Report | Export-Csv -path $exportpath