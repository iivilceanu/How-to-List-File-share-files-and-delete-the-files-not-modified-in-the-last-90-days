#To list:

## Connect to Azure Account  
Connect-AzAccount   
 Select-AzSubscription -subscriptionid "yoursubscriptionID"

## Input Parameters  
$resourceGroupName="storage account resource group"  
$storageAccName="storageaccountname"  
$fileShareName="filesharename"  

  
## Function to Lists directories and files  
## Function to Lists directories and files  
Function GetFiles  
{  
    Write-Host -ForegroundColor Green "Lists directories and files.."    
    ## Get the storage account context  
    $ctx=(Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccName).Context  
    ## List directories  
    $directories=Get-AZStorageFile -Context $ctx -ShareName $fileShareName  
    ## Loop through directories  
    foreach($directory in $directories)  
    {  
        write-host -ForegroundColor Magenta " Directory Name: " $directory.Name  
        $files=Get-AZStorageFile -Context $ctx -ShareName $fileShareName -Path $directory.Name | Get-AZStorageFile  
        ## Loop through all files and display  
        foreach ($file in $files)  
        {  
                if ($file.CloudFile.Properties.LastModified -lt (Get-Date).AddDays(-90))  
        {  

        Select @{ Name = "Uri"; Expression = { $_.CloudFile.SnapshotQualifiedUri} }, @{ Name = "LastModified"; Expression = { $_.CloudFile.Properties.LastModified } }   
            write-host -ForegroundColor Yellow $file.Name $file.LastModified  
        }  
      }
    }  
}  

-	To Delete:

## Connect to Azure Account  
Connect-AzAccount   
 Select-AzSubscription -subscriptionid "yoursubscriptionID"

## Input Parameters  
$resourceGroupName="storage account resource group"  
$accountName="storageaccountname"  
$key  = “storageaccountkey”
$shareName="filesharename"  


$ctx = New-AzStorageContext -StorageAccountName $accountName -StorageAccountKey $key  

$DirIndex = 0  
$dirsToList = New-Object System.Collections.Generic.List[System.Object]  
  
# Get share root Dir  
$shareroot = Get-AzStorageFile -ShareName $shareName -Path . -context $ctx   
$dirsToList += $shareroot   
  
# List files recursively and remove file older than 14 days   
While ($dirsToList.Count -gt $DirIndex)  
{  
    $dir = $dirsToList[$DirIndex]  
    $DirIndex ++  
    $fileListItems = $dir | Get-AzStorageFile  
    $dirsListOut = $fileListItems | where {$_.GetType().Name -eq "AzureStorageFileDirectory"}  
    $dirsToList += $dirsListOut  
    $files = $fileListItems | where {$_.GetType().Name -eq "AzureStorageFile"}  
  
    foreach($file in $files)  
    {  
        # Fetch Attributes of each file and output  
        $task = $file.CloudFile.FetchAttributesAsync()  
        $task.Wait()  
  
        # remove file if it's older than 14 days.  
        if ($file.CloudFile.Properties.LastModified -lt (Get-Date).AddDays(-90))  
        {  
            ## print the file LMT  
            # $file | Select @{ Name = "Uri"; Expression = { $_.CloudFile.SnapshotQualifiedUri} }, @{ Name = "LastModified"; Expression = { $_.CloudFile.Properties.LastModified } }   
  
            # remove file  
            $file | Remove-AzStorageFile  
        }  
    }  
    #Debug log  
    # Write-Host  $DirIndex $dirsToList.Length  $dir.CloudFileDirectory.SnapshotQualifiedUri.ToString()   
}
