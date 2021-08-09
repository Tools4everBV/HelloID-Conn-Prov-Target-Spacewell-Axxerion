##########################################################
# HelloID-Conn-Prov-Target-Spacewell-Axxerion-Update
#
# Version: 1.0.0.0
##########################################################
$VerbosePreference = "Continue"

# Initialize default value's
$c = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$success = $false
$auditLogs = New-Object Collections.Generic.List[PSCustomObject]

$prefix = ""
if(-Not([string]::IsNullOrEmpty($p.Name.FamilyNamePrefix)))
{
    $prefix = $p.Name.FamilyNamePrefix + " "
}

$partnerprefix = ""
if(-Not([string]::IsNullOrEmpty($p.Name.FamilyNamePartnerPrefix)))
{
    $partnerprefix = $p.Name.FamilyNamePartnerPrefix + " "
}

switch($p.Name.Convention)
{
    "B" {$surname += $p.Name.FamilyName; $AxPrefix = $prefix}
    "P" {$surname += $p.Name.FamilyNamePartner; $AxPrefix = $partnerprefix}
    "BP" {$surname += $p.Name.FamilyName + " - " + $partnerprefix + $p.Name.FamilyNamePartner; $AxPrefix = $prefix}
    "PB" {$surname += $p.Name.FamilyNamePartner + " - " + $prefix + $p.Name.FamilyName ; $AxPrefix = $partnerprefix}
    default {$surname += $p.Name.FamilyName; $AxPrefix = $prefix}
}


$email = $p.Accounts.MicrosoftActiveDirectory.Mail
$account = [PSCustomObject]@{
    id           = $p.ExternalId;
    userName     = $p.ExternalId;
    givenName    = $p.Name.Nickname;
    familyName   = $surname;
    prefix          = $AxPrefix;
    cost_center =  $P.PrimaryContract.CostCenter.Name
    job_title = $p.PrimaryContract.Title.Name;
    emailAddress = $email;
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
        Write-Verbose "Updating Axxerion user '$($p.DisplayName)'"
        $clobMBValue = @{
            action = 'Account Update'
            body = @{
                id         = $account.id;
                username   = $account.userName;
                email      = $account.emailAddress;
                first_name = $account.givenName;
                last_name  = $account.familyName;
                prefix      = $account.prefix;
                cost_center = $account.cost_center;
                job_title = $account.job_title;
            }
        } | ConvertTo-Json

        $body = @{
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
            Body    = ([System.Text.Encoding]::UTF8.GetBytes($body))
            Headers = $headers
            Method  = 'POST'
        }
        $updateResponse = Invoke-RestMethod @splatParams
        if ($updateResponse.id){
            $success = $true
            $auditLogs.Add([PSCustomObject]@{
                Action  = "UpdateAccount"
                Message = "Account for '$($p.DisplayName)' successfully updated"
                IsError = $false
            })
        }
    } catch {
        $ex = $PSItem
        $success = $false
        if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
            $errorObject = Resolve-HTTPError -Error $ex
            $auditMessage = "Could not update user account for '$($p.DisplayName)', Error $($errorObject.ErrorMessage)"
        } else {
            $auditMessage = "Could not update user account for '$($p.DisplayName)', Error: $($ex.Exception.Message)"
        }
        $auditLogs.Add([PSCustomObject]@{
            Action  = "UpdateAccount"
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
    
        ExportData = [PSCustomObject]@{
        displayName = $account.id;
        userName = $account.id;
        email = $account.emailAddress;
    };
}

Write-Output $result | ConvertTo-Json -Depth 10
