# Auxiliar: aplica migraciones a una base temporal y reporta errores de sintaxis.
param([string]$FilesCsv, [string]$Db = 'chk_tmp', [switch]$AlFinalBorra)
$ErrorActionPreference = 'Continue'
$Files = @('001_esquema.sql','002_constraints.sql','003_rn05_composicion_deferred.sql','004_rn03_rn06.sql','005_rn08_comprobante.sql') + ($FilesCsv -split ',' | Where-Object { $_.Trim() })
$run = { param($args_) & docker exec -i bodegas-atuel-db psql -X -U bodegas_app -d $Db -v ON_ERROR_STOP=1 -q -f "/tmp/$args_" 2>&1 }
& docker exec bodegas-atuel-db dropdb --if-exists -U bodegas_app $Db
& docker exec bodegas-atuel-db createdb -U bodegas_app -O bodegas_app $Db
if ($LASTEXITCODE -ne 0) { throw 'no se pudo crear la base temporal' }
foreach ($f in $Files) {
    & docker cp "db\migrations\$f" "bodegas-atuel-db:/tmp/$f" | Out-Null
    $out = & $run $f
    $code = $LASTEXITCODE
    $errs = ($out | Out-String) -split "`r?`n" | Select-String -Pattern 'ERROR|NOTA'
    "=== $f => exit $code"
    $errs | ForEach-Object { "    $_" }
}
if ($AlFinalBorra) { & docker exec bodegas-atuel-db dropdb --if-exists -U bodegas_app $Db }
