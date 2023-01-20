Function Get-SubnetAddresses {
Param ([IPAddress]$IP,[ValidateRange(0, 32)][int]$maskbits)

  $mask = ([Math]::Pow(2, $MaskBits) - 1) * [Math]::Pow(2, (32 - $MaskBits))
  $maskbytes = [BitConverter]::GetBytes([UInt32] $mask)
  $DottedMask = [IPAddress]((3..0 | ForEach-Object { [String] $maskbytes[$_] }) -join '.')
  
  $lower = [IPAddress] ( $ip.Address -band $DottedMask.Address )

  $LowerBytes = [BitConverter]::GetBytes([UInt32] $lower.Address)
  [IPAddress]$upper = (0..3 | %{$LowerBytes[$_] + ($maskbytes[(3-$_)] -bxor 255)}) -join '.'

  Return [pscustomobject][ordered]@{
    Lower=$lower
    Upper=$upper
  }
}

Function Get-IPRange {
param (
  [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName)][IPAddress]$lower,
  [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName)][IPAddress]$upper
)
  $IPList = [Collections.ArrayList]::new()
  $null = $IPList.Add($lower)
  $i = $lower

  while ( $i -ne $upper ) { 
    $iBytes = [BitConverter]::GetBytes([UInt32] $i.Address)
    [Array]::Reverse($iBytes)

    $nextBytes = [BitConverter]::GetBytes([UInt32]([bitconverter]::ToUInt32($iBytes,0) +1))
    [Array]::Reverse($nextBytes)

    $i = [IPAddress]$nextBytes
    $null = $IPList.Add($i)
  }

  return $IPList
}

$IP = Read-Host -Prompt 'IP: '
$SUB = Read-Host -Prompt 'Subnet: '

Get-SubnetAddresses $IP $SUB | Get-IPRange | Select -ExpandProperty IPAddressToString > IPAddr.txt

Start-Transcript -Path .\log.txt
(Get-Content .\IPAddr.txt) | ForEach {Write-Host $_, "-",
([System.Net.NetworkInformation.Ping]::new().Send($_)).Status}
Stop-Transcript
