resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

resource "azurerm_template_deployment" "smallcidr" {
  name                = "SmallCidrNetworkFoundation"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

    # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters {
    "vnetName" = "RG-AZE-SPCLOUDPOC-01-VNET"

    "vnetAddressPrefix-MGMT" = "10.228.xx"

    "vnetAddressPrefix-APP" = "10.228.xx"

    "vnetAddressPrefix-DATA" = "10.228.xx"

    "vnetAddressPrefix-PRES" = "10.228.xx"

    "subnet1Name" = "SPCLOUDPOC-MGMT"

    "subnet1Prefix" = "10.228.xx"

    "subnet2Name" = "SPCLOUDPOC-APP"

    "subnet2Prefix" = "10.228.xx"

    "subnet3Name" = "SPCLOUDPOC-DATA"

    "subnet3Prefix" = "10.228.xx"

    "subnet4Name" = "SPCLOUDPOC-PRES"

    "subnet4Prefix" = "10.228.xx"
  }

  template_body = <<DEPLOY
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "vnetName": {
            "type": "string",
            "defaultValue": "vNET1",
            "metadata": {
                "description": "vNET name"
            }
        },
        "vnetAddressPrefix-MGMT": {
            "type": "string",
            "defaultValue": "10.0.0.0/16",
            "metadata": {
                "description": "MGMT prefix"
            }
        },
        "vnetAddressPrefix-APP": {
            "type": "string",
            "defaultValue": "10.0.0.0/16",
            "metadata": {
                "description": "APP prefix"
            }
        },
            "vnetAddressPrefix-DATA": {
            "type": "string",
            "defaultValue": "10.0.0.0/16",
            "metadata": {
                "description": "DATA prefix"
            }
        },
        "vnetAddressPrefix-PRES": {
            "type": "string",
            "defaultValue": "10.0.0.0/16",
            "metadata": {
                "description": "PRES prefix"
            }
        },
        "subnet1Prefix": {
            "type": "string",
            "defaultValue": "10.0.0.0/24",
            "metadata": {
                "description": "Subnet 1 Prefix"
            }
        },
        "subnet1Name": {
            "type": "string",
            "defaultValue": "Subnet1",
            "metadata": {
                "description": "MGMT - Subnet 1 Name"
            }
        },
        "subnet2Prefix": {
            "type": "string",
            "defaultValue": "10.0.1.0/24",
            "metadata": {
                "description": "Subnet 2 Prefix"
            }
        },
        "subnet2Name": {
            "type": "string",
            "defaultValue": "Subnet2",
            "metadata": {
                "description": "Application - Subnet 2 Name"
            }
        },
        "subnet3Prefix": {
            "type": "string",
            "defaultValue": "10.0.1.0/24",
            "metadata": {
                "description": "Subnet 3 Prefix"
            }
        },
        "subnet3Name": {
            "type": "string",
            "defaultValue": "Subnet3",
            "metadata": {
                "description": "Pres - Subnet 3 Name"
            }
        },
        "subnet4Prefix": {
            "type": "string",
            "defaultValue": "10.0.1.0/24",
            "metadata": {
                "description": "Subnet 4 Prefix"
            }
        },
        "subnet4Name": {
            "type": "string",
            "defaultValue": "Subnet4",
            "metadata": {
                "description": "Data - Subnet 4 Name"
            }
        }
    },
    "variables": {
        "apiVersion": "2015-06-15"
    },
    "resources": [{
        "apiVersion": "2015-06-15",
        "type": "Microsoft.Network/virtualNetworks",
        "name": "[parameters('vnetName')]",
        "location": "[resourceGroup().location]",
        "properties": {
            "addressSpace": {
                "addressPrefixes": [
                    "[parameters('vnetAddressPrefix-MGMT')]",
                    "[parameters('vnetAddressPrefix-APP')]",
                    "[parameters('vnetAddressPrefix-DATA')]",
                    "[parameters('vnetAddressPrefix-PRES')]"
                ]
            },
            "subnets": [{
                    "name": "[parameters('subnet1Name')]",
                    "properties": {
                        "addressPrefix": "[parameters('subnet1Prefix')]"
                    }
                },
                {
                    "name": "[parameters('subnet2Name')]",
                    "properties": {
                        "addressPrefix": "[parameters('subnet2Prefix')]"
                    }
                },
                {
                    "name": "[parameters('subnet3Name')]",
                    "properties": {
                        "addressPrefix": "[parameters('subnet3Prefix')]"
                    }
                },
                {
                    "name": "[parameters('subnet4Name')]",
                    "properties": {
                        "addressPrefix": "[parameters('subnet4Prefix')]"
                    }
                }
            ]
        }
    }]
}
DEPLOY

  deployment_mode = "Incremental"
}
