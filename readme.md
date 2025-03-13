# HelloID-Conn-Prov-Target-Spacewell-Axxerion-V2

> [!IMPORTANT]
> Spacewell Axxerion uses a generic User API which needs to be configured for each customer by an Spacewell consultant. Therefore this connector will **not work** out of the box without assistance from a Spacewell consultant and HelloID consultant

> [!WARNING]
> This connector has not been fully tested. Changes will have to be made according to the customer environment

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="https://www.tools4ever.nl/connector-logos/spacewellaxxerion-logo.png" width="500">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-Spacewell-Axxerion-V2](#helloid-conn-prov-target-spacewell-axxerion-v2)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
    - [Connection settings](#connection-settings)
    - [Correlation configuration](#correlation-configuration)
    - [Available lifecycle actions](#available-lifecycle-actions)
    - [Field mapping](#field-mapping)
  - [Remarks](#remarks)
    - [Correlation based on `email`.](#correlation-based-on-email)
    - [`id` returned when creating a user](#id-returned-when-creating-a-user)
    - [Error handling](#error-handling)
    - [Adding data using the `clobMBValue`](#adding-data-using-the-clobmbvalue)
      - [AccountGrant](#accountgrant)
      - [AccountUpdate](#accountupdate)
      - [AccountAccessGrant](#accountaccessgrant)
      - [AccountAccessRevoke](#accountaccessrevoke)
      - [EntitlementGrant](#entitlementgrant)
      - [EntitlementRevoke](#entitlementrevoke)
    - [Retrieving data](#retrieving-data)
      - [Retrieve user(s)](#retrieve-users)
      - [Retrieve permissions](#retrieve-permissions)
    - [API endpoints](#api-endpoints)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-Spacewell-Axxerion-V2_ is a _target_ connector. _Spacewell-Axxerion-V2_ provides a set of REST API's that allow you to programmatically interact with its data.

### Connection settings

The following settings are required to connect to the API.

| Setting       | Description                                                     |
| ------------- | --------------------------------------------------------------- |
| Username      | The username of the user who has rights to access the API       |
| Password      | The password for the user who has rights to access the API      |
| BaseUrl       | The URL to the Spaxewell Axxerion environment                   |

### Correlation configuration

The correlation configuration is used to specify which properties will be used to match an existing account within _Spacewell-Axxerion-V2_ to a person in _HelloID_.

| Setting                   | Value                                    |
| ------------------------- | ---------------------------------------- |
| Enable correlation        | `True`                                   |
| Person correlation field  | `Accounts.MicrosoftActiveDirectory.mail` |
| Account correlation field | `Email`                                  |

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

### Available lifecycle actions

The following lifecycle actions are available:

| Action                                  | Description                                                                     |
| --------------------------------------- | ------------------------------------------------------------------------------- |
| create.ps1                              | Creates a new account.                                                          |
| delete.ps1                              | Removes an existing account or entity.                                          |
| disable.ps1                             | Disables an account, preventing access without permanent removal.               |
| enable.ps1                              | Enables an account, granting access.                                            |
| update.ps1                              | Updates the attributes of an account.                                           |
| permissions/groups/grantPermission.ps1  | Grants specific permissions to an account.                                      |
| permissions/groups/revokePermission.ps1 | Revokes specific permissions from an account.                                   |
| permissions/groups/permissions.ps1      | Retrieves all available permissions.                                            |
| resources/groups/resources.ps1          | Manages resources, such as creating groups.                                     |
| configuration.json                      | Contains the connection settings and general configuration for the connector.   |
| fieldMapping.json                       | Defines mappings between person fields and target system person account fields. |

### Field mapping

The field mapping can be imported by using the _fieldMapping.json_ file.

## Remarks

### Correlation based on `email`.

The correlation is based on the `email` address. Since this is the only _unique_ key within Axxerion. When retrieving users, the field to filter on is the `externalReference`. See also: [retrieve users](#retrieve-users)

### `id` returned when creating a user

When creating a user an `id` will be returned. However this is __not__ the internal database `id` of the user but merely a reference to internal logging.

### Error handling

Error handling is limited because of limitions of the API. No errors are returned by the API as each response results in a '200OK' containing an `id`. This `id` is a reference to internal logging within Axxerion.

### Adding data using the `clobMBValue`

Each `POST` request to `rest/functions/createupdate/ImportItem` requires a `_clobMBValue_`, which holds the JSON payload for the corresponding action.

#### AccountGrant

- JSON payload

```json
{
    "username": "JDoe",
    "email": "jdoe@example",
    "first_name": "John",
    "last_name": "Doe"
}
```

- Full request including the `clobMBValue`

```json
{
    "datasource": "HelloID",
    "stringValue":"AccountGrant",
    "clobMBValue": "ew0KICAgICJ1c2VybmFtZSI6ICJKRG9lIiwNCiAgICAiZW1haWwiOiAiamRvZUBleGFtcGxlIiwNCiAgICAiZmlyc3RfbmFtZSI6ICJKb2huIiwNCiAgICAibGFzdF9uYW1lIjogIkRvZSINCn0="
}
```

#### AccountUpdate

- JSON payload

```json
{
    "username": "JDoe",
    "email": "jdoe@example",
    "first_name": "John",
    "last_name": "Doe"
}
```

- Full request including the `clobMBValue`

```json
{
    "datasource": "HelloID",
    "stringValue":"AccountUpdate",
    "clobMBValue": "ew0KICAgICJ1c2VybmFtZSI6ICJKRG9lIiwNCiAgICAiZW1haWwiOiAiamRvZUBleGFtcGxlIiwNCiAgICAiZmlyc3RfbmFtZSI6ICJKb2huIiwNCiAgICAibGFzdF9uYW1lIjogIkRvZSINCn0="
}
```

#### AccountAccessGrant

- JSON payload

```json
{
    "Email": "JDoe@example"
}
```

- Full request including the `clobMBValue`

```json
{
    "datasource": "HelloID",
    "stringValue": "AccountAccessGrant",
    "clobMBValue": "ew0KICAgICJFbWFpbCI6ICJKRG9lQGV4YW1wbGUiDQp9"
}
```

#### AccountAccessRevoke

- JSON payload

```json
{
    "Email": "JDoe@example"
}
```

- Full request including the `clobMBValue`

```json
{
    "datasource": "HelloID",
    "stringValue": "AccountAccessRevoke",
    "clobMBValue": "ew0KICAgICJFbWFpbCI6ICJKRG9lQGV4YW1wbGUiDQp9"
}
```

#### EntitlementGrant

- JSON payload

The `entitlement` is the `id` of the permission.

```json
{
    "email": "JDoe@example",
    "entitlement": "1510000000000002"
}
```

- Full request including the `clobMBValue`

```json
{
    "datasource": "HelloID",
    "stringValue":"EntitlementGrant",
    "clobMBValue": "ew0KICAgICJlbWFpbCI6ICJKRG9lQGV4YW1wbGUiLA0KICAgICJlbnRpdGxlbWVudCI6ICIxNTEwMDAwMDAwMDAwMDAyIg0KfQ=="
}
```

#### EntitlementRevoke

- JSON payload

The `entitlement` is the `id` of the permission.

```json
{
    "email": "JDoe@example",
    "entitlement": "1510000000000002"
}
```

- Full request including the `clobMBValue`

```json
{
    "datasource": "HelloID",
    "stringValue":"EntitlementRevoke",
    "clobMBValue": "ew0KICAgICJlbWFpbCI6ICJKRG9lQGV4YW1wbGUiLA0KICAgICJlbnRpdGxlbWVudCI6ICIxNTEwMDAwMDAwMDAwMDAyIg0KfQ=="
}
```

### Retrieving data

Data will need to be retrieved using a `POST` to  `rest/functions/completereportresult/`. The JSON payload must contain a _reference_ that corresponds to the action. The name of the _reference_ might be subject to change.

#### Retrieve user(s)

Retrieve a single user based on the `externalReference` which is mapped to the `email address`.

```json
{
	"reference":"HELLOID-USERS",
    "filterFields": [
        "externalReference"
    ],
    "filterValues": [
        "name@example"
    ]
}
```

#### Retrieve permissions

To retrieve permissions:

```json
{
	"reference":"HELLOID-PROFILES"
}
```

### API endpoints

The following endpoints are used by the connector

| Endpoint | Description               |
| -------- | ------------------------- |
| /rest/functions/completereportresult/  | Retrieve user and permission information |
| /rest/functions/createupdate/ImportItem/   | Create and update a user |

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
