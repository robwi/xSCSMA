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
		[PSCredential]
		$Credential
	)

    Write-Verbose "Getting SMA credential $($Name) from web service endpoint $($env:COMPUTERNAME)"
    try
    {
        $smaCredential = Get-SmaCredential -Name $Name -WebServiceEndpoint "https://$($env:COMPUTERNAME)" -ErrorAction SilentlyContinue
    }
    catch
    {
        Write-Verbose "Failed getting SMA Credential $($Name) from web service endpoint $($env:COMPUTERNAME)"
    }

    if($smaCredential)
    {
        $Ensure = "Present"
    }
    else
    {
        $Ensure = "Absent"
    }
    
	$returnValue = @{
		Ensure = $Ensure
		Name = $Name
        Credential = $smaCredential
        Description = $smaCredential.Description
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
		[System.Management.Automation.PsCredential]
		$Credential,

		[System.String]
		$Description
	)
    switch($Ensure)
    {
        "Present"
        {
            Write-Verbose "Setting SMA Credential $($Name) on web service endpoint $($env:COMPUTERNAME)"
            Set-SmaCredential -Name $Name -Description $Description -Value $Credential -WebServiceEndpoint "https://$($env:COMPUTERNAME)" -ErrorAction Stop
        }
        "Absent"
        {
            Write-Verbose "Removing SMA Credential $($Name) from web service endpoint $($env:COMPUTERNAME)"
            Remove-SmaCredential -Name $Name -WebServiceEndpoint "https://$($env:COMPUTERNAME)" -ErrorAction Stop
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
		[System.Management.Automation.PSCredential]
		$Credential,

		[System.String]
		$Description = ""
     )

	$smaCredential = Get-TargetResource -Name $Name -Credential $Credential

    if($smaCredential)
    {
        $result = $true
        if($smaCredential.Ensure -ne $Ensure)
        {
            Write-Verbose "Failed test Ensure"
            $result = $false
        }
        if($smaCredential.Ensure -eq 'Present')
        {
            if($PSBoundParameters.ContainsKey('Description') -and  $smaCredential.Description -ne $Description)
            {
  			    Write-Verbose "Failed Description :: Expected: $($Description) Actual: $($smaCredential.Description)"
                $result = $false
            }
            if($smaCredential.Credential)
            {
                if( $smaCredential.Credential.UserName -ne $Credential.UserName )
                {
					Write-Verbose "Failed Credential.UserName :: Expected: $($Credential.UserName) Actual: $($smaCredential.Credential.UserName)"
					$result = $false 
                }
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