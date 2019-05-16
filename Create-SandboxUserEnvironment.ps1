# Global Config
$subscriptionId = "5f45c73d-f39c-4fef-9f37-8d168fe0f5da"
$rgName = "JD-SandBox-RG"
$Location = "USGov Virginia"

# vNET Config
$vNetName = "JD-SandBox-VNET"
$vNetAddressSpace1 = "10.228.64.0/28"
$vNetAddressSpace2 = "10.228.62.0/28"

# Subnet Config
$frontEndSubnetName = "JD-SandBox-FrontEnd"
$frontEndAddressRange = "10.228.64.0/28"
$managementSubnetName = "JD-SandBox-MGMT"
$managementAddressRange = "10.228.62.0/28"

# NIC Config
$frontEndNICName = "JD-SandBox-FrontEndNIC-01"
$managementNICName = "JD-SandBox-MGMTNIC-01"

# Peering Config
$peervNetA = "JD-SandBox-VNET"
$peervNetAResourceGroup = "JD-SandBox-RG"
$peerNamevNetAtoB = "Peer-JDSandBox-Daoping"
$peervNetBResourceGroup = "RG-AZE-DAOPING-01"
$peervNetB = "RG-AZE-DAOPING-01-VNET"
$peerNamevNetBtoA = "Peer-Daoping-JDSandBox"

# Route Table Config
$routeTableRG = "RG-AZE-DAOPING-01"
$routeTableName = "RT-DAOPING-MM-01"

# VM Image Config
$vmImageRG = "RG-AZE-DAOPING-01"
$vmImageName = "GOLD-WIN2012R2-V1.2-Daoping"

# VM Config
$vmName = "JD-SandBoxVM"
$vmSize = "Standard_D4S_V3"

# Boot Diagnostics account
$diagRG = "RG-AZE-EMSTest-01"
$diagName = "bootdiagcountcms"

#------Begin Script------#

Login-AzureRmAccount -Environment AzureUSGovernment

Set-AzureRmContext -Subscription $subscriptionId

# Create Resource Group If Needed, if not, comment the line below
New-AzureRmResourceGroup -Name $rgName -Location $Location

# Define two virtual network subnets
$subnetFrontEnd = New-AzureRmVirtualNetworkSubnetConfig -Name $frontEndSubnetName `
    -AddressPrefix $frontEndAddressRange
$subnetBackEnd = New-AzureRmVirtualNetworkSubnetConfig -Name $managementSubnetName `
    -AddressPrefix $managementAddressRange
	
# Create virtual network and subnets
$newVnet = New-AzureRmVirtualNetwork -ResourceGroupName $rgName `
    -Location $Location `
    -Name $vNetName `
    -AddressPrefix $vNetAddressSpace1,$vNetAddressSpace2 `
    -Subnet $subnetFrontEnd,$subnetBackEnd
	
# Create two NICs
$frontEnd = $newVnet.Subnets | Where-Object {$_.Name -eq $frontEndSubnetName}
$Nic1 = New-AzureRmNetworkInterface -ResourceGroupName $rgName `
    -Name $frontEndNICName `
    -Location $Location `
    -SubnetId $frontEnd.Id

$backEnd = $newVnet.Subnets | Where-Object {$_.Name -eq $managementSubnetName}
$Nic2 = New-AzureRmNetworkInterface -ResourceGroupName $rgName `
    -Name $managementNICName `
    -Location $Location `
    -SubnetId $backEnd.Id

# Define Gold Image to be used
$image = Get-AzureRmImage -ImageName $vmImageName -ResourceGroupName $vmImageRG
	
# Set VM credentials
$cred = Get-Credential

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
$vmConfig = Set-AzureRmVMBootDiagnostics -VM $vmConfig -Enable -ResourceGroupName $diagRG -StorageAccountName $diagName

# Attach the two NICs
$vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $Nic1.Id -Primary
$vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $Nic2.Id

# Create virual network peerings
$peervNetConfigA = Get-AzureRmVirtualNetwork -Name $peervNetA -ResourceGroupName $peervNetAResourceGroup
$peervNetConfigB = Get-AzureRmVirtualNetwork -Name $peervNetB -ResourceGroupName $peervNetBResourceGroup
Add-AzureRmVirtualNetworkPeering -Name $PeerNamevNetAtoB -VirtualNetwork $peervNetConfigA -RemoteVirtualNetworkId $peervNetConfigB.Id -AllowForwardedTraffic
Add-AzureRmVirtualNetworkPeering -Name $PeerNamevNetBtoA -VirtualNetwork $peervNetConfigB -RemoteVirtualNetworkId $peervNetConfigA.Id -AllowForwardedTraffic -AllowGatewayTransit

# Get route table and add subnets
$routeTableConfig = Get-AzureRmRouteTable -ResourceGroupName $routeTableRG -Name $routeTableName
Set-AzureRmVirtualNetworkSubnetConfig -Name $frontEndSubnetName -VirtualNetwork $newVnet -AddressPrefix $frontEndAddressRange -RouteTableId $routeTableConfig.Id | Set-AzureRmVirtualNetwork
Set-AzureRmVirtualNetworkSubnetConfig -Name $managementSubnetName -VirtualNetwork $newVnet -AddressPrefix $managementAddressRange -RouteTableId $routeTableConfig.Id | Set-AzureRmVirtualNetwork

# Tell us we're deploying
Write-Host -ForegroundColor cyan "Deploying VM: $vmName with NICS, $frontEndNICName and $managementNICName"

# Create VM
New-AzureRmVM -VM $vmConfig -ResourceGroupName $rgName -Location $Location