@description('Nameprefix for the Virtual Machine Scale Set')
param vmssName string = 'vmss-dns'

@description('Vm Size to be used by the Virtual Machine Scale set')
param vmSize string = 'Standard_B2s'

@description('Initial Instance Count.')
param instanceCount int = 3

@description('The Subnet to place the Virtual Machine Scale Set.')
param subnetId string

@description('Id of the Loadbalacners Backend')
param lbBackendId string

@description('adminUser for the VM')
param adminUser string

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Name for the Network Interface')
var nicname = 'nic-${vmssName}'

@description('Location variable')
var location = resourceGroup().location

@description('Linux configuration to disable Password login')
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUser}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

@description('Virtual Machine Scale Set resource')
resource dnsvmss 'Microsoft.Compute/virtualMachineScaleSets@2021-07-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    overprovision: true
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: {
          publisher: 'Debian'
          offer: 'debian-11'
          sku: '11-gen2'
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUser
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
        customData: loadFileAsBase64('cloud-init.txt')
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicname
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig01'
                  properties: {
                    subnet: {
                      id: subnetId
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: lbBackendId
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
  zones: [
    '1'
    '2'
    '3'
  ]
}
