﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject[]]$Devices
)

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\CryptoDredge.exe"
$ManualUri = "https://github.com/technobyl/CryptoDredge"
$Port = "40{0:d2}"

# Miner requires CUDA 9.2 or higher
$DriverVersion = ((Get-Device | Where-Object Type -EQ "GPU" | Where-Object Vendor -EQ "NVIDIA Corporation").OpenCL.Platform.Version | Select-Object -Unique) -replace ".*CUDA ",""
$RequiredVersion = "9.2.00"
if ($DriverVersion -and [System.Version]$DriverVersion -lt [System.Version]$RequiredVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredVersion) or above (installed version is $($DriverVersion)). Please update your Nvidia drivers. "
    return
}

if ($DriverVersion -lt [System.Version]("10.0.0")) {
    $Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.15.2/CryptoDredge_0.15.2_cuda_9.2_windows.zip"
    $HashSHA256 = "3EE6C8EEE0BE19872D8D04C54FBA3F247CC242FF3C7D3E581B0601517830CCDD"
}
else {
    $Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.15.2/CryptoDredge_0.15.2_cuda_10.0_windows.zip"
    $HashSHA256 = "D19A8A85B154CF5070F50093F99E150A2594350380306EEE89B31336A8B945EE"
}

$Commands = [PSCustomObject]@{
    "aeon"            = "" #Aeon, new in 0.9 (CryptoNight-Lite algorithm)
    "allium"          = "" #Allium
    "bitcore"         = "" #BitCore, new in 0.9.5
    "blake2s"         = "" #Blake2s, new in 0.9
    "bcd"             = "" #BitcoinDiamond, new in 0.9.4
    "c11"             = "" #C11, new in 0.9.4
    "cnheavy"         = " -i 5" #CryptoNightHeavy, new in 0.9
    "cnhaven"         = " -i 5" #CryptoNightHeavyHaven, new in 0.9.1
    "cnv7"            = " -i 5" #CyptoNightV7, new in 0.9
    "cnv8"            = " -i 5" #CyptoNightV8, new in 0.9.3
    "cnfast"          = " -i 5" #CryptoNightFast, new in 0.9
    "cnsaber"         = " -i 5" #CryptonightHeavyTube (BitTube), new in 0.9.2
    "dedal"           = "" #Dedal, new in 12.0
    "exosis"          = "" #Exosis, new in 0.9.4
    "hmq1725"         = "" #HMQ1725, new in 0.10.0
    "lbk3"            = "" #used by Vertical VTL, new with 0.9.0
    "lyra2v2"         = "" #Lyra2REv2
    "lyra2rev3"       = "" #Lyra2REv3, new in 0.14.0 
    "lyra2vc0banhash" = "" #Lyra2vc0banHash, New in 0.13.0
    "lyra2z"          = "" #Lyra2z
    "mtp"             = "" #MTP, new with 0.15.0
    "neoscrypt"       = "" #NeoScrypt
    "phi"             = "" #PHI
    "phi2"            = "" #PHI2
    "pipe"            = "" #Pipe, new in 12.0
    "polytimos"       = "" #Polytimos, new in 0.9.4
    "skein"           = "" #Skein
    "skunkhash"       = "" #Skunk
    "stellite"        = " -i 5" #CryptoNightXtl, new in 0.9
    "tribus"          = "" #Tribus, new with 0.8
    "x16r"            = "" #X16R, new in 0.11.0
    "x16s"            = "" #X16S, new in 0.11.0
    "x17"             = "" #X17, new in 0.9.5
    "x21s"            = "" #X21s, new in 0.13.0
    "x22i"            = "" #X22i, new in 0.9.6
}
$CommonCommands = " --no-watchdog --no-color"

$Devices = @($Devices | Where-Object Type -EQ "GPU" | Where-Object Vendor -EQ "NVIDIA Corporation" | Where-Object {([math]::Round((10 * $_.OpenCL.GlobalMemSize / 1GB), 0) / 10) -ge 5}) #GPUs with at least 5 GB of memory

$Devices | Select-Object Model -Unique | ForEach-Object {
    $Miner_Device = @($Devices | Where-Object Model -EQ $_.Model)
    $Miner_Port = $Port -f ($Miner_Device | Select-Object -First 1 -ExpandProperty Index)

    $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {
        $Algorithm_Norm = Get-Algorithm $_

        if ($Config.UseDeviceNameForStatsFileNaming) {
            $Miner_Name = "$Name-$($Miner_Device.count)x$($Miner_Device.Model_Norm | Sort-Object -unique)"
        }
        else {
            $Miner_Name = (@($Name) + @($Miner_Device.Name | Sort-Object) | Select-Object) -join '-'
        }

        Switch ($Algorithm_Norm) {
            "X16R"  {$BenchmarkIntervals = 5}
            default {$BenchmarkIntervals = 1}
        }

        [PSCustomObject]@{
            Name               = $Miner_Name
            DeviceName         = $Miner_Device.Name
            Path               = $Path
            HashSHA256         = $HashSHA256
            Arguments          = ("--api-type ccminer-tcp --api-bind 127.0.0.1:$($Miner_Port) -a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$CommonCommands -d $(($Miner_Device | ForEach-Object {'{0:x}' -f $_.Type_Vendor_Index}) -join ',')" -replace "\s+", " ").trim()
            HashRates          = [PSCustomObject]@{$Algorithm_Norm = $Stats."$($Miner_Name)_$($Algorithm_Norm)_HashRate".Week}
            API                = "Ccminer"
            Port               = $Miner_Port
            URI                = $Uri
            Fees               = $(if($Algorithm_Norm-eq "MPT") {[PSCustomObject]@{$Algorithm_Norm = 2 / 100}} else {[PSCustomObject]@{$Algorithm_Norm = 1 / 100}})
            BenchmarkIntervals = $BenchmarkIntervals
        }
    }
}
