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
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[System.String]
		$SourcePath = "$PSScriptRoot\..\..\",

		[System.String]
		$SourceFolder = "Source",

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$SetupCredential,

		[System.Management.Automation.PSCredential]
		$SourceCredential,

		[System.Boolean]
		$SuppressReboot,

		[System.Boolean]
		$ForceReboot,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$Service,

		[parameter(Mandatory = $true)]
		[System.String]
		$SqlServer,

		[parameter(Mandatory = $true)]
		[System.String]
		$SqlInstance,

		[System.String]
		$SqlDatabase = "SMA",

		[System.String]
		$InstallFolder,

		[System.String]
		$ETWManifest = "Yes",

		[System.String]
		$SendCEIPReports = "No",

		[System.String]
		$MSUpdate = "No",

		[System.String]
		$ProductKey
	)

    Import-Module $PSScriptRoot\..\..\xPDT.psm1
        
    if($SourceCredential)
    {
        NetUse -SourcePath $SourcePath -Credential $SourceCredential -Ensure "Present"
    }
    $Path = Join-Path -Path (Join-Path -Path $SourcePath -ChildPath $SourceFolder) -ChildPath "\WorkerSetup.exe"
    $Path = ResolvePath $Path
    $Version = (Get-Item -Path $Path).VersionInfo.ProductVersion
    if($SourceCredential)
    {
        NetUse -SourcePath $SourcePath -Credential $SourceCredential -Ensure "Absent"
    }

    switch($Version)
    {
        "7.2.1563.0"
        {
            $IdentifyingNumber = "{B2FA6B22-1DDF-4BD4-8B92-ADF17D48262F}"
        }
        "7.2.5002.0"
        {
            $IdentifyingNumber = "{B2FA6B22-1DDF-4BD4-8B92-ADF17D48262F}"
        }
        "7.2.2667.0"
        {
            $IdentifyingNumber = "{B2FA6B22-1DDF-4BD4-8B92-ADF17D48262F}"
        }
        Default
        {
            throw New-TerminatingError -ErrorType UnknownVersion -ErrorCategory InvalidType
        }
    }

    if(Get-WmiObject -Class Win32_Product | Where-Object {$_.IdentifyingNumber -eq $IdentifyingNumber})
    {
        $ServiceUsername = (Get-WmiObject -Class Win32_Service | Where-Object {$_.Name -eq "rbsvc"}).StartName
        $SqlServer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\ServiceManagementAutomation\RunbookWorker" -Name "DatabaseServerName").DatabaseServerName
        $SqlInstance = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\ServiceManagementAutomation\RunbookWorker" -Name "DatabaseServerInstance").DatabaseServerInstance
        if([String]::IsNullOrEmpty($SqlInstance))
        {
            $SqlInstance = "MSSQLSERVER"
        }
        $SqlDatabase = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\ServiceManagementAutomation\RunbookWorker" -Name "DatabaseName").DatabaseName
        $InstallFolder = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\ServiceManagementAutomation\RunbookWorker" -Name "InstallationFolder").InstallationFolder

        $returnValue = @{
		    Ensure = "Present"
		    SourcePath = $SourcePath
		    SourceFolder = $SourceFolder
		    ServiceUsername = $ServiceUsername
		    SqlServer = $SqlServer
		    SqlInstance = $SqlInstance
		    SqlDatabase = $SqlDatabase
		    InstallFolder = $InstallFolder
        }
    }
    else
    {
	    $returnValue = @{
		    Ensure = "Absent"
		    SourcePath = $SourcePath
		    SourceFolder = $SourceFolder
        }
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

		[System.String]
		$SourcePath = "$PSScriptRoot\..\..\",

		[System.String]
		$SourceFolder = "Source",

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$SetupCredential,

		[System.Management.Automation.PSCredential]
		$SourceCredential,

		[System.Boolean]
		$SuppressReboot,

		[System.Boolean]
		$ForceReboot,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$Service,

		[parameter(Mandatory = $true)]
		[System.String]
		$SqlServer,

		[parameter(Mandatory = $true)]
		[System.String]
		$SqlInstance,

		[System.String]
		$SqlDatabase = "SMA",

		[System.String]
		$InstallFolder,

		[System.String]
		$ETWManifest = "Yes",

		[System.String]
		$SendCEIPReports = "No",

		[System.String]
		$MSUpdate = "No",

		[System.String]
		$ProductKey
	)

    Import-Module $PSScriptRoot\..\..\xPDT.psm1
        
    if($SourceCredential)
    {
        NetUse -SourcePath $SourcePath -Credential $SourceCredential -Ensure "Present"
        $TempFolder = [IO.Path]::GetTempPath()
        & robocopy.exe (Join-Path -Path $SourcePath -ChildPath $SourceFolder) (Join-Path -Path $TempFolder -ChildPath $SourceFolder) /e
        $SourcePath = $TempFolder
        NetUse -SourcePath $SourcePath -Credential $SourceCredential -Ensure "Absent"
    }
    $Path = Join-Path -Path (Join-Path -Path $SourcePath -ChildPath $SourceFolder) -ChildPath "\WebServiceSetup.exe"
    $Path = ResolvePath $Path
    $Version = (Get-Item -Path $Path).VersionInfo.ProductVersion

    switch($Version)
    {
        "7.2.1563.0"
        {
            $IdentifyingNumber = "{B2FA6B22-1DDF-4BD4-8B92-ADF17D48262F}"
            $SCVersion = "System Center 2012 R2"
        }
        "7.2.5002.0"
        {
            $IdentifyingNumber = "{B2FA6B22-1DDF-4BD4-8B92-ADF17D48262F}"
            $SCVersion = "System Center Technical Preview"
        }
        "7.2.2667.0"
        {
            $IdentifyingNumber = "{B2FA6B22-1DDF-4BD4-8B92-ADF17D48262F}"
            $SCVersion = "System Center Technical Preview 2"
        }
        Default
        {
            throw New-TerminatingError -ErrorType UnknownVersion -ErrorCategory InvalidType
        }
    }

    $Path = "msiexec.exe"
    $Path = ResolvePath $Path

    switch($Ensure)
    {
        "Present"
        {
            # Set defaults, if they couldn't be set in param due to null configdata input
            foreach($ArgumentVar in ("ETWManifest","SendCEIPReports","MSUpdate"))
            {
                if((Get-Variable -Name $ArgumentVar).Value -ne "Yes")
                {
                    Set-Variable -Name $ArgumentVar -Value "No"
                }

            }

            $MSIPath = Join-Path -Path (Join-Path -Path $SourcePath -ChildPath $SourceFolder) -ChildPath "\WorkerInstaller.msi"
            $MSIPath = ResolvePath $MSIPath
            Write-Verbose "MSIPath: $MSIPath"

            # Create install arguments
            $Arguments = "/q /i $MSIPath"
            if(($PSVersionTable.PSVersion.Major -eq 5) -and ($SCVersion -eq "System Center 2012 R2"))
            {
                $MSTPath = Join-Path -Path $PSScriptRoot -ChildPath "\WMF5Worker.mst"
                $MSTPath = ResolvePath $MSTPath
                Write-Verbose "MSTPath: $MSTPath"
                $Arguments += " TRANSFORMS=`"$MSTPath`""
            }
            $Arguments += " ALLUSERS=2 CreateDatabase=No DatabaseAuthentication=Windows"
            $ArgumentVars = @(
                "SqlServer",
                "SqlDatabase",
                "InstallFolder",
                "ETWManifest"
                "SendCEIPReports",
                "MSUpdate",
                "ProductKey"
            )
            if($SQLInstance -ne "MSSQLSERVER")
            {
                $ArgumentVars += @(
                    "SqlInstance"
                )
            }
            foreach($ArgumentVar in $ArgumentVars)
            {
                if(!([String]::IsNullOrEmpty((Get-Variable -Name $ArgumentVar).Value)))
                {
                    $Arguments += " $ArgumentVar=`"" + [Environment]::ExpandEnvironmentVariables((Get-Variable -Name $ArgumentVar).Value) + "`""
                }
            }
            $AccountVars = @("Service")
            foreach($AccountVar in $AccountVars)
            {
                $Arguments += " $AccountVar`Account=`"" + (Get-Variable -Name $AccountVar).Value.UserName + "`""
                $Arguments += " $AccountVar`Password=`"" + (Get-Variable -Name $AccountVar).Value.GetNetworkCredential().Password + "`""
            }
            
            # Replace sensitive values for verbose output
            $Log = $Arguments
            $LogVars = @("Service")
            foreach($LogVar in $LogVars)
            {
                if((Get-Variable -Name $LogVar).Value -ne "")
                {
                    $Log = $Log.Replace((Get-Variable -Name $LogVar).Value.GetNetworkCredential().Password,"********")
                }
            }
        }
        "Absent"
        {
            $Arguments = "/q /x $IdentifyingNumber"
            $Log = $Arguments
        }
    }

    Write-Verbose "Path: $Path"
    Write-Verbose "Arguments: $Log"
    
    $Process = StartWin32Process -Path $Path -Arguments $Arguments -Credential $SetupCredential
    Write-Verbose $Process
    WaitForWin32ProcessEnd -Path $Path -Arguments $Arguments -Credential $SetupCredential

    if($ForceReboot -or ((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue) -ne $null))
    {
	    if(!($SuppressReboot))
        {
            $global:DSCMachineStatus = 1
        }
        else
        {
            Write-Verbose "Suppressing reboot"
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
		[parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[System.String]
		$SourcePath = "$PSScriptRoot\..\..\",

		[System.String]
		$SourceFolder = "Source",

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$SetupCredential,

		[System.Management.Automation.PSCredential]
		$SourceCredential,

		[System.Boolean]
		$SuppressReboot,

		[System.Boolean]
		$ForceReboot,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$Service,

		[parameter(Mandatory = $true)]
		[System.String]
		$SqlServer,

		[parameter(Mandatory = $true)]
		[System.String]
		$SqlInstance,

		[System.String]
		$SqlDatabase = "SMA",

		[System.String]
		$InstallFolder,

		[System.String]
		$ETWManifest = "Yes",

		[System.String]
		$SendCEIPReports = "No",

		[System.String]
		$MSUpdate = "No",

		[System.String]
		$ProductKey
	)

	$result = ((Get-TargetResource @PSBoundParameters).Ensure -eq $Ensure)
	
	$result
}


Export-ModuleMember -Function *-TargetResource