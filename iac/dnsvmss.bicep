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

param laWorkspaceResourceId string

@description('Log Analytice Workspace ID')
param laWorkspaceId string

@description('Get Key for LogAnalytics Workspace')
var laWorkspaceKey = listKeys(laWorkspaceResourceId,'2020-08-01').primarySharedKey

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

@description('Name for the Log Analytics Extension')
var extensionNameLogAnalytics = 'LogAnalyticsExtension'

@description('Name for the Log Analytics Extension')
var extensionNameDependecyAgent = 'DependencyAgentExtension'

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
    overprovision: false
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
          publisher: 'canonical'
          offer: '0001-com-ubuntu-server-focal'
          sku: '20_04-lts-gen2'
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
      extensionProfile: {
        extensions: [
          {
            name: extensionNameDependecyAgent
            properties: {
              publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
              type: 'DependencyAgentLinux'
              typeHandlerVersion: '9.5'
              autoUpgradeMinorVersion: true
              enableAutomaticUpgrade: true
            }
          }
          {
            name: extensionNameLogAnalytics
            properties: {
              publisher: 'Microsoft.EnterpriseCloud.Monitoring'
              type: 'OmsAgentForLinux'
              typeHandlerVersion: '1.4'
              autoUpgradeMinorVersion: true
              settings: {
                workspaceId: laWorkspaceId
                stopOnMultipleConnections: 'true'
              }
              protectedSettings: {
                workspaceKey: laWorkspaceKey
              }
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
