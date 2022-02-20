<#  
.DESCRIPTION
La funzione permette di filtrare una lista di file in base ad una o più estensioni

.INPUTS
$Files = Lista dei file da filtrare
$extFilter = Array di stringhe delle estensioni da filtrare

#>
function GetListNameByExt {
    param (
      $Files,
      [string[]] $extFilter
    )
  
    $listFilter = [System.Collections.ArrayList]::new()
  
    if ($extFilter) {
      foreach ($file in $Files) {
        $ext = ($file.Name).Substring(($file.Name).lastindexof("."))  
        if ($ext -in $extFilter) {
          $listFilter.Add($file) | Out-Null
        }  
      }   
    }else {
      $listFilter = $Files
    }
    ,$listFilter
  }
# -------------------------------------------------------------------------------------------------------------------------------
<#
.DESCRIPTION
La funzione permette di prendere il file con la data più recente all'interno del nome

.INPUTS
$extFile = stringa dell'estensione per fare il filtro
$List = Lista dei file da filtrare

#>
  function GetLastFilename {
    param (
      [string] $extFile,
      $List
    )

    $Type = $List.GetType().Name

    switch ($Type) {
      "FileInfo" { return $List }
      "Object[]" {
                    $ListByExt = GetListNameByExt -Files $List -extFilter $extFile
                    $LastFilename = $ListByExt | Sort-Object -Property Name -Descending | Select-Object -First 1
                    return $LastFilename
                  }
      "ArrayList" {                    
                    $ListByExt = GetListNameByExt -Files $List -extFilter $extFile
                    $LastFilename = $ListByExt | Sort-Object -Property Name -Descending | Select-Object -First 1
                    return $LastFilename
                  }
      Default     {return $List}
    }
  }
# -------------------------------------------------------------------------------------------------------------------------------
<#
.DESCRIPTION
Funzione che permette l'upload di file da una cartella locale a una cartella nel FTP

.INPUTS
$Client = oggetto Client formato da user,pass e server
$LocalPath = cartella locale della quale si vuole fare l'upload
$RemotePath = cartella remota nella quale si vuore fare l'upload

.NOTES
La funzione carica solamente i file all'interno della cartella, non è possibile fare l'upload delle sottocartelle.
le sotto cartelle devono essere caricate successivamente usando la stessa funzione
#>
function UploadFolderToFTP {
  param (
    [FluentFTP.FtpClient]$Client,
    [string]$LocalPath,      
    [string]$RemoteFolder
  )

  $listFiles=Get-ChildItem -LiteralPath $LocalPath -File -Recurse
  foreach ($file in $listFiles) {

    $pathFile = $file.FullName
    $index = $pathFile.IndexOf($RemoteFolder)
    $subPath = $pathFile.Substring($index)
    $fileFTP = "$($Global:reportFTPPath)/$($subPath)"
    $fileFTP = $fileFTP.Replace("\","/")
  
    Send-FTPFile -Client $Client -LocalPath $pathFile -RemotePath $fileFTP -RemoteExists Overwrite -CreateRemoteDirectory
  }
}