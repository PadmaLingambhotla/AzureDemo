param (
    [string]$resourceGroupName,
    [string]$vmName,
    [string]$location,
    [string]$vmSize,
    [string]$adminUsername,
    [string]$adminPassword
)

# Login to Azure with Tenant ID
Connect-AzAccount -TenantId '87d64337-66c3-4dea-9688-f7c53f8364bb'

# Create a resource group if it doesn't exist
if (-not (Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}

# Create a virtual network
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location -Name "$vmName-vnet" -AddressPrefix "10.0.0.0/16"

# Add a subnet to the virtual network
$subnet = Add-AzVirtualNetworkSubnetConfig -Name "$vmName-subnet" -AddressPrefix "10.0.0.0/24" -VirtualNetwork $vnet

# Apply the changes to the virtual network
$vnet | Set-AzVirtualNetwork

# Retrieve the subnet ID after applying changes
$subnetId = ($vnet.Subnets | Where-Object { $_.Name -eq "$vmName-subnet" }).Id

# Ensure $subnetId is not null
if (-not $subnetId) {
    Write-Error "Subnet ID is null or empty. Please check the virtual network and subnet creation."
    exit
}

# Create a public IP address with static allocation
$publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Static -Name "$vmName-pip" -Sku Standard

# Create a network security group
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$vmName-nsg"

# Create a network interface card and associate with public IP address and NSG
$nic = New-AzNetworkInterface -ResourceGroupName $resourceGroupName -Location $location -Name "$vmName-nic" -SubnetId $subnetId -PublicIpAddress $publicIp -NetworkSecurityGroupId $nsg.Id

# Ensure $nic.Id is not null
if (-not $nic.Id) {
    Write-Error "NIC ID is null or empty. Please check the network interface creation."
    exit
}

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize |
    Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential (New-Object PSCredential -ArgumentList $adminUsername, (ConvertTo-SecureString -String $adminPassword -AsPlainText -Force)) |
    Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version 'latest' |
    Add-AzVMNetworkInterface -Id $nic.Id

# Ensure $vmConfig is not null
if (-not $vmConfig) {
    Write-Error "VM configuration is null or empty. Please check the VM configuration setup."
    exit
}

# Create the virtual machine
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig
