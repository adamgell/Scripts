<#
.SYNOPSIS
  Name: CheckOEMINF.ps1
  The purpose of this script is to check whether NIC oem INF file exists in the machine
  
.DESCRIPTION
  This script verifies for oem inf file for all active NICs in the physical machine.
  It will check for oeminf only for Windows 7 and Windows 2008 R2 

#>

$OS = (Get-WmiObject Win32_OperatingSystem).Caption
$System = Get-WmiObject -Class Win32_ComputerSystem
$Computer = $env:COMPUTERNAME
$Result = @()

If ($System.Model -eq "Virtual Machine" ){
    Write-Output "$Computer is a Virtual Machine - Not Applicable"
    Exit
}
Else{
if ($os -match "Windows 10" -or $os -match "Microsoft Windows 10 Enterprise Insider Preview") {
    try {
			$NICObjs = @() 
			$ActiveNICs = get-wmiobject win32_networkadapter -ErrorAction Stop -filter "netconnectionstatus = 2" | select name
			foreach ( $nic in $ActiveNICs ) {
				 $NICObjs += get-wmiobject win32_PnPSignedDriver -ErrorAction Stop |
                             where { $_.DeviceName -eq $nic.name -or 
						             $_.Description -eq $nic.name -or 
						             $_.FriendlyName -eq $nic.name }
			}
        } catch {
			 Write-Output "Exception : $_.Exception.Message"
			 Exit
        }
    foreach ($nic in $NICObjs ){
           if ( $nic.InfName -match "^oe[m]") {
                  $infPath = Join-Path $env:windir "\inf\$($nic.InfName)"
                  if (Test-Path  $infPath) {
                      $Properties = @{ Computer = $Computer
                                       OS = $OS
                                       NIC = $nic.DeviceName
                                       OEMINF  = "Present" }
                      $Result += New-Object -TypeName PSObject $Properties
                  } Else {
                      $Properties = @{ Computer = $Computer
                                       OS = $OS
                                       NIC = $nic.DeviceName
                                       OEMINF  = "Missing" }
                      $Result += New-Object -TypeName PSObject $Properties 
                
                  }  
      
           }Else {
                 $Properties = @{ Computer = $Computer
                                  OS = $OS
                                  NIC = $nic.DeviceName
                                  OEMINF  = "Missing" }
                 $Result += New-Object -TypeName PSObject $Properties     
           } 
 
    }
	
	Write-Output $Result
} 
Else { 
	Write-Output "Operating System $OS is Not Applicable" 
    Exit
}
	
}