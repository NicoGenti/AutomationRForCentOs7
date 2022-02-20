# Variabili da settare dall'UTENTE:

# Path di dove si trova lo script PowerShell di automazione
$Global:rootFolder = ""

# Nome cartella dello script R (N.B. da inserire nella cartella di esecuzione dell'automazione)
$Global:RFolderName = ""

# Settaggi FTP
$Global:serverFTP = ""
$Global:userFTP = ""
$Global:passFTP = ""

#region Settaggi GIT

$Global:userGit = ""
$Global:passGIT = ""
$Global:IdProject = ""
$Global:IdRepo = ""
$Global:organization = ""
$Global:gitBranch = ""

#endregion

#region FEATURES (da cambiare con consapevolezza)

# Settare a $true per eseguire il Clone/Pull della cartella dello script R o $false per utilizzare quelli nel PC locale
$Global:useGitR = $true
 
# Settare a $true per utilizzare i CSV nel PC locale
$Global:useFtpCsv = $false 

# Settare a $true per utilizzare i XLS nel PC locale
$Global:useFtpXls = $true 

# Settare $true per invio mail
$Global:useEmail = $true

# Settare $true per invio mail al cliente
$Global:useEmailToClient = $true 

#endregion

#region PERCORSI DI SISTEMA (da cambiare con consapevolezza)

# Path della cartella /Config dello script PowerShell
$Global:configFolder = "$Global:rootFolder/Scripts/Config"

# Path delle cartelle del FTP
$Global:historicalFTPPath = '/historical'
$Global:inputFTPPath = '/files'
$Global:outputFTPPath = '/output'

# Path locali delle cartelle per lo script R
$Global:workRPath = "$Global:rootFolder/$Global:RFolderName"
$Global:historicalLocalPath = "$($Global:workRPath)/historical-input"
$Global:inputLocalPath = "$($Global:workRPath)/xls-input"
$Global:elaboratedLocalPath = "$($Global:workRPath)/xls-elaborated"
$Global:reportsLocalPath = "$($Global:workRPath)/reports"
$Global:csvExportLocalPath ="$($Global:workRPath)/export-csv"
$Global:ExportWarningLocalPath ="$($Global:workRPath)/export-warnings"
$Global:pdfElaborated = "$($Global:workRPath)/pdf-elaborated"

# Path FTP su cui sarà caricata la cartella di output locale dei PDF
$Global:reportFTPPath = "$($Global:outputFTPPath)"

#endregion

#region SERILOG

$Global:ConsoleParams = @{ 
    OutputTemplate = "[{MachineName} {Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}"
}

$todayWithSecond = Get-Date -Format "yyyyMMdd_HHmmss"
[string]$Global:timeStamp = $todayWithSecond.ToString()

$Global:pathLog = "$($global:rootFolder)/Logs/log$($timeStamp).txt"
$Global:FileParams= @{
    OutputTemplate = "[{MachineName} {Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}"
    Path = $Global:pathLog
    Formatter = Get-JsonFormatter
    #Rollinginterval = "Day"
    RetainedFileCountLimit = 14
    RestrictedToMinimumLevel = "Debug"
}

$Global:minimumLevel = "Debug"
#endregion

#region MAIL

<#
    .DESCRIPTION
    Invio delle notifiche tramite Send Grid
    .INPUTS
    $Body = corpo della mail
#>
function Send-Mail() {
    Param (
        $Body
    )

$Parameters = @{
    FromAddress = ""
    ToAddress   = ""
    Subject     = ""
    Body        = $Body
    Token       = ""
    FromName    = ""
    #AttachmentPath = ""
}
Send-PSSendGridMail @Parameters
}

<#
    .DESCRIPTION
    Invio delle notifiche tramite Send Grid al Cliente
    .INPUTS
    $Body = corpo della mail
#>
function Send-MailToClient() {
    Param (
        $Body
    )

$Parameters = @{
    FromAddress = ""
    ToAddress   = ""
    Subject     = ""
    Body        = $Body
    Token       = ""
    FromName    = ""
}
Send-PSSendGridMail @Parameters
}

#endregion

#region FUNCTIONS TOOL

<#
.DESCRIPTION
Funzione che verifica se esiste una cartella, se non esiste la crea

.INPUTS
$Path = percorso della cartella da verificare
#>
function IfNotExistCreateFolder {
    param (
        [string]$Path
    )
    
    Write-InformationLog "verifica esistenza cartella $(TrimRoot($Path))..."

    if (-not(Test-Path $Path)) {
        Write-InformationLog "Creazione cartella $(TrimRoot($Path))..."
        New-Item -Path $Path -ItemType "directory" -Force | Out-Null
        Write-InformationLog "Cartella creata."
    }
    Write-InformationLog "Ok."
}
# -------------------------------------------------------------------------------------------------------------------------------
<#
.DESCRIPTION
Funzione che permettere di filtrare il file log creato dall'applicazione, in una lista customizzata
.INPUTS
La funzione utilizza il file di log che è globale $Global:pathLog
.OUTPUTS
La funzione restituisce una lista di oggetti con all'interno solamente gli errori del log
#>
function GetErrorFromLog(){
    $log = Get-Content -Path $Global:pathLog -ErrorAction Stop | ConvertFrom-Json
    $logError = $log | Select-Object -Property Timestamp,Level,MessageTemplate | Where-Object {$_.Level -ne "Information"}
    return $logError
}
# -------------------------------------------------------------------------------------------------------------------------------
<#
.DESCRIPTION
Funzione che prende gli errori dal file log e li formatta in tabella per poi essere inseriti 
nel corpo di una mail.
.OUTPUTS
Stringa con all'interno una tabella di oggetti
#>
function BodyError(){
    $logError=GetErrorFromLog
    [string]$body= $logError | Format-Table -AutoSize -HideTableHeaders | Out-String -Width 4096
    return $body
}
# -------------------------------------------------------------------------------------------------------------------------------
<#
.DESCRIPTION
Funzione che va richiamata nel momento in cui si presenta un errore. 
A seconda dell'input il programma potrà continuare o bloccarsi, in ogni caso invia il log di errore alla mail.
.INPUTS
$stop variabile int che assume valore 1 se l'errore è bloccante, 0 se il programma può andare avanti

.NOTES
Verificare che il parametro $Global:useEmail in questo file sia impostato su $true
#>
function ExitWithError($stop){
    if ($Global:useEmail) {
        [string]$body=BodyError
        Send-Mail -Body $body
    }
    if ($stop -eq 1){
        break
    } 
}
# -------------------------------------------------------------------------------------------------------------------------------
<#
.DESCRIPTION
Funzione richiamata alla fine dello script di automazione per inviare un email, sia a se stessi che 
al proprio cliente, nel momento in cui tutto lo script è andato a buon fine senza errori.

.NOTES
Verificare che i parametri $Global:useEmail e $Global:useEmailToClient in questo file siano impostati entrambi su $true
#>
function ExitWithoutError(){

    $body="Automation successfully completed"
    if ($Global:useEmail) {
        Send-MailToClient -Body $body
    }

    if ($Global:useEmailToClient) {
        Send-MailToEurope -Body $body
    }
}
# -------------------------------------------------------------------------------------------------------------------------------
<#
.DESCRIPTION
Funzione che permette di muovere una lista di file da una cartella ad una sotto cartella chiamata per data di eleborazione

.INPUTS
$PathSourceFolder = percorso della cartella sorgente
$PathDestionationFolder = percorso della cartrella di destinazione

.NOTES
$ExcludeExtensions = @(".end",".start") non permette ai file con quelle estenzioni di essere trasferiti.
#>
function MoveIntoFolderWithDate {
    param (
        [string]$PathSourceFolder,
        [string]$PathDestionationFolder
    )

    $today = Get-Date -Format "yyyyMMdd"
    [string]$dateElaborated = $today.ToString()


    $ExcludeExtensions = @(".end",".start")
    $DestinationFolderWithDate = "$PathDestionationFolder/$dateElaborated"

    IfNotExistCreateFolder -Path $DestinationFolderWithDate

    Write-InformationLog "Spostamento file da $(TrimRoot($PathSourceFolder)) a $(TrimRoot($DestinationFolderWithDate))..."    
    Get-ChildItem -Path $PathSourceFolder -Recurse | Move-Item -destination $DestinationFolderWithDate 

}
# -------------------------------------------------------------------------------------------------------------------------------
<#
.DESCRIPTION
Funzione che dato un percorso in ingresso viene trimmata la parte iniziale del medesimo.

.NOTES
in ingresso si prendono solo i percorsi che iniziano con la $Global:rootFolder
#>
function TrimRoot($Path) {
    return $Path.Replace($Global:rootFolder,"")    
}

#endregion