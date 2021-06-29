##########################################################
# HelloID-Conn-Prov-Target-Spacewell-Axxerion-Disable
#
# Version: 1.0.0.0
##########################################################
$VerbosePreference = "Continue"

# Initialize default value's
$c = $configuration | ConvertFrom-Json
$aRef = $accountReference | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$success = $false
$auditLogs = New-Object Collections.Generic.List[PSCustomObject]

$account = [PSCustomObject]@{
    id           = $p.ExternalId
    userName     = $p.ExternalId
    givenName    = $p.Name.GivenName
    familyName   = $p.Name.FamilyName
    emailAddress = $p.Contact.Business.Email
}

#region helper functions
function Resolve-HTTPError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline
        )]
        [object]$ErrorObject
    )
    process {
        $HttpErrorObj = @{
            FullyQualifiedErrorId = $ErrorObject.FullyQualifiedErrorId
            InvocationInfo        = $ErrorObject.InvocationInfo.MyCommand
            TargetObject          = $ErrorObject.TargetObject.RequestUri
            StackTrace            = $ErrorObject.ScriptStackTrace
        }
        if ($ErrorObject.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') {
            $HttpErrorObj['ErrorMessage'] = $ErrorObject.ErrorDetails.Message
        } elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            $stream = $ErrorObject.Exception.Response.GetResponseStream()
            $stream.Position = 0
            $streamReader = New-Object System.IO.StreamReader $Stream
            $errorResponse = $StreamReader.ReadToEnd()
            $HttpErrorObj['ErrorMessage'] = $errorResponse
        }
        Write-Output $HttpErrorObj
    }
}
#endregion

if (-not($dryRun -eq $true)) {
    try {
        Write-Verbose "Disabling Axxerion user '$($p.DisplayName)'"
        $clobMBValue = @{
            action = 'Account Access Revoke'
            body = @{
                id = $account.id
            }
        } | ConvertTo-Json

        $Body = @{
            datasource  = 'HelloID'
            clobMBValue = $clobMBValue
        } | ConvertTo-Json

        $authorization = "$($c.UserName):$($c.Password)"
        $base64Credentials = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($authorization))
        $headers = @{
            "Authorization" = "Basic $base64Credentials"
        }

        $splatParams = @{
            Uri     = "$($c.BaseUrl)/webservices/$($c.Customer)/rest/functions/createupdate/ImportItem"
            Body    = $body
            Headers = $headers
            Method  = 'POST'
        }
        $disableResponse = Invoke-RestMethod @splatParams
        if ($disableResponse.response -eq 'none'){
            $success = $false
            $auditLogs.Add([PSCustomObject]@{
                Action  = 'DisableAccount'
                Message = $disableResponse.errorMessage
                IsError = $true
            })
        } elseif ($disableResponse.id){
            $success = $true
            $auditLogs.Add([PSCustomObject]@{
                Message = "Account for '$($p.DisplayName)' successfully disabled with id: '$($aRef)'"
                IsError = $false
            })
        }
    } catch {
        $ex = $PSItem
        $success = $false
        if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
            $errorObject = Resolve-HTTPError -Error $ex
            $auditMessage = "Could not disable user account for '$($p.DisplayName)', Error $($errorObject.ErrorMessage)"
        } else {
            $auditMessage = "Could not disable user account for '$($p.DisplayName)', Error: $($ex.Exception.Message)"
        }
        $auditLogs.Add([PSCustomObject]@{
            Action  = "DisableAccount"
            Message = $auditMessage
            IsError = $true
        })
        Write-Verbose $auditLogs.Message
    }
}

$result = [PSCustomObject]@{
    Success   = $success
    Account   = $account
    AuditLogs = $auditLogs
}

Write-Output $result | ConvertTo-Json -Depth 10
