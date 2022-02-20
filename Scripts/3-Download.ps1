#region IMPORT MODULI

import-module Transferetto
Import-Module PoShLog
Import-Module PoShLog.Enrichers
Import-module ./Scripts/Config/VariabiliGlobali.psm1
Import-module ./Scripts/Config/UtilsFTP.psm1

#endregion

#region VARIABILI

# Connessione al client FTP
$Client = Connect-FTP -Server $Global:serverFTP -Username $Global:userFTP -Password $Global:passFTP -Verbose

# Estensione per il download dei csv e log dal FTP
$extensionDownloadHistorical = @(".csv",".logcsv")

# Estensione per il download dei xls,xlxs e log dal FTP
$extensionDownloadInput = @(".xls",".xlsx",".log")

$downloadStart = "$Global:rootFolder/Download.start"

#endregion

#region GET CSV

# prendo i file CSV dalla cartella del FTP
$filesListFTPCsv = Get-FTPList -Client $Client -Path $Global:historicalFTPPath | Where-Object {$_.Type -ne "Directory"}
$filesListFTPCsvFiltered = GetListNameByExt -Files $filesListFTPCsv -extFilter $extensionDownloadHistorical
$lastLogFTPCsv = GetLastFilename -List $filesListFTPCsvFiltered -extFile ".logcsv"

# prendo i file CSV dalla cartella del locale
$filesLogCsvLocal = Get-ChildItem -Path "$($Global:historicalLocalPath)/*.logcsv" -File 
if ($filesLogCsvLocal) {
    $lastLogCsvLocal = GetLastFilename -List $filesLogCsvLocal
}

# DOWNLOAD DEI FILE CSV DA FTP
$filesCsvDownload = $false # inizializzazione a false

if ($Global:useFtpCsv) {
    if ($lastLogCsvLocal) {
        $filesCsvDownload = ($lastLogFTPCsv.Name).Substring(0,8) -gt ($lastLogCsvLocal.Name).Substring(0,8) # Se il .logcsv in /historical è più vecchio del FTP, scaricherò i file (per $useFtpCsv sarà $true in VariabiliGlobali)
    }else {
        $Global:filesCsvDownload=$true # Se la cartella /historical è vuota, scaricherò i file da FTP (per $useFtpCsv sarà $true in VariabiliGlobali)
    }
}

if ($Global:filesCsvDownload) {
    try {
        # Download dei file
        Write-InformationLog "Download dei file CSV..."
        foreach ($RemoteFile in $filesListFTPCsvFiltered) {
            Receive-FTPFile -Client $Client -RemoteFile $RemoteFile -LocalPath "$Global:historicalLocalPath/$($RemoteFile.Name)" -LocalExists Overwrite -VerifyOptions Retry, None
        }
        Write-InformationLog "Download eseguito."
    }
    catch {
        $errorDownloadCsv = "Errore nel Download dei file CSV.."
        $Message = $_.Exception.Message
        Write-ErrorLog $errorDownloadCsv
        Write-ErrorLog $Message
        ExitWithError (0)
    }    
}

#endregion    

#region GET XLS

#region prendo i file XLS dalla cartella del FTP

# Creazione della lista di tutti i file nella cartella xls-input del FTP
$filesListFTPXls = Get-FTPList -Client $Client -Path $Global:inputFTPPath | Where-Object {$_.Type -ne "Directory"}
# Creazione di una nuva lista questa volta filtrata dalla precedente per le estenzioni ".xls",".xlsx",".log"
$filesListFTPXlsFiltered = GetListNameByExt -Files $filesListFTPXls -extFilter $extensionDownloadInput
# Mi prendo l'ultimo file .log caricato nel FTP
$lastLogFTPXls = GetLastFilename -List $filesListFTPXlsFiltered -extFile ".log"

# se esiste prendo l'ultimo file .log dalla cartella locale
$filesLogXlsLocal = Get-ChildItem -Path "$($Global:elaboratedLocalPath)/*.log" -File 
if ($filesLogXlsLocal) {
    $lastLogXlsLocal = GetLastFilename -List $filesLogXlsLocal
}
#endregion

# Se trovo .log in elaborated verifico se è piu grande di quella che ho nella cartella locale
$dataLastLogFTPXls = ($lastLogFTPXls.Name).Substring(0,8)
if ($lastLogXlsLocal) {    
    $dateLastLogLocalXls = ($lastLogXlsLocal.Name).Substring(0,8)
    $filesXlsDownload = $dataLastLogFTPXls -gt $dateLastLogLocalXls
}else {
    $filesXlsDownload=$true
}
$Global:dateExtraction = $dataLastLogFTPXls

if ($Global:useFtpXls) {
#region DOWNLOAD DEI FILE XLS O XLSX DA FTP

    # se la verifca dei due file è approvata oppure il file nella cartella locale non esiste, avvio il download
    if ($filesXlsDownload) {
        try {
            # creazione della lista partendo dalla lista dei file filtrati per le estenzioni scelte nel FTP e li filtro ulteriormente per la data di estrazione
            $filesListFTPXlsFilteredExtracted = $filesListFTPXlsFiltered | Where-Object {$_.Name -like "$Global:dateExtraction*"}
            Write-InformationLog "Creazione file Download.start..."
            # creo la lista dei file che dovranno essere scaricati
            $filesListDownload = $filesListFTPXlsFilteredExtracted |Select-Object -Property Name | Out-File -FilePath $downloadStart
            Write-InformationLog "File creato."
            # Download dei file
            Write-InformationLog "Download dei file XLS..."
            foreach ($RemoteFile in $filesListFTPXlsFilteredExtracted) {            
                Receive-FTPFile -Client $Client -RemoteFile $RemoteFile -LocalPath "$Global:inputLocalPath/$($RemoteFile.Name)" -LocalExists Overwrite -VerifyOptions Retry, None
            }    
            Write-InformationLog "Download eseguito."
            # Una volta concluso il Download dei XLS rinomino il file Download.start in $Global:timestamp_Download.end
            Move-Item -Path $downloadStart -Destination "$Global:elaboratedLocalPath/$($Global:timestamp)_Download.end" -Force
        } 
        catch {
            $errorStartDownload = "Errore nel Download dei file XLS.."
            $Message = $_.Exception.Message
            Write-ErrorLog $errorStartDownload
            Write-ErrorLog $Message
            ExitWithError (1)
        }

        
    }else {
        $warningFindFileFTP = "File xls locali uguali a quelli FTP..."
        $Message = $_.Exception.Message
        Write-ErrorLog $warningFindFileFTP
        Write-ErrorLog $Message
        ExitWithError(1)
    }    
 #endregion
}

#endregion

#region AVVIO SCRIPT PRODUZIONE

$Global:productionStart = "$Global:rootFolder\Production.start" 

Write-InformationLog "Avvio script Automation.ps1 per produzione e upload..."
$filesListProduction = Get-ChildItem -Path $Global:inputLocalPath |ForEach-Object {$_.Name} | Out-File -FilePath $Global:productionStart 

# facciamo  partire lo script per la produzione dei PDF tramite R
./Scripts/4-Automation.ps1 -Client $Client

#endregion