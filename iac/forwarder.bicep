@description('Name of the forwarder VM')
param vmName string = 'vm-forwarder'

@description('Admin username')
param adminUser string

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('The size of the VM')
param vmSize string = 'Standard_B2s'

@description('The subnet to assign the dnsserver to.')
param subnetId string

@description('IP Address if the Master server to be added to the conditional forwarder')
param masterServerIp string 

@description('Name for the NIC')
var networkInterfaceName = 'nic-${vmName}'

@description('Location Variable')
var location = resourceGroup().location

@description('Type for the OS Disk')
var osDiskType = 'Standard_LRS'

@description('Uri to the Powershell script')
param virtualMachineExtensionCustomScriptUri string = 'https://raw.githubusercontent.com/cthoenes/azure-coredns-forwarder-sample/main/iac/InstallandSetupDNS.ps1'


@description('Forwarder VMs NIC')
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
          privateIPAddress: '10.0.0.150'
          privateIPAllocationMethod: 'Static'
        }
      }
    ]
  }
}

@description('Resolver VM to showcase the different resolution behaviours')
resource forwardervm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
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
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter-g2'
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
    }
  }
}

@description('Config for Custom script extension')
var virtualMachineExtensionCustomScript = {
  name: '${forwardervm.name}/config-app'
  location: location
  fileUris: [
    virtualMachineExtensionCustomScriptUri
  ]
  commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ./${last(split(virtualMachineExtensionCustomScriptUri, '/'))} -MasterServer ${masterServerIp}'
}

@description('Custom script extension to install and configure DNS Server')
resource vmext 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: virtualMachineExtensionCustomScript.name
  location: virtualMachineExtensionCustomScript.location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: virtualMachineExtensionCustomScript.fileUris
      commandToExecute: virtualMachineExtensionCustomScript.commandToExecute
    }
    protectedSettings: {}
  }
}

