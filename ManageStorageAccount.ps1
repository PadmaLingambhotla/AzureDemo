param (
    [string]$resourceGroupName,
    [string]$storageAccountName,
    [string]$location
)

# Login to Azure
Connect-AzAccount -TenantId '87d64337-66c3-4dea-9688-f7c53f8364bb'

# Create a storage account
New-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $storageAccountName -Location $location -SkuName "Standard_LRS" -Kind "StorageV2"

# List storage accounts in the resource group
Get-AzStorageAccount -ResourceGroupName $resourceGroupName

# Get storage account keys
$storageAccountKeys = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageAccountName

# Output storage account keys
$storageAccountKeys
