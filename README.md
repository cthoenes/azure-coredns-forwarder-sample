# Azure DNS Resolver Sample

## TL,DR
This repository can be used to deploy a sample of a highly available DNS resolver that is capable of resolving public IP addresses of private endpoint enabled resources that are not connected to corpnet. This is to overcome the behavior described in [https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns):
> Private networks already using the private DNS zone for a given type, can only connect to public resources if they don't have any private endpoint connections, otherwise a corresponding DNS configuration is required on the private DNS zone in order to complete the DNS resolution sequence. 

<br>

## Deployment
There are multiple Options to deploy this Sample.

### Option 1 - Use "Deploy to Azure" Button

You can use this "Deploy to Azure" butten to create the Sample environment in your subscription:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fgithub.com%2Fcthoenes%2Fazure-coredns-forwarder-poc%2Freleases%2Flatest%2Fdownload%2Fmain.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>

<br>

### Option 2 - Use Azure CLI
You can deploy the Sample using a Azure CLI deployment to your subscription

To Do so please clone the repository and create a parameter file for your deployment looking similar to this example:

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "rgName": {
        "value": "<resourceGroupName>"
      },
      "location": {
        "value": "<yourPreferredLocation>"
      },
      "adminUser": {
        "value": "azureuser"
      },
      "publicKey": {
        "value": "<sshPublicKey>"
      },
      "deployBastion": {
        "value": true
      },
      "deployResolver": {
        "value": true
      },
      "deployPrivateZone": {
        "value": true
      },
      "deployStorageAccount": {
        "value": true
      }
    }
  }
````
Afterward you can use AZ CLI to deploy to your Subscription. Make sure you are logged on and the correct subscription is set.

```shell
az deployment sub create --location <yourPreferredLocation> --template-file ./iac/main.bicep --parameters @parameterFile.json
```