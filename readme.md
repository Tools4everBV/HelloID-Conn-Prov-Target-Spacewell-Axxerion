# HelloID-Conn-Prov-Target-Spacewell-Axxerion

| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.       |
<br />
<p align="center">
  <img src="https://www.tools4ever.nl/connector-logos/spacewellaxxerion-logo.png" width="500">
</p>

## Table of contents

- [Introduction](#Introduction)
- [Getting started](#Getting-started)
  + [Connection settings](#Connection-settings)
  + [Prerequisites](#Prerequisites)
  + [Remarks](#Remarks)
  + [Contents](#Contents)
- [Setup the connector](Setup-The-Connector)
- [Getting help](Getting-help)
- [Contributing](Contributing)
- [Code Contributors](Code-Contributors)

## Introduction

The _HelloID-Conn-Prov-Target-Spacewell-Axxerion_ is a facility management suite and provides a set of REST API's that allow you to programmatically interact with it's data.

## Getting started

### Connection settings

The following settings are required to connect to the API.

| Setting     | Description |
| ------------ | ----------- |
| Username     | The username of the user who has rights to access the API |
| Password    | The password for the user who has rights to access the API |
| BaseUrl | The URL to the Spaxewell Axxerion environment |
| Customer | The customer name. (This is the same name as the <customer> in the URL) |

### Prerequisites

> The _HelloID-Conn-Prov-Target-Spacewell-Axxerion connector is built for both Windows PowerShell 5.1 and PowerShell Core 7. This means the connector can be executed using the _On-Premises_ HelloID agent as well as in the cloud.

### Remarks

#### Create,Delete,Update,Enable,Disable,Grant,Revoke.ps1
All PowerShell files (apart from the 'entitlements.ps1' file) use a json body that has a datasource specified. For instance, the _create.ps1_ on line 66.

```powershell
    $body = @{
        datasource  = 'HelloID'
        clobMBValue = $clobMBValue
    } | ConvertTo-Json
```

This body is converted to JSON, since the full body that will be send to _Axxerion Spacewell_ must be a JSON containing a nested JSON string.
The _'datasource'_ is set to 'HelloID'.

#### Entitlements.ps1

The _entitlements.ps1_ also needs a body containing a nested JSON string. See line 43.

```powershell
    $body = @{
        "reference" = "[company_name]-HELLOID-GetGroups"
    } | ConvertTo-Json
```

This body contains a property called "reference" which must be set to __'[company_name]-HELLOID-GetGroups'__ the __[company_name]__ is different for each implementation. You will need to verify the correct name with your Axxerion consultant.

## Getting help

> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012557600-Configure-a-custom-PowerShell-source-system) pages_

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID Docs

The official HelloID documentation can be found at: https://docs.helloid.com/
