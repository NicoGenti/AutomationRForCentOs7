$Message = @(
    "verifica esistenza file Download.start per inizio download...",
    "verifica esistenza file Production.start per inizio download...",
    "verifica esistenza file Production.fail, per precedente blocco R...",
    "Ok.",
    "Avvio di Load.ps1...",
    "`n-----------------------Start IsRunning.ps1 at $(Get-Date -Format ("yyyy-MM-dd")) -----------------------"
)
<#
.DESCRIPTION
Funzione che aggiunge una riga ad un file .txt
#>
function AddLineTextToFile {
    param (
        $Text,
        $TipeMessage = "Info"                
    )
    $File = "./Logs/logIsRunning.txt"

    $timeStamp = Get-Date -Format ("HH:mm:ss")
    
    $line = "$($timeStamp)  $Text"

    if ($TipeMessage -eq "Info") {
        Write-Information $line
    }else {
        Write-Warning $line
    }
    Add-Content $File $line
}

if (-not(Test-Path "./Logs/logIsRunning.txt")) {
    New-Item -ItemType "file" -Path "./Logs/" -Name "logIsRunning.txt" -Force | Out-Null
}

AddLineTextToFile $Message[5]
Write-Host $Message[5] -$TipeMessage

# verifica esistenza file Download.start per inizio download
AddLineTextToFile $Message[0]

if (Test-Path "./Download.start") {
    $warningDownloadStart = "Download file input in corso..."
    AddLineTextToFile $warningDownloadStart "Warning"
    break
}
AddLineTextToFile $Message[3]

# verifica esistenza file production.start per inizio produzione
AddLineTextToFile $Message[1]

if (Test-Path "./Production.start") {
    $warningProductionStart = "Produzione in corso..."
    AddLineTextToFile $warningProductionStart "Warning"
    break
}
AddLineTextToFile $Message[3]

# verifica esistenza file production.fail blocco programma
AddLineTextToFile $Message[2]

if (Test-Path "./Production.fail") {
    $errorProductionFail = "Produzione precedente fallita..."
    AddLineTextToFile $errorProductionFail "Error"
    break
}
AddLineTextToFile $Message[3]

AddLineTextToFile $Message[4]
.\Scripts\1-Load.ps1