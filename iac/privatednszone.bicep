@description('The id of the vnet to attach the blob zone to.')
param vnetId string

@description('Location variable. In this case set to global as private zones are global')
var location = 'global'

@description('Private DNS Zone for blob')
resource blobPrivateZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: location
  properties: {
    
  }
}

@description('Vnet link to enable DNS Resolvers for privatelink resolution')
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'dnslink'
  parent: blobPrivateZone
  location: location
  properties: {
    registrationEnabled: false 
    virtualNetwork: {
      id: vnetId
    }
  }
}

@description('ID of the private zone to be used in further deployments')
output blobPrivateZoneId string = blobPrivateZone.id
