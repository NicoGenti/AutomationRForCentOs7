[CmdletBinding()]
param (
    [FluentFTP.FtpClient]$Client
)

#region IMPORT MODULI

import-module Transferetto
Import-Module PoShLog
Import-Module PoShLog.Enrichers
Import-module ./Scripts/Config/VariabiliGlobali.psm1
Import-module ./Scripts/Config/UtilsFTP.psm1

#endregion

#region VARIABILI
$productionEnd = "$($Global:timestamp)_Production.end"

# Nome della cartella di output R per i PDF
$today = Get-Date -Format "yyyyMMdd"
[string]$dateElaborated = $today.ToString()
$lastReport = "Programming_$($Global:dateExtraction)_$($dateElaborated)"


# Path della cartella che contiene i PDF odierni di output di R
$lastReportLocalPath = "$($Global:pdfElaborated)/$($lastReport)"

#endregion

#region SCRIPT PRODUZIONE

Write-InformationLog "Verifica presenza file dentro $(TrimRoot($Global:historicalLocalPath))..."

# Verifica presenza file dentro historical-input
if (-not(Test-Path "$($Global:historicalLocalPath)/*.*")) {
    Write-ErrorLog "Cartella historical-input vuota..."
    ExitWithError(1)
}

Write-InformationLog "Inizio produzione file con R..."

# Lancio script per produzione R
pwsh ./Scripts/5-startR.ps1

# Se R è andato a buon fine:
if ($LASTEXITCODE -eq 0) {
    Write-InformationLog "Produzione completata con successo!"    
    Write-InformationLog "creazione cartella $(TrimRoot($lastReportLocalPath))..." 
    # Creazione cartella Programming_$($Global:dateExtraction)_$($dateElaborated)
    New-Item -Path $lastReportLocalPath -ItemType "directory" -Force | Out-Null
    Write-InformationLog "cartella creata."
    Write-InformationLog "spostamento file da reports a $(TrimRoot($lastReportLocalPath))..."  
    Move-Item -Path "$($Global:reportsLocalPath)/*" -Destination "$lastReportLocalPath" -Force | Out-Null
    # Spostamento dei PDF da /reports alla cartella Programming_$($Global:dateExtraction)_$($dateElaborated)
    Write-InformationLog "spostamento eseguito con successo."
    # Creazione data.log della produzione del momento
    New-Item -Path $lastReportLocalPath -Name "$dateElaborated.log" -ItemType "file" -Force | Out-Null
    Write-InformationLog "rinomina del file $(TrimRoot($Global:productionStart))..." 
    # Rinominazione del file Production.start in $Global:timestampProduction.end
    Move-Item -Path $Global:productionStart -Destination "$($Global:pdfElaborated)/$($productionEnd)" -Force | Out-Null
    Write-InformationLog "file rinominato."    
}else {
    Write-InformationLog "rinomina del file $(TrimRoot($Global:productionStart))..." 
    # Rinominazione del file Production.start in $Global:timestampProduction.end
    Rename-Item -Path $Global:productionStart -NewName "Production.fail" -Force | Out-Null
    Write-InformationLog "file rinominato."
    $errorProduction= "Errore nello script R, produzione non avvenuta.."
    Write-ErrorLog $errorProduction
    ExitWithError(1)
}

#endregion

#region UPLOAD FILE PDF SU FTP

$listPdf = Get-ChildItem -Path "$($lastReportLocalPath)/*.pdf" -Recurse -Force
if ($listPdf.Count -le 0) {
    $errorPDF= "PDF non prodotti!"
    Write-ErrorLog $errorPDF
    ExitWithError(1)
}

# se presenti avvia upload
try {
    # Upload dei file PDF nel FTP
    UploadFolderToFTP -Client $Client -LocalPath $lastReportLocalPath -RemoteFolder $lastReport 
}
catch {
    $errorUpload= "Errore nell'upload..."
    $Message = $_.Exception.Message
    Write-ErrorLog $errorUpload
    Write-ErrorLog $Message
    ExitWithError (0)
}

#endregion

# spostamento file xls elaborati da xls-input a xls-elaborated
MoveIntoFolderWithDate -PathSourceFolder $Global:inputLocalPath -PathDestionationFolder $Global:elaboratedLocalPath

# pulizia cartella reports tranne Production.end
Remove-Item -Path "$($Global:reportsLocalPath)/*.*" -Exclude "*.end" -Force -Recurse | Out-Null

Disconnect-FTP -Client $Client

if ($LASTEXITCODE -ne 0) {
    $errorProduction = "Script Automation.ps1 fallito..."
    Write-ErrorLog $errorProduction
    ExitWithError (1)
}

# prendo gli errori dal log 
$logError = GetErrorFromLog
# se ci sono entro in ExitWithError
if ($logError.Count -gt 0) {
    ExitWithError (0)
}else {
    # Altrimenti l'automazione è andata a buon fine.
    ExitWithoutError    
    Write-InformationLog "Automation successfully completed"
}

Close-Logger