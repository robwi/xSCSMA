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
        $SMAModule = Get-SmaModule -Name $Name -WebServiceEndpoint "https://$($env:COMPUTERNAME)" -ErrorAction SilentlyContinue
    }
    catch
    {
        Write-Verbose "Failed getting SMA Module $($Name) from web service endpoint $($env:COMPUTERNAME)"
    }

    if($SMAModule)
    {
        $Ensure = "Present"

    }
    else
    {
        $Ensure = "Absent"
    }
    
	$returnValue = @{
		Ensure = $Ensure
		Name = $SMAModule.Name
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
		$Path

	)

    switch($Ensure)
    {
        "Present"
        {
            Write-Verbose "Updating $($Name) from SourcePath: $($Path)"
            Write-Verbose "Importing module... $($Path)\$($Name)"
            Import-SmaModule -Path $Path\$Name.zip -ErrorAction Stop -WebServiceEndpoint "https://$($env:COMPUTERNAME)"
        }
        "Absent"
        {
            Write-Verbose "Removing SMA Module $($Name) from web service endpoint $($env:COMPUTERNAME)"
            Remove-SmaModule -Name $Name -ErrorAction Stop -WebServiceEndpoint "https://$($env:COMPUTERNAME)"
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
		$Path

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
          if($SMATest.Module)
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