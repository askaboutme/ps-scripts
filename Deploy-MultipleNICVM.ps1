# Global Config
$subscriptionId = "9f657357-308f-4780-aee7-070aa7f55580"
$rgName = "CERRS-DEV-TEST-RG"
$Location = "USGov Virginia"

# vNET Config
$vNetName = "JD-TEST-VNET"
$vNetAddressSpace1 = "10.228.65.0/28"
$vNetAddressSpace2 = "10.228.63.0/28"

# Subnet Config
$frontEndSubnetName = "JD-TEST-FrontEnd"
$frontEndAddressRange = "10.228.65.0/28"
$managementSubnetName = "JD-TEST-MGMT"
$managementAddressRange = "10.228.63.0/28"

# NIC Config
$frontEndNICName = "JD-TEST-FrontEndNIC-01"
$managementNICName = "JD-TEST-MGMTNIC-01"

# VM Image Config
$vmImageName = "JD-TESTVM-AS4-IMAGE"

# VM Config
$vmLocalAdminUser = "suser"
$vmLocalAdminSecurePassword = ConvertTo-SecureString 'YUwScD24oAnXQVE#$U3dU2' -AsPlainText -Force
$vmName = "JD-TEST-SandBoxVM"
$vmSize = "Standard_D4S_V3"

# Boot Diagnostics account
$diagName = "JD-TEST-DIAG"

Login-AzureRmAccount -Environment AzureUSGovernment

Set-AzureRmContext -Subscription $subscriptionId

# Create Resource Group If Needed, if not, comment the line below
#New-AzureRmResourceGroup -Name $rgName -Location $Location

# Define two virtual network subnets
$subnetFrontEnd = New-AzureRmVirtualNetworkSubnetConfig -Name $frontEndSubnetName `
    -AddressPrefix $frontEndAddressRange
$subnetBackEnd = New-AzureRmVirtualNetworkSubnetConfig -Name $managementSubnetName `
    -AddressPrefix $managementAddressRange
	
# Create virtual network and subnets
$myVnet = New-AzureRmVirtualNetwork -ResourceGroupName $rgName `
    -Location $Location `
    -Name $vNetName `
    -AddressPrefix $vNetAddressSpace1,$vNetAddressSpace2 `
    -Subnet $subnetFrontEnd,$subnetBackEnd
	
# Create two NICs
$frontEnd = $myVnet.Subnets|?{$_.Name -eq $frontEndSubnetName}
$Nic1 = New-AzureRmNetworkInterface -ResourceGroupName $rgName `
    -Name $frontEndNICName `
    -Location $Location `
    -SubnetId $frontEnd.Id

$backEnd = $myVnet.Subnets|?{$_.Name -eq $managementSubnetName}
$Nic2 = New-AzureRmNetworkInterface -ResourceGroupName $rgName `
    -Name $managementNICName `
    -Location $Location `
    -SubnetId $backEnd.Id

# Define Gold Image to be used
$image = Get-AzureRmImage -ImageName $vmImageName -ResourceGroupName $ResourceGroupName
	
# Set VM credentials
$cred = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

# Define VM
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize

# Create the rest of VM configuration
$vmConfig = Set-AzureRmVMOperatingSystem -VM $vmConfig `
    -Windows `
    -ComputerName $vmName `
    -Credential $cred `
    -ProvisionVMAgent `
    -EnableAutoUpdate
$vmConfig = Set-AzureRmVMSourceImage -VM $vmConfig -Id $image.Id
$vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite
$vmConfig = Set-AzureRmVMBootDiagnostics -VM $vmConfig -Enable -ResourceGroupName $rgName -StorageAccountName $diagName

# Attach the two NICs
$vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $Nic1.Id -Primary
$vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $Nic2.Id

Write-Host -ForegroundColor cyan "Deploying $vmName with $frontEndNICName and $managementNICName"

# Create VM
New-AzureRmVM -VM $vmConfig -ResourceGroupName $rgName -Location $Location