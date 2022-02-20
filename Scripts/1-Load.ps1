#region IMPORT MODULI

Import-Module PoShLog
Import-Module PoShLog.Enrichers
Import-module ./Scripts/Config/VariabiliGlobali.psm1

#endregion

#region VARIABILI

# Creazione del LOG
New-Logger |
Set-MinimumLevel -Value $Global:minimumLevel |
Add-EnrichWithEnvironment |
Add-EnrichWithExceptionDetails |
Add-SinkFile @FileParams |
Add-SinkConsole @ConsoleParams|
Start-Logger

$failsPath = "$($Global:elaboratedLocalPath)/fail"

#endregion

#region CLONE O PULL DELLO SCRIPT R DI DEVOPS

if ($Global:useGitR) {
    Write-InformationLog "Inizio script Git.R..."    
    ./Scripts/2-GitR.ps1
}else {
    Write-InformationLog "Attenzione, è stato selezionato da il file VariabiliGlobali.psm1 di non fare il clone o il pull di $(TrimRoot($Global:workRPath))..."
}

#endregion

#region VERIFICHE PRELIMINARI

# verifica esistenza file VariabiliGlobali.psm1
Write-InformationLog "verifica esistenza file VariabiliGlobali.psm1..."

if (-not(Test-Path "$($Global:configFolder)/VariabiliGlobali.psm1")) {
    $errorVariabiliGlobali = "ERROR: VariabiliGlobali.psm1 non trovato, verificare l'esistenza e le variabili all'interno!"
    Write-FatalLog $errorVariabiliGlobali
    New-Item -ItemType "file" -Path "$($Global:rootFolder)/Logs/" -Name "FATAL_LOG.txt" -Value $errorVariabiliGlobali -Force | Out-Null
    if ($Global:useEmail) {
        Send-Mail -Body $errorVariabiliGlobali
    }
    break
}
Write-InformationLog "Ok."

if ($Global:useFtpXls) {
    # verifica esistenza cartella xls-input
    IfNotExistCreateFolder -Path $Global:inputLocalPath

    # verifica contenuto della cartella xls-input e creazione cartella fail
    Write-InformationLog "verifica contenuto della cartella xls-input e creazione cartella fail..."
    if (Test-Path "$($Global:inputLocalPath)/*.*") {
        MoveIntoFolderWithDate -PathSourceFolder $Global:inputLocalPath -PathDestionationFolder $failsPath
    }
}

# verifica esistenza cartella /historical-input
IfNotExistCreateFolder -Path $Global:historicalLocalPath

# verifica esistenza cartella xls-elaborated
IfNotExistCreateFolder -Path $Global:elaboratedLocalPath

# verifica esistenza cartella xls-elaborated/fails
IfNotExistCreateFolder -Path $failsPath

# verifica esistenza cartella reports
IfNotExistCreateFolder -Path $Global:reportsLocalPath

# verifica esistenza cartella pdf-elaborated
IfNotExistCreateFolder -Path $Global:pdfElaborated

# verifica esistenza cartella export-csv
IfNotExistCreateFolder -Path $Global:csvExportLocalPath

# verifica esistenza cartella export-warnings
IfNotExistCreateFolder -Path $Global:ExportWarningLocalPath

Write-InformationLog "Ok."

#endregion

#region AVVIO DOWNLOAD FILE
Write-InformationLog "Avvio script Download file CSV e XLS..."
./Scripts/3-Download.ps1

#endregion
