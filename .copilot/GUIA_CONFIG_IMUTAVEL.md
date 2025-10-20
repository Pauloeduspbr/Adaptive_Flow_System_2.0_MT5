# ============================================================================
# GUIA DE USO - CONFIG_IMUTAVEL.ps1
# ============================================================================
# Data: 03/10/2025 12:15
# ============================================================================

## COMO USAR O ARQUIVO DE CONFIGURACAO IMUTAVEL

### 1. CARREGAR CONFIGURACAO (SEMPRE FAZER ISSO PRIMEIRO!)

```powershell
. "d:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5\.copilot\CONFIG_IMUTAVEL.ps1"
```

Isso vai:
- ✅ Validar TODAS as variáveis (broker, paths, EA, indicators)
- ✅ Criar funções helper seguras
- ✅ Mostrar comandos disponíveis

---

### 2. COMANDOS DISPONIVEIS

#### Compilar Expert Advisor
```powershell
Compile-EA-Safe
```

**Output esperado:**
```
Compilando EA...
Arquivo: d:\EA_Projetos\...\AdaptiveFlowSystem_v2.mq5
[OK] Compilacao concluida!
Arquivo: AdaptiveFlowSystem_v2.ex5
Tamanho: 65454 bytes
Data: 10/03/2025 12:12:40
```

---

#### Ver Informações do EA Compilado
```powershell
Get-EA-Info-Safe
```

**Output esperado:**
```
============================================
INFORMACOES DO EA COMPILADO
============================================
Arquivo: AdaptiveFlowSystem_v2.ex5
Tamanho: 65454 bytes
Data: 10/03/2025 12:12:40
Caminho: D:\EA_Projetos\...\AdaptiveFlowSystem_v2.ex5
============================================
```

---

#### Compilar Todos os Indicadores
```powershell
Compile-All-Indicators
```

**Output esperado:**
```
============================================
COMPILANDO TODOS OS INDICADORES
============================================

Compilando ADX Professional...
[OK] Indicator compilado!

Compilando Choppiness Index...
[OK] Indicator compilado!

... (continua para todos)

============================================
RESULTADO: 6 OK | 0 ERRO
============================================
```

---

#### Compilar Indicador Específico
```powershell
# ADX
Compile-Indicator-Safe -IndicatorSourcePath $IND_ADX_SOURCE

# Choppiness Index
Compile-Indicator-Safe -IndicatorSourcePath $IND_CI_SOURCE

# Bollinger Keltner Squeeze
Compile-Indicator-Safe -IndicatorSourcePath $IND_BKS_SOURCE

# ATR
Compile-Indicator-Safe -IndicatorSourcePath $IND_ATR_SOURCE

# Waddah Attar Explosion
Compile-Indicator-Safe -IndicatorSourcePath $IND_WAE_SOURCE

# Volume Profile
Compile-Indicator-Safe -IndicatorSourcePath $IND_VP_SOURCE
```

---

#### Mostrar Toda a Configuração
```powershell
Show-Config
```

**Output esperado:**
```
============================================
CONFIGURACAO IMUTAVEL DO PROJETO
============================================

BROKER:
  Path: C:\Program Files\easyMarkets MetaTrader 5
  MetaEditor: C:\Program Files\easyMarkets MetaTrader 5\metaeditor64.exe
  Terminal: C:\Program Files\easyMarkets MetaTrader 5\terminal64.exe

TERMINAL DATA:
  Path: C:\Users\paulo\AppData\Roaming\MetaQuotes\Terminal\FEC98F1D078C037902D797DB372EA18E

WORKSPACE:
  Root: d:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5
  MQL5: d:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5\MQL5

EXPERT ADVISOR:
  Source: d:\EA_Projetos\...\AdaptiveFlowSystem_v2.mq5
  Compiled: d:\EA_Projetos\...\AdaptiveFlowSystem_v2.ex5

INDICATORS:
  1. ADX: d:\EA_Projetos\...\ADX_Professional.mq5
  2. CI: d:\EA_Projetos\...\ChoppinessIndex_Professional.mq5
  3. BKS: d:\EA_Projetos\...\BollingerKeltnerSqueeze_Professional.mq5
  4. ATR: d:\EA_Projetos\...\ATR_Professional.mq5
  5. WAE: d:\EA_Projetos\...\WaddahAttarExplosion_Professional.mq5
  6. VP: d:\EA_Projetos\...\VolumeProfile_Professional.mq5
============================================
```

---

#### Abrir MetaTrader 5
```powershell
Open-MT5-Safe
```

---

### 3. VARIAVEIS IMUTAVEIS DISPONIVEIS

Após carregar o script, você pode usar estas variáveis em QUALQUER comando:

#### Broker
```powershell
$MT5_BROKER_PATH        # C:\Program Files\easyMarkets MetaTrader 5
$MT5_METAEDITOR         # C:\Program Files\easyMarkets MetaTrader 5\metaeditor64.exe
$MT5_TERMINAL           # C:\Program Files\easyMarkets MetaTrader 5\terminal64.exe
```

#### Terminal Data
```powershell
$MT5_TERMINAL_DATA      # C:\Users\paulo\AppData\Roaming\MetaQuotes\Terminal\FEC98F1D078C037902D797DB372EA18E
```

#### Workspace
```powershell
$WORKSPACE_ROOT         # d:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5
$MQL5_ROOT              # d:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5\MQL5
```

#### Expert Advisor
```powershell
$EA_SOURCE_PATH         # d:\EA_Projetos\...\MQL5\Experts
$EA_SOURCE_FILE         # d:\EA_Projetos\...\MQL5\Experts\AdaptiveFlowSystem_v2.mq5
$EA_COMPILED_FILE       # d:\EA_Projetos\...\MQL5\Experts\AdaptiveFlowSystem_v2.ex5
```

#### Indicadores
```powershell
# ADX Professional
$IND_ADX_PATH           # d:\EA_Projetos\...\Indicators\ADX_Professional
$IND_ADX_SOURCE         # d:\EA_Projetos\...\Indicators\ADX_Professional\ADX_Professional.mq5
$IND_ADX_COMPILED       # d:\EA_Projetos\...\Indicators\ADX_Professional\ADX_Professional.ex5

# Choppiness Index
$IND_CI_PATH
$IND_CI_SOURCE
$IND_CI_COMPILED

# Bollinger Keltner Squeeze
$IND_BKS_PATH
$IND_BKS_SOURCE
$IND_BKS_COMPILED

# ATR Professional
$IND_ATR_PATH
$IND_ATR_SOURCE
$IND_ATR_COMPILED

# Waddah Attar Explosion
$IND_WAE_PATH
$IND_WAE_SOURCE
$IND_WAE_COMPILED

# Volume Profile
$IND_VP_PATH
$IND_VP_SOURCE
$IND_VP_COMPILED
```

---

### 4. EXEMPLOS PRATICOS

#### Compilar EA e verificar resultado
```powershell
. "d:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5\.copilot\CONFIG_IMUTAVEL.ps1"
Compile-EA-Safe
Get-EA-Info-Safe
```

#### Compilar todos os indicators de uma vez
```powershell
. "d:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5\.copilot\CONFIG_IMUTAVEL.ps1"
Compile-All-Indicators
```

#### Verificar paths antes de compilar
```powershell
. "d:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5\.copilot\CONFIG_IMUTAVEL.ps1"
Show-Config
```

#### Usar variável em comando customizado
```powershell
. "d:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5\.copilot\CONFIG_IMUTAVEL.ps1"

# Copiar EA compilado para outra pasta
Copy-Item $EA_COMPILED_FILE -Destination "C:\Backup\"

# Ver conteúdo do arquivo source
Get-Content $EA_SOURCE_FILE | Select-Object -First 50

# Listar todos os arquivos .ex5 compilados
Get-ChildItem "$MQL5_ROOT\Experts\*.ex5"
Get-ChildItem "$MQL5_ROOT\Indicators\**\*.ex5" -Recurse
```

---

### 5. VALIDACAO AUTOMATICA

Quando você carrega o script, ele AUTOMATICAMENTE valida:

✅ **Broker instalado** (easyMarkets MT5)
✅ **MetaEditor existe** (C:\Program Files\easyMarkets MetaTrader 5\metaeditor64.exe)
✅ **Terminal existe** (C:\Program Files\easyMarkets MetaTrader 5\terminal64.exe)
✅ **Terminal Data existe** (pasta do usuário)
✅ **EA Source existe** (AdaptiveFlowSystem_v2.mq5)
⚠️ **Indicadores** (aviso se não encontrados, mas não bloqueia)

**Se houver ERRO CRÍTICO**, o script para com `exit 1`

---

### 6. PROTECAO CONTRA ERROS

As variáveis são **ReadOnly** (somente leitura):

```powershell
# Isso vai FALHAR:
$MT5_BROKER_PATH = "C:\Program Files\MetaTrader 5"  # ❌ ERRO!

# A variável NÃO muda, mantém o valor correto:
# C:\Program Files\easyMarkets MetaTrader 5  # ✅ PROTEGIDO!
```

---

### 7. TROUBLESHOOTING

#### Problema: "Variável não encontrada"
**Solução**: Carregue o script primeiro:
```powershell
. "d:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5\.copilot\CONFIG_IMUTAVEL.ps1"
```

#### Problema: "Compilação falhou Exit code 1"
**Solução**: Verifique erros no VS Code:
```powershell
Get-EA-Info-Safe  # Verifica se compilou mesmo assim
```

#### Problema: "MetaEditor não encontrado"
**Solução**: Verifique se easyMarkets MT5 está instalado:
```powershell
Test-Path "C:\Program Files\easyMarkets MetaTrader 5\metaeditor64.exe"
```

---

### 8. ATUALIZACOES FUTURAS

Se precisar **adicionar novos indicadores**:

1. Edite `CONFIG_IMUTAVEL.ps1`
2. Adicione as variáveis no formato:
```powershell
Set-Variable -Name "IND_NOVO_PATH" -Value "$INDICATORS_ROOT\NovoIndicator" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "IND_NOVO_SOURCE" -Value "$IND_NOVO_PATH\NovoIndicator.mq5" -Option ReadOnly -Scope Global -Force
Set-Variable -Name "IND_NOVO_COMPILED" -Value "$IND_NOVO_PATH\NovoIndicator.ex5" -Option ReadOnly -Scope Global -Force
```
3. Adicione à validação
4. Adicione à função `Compile-All-Indicators`

---

**✅ ARQUIVO CRIADO**: `CONFIG_IMUTAVEL.ps1`
**✅ STATUS**: 100% FUNCIONAL
**✅ TESTADO**: Compilação EA OK (65,454 bytes, 12:12:40)
**✅ BROKER**: easyMarkets MetaTrader 5 (CORRETO!)
