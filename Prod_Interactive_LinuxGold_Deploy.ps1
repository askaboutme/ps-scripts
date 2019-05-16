Login-AzureRmAccount -Environment AzureUSGovernment

Write-Host -ForegroundColor Green "Subscription Information"
$SubscriptionName = Read-Host "Enter Subscription Name"

Write-Host -ForegroundColor Green "Setting Subscription"
Select-AzureRmSubscription -Subscription "$SubscriptionName"

Write-Host -ForegroundColor Green "Image Local Account Details"
$VMLocalAdminUser = Read-Host "Enter Image Local Admin Username"
$VMLocalAdminSecurePassword = Read-Host "Enter Image Local Admin Password" -AsSecureString

Write-Host -ForegroundColor Green "Global Variables Configuration"
$ResourceGroupName = Read-Host "Resource Group Name"
$urlOfUploadedImageVhd = Read-Host "URL of  Uploaded Image VHD"
$vmName = Read-Host "Name of New VM"
$computerName = Read-Host "Computer Name (same as VM name)"
$vmSize = Read-Host "Size of VM"
$location = Read-Host "Region" 
$imageName = Read-Host "Name of Image Used"

Write-Host -ForegroundColor Green "Gathering Image Details"

## Image Config
$imageConfig = New-AzureRmImageConfig -Location $location
$imageConfig = Set-AzureRmImageOsDisk -Image $imageConfig -OsType Linux -OsState Generalized -BlobUri $urlOfUploadedImageVhd
$image = New-AzureRmImage -ImageName $imageName -ResourceGroupName $ResourceGroupName -Image $imageConfig

Write-Host -ForegroundColor Green "Networking Details"

$NewOrExistingVnet = Read-Host "New or Existing Vnet?"

$VNETName = Read-Host "Name of Vnet"
$SubnetName = Read-Host "Name of Subnet"
$DNSNameLabel = Read-Host "DNS Label for VM"
$NICName = Read-Host "NIC Name"
$PublicIPAddressName = Read-Host "Public IP Address Name"

if ($NewOrExistingVnet -eq "New")

  {
    $VnetAddressPrefix = Read-Host "Enter Vnet Address Prefix"
    $SubnetAddressPrefix = Read-Host "Enter Subnet Address Prefix"
    $SingleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
    $Vnet = New-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $ResourceGroupName -Location $location -AddressPrefix $VnetAddressPrefix
    $PIP = New-AzureRmPublicIpAddress -Name $PublicIPAddressName -DomainNameLabel $DNSNameLabel -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic
    $NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $PIP.Id
     }
elseif ($NewOrExistingVnet -eq "Existing")

   {
     $Vnet = Get-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $ResourceGroupName
     $PIP = New-AzureRmPublicIpAddress -Name $PublicIPAddressName -DomainNameLabel $DNSNameLabel -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic
     $NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $PIP.Id
     }

$DiagName = Read-Host "Name of Diagnostics Storage Account"

$confirmation = Read-Host "Beginning Script.  Do you wish to continue? [y/n]"
if ($confirmation -ne 'y') {exit}


Write-Host -ForegroundColor yellow "Building $vmName VM from $imageName image using $NewOrExistingVnet Vnet"

#-------------------------------#
#---------Begin-Script----------#
#-------------------------------#

$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

$VM = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize

$vm = Set-AzureRmVMSourceImage -VM $vm -Id $image.Id

$vm = Set-AzureRmVMOSDisk -VM $vm -DiskSizeInGB 128 `
-CreateOption FromImage -Caching ReadWrite

$vm = Set-AzureRmVMOperatingSystem -VM $vm -Linux -ComputerName $computerName `
-Credential $credential

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

$vm = Set-AzureRmVMBootDiagnostics -VM $vm -Enable -ResourceGroupName $ResourceGroupName -StorageAccountName $DiagName

Write-Host -ForegroundColor cyan "Deploying..."

$CreateVM = New-AzureRmVM -VM $vm -ResourceGroupName $ResourceGroupName -Location $location

Write-Host -ForegroundColor Green "Build Complete!"