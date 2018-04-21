using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-Alexis78\ccminer-alexis.exe"
$Uri = "https://github.com/nemosminer/ccminer-hcash/releases/download/alexishsr/ccminer-hsr-alexis-x86-cuda8.7z"

$Commands = [PSCustomObject]@{
    #GPU - profitable 20/04/2018
    "bastion" = "" #bastion
    "bitcore" = "" #Bitcore
    "bmw" = "" #bmw
    "c11" = "" #C11
    "deep" = "" #deep
    "dmd-gr" = "" #dmd-gr
    "fresh" = "" #fresh
    "fugue256" = "" #Fugue256
    "groestl" = "" #Groestl
    "heavy" = "" #heavy
    "hmq1725" = "" #HMQ1725
    "hsr" = "" #HSR, HShare
    "keccak" = "" #Keccak
    "jackpot" = "" #JackPot
    "jha" = "" #JHA
    "luffa" = "" #Luffa
    "lyra2" = "" #Lyra2
    "lyra2v2" = "" #lyra2v2
    "lyra2z" = "" #Lyra2z, ZCoin
    "mjollnir" = "" #Mjollnir
    "neoscrypt" = "" #NeoScrypt
    "pentablake" = "" #pentablake
    "penta" = "" #Pentablake
    "scryptjane:nf" = "" #scryptjane:nf
    "sha256t" = "" #sha256t
    #"skein" = "" #Skein
    "skein2" = "" #skein2
    #"skunk" = "" #Skunk
    "s3" = "" #S3
    "timetravel" = "" #Timetravel
    "vanilla" = "" #BlakeVanilla
    "veltor" = "" #Veltor
    #"whirlcoin" = "" #WhirlCoin
    #"whirlpool" = "" #Whirlpool
    #"whirlpoolx" = "" #whirlpoolx
    "wildkeccak" = "" #wildkeccak
    "x11evo" = "" #X11evo
    "x17" = "" #x17
    "zr5" = "" #zr5

    # ASIC - never profitable 20/04/2018
    #"blake2s" = "" #Blake2s
    #"blake" = "" #blake
    #"blakecoin" = "" #Blakecoin
    #"cryptolight" = "" #cryptolight
    #"cryptonight" = "" #CryptoNight
    #"decred" = "" #Decred
    #"lbry" = "" #Lbry
    #"myr-gr" = "" #MyriadGroestl
    #"nist5" = "" #Nist5
    #"quark" = "" #Quark
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"scrypt:N" = "" #scrypt:N
    #"sha256d" = "" #sha256d
    #"sia" = "" #SiaCoin
    #"sib" = "" #Sib
    #"x11" = "" #X11
    #"x13" = "" #x13
    #"x14" = "" #x14
    #"x15" = "" #x15
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -o $($Pools.(Get-Algorithm $_).Protocol)://$($Pools.(Get-Algorithm $_).Host):$($Pools.(Get-Algorithm $_).Port) -u $($Pools.(Get-Algorithm $_).User) -p $($Pools.(Get-Algorithm $_).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm $_) = $Stats."$($Name)_$(Get-Algorithm $_)_HashRate".Week}
        API = "Ccminer"
        Port = 4068
        URI = $Uri
    }
}
