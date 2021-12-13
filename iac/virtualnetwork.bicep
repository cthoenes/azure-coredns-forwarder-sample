@description('Name for the vnet to be created')
param vnetname string = 'vnet-dns'

@description('Name of the Network Security Group')
param nsgname string = 'nsg-dns'

@description('Addressspaces for the vnet to be created')
param addressprefixes array = [
  '10.0.0.0/24'
]

@description('Subnet CIDR for the Resolver VM')
param snresolverprefix string = '10.0.0.0/26'

@description('Subnet CIDR for the Resolver VM')
param snbastionprefix string = '10.0.0.64/26'

@description('Subnet CIDR For DNS Resolver VMSS and Loadbalancer')
param sndnsserverprefix string = '10.0.0.128/25'

@description('ID of the NAT Gateway to be used by th VMSS to connect to the Internet')
param natgateway string

@description('Location variable')
var location = resourceGroup().location

@description('Network Securtiy Group to be added to the subnets')
resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: nsgname
  location: location
  properties: {
    securityRules: [

    ]
  }
}

@description('Virtual network for PoC environment')
resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: vnetname
  location: location
  properties: {
      addressSpace: {
        addressPrefixes: addressprefixes
      }
      subnets: [
        {
          name: 'ResolverSubnet' 
          properties: {
            addressPrefix: snresolverprefix
            privateEndpointNetworkPolicies: 'Disabled'
            privateLinkServiceNetworkPolicies: 'Enabled'
            networkSecurityGroup: {
              id: nsg.id
            }
          }
        }
        {
          name: 'AzureBastionSubnet' 
          properties: {
            addressPrefix: snbastionprefix
          }
        }
        {
          name: 'DNSSubnet'
          properties: {
            addressPrefix: sndnsserverprefix
            natGateway: {
              id: natgateway
            }
            networkSecurityGroup: {
              id: nsg.id
            }
          }
        }
      ]
  }
}

@description('Output vnet ID to be used by other modules')
output vnet string = vnet.id

@description('Subnet for the Resolver VM')
output snetResolverId string = vnet.properties.subnets[0].id

@description('Subnet for Azure Bastion')
output snetBastionId string = vnet.properties.subnets[1].id

@description('Subnet to be used by DNS Servers')
output snetDNSServerId string = vnet.properties.subnets[2].id
