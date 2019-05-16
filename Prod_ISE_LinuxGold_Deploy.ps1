Add-AzureRmAccount -Environment AzureUSGovernment

# Enter subscription name to use
$SubscriptionName = "xxxx"

Select-AzureRmSubscription -Subscription $SubscriptionName

# Credentials for Local Admin account for the Image and SSH public key
$VMLocalAdminUser = "suser"
$VMLocalAdminSecurePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
$SSHKeyLocation = "$env:USERPROFILE\.ssh\id_rsa.pub"

## Global Variables
$ResourceGroupName = "CERRS-DEV-TEST-RG"
$urlOfUploadedImageVhd = "https://xxxxx.blob.core.usgovcloudapi.net/vhds/rhel6820180118100712-v1.vhd"
$vmName = "RHEL68GOLD-DEV3"
$computerName = "RHEL68GOLD-DEV3"
$vmSize = "Standard_DS1_v2"
$location = "USGov Virginia"
$imageName = "RHEL68-GOLD-v1"

## Networking
$DNSNameLabel = "rhel68golddev3"
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
$imageConfig = Set-AzureRmImageOsDisk -Image $imageConfig -OsType Linux -OsState Generalized -BlobUri $urlOfUploadedImageVhd
$image = New-AzureRmImage -ImageName $imageName -ResourceGroupName $ResourceGroupName -Image $imageConfig

#  Networking Config
#$SingleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
$Vnet = Get-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $ResourceGroupName
$Subnet = Get-AzureRMVirtualNetworkSubnetConfig -VirtualNetwork $Vnet -Name
$PIP = New-AzureRmPublicIpAddress -Name $PublicIPAddressName -DomainNameLabel $DNSNameLabel -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic
$NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $PIP.Id

$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

$VM = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize

$vm = Set-AzureRmVMSourceImage -VM $vm -Id $image.Id

$vm = Set-AzureRmVMOSDisk -VM $vm -DiskSizeInGB 32 -CreateOption FromImage -Caching ReadWrite

$vm = Set-AzureRmVMOperatingSystem -VM $vm -Linux -ComputerName $computerName -Credential $credential

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

$vm = Set-AzureRmVMBootDiagnostics -VM $vm -Enable -ResourceGroupName $ResourceGroupName -StorageAccountName $DiagName

#  SSH Key
$sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"

$vm = Add-AzureRmVMSshPublicKey -VM $vm -KeyData $sshPublicKey -Path "/home/$VMLocalAdminUser/.ssh/authorized_keys"

Write-Host -ForegroundColor cyan "Deploying..."

New-AzureRmVM -VM $vm -ResourceGroupName $ResourceGroupName -Location $location -Verbose -Debug

$vmList = Get-AzureRmVM -ResourceGroupName $ResourceGroupName
    $vmList.Name
