using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "NVIDIA"
if (-not ($Devices.$Type -or $Config.InfoOnly)) {return} # No NVIDIA mining device present in system, InfoOnly is for Get-Binaries

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\PhoenixMiner-29e\PhoenixMiner.exe"
$API = "Claymore"
$HashSHA256 = ""
$Uri = ""
$Port = 23334
$Fees = 0.65
$Commands = [PSCustomObject]@{
    "ethash"    = ""
    "ethash2gb" = ""
}

# Get array of IDs of all devices in device set, returned DeviceIDs are of base $DeviceIdBase representation starting from $DeviceIdOffset
$DeviceIDsSet = Get-DeviceIDs -Config $Config -Devices $Devices -Type $Type -DeviceTypeModel $($Devices.$Type) -DeviceIdBase 10 -DeviceIdOffset 1

$Commands | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_
    
    Switch ($Algorithm_Norm) { # default is all devices, ethash has a 4GB minimum memory limit
        "Ethash"    {$DeviceIDs = $DeviceIDsSet."4gb"}
        "Ethash3gb" {$DeviceIDs = $DeviceIDsSet."3gb"}
        default     {$DeviceIDs = $DeviceIDsSet."All"}
    }
	
    if ($Pools.$Algorithm_Norm -and $DeviceIDs) { # must have a valid pool to mine and available devices

        $HashRate = ($Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week)

        $HashRate = $HashRate * (1 - $Fees / 100)

        [PSCustomObject]@{
            Name       = $Name
            Type       = $Type
            Path       = $Path
            HashSHA256 = $HashSHA256
            Arguments  = ("-rmode 0 -cdmport $Port -cdm 1 -pool $($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -wal $($Pools.$Algorithm_Norm.User) -pass $($Pools.$Algorithm_Norm.Pass) -proto 4 -coin auto -nvidia -gpus $($DeviceIDs -join ',')")
            HashRates  = [PSCustomObject]@{"$Algorithm_Norm" = $HashRate}
            API        = $Api
            Port       = $Port
            URI        = $Uri
            Fees       = @($Fees)
        }
    }
}