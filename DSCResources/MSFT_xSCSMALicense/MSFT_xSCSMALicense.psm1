# NOTE: This resource requires WMF5 and PsDscRunAsCredential

# DSC resource to manage SMA license.
# Runs on the SMA Web Service Server.

$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSCSMAHelper.psm1 -Verbose:$false -ErrorAction Stop

function ImportSMAModule
{
    try
    {
        if(!(Get-Module 'Microsoft.SystemCenter.ServiceManagementAutomation'))
        {
            Write-Verbose 'Importing Microsoft.SystemCenter.ServiceManagementAutomation module'
            $CurrentVerbose = $VerbosePreference
            $VerbosePreference = 'SilentlyContinue'
            Import-Module 'Microsoft.SystemCenter.ServiceManagementAutomation' -ErrorAction Stop
            $VerbosePreference = $CurrentVerbose
            $true
        }
        else
        {
            $true
        }
    }
    catch
    {
        $VerbosePreference = $CurrentVerbose
        Write-Verbose 'Failed importing Microsoft.SystemCenter.ServiceManagementAutomation module'
        $false
    }
}


function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$ProductKey
	)

    if(ImportSMAModule)
    {
        try
        {
            Write-Verbose "Getting license expiration date for SMA server $($env:COMPUTERNAME)"
            $SMALicenseExpirationDate = (Get-SmaLicense -WebServiceEndpoint "https://$($env:ComputerName)").ExpirationDate
            Write-Verbose "License expiration for SMA server $($env:COMPUTERNAME) is $SMALicenseExpirationDate"
            if(([DateTime]$SMALicenseExpirationDate - (Get-Date)).Days -le 180)
            {
                $Ensure = "Absent"
            }
            else
            {
                $Ensure = "Present"
            }
        }
        catch
        {
            Write-Verbose "Failed getting license expiration date for SMA server $($env:COMPUTERNAME)"
            $Ensure = "Absent"
        }
    }

    $returnValue = @{
        Ensure = $Ensure
	}

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$ProductKey
	)

    if(ImportSMAModule)
    {
        switch($Ensure)
        {
            "Present"
            {
                try
                {
                    Write-Verbose "Setting license for SMA server $($env:COMPUTERNAME)"
                    Set-SmaLicense -WebServiceEndpoint "https://$($env:ComputerName)" -ProductKey $ProductKey
                }
                catch
                {
                    Write-Verbose "Failed setting license for SMA server $($env:COMPUTERNAME)"
                }
            }
            "Absent"
            {
                throw New-TerminatingError -ErrorType AbsentNotImplemented -ErrorCategory NotImplemented
            }
        }
    }

    if(!(Test-TargetResource @PSBoundParameters))
    {
        Write-Verbose "Test-TargetResouce xSCSMA/XSCSMALicense failed after Set-TargetResource"
        # Note: No throw since we want to allow this resource to fail
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$ProductKey
	)

    $result = ((Get-TargetResource @PSBoundParameters).Ensure -eq $Ensure)

	$result
}


Export-ModuleMember -Function *-TargetResource