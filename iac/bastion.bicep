@description('Name for the Azure Bastion Service')
param bastionName string = 'bastion-dns'

@description('Name of the Public IP attached to the Bastion Host')
param pipName string = 'pip-bastion'

@description('Id of the AzureBationSubnet')
param subnetId string

@description('Location Variable')
var location = resourceGroup().location

@description('Public IP Resource to be used with Azure Bastion')
resource bastionpip 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: pipName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

@description('Azure Bastion Host to connect to resolver VM')
resource bastion 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: bastionName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    disableCopyPaste: false 
    enableFileCopy: true
    enableIpConnect: true 
    enableTunneling: true
    ipConfigurations: [
      {
        name: 'IpConfig01'
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: bastionpip.id
          }
        }
      }
    ]
  }
}
