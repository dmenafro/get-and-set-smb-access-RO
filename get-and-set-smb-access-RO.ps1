# The purpose of this script is to collect the permissions of the shares listed in the csv
# Output the collected permissions to a file on your desktop
# Set the shares to read only

#    Import CSV
#    Headers for the CSV should be the following
#    Server,Share

#    Server: Should contain just the server name

#    Share: Should contain just the name of the share


# Getting the desktop path of the user launching the script. Just as a default starting path
$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

# Prompt the user to select the CSV file for the script
Function Get-FileName($initialDirectory){
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $initialDirectory
    $OpenFileDialog.Filter = "CSV (*.csv) | *.csv"
    $OpenFileDialog.Title = "Select GET SHARE ACCESS CSV"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.FileName
}

$FilePath  = Get-FileName -initialDirectory $DesktopPath
$csv      = @()
$csv      = Import-Csv -Path $FilePath 
$results = @()

# Set count for activity status
$i = 0

#Loop through all items in the CSV 
ForEach ($item In $csv) 
{

    # Put the objects into string variables, because new-dfsnfoldertarget likes strings
    [string]$server = $item.server
    [string]$share = $item.share
    
    # This little diddy will provide a progress bar!
    $i = $i+1
    Write-Progress -Activity "Checking \\$server\$share" -Status "Progress:" -PercentComplete ($i/$csv.Count*100)
    
    # Getting SMB share permissions for each server/share in the CSV
    $results += get-SmbShareAccess -CimSession $server -Name $share
}

write-host -ForegroundColor Green "Saving share-results.csv to desktop"
$results | export-csv -path $desktopPath+"\share-results.csv" -NoTypeInformation

# clear variables to be used in setting share permissions
Clear-Variable i
Clear-Variable item
Clear-Variable server
Clear-Variable share

#Loop through all items in the the results (data is fresh
ForEach ($item In $results) 
{

    # Put the objects into string variables, because new-dfsnfoldertarget likes strings
    [string]$server = $item.PSComputerName
    [string]$share = $item.name
    [string]$account = $item.AccountName
    [string]$permissions = "Read"
    
    # This little diddy will provide a progress bar!
    $i = $i+1
    Write-Progress -Activity "Updating \\$server\$share permissions to $permissions for $account" -Status "Progress:" -PercentComplete ($i/$csv.Count*100)
    
    # Setting the SMB share permissions to READ for each server/share in the results (created from initial CSV)
    Grant-SmbShareAccess -CimSession $server -Name $share -AccountName $account -AccessRight $permissions -force
}
