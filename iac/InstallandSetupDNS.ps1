#Install and Confgure DNS Server
[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $MasterServer = "10.0.0.200"
)

Install-WindowsFeature -Name DNS -IncludeManagementTools
Add-DNSServerForwarder -IPAddress 1.1.1.1
Add-DnsServerConditionalForwarderZone -Name "blob.core.windows.net" -MasterServers $MasterServer