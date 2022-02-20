Import-module ./Scripts/Config/VariabiliGlobali.psm1

$urlWithCredential = "https://$($Global:userGit):$($Global:passGIT)@dev.azure.com/$($Global:organization)/$($Global:IdProject)/_git/$($Global:IdRepo)\"


if(-not(Test-Path -Path "$($Global:RFolderName)")) {
    Write-InformationLog "Richiesta Clone di $(TrimRoot($Global:workRPath))..."

    git clone $urlWithCredential "./$Global:RFolderName" -c core.longpaths=true
    Push-Location -Path $Global:workRPath
    git checkout $Global:gitBranch
    Pop-Location
    
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorLog "Clone di $($Global:RFolderName) fallito"
        ExitWithError(1)      
    }

    Write-InformationLog "Richiesta andata a buon fine"
} else {
    Write-InformationLog "Richiesta Pull di $(TrimRoot($Global:workRPath))..."
      
    Push-Location -Path $Global:workRPath
    git checkout $Global:gitBranch
    git pull origin $Global:gitBranch
    Pop-Location
    
    if ($LASTEXITCODE -ne 0) {
        Write-WarningLog "Pull di $($Global:RFolderName) fallito"
        exit 0
    }

    Write-InformationLog "Richiesta andata a buon fine"
}

exit 0