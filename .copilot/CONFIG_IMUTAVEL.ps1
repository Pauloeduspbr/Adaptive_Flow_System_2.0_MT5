# ============================================================================
# CONFIGURACAO IMUTAVEL - Adaptive Flow System 2.0
# ============================================================================
# ATENCAO: Este arquivo define TODAS as variaveis do projeto
#          NUNCA altere manualmente - sao CONSTANTES
# Data: 03/10/2025 12:05
# ============================================================================

# ============================================================================
# BROKER - easyMarkets MetaTrader 5 (IMUTAVEL)
# ============================================================================
Set-Variable -Name "MT5_BROKER_PATH" -Value "C:\Program Files\easyMarkets MetaTrader 5" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "MT5_METAEDITOR" -Value "$MT5_BROKER_PATH\metaeditor64.exe" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "MT5_TERMINAL" -Value "$MT5_BROKER_PATH\terminal64.exe" -Option ReadOnly -Scope Global -Force

# ============================================================================
# TERMINAL DATA (IMUTAVEL)
# ============================================================================
Set-Variable -Name "MT5_TERMINAL_DATA" -Value "C:\Users\paulo\AppData\Roaming\MetaQuotes\Terminal\FEC98F1D078C037902D797DB372EA18E" -Option ReadOnly -Scope Global -Force

# ============================================================================
# WORKSPACE PATHS (IMUTAVEL)
# ============================================================================
Set-Variable -Name "WORKSPACE_ROOT" -Value "d:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "MQL5_ROOT" -Value "$WORKSPACE_ROOT\MQL5" -Option ReadOnly -Scope Global -Force

# ============================================================================
# EXPERT ADVISOR (IMUTAVEL)
# ============================================================================
Set-Variable -Name "EA_SOURCE_PATH" -Value "$MQL5_ROOT\Experts\AdaptiveFlowSystem_v2" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "EA_SOURCE_FILE" -Value "$EA_SOURCE_PATH\AdaptiveFlowSystem_v2.mq5" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "EA_COMPILED_FILE" -Value "$EA_SOURCE_PATH\AdaptiveFlowSystem_v2.ex5" -Option ReadOnly -Scope Global -Force

# ============================================================================
# INDICATORS (IMUTAVEL)
# ============================================================================
Set-Variable -Name "INDICATORS_ROOT" -Value "$MQL5_ROOT\Indicators" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "INCLUDE_ROOT" -Value "$MQL5_ROOT\Include" -Option ReadOnly -Scope Global -Force

# ADX Professional
Set-Variable -Name "IND_ADX_PATH" -Value "$INDICATORS_ROOT\ADX_Professional" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "IND_ADX_SOURCE" -Value "$IND_ADX_PATH\ADX_Professional.mq5" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "IND_ADX_COMPILED" -Value "$IND_ADX_PATH\ADX_Professional.ex5" -Option ReadOnly -Scope Global -Force

# Choppiness Index
Set-Variable -Name "IND_CI_PATH" -Value "$INDICATORS_ROOT\ChoppinessIndex_Professional" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "IND_CI_SOURCE" -Value "$IND_CI_PATH\ChoppinessIndex_Professional.mq5" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "IND_CI_COMPILED" -Value "$IND_CI_PATH\ChoppinessIndex_Professional.ex5" -Option ReadOnly -Scope Global -Force

# Bollinger Keltner Squeeze
Set-Variable -Name "IND_BKS_PATH" -Value "$INDICATORS_ROOT\BollingerKeltnerSqueeze_Professional" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "IND_BKS_SOURCE" -Value "$IND_BKS_PATH\BollingerKeltnerSqueeze_Professional.mq5" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "IND_BKS_COMPILED" -Value "$IND_BKS_PATH\BollingerKeltnerSqueeze_Professional.ex5" -Option ReadOnly -Scope Global -Force

# ATR Professional
Set-Variable -Name "IND_ATR_PATH" -Value "$INDICATORS_ROOT\ATR_Professional" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "IND_ATR_SOURCE" -Value "$IND_ATR_PATH\ATR_Professional.mq5" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "IND_ATR_COMPILED" -Value "$IND_ATR_PATH\ATR_Professional.ex5" -Option ReadOnly -Scope Global -Force

# Waddah Attar Explosion
Set-Variable -Name "IND_WAE_PATH" -Value "$INDICATORS_ROOT\WaddahAttarExplosion_Professional" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "IND_WAE_SOURCE" -Value "$IND_WAE_PATH\WaddahAttarExplosion_Professional.mq5" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "IND_WAE_COMPILED" -Value "$IND_WAE_PATH\WaddahAttarExplosion_Professional.ex5" -Option ReadOnly -Scope Global -Force

# Volume Profile
Set-Variable -Name "IND_VP_PATH" -Value "$INDICATORS_ROOT\VolumeProfile_Professional" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "IND_VP_SOURCE" -Value "$IND_VP_PATH\VolumeProfile_Professional.mq5" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "IND_VP_COMPILED" -Value "$IND_VP_PATH\VolumeProfile_Professional.ex5" -Option ReadOnly -Scope Global -Force

# Include Files (MQH)
Set-Variable -Name "INCLUDE_REGIME_DETECTOR" -Value "$INCLUDE_ROOT\AFS_RegimeDetector.mqh" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "INCLUDE_SETUP_MANAGER" -Value "$INCLUDE_ROOT\AFS_SetupManager.mqh" -Option ReadOnly -Scope Global -Force

# ============================================================================
# VALIDACAO - Verifica se paths existem
# ============================================================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "VALIDANDO CONFIGURACAO IMUTAVEL" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$validationErrors = 0

# Valida Broker
if (Test-Path $MT5_METAEDITOR) {
    Write-Host "[OK] MetaEditor encontrado" -ForegroundColor Green
} else {
    Write-Host "[ERRO] MetaEditor NAO encontrado em: $MT5_METAEDITOR" -ForegroundColor Red
    $validationErrors++
}

if (Test-Path $MT5_TERMINAL) {
    Write-Host "[OK] Terminal encontrado" -ForegroundColor Green
} else {
    Write-Host "[ERRO] Terminal NAO encontrado em: $MT5_TERMINAL" -ForegroundColor Red
    $validationErrors++
}

# Valida Terminal Data
if (Test-Path $MT5_TERMINAL_DATA) {
    Write-Host "[OK] Terminal Data encontrado" -ForegroundColor Green
} else {
    Write-Host "[AVISO] Terminal Data NAO encontrado (pode nao ter sido iniciado ainda)" -ForegroundColor Yellow
}

# Valida EA
if (Test-Path $EA_SOURCE_FILE) {
    Write-Host "[OK] EA Source encontrado" -ForegroundColor Green
} else {
    Write-Host "[ERRO] EA Source NAO encontrado em: $EA_SOURCE_FILE" -ForegroundColor Red
    $validationErrors++
}

# Valida Indicators
$indicators = @(
    @{Name="ADX Professional"; Path=$IND_ADX_SOURCE},
    @{Name="Choppiness Index"; Path=$IND_CI_SOURCE},
    @{Name="Bollinger Keltner Squeeze"; Path=$IND_BKS_SOURCE},
    @{Name="ATR Professional"; Path=$IND_ATR_SOURCE},
    @{Name="Waddah Attar Explosion"; Path=$IND_WAE_SOURCE},
    @{Name="Volume Profile"; Path=$IND_VP_SOURCE}
)

foreach ($ind in $indicators) {
    if (Test-Path $ind.Path) {
        Write-Host "[OK] $($ind.Name)" -ForegroundColor Green
    } else {
        Write-Host "[AVISO] $($ind.Name) NAO encontrado" -ForegroundColor Yellow
    }
}

Write-Host ""
if ($validationErrors -eq 0) {
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "VALIDACAO COMPLETA - CONFIGURACAO OK" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
} else {
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "VALIDACAO FALHOU - $validationErrors ERROS" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================================
# FUNCOES HELPER
# ============================================================================

function Compile-EA-Safe {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "COMPILANDO EA + DEPLOY AUTOMATICO" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "Arquivo: $EA_SOURCE_FILE" -ForegroundColor Gray
    Write-Host ""
    
    # COMPILAR
    & $MT5_METAEDITOR /compile:$EA_SOURCE_FILE /log
    
    Start-Sleep -Seconds 2  # Aguarda compilacao finalizar
    
    if (Test-Path $EA_COMPILED_FILE) {
        $info = Get-Item $EA_COMPILED_FILE
        Write-Host "[OK] Compilacao concluida!" -ForegroundColor Green
        Write-Host "Arquivo: $($info.Name)" -ForegroundColor Cyan
        Write-Host "Tamanho: $($info.Length) bytes" -ForegroundColor Cyan
        Write-Host "Data: $($info.LastWriteTime)" -ForegroundColor Cyan
        Write-Host ""
        
        # LIMPAR PASTA DO BROKER ANTES DE COPIAR (REMOVE ARQUIVOS ANTIGOS)
        Write-Host "Limpando pasta do broker..." -ForegroundColor Yellow
        $brokerExpertsPath = "$MT5_TERMINAL_DATA\MQL5\Experts\AdaptiveFlowSystem_v2"
        
        if (Test-Path $brokerExpertsPath) {
            Remove-Item "$brokerExpertsPath\*" -Force -ErrorAction SilentlyContinue
            Write-Host "[OK] Arquivos antigos removidos" -ForegroundColor Green
        } else {
            New-Item -ItemType Directory -Path $brokerExpertsPath -Force | Out-Null
            Write-Host "[OK] Pasta criada: $brokerExpertsPath" -ForegroundColor Green
        }
        
        # COPIAR ARQUIVOS NOVOS PARA BROKER
        Write-Host "Copiando arquivos para broker..." -ForegroundColor Yellow
        Copy-Item $EA_COMPILED_FILE -Destination $brokerExpertsPath -Force
        Copy-Item $EA_SOURCE_FILE -Destination $brokerExpertsPath -Force
        
        # VERIFICAR SE COPIOU (.ex5 e .mq5)
        $brokerEx5 = "$brokerExpertsPath\AdaptiveFlowSystem_v2.ex5"
        $brokerMq5 = "$brokerExpertsPath\AdaptiveFlowSystem_v2.mq5"
        if (Test-Path $brokerEx5) {
            $brokerInfo = Get-Item $brokerEx5
            Write-Host "[OK] EA .ex5 copiado!" -ForegroundColor Green
            Write-Host "  Caminho: $brokerEx5" -ForegroundColor Gray
            Write-Host "  Tamanho: $($brokerInfo.Length) bytes" -ForegroundColor Cyan
            Write-Host "  Data: $($brokerInfo.LastWriteTime)" -ForegroundColor Cyan
        } else {
            Write-Host "[ERRO] Falha ao copiar .ex5 para broker!" -ForegroundColor Red
        }
        if (Test-Path $brokerMq5) {
            $brokerInfoSrc = Get-Item $brokerMq5
            Write-Host "[OK] EA .mq5 copiado!" -ForegroundColor Green
            Write-Host "  Caminho: $brokerMq5" -ForegroundColor Gray
            Write-Host "  Tamanho: $($brokerInfoSrc.Length) bytes" -ForegroundColor Cyan
            Write-Host "  Data: $($brokerInfoSrc.LastWriteTime)" -ForegroundColor Cyan
        } else {
            Write-Host "[ERRO] Falha ao copiar .mq5 para broker!" -ForegroundColor Red
        }
        Write-Host ""
        
        # COPIAR INCLUDE FILES COM LOG DETALHADO
        Write-Host "Copiando Include files (.mqh)..." -ForegroundColor Yellow
        $brokerIncludePath = "$MT5_TERMINAL_DATA\MQL5\Include"
        if (-not (Test-Path $brokerIncludePath)) {
            New-Item -ItemType Directory -Path $brokerIncludePath -Force | Out-Null
            Write-Host "  [+] Pasta criada: $brokerIncludePath" -ForegroundColor Gray
        }
        
        # Copiar AFS_RegimeDetector.mqh
        if (Test-Path $INCLUDE_REGIME_DETECTOR) {
            Copy-Item $INCLUDE_REGIME_DETECTOR -Destination $brokerIncludePath -Force
            $destFile = "$brokerIncludePath\AFS_RegimeDetector.mqh"
            if (Test-Path $destFile) {
                $fileInfo = Get-Item $destFile
                Write-Host "  [OK] AFS_RegimeDetector.mqh ($($fileInfo.Length) bytes)" -ForegroundColor Green
            } else {
                Write-Host "  [ERRO] Falha ao copiar AFS_RegimeDetector.mqh" -ForegroundColor Red
            }
        }
        
        # Copiar AFS_SetupManager.mqh
        if (Test-Path $INCLUDE_SETUP_MANAGER) {
            Copy-Item $INCLUDE_SETUP_MANAGER -Destination $brokerIncludePath -Force
            $destFile = "$brokerIncludePath\AFS_SetupManager.mqh"
            if (Test-Path $destFile) {
                $fileInfo = Get-Item $destFile
                Write-Host "  [OK] AFS_SetupManager.mqh ($($fileInfo.Length) bytes)" -ForegroundColor Green
            } else {
                Write-Host "  [ERRO] Falha ao copiar AFS_SetupManager.mqh" -ForegroundColor Red
            }
        }
        Write-Host ""
        
        # COPIAR INDICADORES COM LOG DETALHADO
        Write-Host "Copiando Indicadores (.ex5 + .mq5)..." -ForegroundColor Yellow
        $indicatorsList = @(
            @{Name="ADX_Professional"; Source=$IND_ADX_SOURCE; Compiled=$IND_ADX_COMPILED},
            @{Name="ChoppinessIndex_Professional"; Source=$IND_CI_SOURCE; Compiled=$IND_CI_COMPILED},
            @{Name="BollingerKeltnerSqueeze_Professional"; Source=$IND_BKS_SOURCE; Compiled=$IND_BKS_COMPILED},
            @{Name="ATR_Professional"; Source=$IND_ATR_SOURCE; Compiled=$IND_ATR_COMPILED},
            @{Name="WaddahAttarExplosion_Professional"; Source=$IND_WAE_SOURCE; Compiled=$IND_WAE_COMPILED},
            @{Name="VolumeProfile_Professional"; Source=$IND_VP_SOURCE; Compiled=$IND_VP_COMPILED}
        )
        
        foreach ($indicator in $indicatorsList) {
            $brokerIndPath = "$MT5_TERMINAL_DATA\MQL5\Indicators\$($indicator.Name)"
            
            # Criar pasta se não existir
            if (-not (Test-Path $brokerIndPath)) {
                New-Item -ItemType Directory -Path $brokerIndPath -Force | Out-Null
                Write-Host "  [+] Pasta criada: $($indicator.Name)" -ForegroundColor Gray
            }
            
            # Copiar .ex5 (compilado)
            if (Test-Path $indicator.Compiled) {
                Copy-Item $indicator.Compiled -Destination $brokerIndPath -Force
                $destEx5 = "$brokerIndPath\$($indicator.Name).ex5"
                if (Test-Path $destEx5) {
                    $fileInfo = Get-Item $destEx5
                    Write-Host "  [OK] $($indicator.Name).ex5 ($($fileInfo.Length) bytes)" -ForegroundColor Green
                } else {
                    Write-Host "  [ERRO] Falha ao copiar $($indicator.Name).ex5" -ForegroundColor Red
                }
            } else {
                Write-Host "  [AVISO] $($indicator.Name).ex5 não encontrado no repositório" -ForegroundColor Yellow
            }
            
            # Copiar .mq5 (código-fonte)
            if (Test-Path $indicator.Source) {
                Copy-Item $indicator.Source -Destination $brokerIndPath -Force
                $destMq5 = "$brokerIndPath\$($indicator.Name).mq5"
                if (Test-Path $destMq5) {
                    $fileInfo = Get-Item $destMq5
                    Write-Host "  [OK] $($indicator.Name).mq5 ($($fileInfo.Length) bytes)" -ForegroundColor Green
                } else {
                    Write-Host "  [ERRO] Falha ao copiar $($indicator.Name).mq5" -ForegroundColor Red
                }
            } else {
                Write-Host "  [AVISO] $($indicator.Name).mq5 não encontrado no repositório" -ForegroundColor Yellow
            }
        }
        Write-Host ""
        
        # LIMPAR CACHE MT5
        Write-Host "Limpando cache MT5..." -ForegroundColor Yellow
        Clear-MT5-Cache
        
        Write-Host ""
        Write-Host "============================================" -ForegroundColor Green
        Write-Host "DEPLOY COMPLETO! EA PRONTO NO BROKER!" -ForegroundColor Green
        Write-Host "============================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "PROXIMO PASSO: Abra MT5 e execute o backtest" -ForegroundColor Yellow
        return $true
    } else {
        Write-Host "[ERRO] Compilacao falhou! Exit code: $LASTEXITCODE" -ForegroundColor Red
        return $false
    }
}

function Compile-Indicator-Safe {
    param([string]$IndicatorSourcePath)
    
    if (-not (Test-Path $IndicatorSourcePath)) {
        Write-Host "[ERRO] Indicator nao encontrado: $IndicatorSourcePath" -ForegroundColor Red
        return $false
    }
    
    Write-Host "Compilando indicator: $IndicatorSourcePath" -ForegroundColor Yellow
    
    & $MT5_METAEDITOR /compile:$IndicatorSourcePath /log
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Indicator compilado!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[ERRO] Compilacao falhou! Exit code: $LASTEXITCODE" -ForegroundColor Red
        return $false
    }
}

function Compile-All-Indicators {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "COMPILANDO TODOS OS INDICADORES" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    
    $success = 0
    $failed = 0
    
    $indicators = @(
        @{Name="ADX Professional"; Path=$IND_ADX_SOURCE},
        @{Name="Choppiness Index"; Path=$IND_CI_SOURCE},
        @{Name="Bollinger Keltner Squeeze"; Path=$IND_BKS_SOURCE},
        @{Name="ATR Professional"; Path=$IND_ATR_SOURCE},
        @{Name="Waddah Attar Explosion"; Path=$IND_WAE_SOURCE},
        @{Name="Volume Profile"; Path=$IND_VP_SOURCE}
    )
    
    foreach ($ind in $indicators) {
        Write-Host "Compilando $($ind.Name)..." -ForegroundColor Yellow
        if (Compile-Indicator-Safe -IndicatorSourcePath $ind.Path) {
            $success++
        } else {
            $failed++
        }
        Write-Host ""
    }
    
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "RESULTADO: $success OK | $failed ERRO" -ForegroundColor $(if ($failed -eq 0) {"Green"} else {"Yellow"})
    Write-Host "============================================" -ForegroundColor Cyan
}

function Get-EA-Info-Safe {
    if (Test-Path $EA_COMPILED_FILE) {
        $info = Get-Item $EA_COMPILED_FILE
        Write-Host "============================================" -ForegroundColor Cyan
        Write-Host "INFORMACOES DO EA COMPILADO" -ForegroundColor Cyan
        Write-Host "============================================" -ForegroundColor Cyan
        Write-Host "Arquivo: $($info.Name)" -ForegroundColor White
        Write-Host "Tamanho: $($info.Length) bytes" -ForegroundColor White
        Write-Host "Data: $($info.LastWriteTime)" -ForegroundColor White
        Write-Host "Caminho: $($info.FullName)" -ForegroundColor Gray
        Write-Host "============================================" -ForegroundColor Cyan
        return $info
    } else {
        Write-Host "[AVISO] EA nao compilado ainda" -ForegroundColor Yellow
        return $null
    }
}

function Open-MT5-Safe {
    Write-Host "Abrindo easyMarkets MT5..." -ForegroundColor Yellow
    if (Test-Path $MT5_TERMINAL) {
        Start-Process $MT5_TERMINAL
        Write-Host "[OK] Terminal aberto!" -ForegroundColor Green
    } else {
        Write-Host "[ERRO] Terminal nao encontrado" -ForegroundColor Red
    }
}

function Clear-MT5-Cache {
    Write-Host "Limpando cache do MetaTrader 5..." -ForegroundColor Yellow
    
    $cachePaths = @(
        "$MT5_TERMINAL_DATA\bases",
        "$MT5_TERMINAL_DATA\tester\cache",
        "$MT5_TERMINAL_DATA\tester\logs"
    )
    
    foreach ($path in $cachePaths) {
        if (Test-Path $path) {
            try {
                Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "[OK] Cache limpo: $path" -ForegroundColor Green
            } catch {
                Write-Host "[AVISO] Nao foi possivel limpar: $path" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "[OK] Cache do MT5 limpo!" -ForegroundColor Green
}

function Deploy-EA-To-Broker {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "DEPLOY EA PARA BROKER" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Verifica se EA compilado existe
    if (-not (Test-Path $EA_COMPILED_FILE)) {
        Write-Host "[ERRO] EA nao compilado! Execute Compile-EA-Safe primeiro" -ForegroundColor Red
        return $false
    }
    
    # Cria pasta no broker com subpasta EA
    $brokerExpertsPath = "$MT5_TERMINAL_DATA\MQL5\Experts\AdaptiveFlowSystem_v2"
    if (-not (Test-Path $brokerExpertsPath)) {
        New-Item -ItemType Directory -Path $brokerExpertsPath -Force | Out-Null
        Write-Host "[OK] Pasta criada: $brokerExpertsPath" -ForegroundColor Green
    }
    
    # Copia arquivos EA para subpasta
    Write-Host "Copiando arquivos..." -ForegroundColor Yellow
    Copy-Item $EA_COMPILED_FILE -Destination $brokerExpertsPath -Force
    Copy-Item $EA_SOURCE_FILE -Destination $brokerExpertsPath -Force
    
    # Copia Include files
    $brokerIncludePath = "$MT5_TERMINAL_DATA\MQL5\Include"
    if (-not (Test-Path $brokerIncludePath)) {
        New-Item -ItemType Directory -Path $brokerIncludePath -Force | Out-Null
    }
    Copy-Item $INCLUDE_REGIME_DETECTOR -Destination $brokerIncludePath -Force -ErrorAction SilentlyContinue
    Copy-Item $INCLUDE_SETUP_MANAGER -Destination $brokerIncludePath -Force -ErrorAction SilentlyContinue
    
    $info = Get-Item $EA_COMPILED_FILE
    Write-Host "[OK] EA copiado:" -ForegroundColor Green
    Write-Host "  De: $EA_COMPILED_FILE" -ForegroundColor Gray
    Write-Host "  Para: $brokerExpertsPath" -ForegroundColor Gray
    Write-Host "  Tamanho: $($info.Length) bytes" -ForegroundColor Cyan
    Write-Host "  Data: $($info.LastWriteTime)" -ForegroundColor Cyan
    Write-Host ""
    
    # Limpa cache
    Clear-MT5-Cache
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "DEPLOY COMPLETO!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "PROXIMO PASSO:" -ForegroundColor Yellow
    Write-Host "1. Abrir MT5: Open-MT5-Safe" -ForegroundColor White
    Write-Host "2. Recarregar lista de EAs (Ctrl+R no Navigator)" -ForegroundColor White
    Write-Host "3. Executar backtest" -ForegroundColor White
    
    return $true
}

function Show-Config {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "CONFIGURACAO IMUTAVEL DO PROJETO" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "BROKER:" -ForegroundColor Yellow
    Write-Host "  Path: $MT5_BROKER_PATH" -ForegroundColor White
    Write-Host "  MetaEditor: $MT5_METAEDITOR" -ForegroundColor White
    Write-Host "  Terminal: $MT5_TERMINAL" -ForegroundColor White
    Write-Host ""
    Write-Host "TERMINAL DATA:" -ForegroundColor Yellow
    Write-Host "  Path: $MT5_TERMINAL_DATA" -ForegroundColor White
    Write-Host ""
    Write-Host "WORKSPACE:" -ForegroundColor Yellow
    Write-Host "  Root: $WORKSPACE_ROOT" -ForegroundColor White
    Write-Host "  MQL5: $MQL5_ROOT" -ForegroundColor White
    Write-Host ""
    Write-Host "EXPERT ADVISOR:" -ForegroundColor Yellow
    Write-Host "  Source: $EA_SOURCE_FILE" -ForegroundColor White
    Write-Host "  Compiled: $EA_COMPILED_FILE" -ForegroundColor White
    Write-Host ""
    Write-Host "INDICATORS:" -ForegroundColor Yellow
    Write-Host "  1. ADX: $IND_ADX_SOURCE" -ForegroundColor White
    Write-Host "  2. CI: $IND_CI_SOURCE" -ForegroundColor White
    Write-Host "  3. BKS: $IND_BKS_SOURCE" -ForegroundColor White
    Write-Host "  4. ATR: $IND_ATR_SOURCE" -ForegroundColor White
    Write-Host "  5. WAE: $IND_WAE_SOURCE" -ForegroundColor White
    Write-Host "  6. VP: $IND_VP_SOURCE" -ForegroundColor White
    Write-Host "============================================" -ForegroundColor Cyan
}

function Run-Backtest-Safe {
    param(
        [string]$Symbol = "USDJPY",
        [string]$Timeframe = "M15",
        [string]$StartDate = "2024.01.01",
        [string]$EndDate = "2025.09.19",
        [double]$Deposit = 70.0,
        [double]$Confidence = 0.65,
        [string]$StartTime = "07:00",
        [string]$EndTime = "17:00",
        [bool]$ClearLogFirst = $true
    )
    
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "BACKTEST AUTOMATIZADO - EA v2.06" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Parametros do teste
    Write-Host "CONFIGURACAO DO TESTE:" -ForegroundColor Yellow
    Write-Host "  EA: AdaptiveFlowSystem_v2 (v2.06)" -ForegroundColor White
    Write-Host "  Symbol: $Symbol" -ForegroundColor White
    Write-Host "  Timeframe: $Timeframe" -ForegroundColor White
    Write-Host "  Period: $StartDate - $EndDate" -ForegroundColor White
    Write-Host "  Deposit: R$ $Deposit" -ForegroundColor White
    Write-Host "  Model: Every tick" -ForegroundColor White
    Write-Host "  Confidence: $Confidence" -ForegroundColor White
    Write-Host "  Horario: $StartTime - $EndTime" -ForegroundColor White
    Write-Host ""
    
    # 1. LIMPAR LOGS ANTIGOS
    if ($ClearLogFirst) {
        Write-Host "[1/5] Limpando logs antigos..." -ForegroundColor Yellow
        $logPath = "$MT5_TERMINAL_DATA\tester\logs"
        if (Test-Path $logPath) {
            Remove-Item "$logPath\*.log" -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Logs antigos removidos" -ForegroundColor Green
        }
    }
    
    # 2. CRIAR ARQUIVO .SET COM PARAMETROS
    Write-Host "[2/5] Criando arquivo de parametros (.set)..." -ForegroundColor Yellow
    $setContent = @"
; Adaptive Flow System v2.06 - Backtest Configuration
; Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

InpMagicNumber=240125
InpTradeComment=AFS_v206_Backtest
InpRiskPercent=1.0
InpMaxDailyRisk=2.0
InpMaxWeeklyRisk=5.0
InpMaxOpenPositions=2
InpCorrelationThreshold=0.75

; REGIME DETECTION
InpADX_Period=14
InpADX_TrendThreshold=25.0
InpCI_Period=14
InpCI_RangingThreshold=61.8
InpBB_Period=20
InpBB_Deviation=2.0
InpBBW_SqueezeThreshold=3.0

; INDICATORS
InpATR_Period=14
InpATR_ROC_Period=5
InpWAE_FastMA=20
InpWAE_SlowMA=40
InpWAE_Sensitivity=150
InpUseVolumeProfile=true
InpUseOrderFlow=false

; TRADING SETUPS
InpEnableSetupA=true
InpEnableSetupB=true
InpEnableSetupC=true
InpEnableSetupD=true
InpEnableSetupE=true
InpEnableSetupF=true

; SIGNAL CONFIDENCE (CORRECAO #6)
InpMinSignalConfidence=$Confidence

; TRADING SESSIONS
InpTradeAsianSession=false
InpTradeLondonSession=true
InpTradeNewYorkSession=true
InpTimeZoneOffset=2

; TEMPORAL FILTER (CORRECAO #9)
InpStartTimeHHMM=$StartTime
InpEndTimeHHMM=$EndTime

InpSlippage=10
"@
    
    $setFilePath = "$MT5_TERMINAL_DATA\tester\AdaptiveFlowSystem_v2.set"
    $setContent | Out-File -FilePath $setFilePath -Encoding UTF8 -Force
    Write-Host "  [OK] Arquivo .set criado: $setFilePath" -ForegroundColor Green
    
    # 3. INFORMACOES PARA EXECUCAO MANUAL
    Write-Host ""
    Write-Host "[3/5] Preparando ambiente..." -ForegroundColor Yellow
    Write-Host "  [OK] EA deployado em: Experts\AdaptiveFlowSystem_v2\" -ForegroundColor Green
    Write-Host "  [OK] Parametros salvos em: tester\AdaptiveFlowSystem_v2.set" -ForegroundColor Green
    Write-Host ""
    
    # 4. INSTRUCOES PARA EXECUCAO MANUAL (MT5 nao tem CLI completo)
    Write-Host "[4/5] INSTRUCOES PARA BACKTEST:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  O MT5 nao suporta backtest 100% automatizado via linha de comando." -ForegroundColor Gray
    Write-Host "  Execute os seguintes passos no Strategy Tester:" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  1. Abrir MT5: Open-MT5-Safe" -ForegroundColor White
    Write-Host "  2. Pressionar Ctrl+R para abrir Strategy Tester" -ForegroundColor White
    Write-Host "  3. Selecionar:" -ForegroundColor White
    Write-Host "     - EA: AdaptiveFlowSystem_v2" -ForegroundColor Cyan
    Write-Host "     - Symbol: $Symbol" -ForegroundColor Cyan
    Write-Host "     - Period: $Timeframe" -ForegroundColor Cyan
    Write-Host "     - Dates: $StartDate - $EndDate" -ForegroundColor Cyan
    Write-Host "     - Deposit: $Deposit" -ForegroundColor Cyan
    Write-Host "     - Model: Every tick" -ForegroundColor Cyan
    Write-Host "  4. Clicar em 'Load' e selecionar: AdaptiveFlowSystem_v2.set" -ForegroundColor White
    Write-Host "  5. DESMARCAR: Visualization (sem grafico)" -ForegroundColor White
    Write-Host "  6. Clicar em 'Start'" -ForegroundColor White
    Write-Host ""
    
    # 5. ONDE ENCONTRAR O LOG
    Write-Host "[5/5] LOCALIZACAO DO LOG:" -ForegroundColor Yellow
    $expectedLogPath = "$MT5_TERMINAL_DATA\tester\logs"
    Write-Host "  Caminho: $expectedLogPath" -ForegroundColor Cyan
    Write-Host "  Arquivo: AAAAMMDD.log (data do teste)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Apos conclusao do backtest, use:" -ForegroundColor Gray
    Write-Host "  Get-ChildItem '$expectedLogPath' | Sort-Object LastWriteTime -Descending | Select-Object -First 1" -ForegroundColor White
    Write-Host ""
    
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "CONFIGURACAO PRONTA! Execute manualmente" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    
    # Perguntar se deve abrir MT5
    $response = Read-Host "Deseja abrir MT5 agora? (S/N)"
    if ($response -eq "S" -or $response -eq "s") {
        Open-MT5-Safe
    }
    
    return $true
}

function Get-Latest-Backtest-Log {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "LOCALIZANDO LOG MAIS RECENTE" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    
    $logPath = "$MT5_TERMINAL_DATA\tester\logs"
    if (-not (Test-Path $logPath)) {
        Write-Host "[ERRO] Pasta de logs nao encontrada: $logPath" -ForegroundColor Red
        return $null
    }
    
    $latestLog = Get-ChildItem "$logPath\*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    if ($latestLog) {
        Write-Host "[OK] Log encontrado:" -ForegroundColor Green
        Write-Host "  Arquivo: $($latestLog.Name)" -ForegroundColor White
        Write-Host "  Caminho: $($latestLog.FullName)" -ForegroundColor Gray
        Write-Host "  Tamanho: $($latestLog.Length) bytes" -ForegroundColor Cyan
        Write-Host "  Data: $($latestLog.LastWriteTime)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Para copiar para workspace:" -ForegroundColor Yellow
        Write-Host "  Copy-Item '$($latestLog.FullName)' -Destination '.\logs\backtest_v206_$(Get-Date -Format 'yyyyMMdd_HHmmss').log'" -ForegroundColor White
        Write-Host ""
        
        return $latestLog.FullName
    } else {
        Write-Host "[ERRO] Nenhum log encontrado em: $logPath" -ForegroundColor Red
        return $null
    }
}

# ============================================================================
# EXEMPLOS DE USO
# ============================================================================
Write-Host "COMANDOS DISPONIVEIS:" -ForegroundColor Yellow
Write-Host "  Compile-EA-Safe                - Compila EA + Deploy + Limpa Cache" -ForegroundColor White
Write-Host "  Deploy-EA-To-Broker            - Copia EA para broker + Limpa Cache" -ForegroundColor White
Write-Host "  Clear-MT5-Cache                - Limpa apenas o cache" -ForegroundColor White
Write-Host "  Compile-All-Indicators         - Compila todos os indicadores" -ForegroundColor White
Write-Host "  Compile-Indicator-Safe -Path   - Compila um indicador especifico" -ForegroundColor White
Write-Host "  Get-EA-Info-Safe               - Mostra info do EA compilado" -ForegroundColor White
Write-Host "  Open-MT5-Safe                  - Abre o MT5" -ForegroundColor White
Write-Host "  Show-Config                    - Mostra toda a configuracao" -ForegroundColor White
Write-Host "  Run-Backtest-Safe              - Prepara e orienta backtest automatizado" -ForegroundColor White
Write-Host "  Get-Latest-Backtest-Log        - Localiza o log mais recente do backtest" -ForegroundColor White
Write-Host ""
