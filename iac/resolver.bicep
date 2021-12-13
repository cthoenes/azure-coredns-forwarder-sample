@description('Name of the VM used as a test client.')
param vmName string = 'vm-resolver'

@description('adminUser for this VM to be used with SSH')
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

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  '18.04-LTS'
])
param ubuntuOSVersion string = '18.04-LTS'

@description('The size of the VM')
param vmSize string = 'Standard_B2s'

@description('The subnet to assign the test client to.')
param subnetId string

@description('Name for the NIC')
var networkInterfaceName = 'nic-${vmName}'

@description('Location Variable')
var location = resourceGroup().location

@description('Type for the OS Disk')
var osDiskType = 'Standard_LRS'

@description('Liniux configuration to disable password login')
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

@description('Resolver VMs NIC')
resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

@description('Resolver VM to showcase the different resolution behaviours')
resource resolvervm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: vmName
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUser
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
  }
}
