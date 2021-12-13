targetScope = 'subscription'

@description('Name for the Resource Group to deploy the PoC')
param rgName string 

@description('Location for the PoC Resources')
param location string 

@description('Adminusername for all VMs')
param adminUser string = 'azureuser'

@description('Your public key to access the vms. If you dont have a key currently please review: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-ssh-keys-detailed')
param publicKey string 

@description('Decide if the Resolver VM needs to be deployed')
param deployResolver bool = true

@description('Decide if the Bastion needs to be deployed')
param deployBastion bool = true

@description('Decide if the Private DNS Zone needs to be deployed')
param deployPrivateZone bool = true

@description('Decide if the Storage Account needs to be deployed')
param deployStorageAccount bool = true

resource dnsrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

@description('Module to deploy virtual network for the PoC environment')
module vnet 'virtualnetwork.bicep' = {
  scope: dnsrg
  name: 'VirtualNetworkDeployment'
  params: {
    natgateway: natgw.outputs.natgw
  }
}

@description('Module to deploy NAT Gateway for the DNS Servers')
module natgw 'natgateway.bicep' = {
  scope: dnsrg
  name: 'NATGatewayDeployment'
}

@description('Module to deploy Loadbalancer for the DNS Servers')
module loadbalancer 'loadbalancer.bicep' = {
  scope: dnsrg
  name: 'LoadbalancerDeployment'
  params: {
    subnetId: vnet.outputs.snetDNSServerId
  }
}

@description('Module to deploy Scale Set of DNS Servers')
module dnsvmss 'dnsvmss.bicep' = {
  scope: dnsrg
  name: 'DNSVMSSDeployment'
  params: {
    adminUser: adminUser
    adminPasswordOrKey: publicKey
    subnetId: vnet.outputs.snetDNSServerId
    lbBackendId: loadbalancer.outputs.lbBackend
  }
}

@description('Module to deploy a VM to showcase differend resolution cases')
module resolvervm 'resolver.bicep' = if (deployResolver) {
  scope: dnsrg
  name: 'ResolverVMDeployment'
  params: {
    adminUser: adminUser
    adminPasswordOrKey: publicKey
    subnetId: vnet.outputs.snetResolverId
  }
}

@description('Module to deploy Azure Bastion to connect to the Resolver VM')
module bastion 'bastion.bicep' = if (deployBastion) {
  scope: dnsrg
  name: 'BastionDeployment'
  params: {
    subnetId: vnet.outputs.snetBastionId
  }
}

@description('Module to deploy Private DNS Zone needed for demonstration')
module privatezone 'privatednszone.bicep'  = if (deployPrivateZone) {
  scope: dnsrg
  name: 'PrivateDNSZoneDeployment'
  params: {
    vnetId: vnet.outputs.vnet
  }
}

@description('Module to deploy Storage Account as an affected resource of the behaviour')
module storage 'storageaccount.bicep' = if (deployStorageAccount) {
  scope: dnsrg
  name: 'StorageDeployment'
  params: {
    subnetId: vnet.outputs.snetResolverId
  }
}
