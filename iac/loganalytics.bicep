@description('Prefix of the Log Analytics Workspace')
param laName string = 'log-dns-${uniqueString(resourceGroup().id)}'

@description('Location Variable')
var location = resourceGroup().location

@description('LogAnalytics Workspace as target for DNS logs')
resource loganalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: laName
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

@description('Enable syslogging for local5. coredns is configured to log to local5 to reduce noise of other services in log analytics')
resource syslog 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = {
  name: 'Sysloglocal5'
  parent: loganalytics
  kind: 'LinuxSyslog'
  properties: {
    syslogName: 'local5'
    syslogSeverities: [
      {
        severity: 'emerg'
      }
      {
        severity: 'alert'
      }
      {
        severity: 'crit'
      }
      {
        severity: 'err'
      }
      {
        severity: 'warning'
      }
      {
        severity: 'notice'
      }
      {
        severity: 'info'
      }
      {
        severity: 'debug'
      }
    ]
  }
}

@description('Log Analytics Workspace ID')
output laWorkspaceId string =  loganalytics.properties.customerId

@description('Log Analytics Key')
output laWorkspaceKey string = listKeys(loganalytics.id,'2020-08-01').primarySharedKey
