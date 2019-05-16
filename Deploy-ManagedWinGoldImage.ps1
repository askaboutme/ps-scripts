Add-AzureRmAccount -Environment AzureUSGovernment

## Enter subscription name to use
$SubscriptionName = "xxxxx"

Select-AzureRmSubscription -Subscription $SubscriptionName

## Credentials for Local Admin account for the Image
$VMLocalAdminUser = "suser"
$VMLocalAdminSecurePassword = ConvertTo-SecureString 'xxxx' -AsPlainText -Force

## Global Variables
$ResourceGroupName = "CERRS-DEV-TEST-RG"
$vmName = "WINGOLD-DEVIM8"
$vmSize = "Standard_DS1_v2"
$location = "USGov Virginia" 
$imageName = "JD-TESTVM-AS4-IMAGE"

## Networking
$VNETName = "VMIMAGE-DEV-TEST"
$NICName = "$vmName" + "-NIC1"
$SubnetName = "TEST-SUBNET"

## Diagnostics Storage Account Name
$DiagName = "cerrsvmgoldimage"

#-------------------------------------------------#
#-----------------Begin Script--------------------#
#-------------------------------------------------#

## Image Config
$image = Get-AzureRmImage -ImageName $imageName -ResourceGroupName $ResourceGroupName

#  Networking Config
$Vnet = Get-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $ResourceGroupName
$NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Vnet.Subnets[0].Id

$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize | Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate

$vm = Set-AzureRmVMSourceImage -VM $vmConfig -Id $image.Id

$vm = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic.Id

$vm = Set-AzureRmVMOSDisk -VM $vm -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite

$vm = Set-AzureRmVMBootDiagnostics -VM $vm -Enable -ResourceGroupName $ResourceGroupName -StorageAccountName $DiagName

Write-Host -ForegroundColor cyan "Deploying..."

New-AzureRmVM -VM $vm -ResourceGroupName $ResourceGroupName -Location $location
