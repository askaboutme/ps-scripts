Add-AzureRmAccount -Environment AzureUSGovernment

# Enter subscription name to use
$SubscriptionName = "Cognosante CERRS Dev/Test Azure Gov Sub"

Select-AzureRmSubscription -Subscription $SubscriptionName

# Credentials for Local Admin account for the Image
$VMLocalAdminUser = "suser"
$VMLocalAdminSecurePassword = ConvertTo-SecureString 'YUwScD24oAnXQVE#$U3dU2' -AsPlainText -Force

## Global Variables
$ResourceGroupName = "CERRS-DEV-TEST-RG"
$urlOfUploadedImageVhd = "https://cerrsvmgoldimage.blob.core.usgovcloudapi.net/vhds/WIN2012R2GOLD20171227v1.vhd"
$vmName = "WINGOLD-DEV8"
$computerName = "WINGOLD-DEV8"
$vmSize = "Standard_DS1_v2"
$location = "USGov Virginia" 
$imageName = "WIN2012R2-GOLD-v1"

## Networking
$DNSNameLabel = "wingolddev8"
$VNETName = "VMIMAGE-DEV-TEST"
$NICName = "$VMName" + "-NIC1"
$PublicIPAddressName = "$VMName" + "-PIP"
$SubnetName = "TEST-SUBNET"
#$SubnetAddressPrefix = "10.0.0.0/24"
#$VnetAddressPrefix = "10.0.0.0/16"

## Must specify existing storage account or script will fail!
$DiagName = "cerrsvmgoldimage"

#-------------------------------------------------#
#-----------------Begin Script--------------------#
#-------------------------------------------------#

## Image Config
$imageConfig = New-AzureRmImageConfig -Location $location
$imageConfig = Set-AzureRmImageOsDisk -Image $imageConfig -OsType Windows -OsState Generalized -BlobUri $urlOfUploadedImageVhd
$image = New-AzureRmImage -ImageName $imageName -ResourceGroupName $ResourceGroupName -Image $imageConfig

#  Networking Config
#$SingleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
$Vnet = Get-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $ResourceGroupName
$PIP = New-AzureRmPublicIpAddress -Name $PublicIPAddressName -DomainNameLabel $DNSNameLabel -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic
$NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $PIP.Id

$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

$VM = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize

$vm = Set-AzureRmVMSourceImage -VM $vm -Id $image.Id

$vm = Set-AzureRmVMOSDisk -VM $vm -DiskSizeInGB 128 `
-CreateOption FromImage -Caching ReadWrite

$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $computerName `
-Credential $credential -ProvisionVMAgent -EnableAutoUpdate

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

$vm = Set-AzureRmVMBootDiagnostics -VM $vm -Enable -ResourceGroupName $ResourceGroupName -StorageAccountName $DiagName

Write-Host -ForegroundColor cyan "Deploying..."

New-AzureRmVM -VM $vm -ResourceGroupName $ResourceGroupName -Location $location -Verbose -Debug

$vmList = Get-AzureRmVM -ResourceGroupName $ResourceGroupName
    $vmList.Name

