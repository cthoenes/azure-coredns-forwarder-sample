targetScope = 'subscription'

@description('Name for the Resource Group to deploy the sample')
param rgName string 

@description('Location for the sample Resources')
param location string 

@description('Adminusername for all VMs')
param adminUser string = 'azureuser'

@description('Admin Password for Windows Resolver')
@secure()
param adminPassword string

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

@description('SubnetId for DNS Server if you want to use a prexisting network.')
param dnsServerSubnetId string = ''

@description('SubnetId for DNS Server if you want to use a prexisting network.')
param resolverSubnetId string = ''

@description('SubnetId for DNS Server if you want to use a prexisting network.')
param bastionSubnetId string = ''

@description('The frontend IP for the internal loadbalancer if using a prexisting network.')
param loadBalancerFrontendIp string = ''

@description('The frontend IP for the internal loadbalancer if using a prexisting network.')
param vnetId string = ''

@description('Id of a preexisting Log Analytics Workspace')
param laWorkspaceId string = ''

@description('Resource ID of preexisting Log Analytics')
param laWorkspaceResourceId string = ''

@description('Variable to decide if preexisting network will be used')
var deployVirtualNetworkVariable = ((!empty(dnsServerSubnetId)) ? false : true)

@description('If subnet id is provieded take it. If not use the one created.')
var dnsServerSubnetIdVariable = ((!empty(dnsServerSubnetId)) ? dnsServerSubnetId : vnet.outputs.snetDNSServerId)

@description('If subnet id is provieded take it. If not use the one created.')
var resolverSubnetIdVariable = ((!empty(resolverSubnetId)) ? resolverSubnetId : vnet.outputs.snetResolverId)

@description('If subnet id is provieded take it. If not use the one created.')
var bastionSubnetIdVariable = ((!empty(bastionSubnetId)) ? bastionSubnetId : vnet.outputs.snetBastionId)

@description('Loadbalancer Frontend IP')
var loadBalancerFrontendIpVariable = ((!empty(loadBalancerFrontendIp)) ? loadBalancerFrontendIp : '10.0.0.200')

@description('Virtual Network')
var vnetIdVariable = ((!empty(vnetId)) ? vnetId : vnet.outputs.vnet)

@description('Varaiable for NAT Gateway to resolve dependecy')
var natGwVariable = ((deployVirtualNetworkVariable) ? natgw.outputs.natgw : '')

@description('Variable for Workspace ID')
var laWorkspaceIdVariable = ((!empty(laWorkspaceId)) ? laWorkspaceId : logAnalytics.outputs.laWorkspaceId)

@description('Variable for Workspace Key')
var laWorkspaceResourceIdVariable = ((!empty(laWorkspaceResourceId)) ? laWorkspaceResourceId : logAnalytics.outputs.laWorkspaceResourceId)

@description('')
resource dnsrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

@description('Module to deploy virtual network for the sample environment')
module vnet 'virtualnetwork.bicep' = if (deployVirtualNetworkVariable) {
  scope: dnsrg
  name: 'VirtualNetworkDeployment'
  params: {
    natgateway: natGwVariable
  }
}

@description('Module to deploy NAT Gateway for the DNS Servers')
module natgw 'natgateway.bicep' = if (deployVirtualNetworkVariable) {
  scope: dnsrg
  name: 'NATGatewayDeployment'
}

@description('Module to deploy Loadbalancer for the DNS Servers')
module loadbalancer 'loadbalancer.bicep' = {
  scope: dnsrg
  name: 'LoadbalancerDeployment'
  params: {
    subnetId: dnsServerSubnetIdVariable
    lbInternalIP: loadBalancerFrontendIpVariable
  }
}

@description('Module to deploy Scale Set of DNS Servers')
module dnsvmss 'dnsvmss.bicep' = {
  scope: dnsrg
  name: 'DNSVMSSDeployment'
  params: {
    adminUser: adminUser
    adminPasswordOrKey: publicKey
    subnetId: dnsServerSubnetIdVariable
    lbBackendId: loadbalancer.outputs.lbBackend
    laWorkspaceId: laWorkspaceIdVariable
    laWorkspaceResourceId: laWorkspaceResourceIdVariable
  }
}

@description('Module to deploy a VM to showcase differend resolution cases')
module resolvervm 'resolver.bicep' = if (deployResolver) {
  scope: dnsrg
  name: 'ResolverVMDeployment'
  params: {
    adminUser: adminUser
    adminPasswordOrKey: publicKey
    subnetId: resolverSubnetIdVariable
  }
}

@description('Module to deploy Azure Bastion to connect to the Resolver VM')
module bastion 'bastion.bicep' = if (deployBastion) {
  scope: dnsrg
  name: 'BastionDeployment'
  params: {
    subnetId: bastionSubnetIdVariable
  }
}

@description('Module to deploy Private DNS Zone needed for demonstration')
module privatezone 'privatednszone.bicep'  = if (deployPrivateZone) {
  scope: dnsrg
  name: 'PrivateDNSZoneDeployment'
  params: {
    vnetId: vnetIdVariable
  }
}

@description('Module to deploy Storage Account as an affected resource of the behaviour')
module storage 'storageaccount.bicep' = if (deployStorageAccount) {
  scope: dnsrg
  name: 'StorageDeployment'
  params: {
    subnetId: resolverSubnetIdVariable
  }
}

@description('Log Analytics module to enable VM Insights in VMSS')
module logAnalytics 'loganalytics.bicep' = {
  scope: dnsrg
  name: 'LogAnalyticsDeployment'
}

@description('Windows Server forwarder that would be preexisting in the hub')
module forwarder 'forwarder.bicep' = {
  scope: dnsrg
  name: 'DNSForwarderDeployment'
  params: {
    subnetId: dnsServerSubnetIdVariable
    adminUser: adminUser
    adminPasswordOrKey: adminPassword
    masterServerIp: loadBalancerFrontendIpVariable
  }
}
