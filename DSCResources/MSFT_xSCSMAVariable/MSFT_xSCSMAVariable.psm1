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
		$Value
	)

    Write-Verbose "Getting SMA variable $($Name) from web service endpoint $($env:COMPUTERNAME)"

    try
    {
        $SMAVariable = Get-SmaVariable -Name $Name -WebServiceEndpoint "https://$($env:COMPUTERNAME)" -ErrorAction SilentlyContinue
    }
    catch
    {
        Write-Verbose "Failed getting SMA variable $($Name) from web service endpoint $($env:COMPUTERNAME)"
    }
    if($SMAVariable)
    {
        $Ensure = "Present"
    }
    else
    {
        $Ensure = "Absent"
    }
    
	$returnValue = @{
		Ensure = $Ensure
		Name = $SMAVariable.Name
		Value = $SMAVariable.Value
		Description = $SMAVariable.Description
		Encrypted = $SMAVariable.IsEncrypted
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
		$Value,

		[System.String]
		$Description = "",

		[System.Boolean]
		$Encrypted = $false
	)

    switch($Ensure)
    {
        "Present"
        {
            Write-Verbose "Setting SMA variable $($Name) on web service endpoint $($env:COMPUTERNAME)"
            Set-SmaVariable -Name $Name -WebServiceEndpoint "https://$($env:COMPUTERNAME)" -Value $Value -Description $Description -Encrypted:$Encrypted -ErrorAction Stop
        }
        "Absent"
        {
            Write-Verbose "Removing SMA variable $($Name) from web service endpoint $($env:COMPUTERNAME)"
            Remove-SmaVariable -Name $Name -WebServiceEndpoint "https://$($env:COMPUTERNAME)" -ErrorAction Stop
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
		$Value,

		[System.String]
		$Description = "",

		[System.Boolean]
		$Encrypted = $false
	)

	$SMAVariable = Get-TargetResource -Name $Name -Value $Value

    if($SMAVariable)
    {
        $result = $true
        if($SMAVariable.Ensure -ne $Ensure)
        {
            Write-Verbose "Failed test Ensure"
            $result = $false
        }
        if($SMAVariable.Ensure -eq 'Present')
        {
            if($PSBoundParameters.ContainsKey('Description') -and  $SMAVariable.Description -ne $Description)
            {
  			    Write-Verbose "Failed Description :: Expected: $($Description) Actual: $($SMAVariable.Description)"
                $result = $false
            }
            if($SMAVariable.Encrypted -ne $Encrypted)
            {
  			    Write-Verbose "Failed Encrypted :: Expected: $($Encrypted) Actual: $($SMAVariable.Encrypted)"
                $result = $false
            }
            if(!$Encrypted -and ($SMAVariable.Value -ne $Value))
            {
  			    Write-Verbose "Failed Value :: Expected: $($Value) Actual: $($SMAVariable.Value)"
                $result = $false
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
