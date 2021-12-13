@description('Storage Account Name including random string to be unique')
param storageAccountName string = 'st${uniqueString(resourceGroup().id)}'

@description('Name for the private Endpoint')
param peName string = 'pe-blob'

@description('Subnet for the Private Endpoint')
param subnetId string 

@description('Location Variable')
var location = resourceGroup().location

@description('Storage Account to showcase the behavior')
resource sa 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

@description('Private Endpoint resource')
resource pe 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: peName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'peblob'
        properties: {
          privateLinkServiceId: sa.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}
