@description('Name for the Internal Loadbalancer Resource')
param lbName string = 'lb-dns'

@description('Loadbalacner Subner')
param subnetId string

@description('Static internal IP for Load Balancer Frontend')
param lbInternalIP string

@description('Location variable')
var location = resourceGroup().location

@description('Loadbalancer Resource with DNS Rule and Backend configuration')
resource loadBalancer 'Microsoft.Network/loadBalancers@2020-06-01' = {
  name: lbName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAddress: lbInternalIP
          privateIPAllocationMethod: 'Static'
        }
        name: 'DNSLBIP'
      }
    ]
    backendAddressPools: [
      {
        name: 'DNSServerVMSS'
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', lbName, 'DNSLBIP')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, 'DNSServerVMSS')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, 'ReadyProbe')
          }
          protocol: 'Tcp'
          frontendPort: 53
          backendPort: 53
          idleTimeoutInMinutes: 15
        }
        name: 'DNS-TCP'
      }
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', lbName, 'DNSLBIP')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, 'DNSServerVMSS')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, 'ReadyProbe')
          }
          protocol: 'Udp'
          frontendPort: 53
          backendPort: 53
          idleTimeoutInMinutes: 15
        }
        name: 'DNS-UDP'
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Http'
          port: 8181
          requestPath: '/ready'
          intervalInSeconds: 15
          numberOfProbes: 2
        }
        name: 'ReadyProbe'
      }
    ]
  }
}

@description('Output to be used in VMSS creation')
output lbBackend string = loadBalancer.properties.backendAddressPools[0].id
