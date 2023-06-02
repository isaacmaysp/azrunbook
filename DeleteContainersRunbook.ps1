#This script is used to daily delete containers from a Storage Account in Azure

# Parameters
param (
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)
$prefix = "x"  # Specify the prefix required for deleted containers
$daysOldLimit = 0  #Specify the age after which containers get deleted

Connect-AzAccount -Identity

# get a reference to the storage account and the context
$storageAccount = Get-AzStorageAccount `
  -ResourceGroupName $ResourceGroupName `
  -Name $StorageAccountName
$ctx = $storageAccount.Context 

# list all containers in the storage account 
Write-Output "`nAll containers:"
Get-AzStorageContainer -Context $ctx | select Name

# retrieve list of containers to delete
$listOfContainersToDelete = Get-AzStorageContainer -Context $ctx -Prefix $prefix

Write-Output ("`nDeleting containers older than {0} days:" -f $daysOldLimit)

Foreach ($container in $listOfContainersToDelete) {
    $lastModified = $container.LastModified
    $now = Get-Date ([datetime]::UtcNow)
    $difference = (([DateTime]$now - [DateTime](get-date $lastModified.UtcDateTime))).TotalDays
    Write-Output $difference

    if ($difference -gt $daysOldLimit) {
    # This is where the DELETION happens
        try {
            Remove-AzStorageContainer -Name $container.Name -Context $ctx -Force
            Write-Output ("{0} has been deleted." -f $container.Name)
        }
        catch{
            Write-Output ("An error occurred whilst attempting to delete container {0}" -f $container.Name)
            Write-Output $_
        }
    }
}

# show list of containers not deleted 
Write-Output "`nAll containers not deleted:"
Get-AzStorageContainer -Context $ctx | select Name