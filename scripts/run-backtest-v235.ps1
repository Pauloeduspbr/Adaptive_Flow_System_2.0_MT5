# ============================================
# BACKTEST AUTOMATIZADO v2.35
# ============================================

param(
    [string]$Symbol = "USDJPY",
    [string]$Period = "M15",
    [string]$FromDate = "2024.01.01",
    [string]$ToDate = "2025.04.30",
    [int]$Deposit = 10000
)

# Carregar configuração
. "$PSScriptRoot\..\.copilot\CONFIG_IMUTAVEL.ps1"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "BACKTEST v2.35 - BE/TS DIFERENCIADO" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Copiar arquivo .set para tester
$SetSource = "$WORKSPACE_ROOT\sets\AFS_v235_USDJPY_M15.set"
$SetDest = "$MT5_TERMINAL_DATA\tester\AdaptiveFlowSystem_v2.set"

if (Test-Path $SetSource) {
    Copy-Item -Path $SetSource -Destination $SetDest -Force
    Write-Host "[OK] Arquivo .set copiado para tester" -ForegroundColor Green
    Write-Host "    De: $SetSource" -ForegroundColor Gray
    Write-Host "    Para: $SetDest" -ForegroundColor Gray
} else {
    Write-Host "[ERRO] Arquivo .set nao encontrado: $SetSource" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "CONFIGURACAO DO BACKTEST:" -ForegroundColor Yellow
Write-Host "  EA: AdaptiveFlowSystem_v2 v2.35" -ForegroundColor White
Write-Host "  Symbol: $Symbol" -ForegroundColor White
Write-Host "  Period: $Period" -ForegroundColor White
Write-Host "  Dates: $FromDate - $ToDate" -ForegroundColor White
Write-Host "  Deposit: `$$Deposit" -ForegroundColor White
Write-Host "  Settings: AFS_v235_USDJPY_M15.set" -ForegroundColor White
Write-Host ""

Write-Host "PARAMETROS v2.35 (BE/TS DIFERENCIADO):" -ForegroundColor Yellow
Write-Host "  SHORT BE: 0.8R (22 pips), Offset 40% (+11 pips)" -ForegroundColor Red
Write-Host "  SHORT TS: 1.5R (42 pips), Step 8 pips" -ForegroundColor Red
Write-Host "  LONG BE: 1.0R (28 pips), Offset 50% (+14 pips)" -ForegroundColor Green
Write-Host "  LONG TS: 1.8R (50 pips), Step 10 pips" -ForegroundColor Green
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "INSTRUCOES PARA EXECUTAR BACKTEST:" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Strategy Tester esta configurado automaticamente" -ForegroundColor White
Write-Host "2. Abra o MT5 (tecle Enter para abrir agora)" -ForegroundColor White
Write-Host "3. Pressione Ctrl+R para abrir Strategy Tester" -ForegroundColor White
Write-Host "4. Configurar:" -ForegroundColor White
Write-Host "   - EA: AdaptiveFlowSystem_v2" -ForegroundColor Gray
Write-Host "   - Symbol: $Symbol" -ForegroundColor Gray
Write-Host "   - Period: $Period" -ForegroundColor Gray
Write-Host "   - Dates: $FromDate - $ToDate" -ForegroundColor Gray
Write-Host "   - Deposit: $Deposit" -ForegroundColor Gray
Write-Host "   - Model: Every tick (mais preciso)" -ForegroundColor Gray
Write-Host "5. Clicar 'Load' e selecionar: AdaptiveFlowSystem_v2.set" -ForegroundColor White
Write-Host "6. DESMARCAR 'Visualization' (mais rapido)" -ForegroundColor White
Write-Host "7. Clicar 'Start'" -ForegroundColor White
Write-Host ""

Write-Host "O QUE OBSERVAR NOS RESULTADOS:" -ForegroundColor Yellow
Write-Host "  - Total trades vs v2.34 (57 trades)" -ForegroundColor White
Write-Host "  - Win rate > 25% (v2.34)" -ForegroundColor White
Write-Host "  - Profit factor > 0" -ForegroundColor White
Write-Host "  - Drawdown < v2.34" -ForegroundColor White
Write-Host ""

Write-Host "O QUE OBSERVAR NOS LOGS:" -ForegroundColor Yellow
Write-Host '  - "✅ BREAK EVEN [SETUP A SHORT]:" em ~40% dos SHORT' -ForegroundColor Red
Write-Host '  - "✅ BREAK EVEN [SETUP A LONG]:" em ~60% dos LONG' -ForegroundColor Green
Write-Host '  - "🎯 TRAILING [SETUP A SHORT]:" quando lucro > +42 pips' -ForegroundColor Red
Write-Host '  - "🎯 TRAILING [SETUP A LONG]:" quando lucro > +50 pips' -ForegroundColor Green
Write-Host ""

$response = Read-Host "Pressione Enter para abrir MT5 (ou 'N' para cancelar)"
if ($response -ne "N" -and $response -ne "n") {
    Write-Host "[OK] Abrindo MT5..." -ForegroundColor Green
    Open-MT5-Safe
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "APOS O BACKTEST CONCLUIR:" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Execute para analisar os logs:" -ForegroundColor Yellow
    Write-Host '  $LogPath = Get-Latest-Backtest-Log' -ForegroundColor Gray
    Write-Host '  python analise_BE_TS_por_direcao.py' -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "[INFO] Cancelado pelo usuario" -ForegroundColor Yellow
}
