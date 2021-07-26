##########################################################
# HelloID-Conn-Prov-Target-Spacewell-Axxerion-Entitlements
#
# Version: 1.0.0.0

# Make sure you update rownr 47! -> [Customer]

##########################################################
$VerbosePreference = "Continue"

# Initialize default value's
$c = $configuration | ConvertFrom-Json

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

try {
    Write-Verbose 'Retrieving Axxerion permissions'
    $body = @{
        "reference" = "[company_name]-HELLOID-GetGroups"
    } | ConvertTo-Json

    $authorization = "$($c.UserName):$($c.Password)"
    $base64Credentials = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($authorization))
    $headers = @{
        "Authorization" = "Basic $base64Credentials"
    }

    $splatParams = @{
        Uri     = "$($c.BaseUrl)/webservices/$($c.Customer)/rest/functions/completereportresult/"
        Body = $body
        Headers = $headers
        Method  = 'POST'
    }
    $groupsResponse = Invoke-RestMethod @splatParams
    $permissions = [System.Collections.Generic.List[object]]::new()
    foreach ($group in $groupsResponse.data){
        $permission = @{
            DisplayName = $group.UserGroupName
            Identification = @{
                UserGroupId  = $group.UserGroupId
                Id           = $group.id
                ObjectNameId = $group.objectNameId
            }
        }
        $permissions.add($permission)
    }
    Write-Output $permissions | ConvertTo-Json
} catch {
    $ex = $PSItem
    if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObject = Resolve-HTTPError -Error $ex
        $auditMessage = "Could not retrieve permissions '$($p.DisplayName)', Error $($errorObject.ErrorMessage)"
    } else {
        $auditMessage = "Could not retrieve permissions '$($p.DisplayName)', Error: $($ex.Exception.Message)"
    }
    Write-Verbose $auditMessage
}
