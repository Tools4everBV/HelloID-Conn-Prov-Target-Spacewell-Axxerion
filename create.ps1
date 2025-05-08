#######################################################
# HelloID-Conn-Prov-Target-Spacewell-Axxerion-V2-Create
# PowerShell V2
#######################################################

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
        }         catch {
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails
        }
        Write-Output $httpErrorObj
    }
}
#endregion

try {
    # Initial Assignments
    $outputContext.AccountReference = 'Currently not available'

    Write-Information 'Creating authentication headers'
    $headers = [System.Collections.Generic.Dictionary[string, string]]::new()
    $headers.Add("Authorization", "Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$($actionContext.Configuration.UserName):$($actionContext.Configuration.Password)")))")    

    # Validate correlation configuration
    if ($actionContext.CorrelationConfiguration.Enabled) {
        $correlationField = $actionContext.CorrelationConfiguration.AccountField
        $correlationValue = $actionContext.CorrelationConfiguration.PersonFieldValue

        if ([string]::IsNullOrEmpty($($correlationField))) {
            throw 'Correlation is enabled but not configured correctly'
        }
        if ([string]::IsNullOrEmpty($($correlationValue))) {
            throw 'Correlation is enabled but [accountFieldValue] is empty. Please make sure it is correctly mapped'
        }

        Write-Information 'Determine if a user needs to be created or correlated'
        $splatCompleterReportResultFunction = @{            
            Uri     = "$($actionContext.Configuration.BaseUrl)/webservices/$($actionContext.Configuration.OrganizationReference)/rest/functions/completereportresult"
            Method  = 'POST'
            Body    = [PSCustomObject]@{                
                reference    = $actionContext.Configuration.UserReference
                filterFields = @("externalReference")
                filterValues = @("$correlationValue")
            } | ConvertTo-Json -Depth 10
            Headers = $headers
        }
        $correlatedAccount = Invoke-RestMethod @splatCompleterReportResultFunction        
    }

    if ($correlatedAccount.data.count -eq 1) {
        $action = 'CorrelateAccount'
    } elseif ($correlatedAccount.data.count -eq 0) {
        $action = 'CreateAccount'
    } else {
        throw "Multiple accounts found with: [$($correlationValue)]. Please correct this to ensure the correlation results in a single unique account."
    }

    # Process
    switch ($action) {
        'CreateAccount' {
            if (-not($actionContext.DryRun -eq $true)) {
                Write-Information 'Creating and correlating Spacewell-Axxerion-V2 account'
                $actionContextDataJson = $actionContext.Data | ConvertTo-Json                
                $accountObjBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($actionContextDataJson))
                $splatCreateParams = @{
                    Uri         = "$($actionContext.Configuration.BaseUrl)/webservices/$($actionContext.Configuration.OrganizationReference)/rest/functions/createupdate/ImportItem"
                    Method      = 'POST'
                    Body        = @{
                        datasource  = 'HelloID'
                        stringValue = 'AccountGrant'
                        clobMBValue = $accountObjBase64
                    } | ConvertTo-Json -Depth 10
                    Headers     = $headers
                    ContentType = 'application/json'
                }
                $null = Invoke-RestMethod @splatCreateParams

                Write-Information 'Determine if a user is created'
                $splatCompleterReportResultFunction = @{
                    Uri     = "$($actionContext.Configuration.BaseUrl)/webservices/$($actionContext.Configuration.OrganizationReference)/rest/functions/completereportresult"
                    Method  = 'POST'
                    Body    = [PSCustomObject]@{
                        reference    = $actionContext.Configuration.UserReference
                        filterFields = @("externalReference")
                        filterValues = @("$correlationValue")
                    } | ConvertTo-Json -Depth 10
                    Headers = $headers
                }
                $createdAccount = Invoke-RestMethod @splatCompleterReportResultFunction
                
                if ($createdAccount.data.count -eq 1) {
                    $outputContext.Data = $createdAccount.data
                    $outputContext.AccountReference = $createdAccount.data.Email
                } else {
                    throw 'Spacewell-Axxerion-V2 account could not be created'
                }
            } else {
                Write-Information '[DryRun] Create and correlate Spacewell-Axxerion-V2 account, will be executed during enforcement'
            }
            $auditLogMessage = "Create account was successful. AccountReference is: [$($outputContext.AccountReference)]"
            break
        }

        'CorrelateAccount' {
            Write-Information 'Correlating Spacewell-Axxerion-V2 account'
            $outputContext.Data = $correlatedAccount.data
            $outputContext.AccountReference = $correlatedAccount.data.Email
            $outputContext.AccountCorrelated = $true
            $auditLogMessage = "Correlated account: [$($outputContext.AccountReference)] on field: [$($correlationField)] with value: [$($correlationValue)]"
            break
        }
    }

    $outputContext.success = $true
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Action  = $action
            Message = $auditLogMessage
            IsError = $false
        })
} catch {    
    $outputContext.success = $false
    $ex = $PSItem    
    
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-Spacewell-Axxerion-V2Error -ErrorObject $ex
        $auditMessage = "Could not create or correlate Spacewell-Axxerion-V2 account. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    } else {
        $auditMessage = "Could not create or correlate Spacewell-Axxerion-V2 account. Error: $($ex.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
}