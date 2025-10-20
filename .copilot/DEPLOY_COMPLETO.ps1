# Carregar configuracao
. "$PSScriptRoot\CONFIG_IMUTAVEL.ps1"

Write-Host "DEPLOY COMPLETO..." -ForegroundColor Cyan

# 1. Compilar e copiar .mqh
Write-Host "[1/3] Includes..." -ForegroundColor Yellow
& $MT5_METAEDITOR /compile:$INCLUDE_REGIME_DETECTOR /log
& $MT5_METAEDITOR /compile:$INCLUDE_SETUP_MANAGER /log
Copy-Item $INCLUDE_REGIME_DETECTOR "$MT5_TERMINAL_DATA\MQL5\Include\" -Force
Copy-Item $INCLUDE_SETUP_MANAGER "$MT5_TERMINAL_DATA\MQL5\Include\" -Force
Write-Host "[OK]" -ForegroundColor Green

# 2. Compilar e copiar indicadores
Write-Host "[2/3] Indicadores..." -ForegroundColor Yellow
$indicators = @(
    @{Name="ADX_Professional"; Source=$IND_ADX_SOURCE; Compiled=$IND_ADX_COMPILED},
    @{Name="ChoppinessIndex_Professional"; Source=$IND_CI_SOURCE; Compiled=$IND_CI_COMPILED},
    @{Name="BollingerKeltnerSqueeze_Professional"; Source=$IND_BKS_SOURCE; Compiled=$IND_BKS_COMPILED},
    @{Name="ATR_Professional"; Source=$IND_ATR_SOURCE; Compiled=$IND_ATR_COMPILED},
    @{Name="WaddahAttarExplosion_Professional"; Source=$IND_WAE_SOURCE; Compiled=$IND_WAE_COMPILED},
    @{Name="VolumeProfile_Professional"; Source=$IND_VP_SOURCE; Compiled=$IND_VP_COMPILED}
)
foreach ($ind in $indicators) {
    & $MT5_METAEDITOR /compile:$($ind.Source) /log
    $dest = "$MT5_TERMINAL_DATA\MQL5\Indicators\$($ind.Name)"
    if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
    Copy-Item $ind.Compiled -Destination $dest -Force -ErrorAction SilentlyContinue
    Copy-Item $ind.Source -Destination $dest -Force -ErrorAction SilentlyContinue
}
Write-Host "[OK]" -ForegroundColor Green

# 3. Compilar e copiar EA
Write-Host "[3/3] EA..." -ForegroundColor Yellow
& $MT5_METAEDITOR /compile:$EA_SOURCE_FILE /log
$destEA = "$MT5_TERMINAL_DATA\MQL5\Experts\AdaptiveFlowSystem_v2"
if (-not (Test-Path $destEA)) { New-Item -ItemType Directory -Path $destEA -Force | Out-Null }
Copy-Item $EA_COMPILED_FILE -Destination $destEA -Force
Copy-Item $EA_SOURCE_FILE -Destination $destEA -Force
Write-Host "[OK]" -ForegroundColor Green

Write-Host ""
Write-Host "DEPLOY COMPLETO!" -ForegroundColor Green
Write-Host "Arquivos atualizados no broker!" -ForegroundColor Green
