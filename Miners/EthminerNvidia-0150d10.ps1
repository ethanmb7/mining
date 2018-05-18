using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "NVIDIA"
if (-not ($Devices.$Type -or $Config.InfoOnly)) {return} # No NVIDIA mining device present in system, InfoOnly is for Get-Binaries

$Path = ".\Bin\Ethash-Ethminer-0150d10\ethminer.exe"
$HashSHA256 = ""
$API = "Claymore"
$Uri = "https://github.com/ethereum-mining/ethminer/releases/download/v0.15.0.dev10/ethminer-0.15.0.dev10-Windows.zip"$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Port = 23333
$Commands = [PSCustomObject]@{
    "ethash"    = ""
    "ethash2gb" = ""
}

# Get array of IDs of all devices in device set, returned DeviceIDs are of base $DeviceIdBase representation starting from $DeviceIdOffset
$DeviceIDsSet = Get-DeviceIDs -Config $Config -Devices $Devices -Type $Type -DeviceTypeModel $($Devices.$Type) -DeviceIdBase 10 -DeviceIdOffset 0

$Commands | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_
    
    Switch ($Algorithm_Norm) { # default is all devices, ethash has a 4GB minimum memory limit
        "Ethash"    {$DeviceIDs = $DeviceIDsSet."4gb"}
        "Ethash3gb" {$DeviceIDs = $DeviceIDsSet."3gb"}
        default     {$DeviceIDs = $DeviceIDsSet."All"}
    }
	
    if ($Pools.$Algorithm_Norm -and $DeviceIDs) { # must have a valid pool to mine and available devices

        $HashRate = ($Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week)

        [PSCustomObject]@{
            Name       = $Name
            Type       = $Type
            Path       = $Path
            HashSHA256 = $HashSHA256
            Arguments  = ("--api-port $Port -P $($Pools.$Algorithm_Norm.Protocol)://$([System.Web.HttpUtility]::UrlEncode($Pools.$Algorithm_Norm.User)):$([System.Web.HttpUtility]::UrlEncode($Pools.$Algorithm_Norm.Pass))@$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port)$($Commands.$_) --cuda --cuda-devices $($DeviceIDs)")
            HashRates  = [PSCustomObject]@{"$Algorithm_Norm" = $HashRate}
            API        = $Api
            Port       = $Port
            URI        = $Uri
            Fees       = @($null)
        }
    }
}
