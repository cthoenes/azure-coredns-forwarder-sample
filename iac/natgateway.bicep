@description('Name for the NAT Gateway Resource')
param gatewayname string = 'nat-dns'

@description('Public IP Name for NAT Gateway')
param pipname string = 'pip-nat-dns'

@description('Public IP to be used with NAT Gateway')
resource natpip 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: pipname
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

@description('NAT Gateway Resource to be used with DNS Servers')
resource natgw 'Microsoft.Network/natGateways@2021-03-01' = {
  name: gatewayname
  location: resourceGroup().location
  sku: {
     name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: natpip.id
      }
    ]
  }
}

@description('Output NAT Gateway id to be used in Subnet configuration')
output natgw string = natgw.id
