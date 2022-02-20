Import-module ./Scripts/Config/VariabiliGlobali.psm1
# Sposto location alla root dello script startR
Push-Location -Path $Global:workRPath
# Riconoscimento del OS per identificare quale Rscript far partire
if ($IsLinux) {
    Rscript nameScriptR
}else {
    Rscript.exe .\nameScriptR
}

# Torno alla location precedente
Pop-Location

exit $LASTEXITCODE