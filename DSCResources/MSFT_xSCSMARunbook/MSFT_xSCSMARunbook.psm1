$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSCSMAHelper.psm1 -Verbose:$false -ErrorAction Stop

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path
	)

    try
    {
        $SMARunbook = Get-SmaRunbook -Name $Name -WebServiceEndpoint "https://$($env:COMPUTERNAME)" -ErrorAction SilentlyContinue
    }
    catch
    {
        Write-Verbose "Failed getting SMA Runbook $($Name) from web service endpoint $($env:COMPUTERNAME)"
    }
    
	if($SMARunbook)
    {
        $Ensure = "Present"
    }
    else
    {
        $Ensure = "Absent"
    }
    
	$returnValue = @{
		Ensure = $Ensure
		Name = $SMARunbook.Name
	}
	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

		[System.Boolean]
		$DisableVerboseLogging = $false
	)

    switch($Ensure)
    {
        "Present"
        {
            Write-Verbose "Updating $($Name) from SourcePath: $($Path)"
            Write-Verbose "Importing runbook ... $($Path)\$($Name).ps1"
            Import-SmaRunbook -Path $Path\$Name.ps1 -ErrorAction Stop -WebServiceEndpoint "https://$($env:COMPUTERNAME)"
            Write-Verbose "Publishing runbook ... $($Path)\$($Name.ps)"
            Publish-SmaRunbook -Name $Name -ErrorAction Stop -WebServiceEndpoint "https://$($env:COMPUTERNAME)"
            if( $DisableVerboseLogging -ne $true )
            {
                $runbook = Get-SmaRunbook -WebServiceEndpoint "https://$($env:COMPUTERNAME)" -Name $Name
                Set-SmaRunbookConfiguration -Id $runbook.RunbookId -LogVerbose $true -WebServiceEndpoint "https://$($env:COMPUTERNAME)"
            }
        }
        "Absent"
        {
            Write-Verbose "Removing SMA Runbook $($Name) from web service endpoint $($env:COMPUTERNAME)"
            Remove-SmaRunbook -Name $Name -ErrorAction Stop -WebServiceEndpoint "https://$($env:COMPUTERNAME)"
        }
    }

    if(!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

		[System.Boolean]
		$DisableVerboseLogging = $false
	)

	$SMATest = Get-TargetResource -Name $Name -Path $Path

    if($SMATest)
    {
        $result = $true
        if($SMATest.Ensure -ne $Ensure)
        {
            Write-Verbose "Failed test Ensure"
            $result = $false
        }
        if($Ensure -eq 'Present')
        {
          if($SMATest.Runbook)
          {
            $result = $true
          }
        }
    }
    else
    {
        $result = $false
    }
	$result
}

Export-ModuleMember -Function *-TargetResource