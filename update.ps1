#################################################
# HelloID-Conn-Prov-Target-Spacewell-Axxerion-V2-Update
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
function Resolve-Spacewell-Axxerion-V2Error {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            ScriptLineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
            Line             = $ErrorObject.InvocationInfo.Line
            ErrorDetails     = $ErrorObject.Exception.Message
            FriendlyMessage  = $ErrorObject.Exception.Message
        }
        if (-not [string]::IsNullOrEmpty($ErrorObject.ErrorDetails.Message)) {
            $httpErrorObj.ErrorDetails = $ErrorObject.ErrorDetails.Message
        } elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            if ($null -ne $ErrorObject.Exception.Response) {
                $streamReaderResponse = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
                if (-not [string]::IsNullOrEmpty($streamReaderResponse)) {
                    $httpErrorObj.ErrorDetails = $streamReaderResponse
                }
            }
        }
        try {
            $errorDetailsObject = ($httpErrorObj.ErrorDetails | ConvertFrom-Json)
            # Make sure to inspect the error result object and add only the error message as a FriendlyMessage.
            # $httpErrorObj.FriendlyMessage = $errorDetailsObject.message
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails # Temporarily assignment
        } catch {
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails
        }
        Write-Output $httpErrorObj
    }
}
#endregion

try {
    # Verify if [aRef] has a value
    if ([string]::IsNullOrEmpty($($actionContext.References.Account))) {
        throw 'The account reference could not be found'
    }

    Write-Information 'Creating authentication headers'
    $headers = [System.Collections.Generic.Dictionary[string, string]]::new()
    $headers.Add("Authorization", "Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($actionContext.Configuration.UserName):$($actionContext.Configuration.Password)")))")

    Write-Information 'Verifying if a Spacewell-Axxerion-V2 account exists'
    $splatCompleterReportResultFunction = @{
        Uri     = "$($actionContext.Configuration.BaseUrl)/webservices/$($actionContext.Configuration.OrganizationReference)/rest/functions/completereportresult"
        Method  = 'POST'
        Body    = [PSCustomObject]@{
            reference    = $actionContext.Configuration.UserReference
            filterFields = @('externalReference')
            filterValues = @("$($actionContext.References.Account)")
        } | ConvertTo-Json -Depth 10
        Headers = $headers
    }
    $correlatedAccount = Invoke-RestMethod @splatCompleterReportResultFunction

    # Always compare the account against the current account in target system
    if ($null -ne $correlatedAccount) {
        $splatCompareProperties = @{
            ReferenceObject  = @($correlatedAccount.PSObject.Properties)
            DifferenceObject = @($actionContext.Data.PSObject.Properties)
        }
        $propertiesChanged = Compare-Object @splatCompareProperties -PassThru | Where-Object { $_.SideIndicator -eq '=>' }
        if ($propertiesChanged) {
            $action = 'UpdateAccount'
        } else {
            $action = 'NoChanges'
        }
    } else {
        $action = 'NotFound'
    }

    # Process
    switch ($action) {
        'UpdateAccount' {
            if (-not($actionContext.DryRun -eq $true)) {
                Write-Information "Updating Spacewell-Axxerion-V2 account with accountReference: [$($actionContext.References.Account)]"
                $actionContext.Data.email = $actionContext.References.Account
                $actionContextDataJson = $actionContext.Data | ConvertTo-Json
                $accountObjBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($actionContextDataJson))
                $splatUpdateParams = @{
                    Uri         = "$($actionContext.Configuration.BaseUrl)/webservices/$($actionContext.Configuration.OrganizationReference)/rest/functions/createupdate/ImportItem"
                    Method      = 'POST'
                    Body        = @{
                        datasource  = 'HelloID'
                        stringValue = 'AccountUpdate'
                        clobMBValue = $accountObjBase64
                    } | ConvertTo-Json -Depth 10
                    Headers     = $headers
                    ContentType = 'application/json'
                }
                $updatedAccount = Invoke-RestMethod @splatUpdateParams
                $outputContext.Data = $updatedAccount

                $outputContext.success = $true
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Action  = $action
                        Message = "Updated account with AccountReference: $($outputContext.AccountReference | ConvertTo-Json)."
                        IsError = $false
                    })
            } else {
                Write-Information "[DryRun] Update Spacewell-Axxerion-V2 account with accountReference: [$($actionContext.References.Account)], will be executed during enforcement"
            }
        }
        'NotFound' {
            Write-Information "Spacewell-Axxerion-V2 account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = "Spacewell-Axxerion-V2 account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
                    IsError = $false
                })
            break
        }
    }
} catch {
    $outputContext.Success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-Spacewell-Axxerion-V2Error -ErrorObject $ex
        $auditMessage = "Could not update Spacewell-Axxerion-V2 account. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    } else {
        $auditMessage = "Could not update Spacewell-Axxerion-V2 account. Error: $($ex.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
}