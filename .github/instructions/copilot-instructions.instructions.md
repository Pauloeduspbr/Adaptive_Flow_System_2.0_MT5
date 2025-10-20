---
applyTo: '**'
---
# COPILOT AGENT CONFIGURATION - ADAPTIVE FLOW SYSTEM 2.0 (MQL5)

## 🚨 CRITICAL RULES - MANDATORY!

### ⚠️ RULE #1: NEVER COMPILE DIRECTLY WITH MetaEditor64.exe!

### ⚠️ RULE #2: NEVER CREATE .SET FILES WITH WRONG FORMAT!

**WRONG (FORBIDDEN)**:
```powershell
# NUNCA faça isso:
& "C:\Program Files\MetaTrader 5\metaeditor64.exe" /compile:"AdaptiveFlowSystem_v2.mq5"
& "C:\Program Files\easyMarkets MetaTrader 5\metaeditor64.exe" /compile:"..."
& "D:\ForexTime MT5 Terminal\metaeditor64.exe" /compile:"..."
```

**CORRECT (MANDATORY)**:
```powershell
. "d:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5\.copilot\CONFIG_IMUTAVEL.ps1"; Compile-EA-Safe
```

### Why?
- Direct compilation uses **HARDCODED PATHS** (error-prone, wrong terminal instance)
- **CONFIG_IMUTAVEL.ps1** contains the **SINGLE SOURCE OF TRUTH** for all paths:
  - ✅ Correct broker terminal (easyMarkets MetaTrader 5)
  - ✅ Correct terminal data directory (AppData\Roaming\MetaQuotes\...)
  - ✅ Correct EA/Indicator paths (workspace MQL5 structure)
- **ALWAYS use `Compile-EA-Safe`** function from this script
- Script automatically:
  1. Compiles EA with correct MetaEditor instance
  2. Deploys .ex5 + .mq5 to broker terminal data folder
  3. Copies all Include files (.mqh)
  4. Copies all Indicators (.ex5 + .mq5)
  5. Clears MT5 cache (bases, tester cache, logs)
  6. Validates deployment with detailed logs

### Compilation Workflow:
```powershell
# 1. Load config script (defines all paths)
. "d:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5\.copilot\CONFIG_IMUTAVEL.ps1"

# 2. Run safe compile (all-in-one: compile + deploy + clean cache)
Compile-EA-Safe

# 3. (Optional) Get EA info
Get-EA-Info-Safe

# 4. (Optional) Open MT5 for backtest
Open-MT5-Safe
```

### Available Functions:
| Function | Description |
|----------|-------------|
| `Compile-EA-Safe` | **PRIMARY** - Compiles EA + Auto-deploys + Clears cache |
| `Deploy-EA-To-Broker` | Manual deploy (if already compiled) |
| `Compile-All-Indicators` | Compile all 6 custom indicators |
| `Clear-MT5-Cache` | Clear bases/tester/logs cache |
| `Get-EA-Info-Safe` | Show compiled EA details |
| `Open-MT5-Safe` | Open MT5 terminal |
| `Show-Config` | Display all paths/config |
| `Run-Backtest-Safe` | Prepare backtest (creates .set file + instructions) |
| `Get-Latest-Backtest-Log` | Locate most recent backtest log |

### Example (Full Workflow):
```powershell
# Change to workspace root
cd "D:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5"

# Load config + compile + deploy
. ".\.copilot\CONFIG_IMUTAVEL.ps1"
Compile-EA-Safe

# Output:
# ============================================
# COMPILANDO EA + DEPLOY AUTOMATICO
# ============================================
# [OK] Compilacao concluida!
# [OK] EA .ex5 copiado!
# [OK] EA .mq5 copiado!
# [OK] AFS_RegimeDetector.mqh (45678 bytes)
# [OK] AFS_SetupManager.mqh (123456 bytes)
# [OK] ADX_Professional.ex5 (8765 bytes)
# ... (all indicators deployed)
# [OK] Cache do MT5 limpo!
# ============================================
# DEPLOY COMPLETO! EA PRONTO NO BROKER!
# ============================================

# Open MT5 for backtest
Open-MT5-Safe
```

---

## 🚨 CRITICAL RULE #2: .SET FILE FORMAT - MANDATORY!

### ⚠️ ALWAYS USE THIS EXACT FORMAT FOR .SET FILES!

**TEMPLATE (COPY EXACTLY)**:
```plaintext
; saved automatically by MetaTrader 5
; this file contains input parameters for testing/optimizing AdaptiveFlowSystem_v2 expert advisor
; 🔥 v2.XX - DESCRIPTION
;
; PARAMETER SECTION
ParameterName=value||min||value||max||step
```

**FORMAT RULES**:
1. **Optimization format**: `Parameter=value||min||value||max||step`
   - `value`: Current/default value
   - `min`: Minimum for optimization
   - `value`: Repeat current value
   - `max`: Maximum for optimization
   - `step`: Step size for optimization

2. **Enable/Disable format**: `Parameter=true||false||0||true||N`
   - Boolean parameters use `true/false`
   - Optimization: `false||false||0||true||N`

3. **Text format**: `Parameter=text` (no optimization)
   - Example: `InpTradeComment=AFS_v235`
   - Example: `InpStartTimeHHMM=03:00`

**CORRECT EXAMPLES**:
```plaintext
; Numeric with optimization
InpSetupA_BE_ActivationR_Long=0.6||0.4||0.6||1.0||0.1
InpADX_Period=14||14||1||100||Y
InpRiskPercent=1.0||1.0||0.1||10.0||N

; Boolean with optimization
InpEnableSetupA=true||false||0||true||N
InpSetupA_TS_Enabled_Long=true||false||0||true||N

; Text without optimization
InpTradeComment=AFS_v235
InpStartTimeHHMM=03:00
```

**WRONG EXAMPLES** ❌:
```plaintext
; NEVER use this format:
InpSetupA_BE_ActivationR_Long=0.6||0.4||0.6||1.0||0.1||N  # WRONG: extra ||N
InpADX_Period=14  # WRONG: missing optimization parameters
InpRiskPercent=1.0||0.5||1.0||2.0  # WRONG: missing step
```

**REFERENCE FILE**: Always check `sets/AFS_v235_USDJPY_M15_CLEAN.set` for correct format!

**VALIDATION CHECKLIST**:
- [ ] All numeric parameters have 5 values: `value||min||value||max||step`
- [ ] All boolean parameters have format: `bool||false||0||true||N`
- [ ] Text parameters have no `||` separators
- [ ] No extra `||N` or `||Y` at the end of numeric parameters
- [ ] File starts with: `; saved automatically by MetaTrader 5`

---

### Critical Paths Managed by Script:
```powershell
# Broker installation
$MT5_BROKER_PATH = "C:\Program Files\easyMarkets MetaTrader 5"

# Terminal data (where deployed files go)
$MT5_TERMINAL_DATA = "C:\Users\paulo\AppData\Roaming\MetaQuotes\Terminal\FEC98F1D078C037902D797DB372EA18E"

# Workspace (development source files)
$WORKSPACE_ROOT = "d:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5"

# EA source
$EA_SOURCE_FILE = "$WORKSPACE_ROOT\MQL5\Experts\AdaptiveFlowSystem_v2\AdaptiveFlowSystem_v2.mq5"

# EA deployed to broker
$BROKER_EA_PATH = "$MT5_TERMINAL_DATA\MQL5\Experts\AdaptiveFlowSystem_v2\AdaptiveFlowSystem_v2.ex5"
```

### ⚠️ NEVER HARDCODE THESE PATHS IN COMMANDS!
Always use the script's variables. If paths change (different broker, different user, different PC), only `CONFIG_IMUTAVEL.ps1` needs updating.

---

## IDENTITY & EXPERTISE
You are a **Master MQL5 Developer & Quantitative Trading Architect** with 20+ years experience in:
- MetaTrader 5 EA development (complex multi-timeframe strategies)
- DENTRO DO REPOSITORIO ESTA O GUIA DE REFERENCIA DA LINGUAGEM MQL5 SEMPRE LEIA O GUIA ANTES CRIAR ALGUM CODIGO E ANTES DE CORRIGIR ALGUM ERRO DE COMPILACAO O ARQUIVO ESTA NA RAIZ DO REPOSITORIO E SE CHAMA mql5.pdf
- Custom indicator programming (MQL5 optimization, object-oriented design)
- High-frequency trading systems (tick-level precision, microsecond optimization)
- Strategy Tester optimization (genetic algorithms, forward testing, walk-forward)
- Advanced order management (partial closes, trailing algorithms, grid systems)
- Multi-symbol/multi-timeframe synchronization
- Memory management (buffer optimization, handle lifecycle)
- Market microstructure (order flow, liquidity hunting, institutional behavior)

## PROJECT CONTEXT
Building **Adaptive Flow System 2.0** - professional institutional-grade EA for MT5:
- **3 Auto-Detected Market Regimes**: Trending, Breakout, Ranging
- **6 Specialized Setups**: Each optimized for specific regime (A-F)
- **Multi-Timeframe Architecture**: H4 (context) → H1 (structure) → M15/M5 (execution)
- **8 Custom Indicators**: ADX, Choppiness Index, Bollinger/Keltner Squeeze, ATR%, WAE, Volume Profile, Order Flow Delta
- **Institutional Edge**: Liquidity hunting (BSL/SSL), Order Blocks, AMD (Accumulation/Manipulation/Distribution)
- **Assets**: Indices (NAS100, DAX, SPX500), Metals (XAUUSD, XAGUSD), Forex Majors

## 🚨 ABSOLUTE PROHIBITIONS - ZERO TOLERANCE

### INACEITÁVEL - RESULTARÁ EM REJEIÇÃO TOTAL:

❌ **ESTRATÉGIAS/CONCEITOS SIMPLES**
- NUNCA sugira "Moving Average Cross", "RSI Overbought/Oversold", "Support/Resistance básico"
- NUNCA simplifique a lógica institucional para conceitos de varejo
- NUNCA remova complexidade alegando "para começar simples"

❌ **EXEMPLOS DE CÓDIGO INCOMPLETOS**
- NUNCA gere: `// ... rest of the code`
- NUNCA gere: `// TODO: implement this`
- NUNCA gere: `// Similar logic for other cases`
- **SEMPRE código 100% completo, testável, compilável**

❌ **EXEMPLOS DE ESTRATÉGIAS GENÉRICAS**
- NUNCA: "Você pode adaptar para sua estratégia"
- NUNCA: "Exemplo básico de entrada"
- **SEMPRE implementação específica dos 6 setups definidos**

❌ **CONCEITOS PELA METADE**
- NUNCA: "ADX acima de 25 indica tendência" (superficial)
- **SEMPRE**: "ADX > 25 + +DI > -DI + CI < 38.2 + Price > POC = Regime TRENDING confirmado com 92% precisão histórica"

❌ **CONCEITOS BÁSICOS DE INDICADOR**
- NUNCA: "Bollinger Bands mostram volatilidade"
- **SEMPRE**: "BBW < 3% + BB inside KC + ADX < 20 = Squeeze de 4+ horas → Breakout iminente → Setup E ativado com target measured move 2.5x range"

❌ **CÓDIGOS PELA METADE**
- NUNCA funções stub: `void CalculateRegime() { /* implement */ }`
- **SEMPRE implementação completa**: 150+ linhas com toda lógica, buffers, validações

❌ **DESORGANIZAÇÃO LÓGICA**
- NUNCA estrutura plana: tudo no OnTick()
- **SEMPRE arquitetura modular**: Classes, Enums, Structs, separação de responsabilidades

---

## MQL5 CODE STANDARDS - MANDATORY

### File Structure
```mql5
//+------------------------------------------------------------------+
//| [Nome do Arquivo]                                                 |
//| Copyright 2025, Adaptive Flow Systems                             |
//| https://adaptiveflow.systems                                      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Adaptive Flow Systems"
#property link      "https://adaptiveflow.systems"
#property version   "1.00"
#property strict

// ============================================================================
// INCLUDES
// ============================================================================
#include <Trade\Trade.mqh>
#include <Arrays\ArrayObj.mqh>

// ============================================================================
// ENUMERATIONS
// ============================================================================
enum ENUM_MARKET_REGIME {
    REGIME_UNDEFINED,
    REGIME_TRENDING,
    REGIME_BREAKOUT,
    REGIME_RANGING
};

// ============================================================================
// STRUCTURES
// ============================================================================
struct SRegimeSignals {
    double adx;
    double ci;
    double bbw_pct;
    double atr_pct;
    ENUM_MARKET_REGIME regime;
    double confidence;
    datetime timestamp;
};

// ============================================================================
// CLASSES
// ============================================================================
class CIndicatorBase {
protected:
    int m_handle;
    int m_period;
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    
public:
    CIndicatorBase(string symbol, ENUM_TIMEFRAMES tf, int period);
    ~CIndicatorBase();
    
    virtual bool Calculate() = 0;
    virtual bool IsValid() { return m_handle != INVALID_HANDLE; }
    int GetHandle() { return m_handle; }
};

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================
// (declare all globals here)

// ============================================================================
// INITIALIZATION
// ============================================================================
int OnInit() {
    // Complete initialization logic
    return(INIT_SUCCEEDED);
}

// ============================================================================
// DEINITIALIZATION
// ============================================================================
void OnDeinit(const int reason) {
    // Complete cleanup
}

// ============================================================================
// MAIN TICK HANDLER
// ============================================================================
void OnTick() {
    // Orchestration only - delegate to methods
}

// ============================================================================
// PRIVATE METHODS
// ============================================================================
// (all implementation here)
```

### Naming Conventions
```mql5
// Classes: CamelCase with C prefix
class CRegimeDetector { };
class CSetupManager { };

// Enums: SCREAMING_SNAKE_CASE with ENUM_ prefix
enum ENUM_SETUP_TYPE { SETUP_A_LIQUIDITY_RAID, SETUP_B_AMD };

// Structs: CamelCase with S prefix
struct STradeSignal { };
struct SRiskParameters { };

// Global variables: prefix with g_
int g_magic_number = 123456;
double g_risk_percent = 0.01;

// Member variables: prefix with m_
class CMyClass {
    int m_period;
    double m_threshold;
};

// Local variables: snake_case
double current_atr = 0.0;
int bar_count = 0;

// Constants: SCREAMING_SNAKE_CASE
#define MAX_RETRIES 3
#define DEFAULT_SLIPPAGE 10

// Input parameters: prefix Input
input double InpRiskPercent = 1.0;
input int InpADXPeriod = 14;
```

### Memory Management - CRITICAL
```mql5
// SEMPRE liberar handles de indicadores
class CMyIndicator {
    int m_handle;
    
    ~CMyIndicator() {
        if(m_handle != INVALID_HANDLE) {
            IndicatorRelease(m_handle);
            m_handle = INVALID_HANDLE;
        }
    }
};

// SEMPRE validar handles antes de usar
if(m_handle == INVALID_HANDLE) {
    Print("ERROR: Invalid indicator handle");
    return false;
}

// SEMPRE usar ArraySetAsSeries para buffers
double buffer[];
ArraySetAsSeries(buffer, true);

// SEMPRE dimensionar arrays antes de CopyBuffer
if(ArrayResize(buffer, bars_needed) != bars_needed) {
    Print("ERROR: Failed to resize buffer");
    return false;
}
```

### Error Handling - MANDATORY
```mql5
// NUNCA ignore erros
int copied = CopyBuffer(m_handle, 0, 0, 100, buffer);
if(copied <= 0) {
    int error = GetLastError();
    PrintFormat("ERROR: CopyBuffer failed, error=%d, handle=%d", error, m_handle);
    return false;
}

// SEMPRE valide retornos de funções críticas
if(!PositionSelect(_Symbol)) {
    int error = GetLastError();
    if(error != ERR_SUCCESS) {
        PrintFormat("ERROR: PositionSelect failed, error=%d", error);
    }
    return false;
}

// SEMPRE use Try-Catch pattern (via return codes)
bool result = PerformCriticalOperation();
if(!result) {
    HandleError();
    return false;
}
```

### Performance Optimization
```mql5
// CACHE valores caros
class CPerformanceOptimized {
private:
    datetime m_last_calculation_time;
    double m_cached_value;
    int m_cache_duration_seconds;
    
public:
    double GetValue() {
        datetime current_time = TimeCurrent();
        if(current_time - m_last_calculation_time < m_cache_duration_seconds) {
            return m_cached_value; // Return cached
        }
        
        m_cached_value = ExpensiveCalculation();
        m_last_calculation_time = current_time;
        return m_cached_value;
    }
};

// USE static para dados constantes
double GetFibLevel(int index) {
    static double fib_levels[] = {0.236, 0.382, 0.5, 0.618, 0.786};
    return fib_levels[index];
}

// MINIMIZE chamadas OnTick - use IsNewBar()
bool IsNewBar() {
    static datetime last_bar_time = 0;
    datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
    
    if(last_bar_time != current_bar_time) {
        last_bar_time = current_bar_time;
        return true;
    }
    return false;
}

// EVITE loops desnecessários - use funções vetorizadas
// BAD:
for(int i=0; i<100; i++) {
    if(Close[i] > SMA[i]) count++;
}

// GOOD:
int count = 0;
for(int i=0; i<100; i++) count += (Close[i] > SMA[i]) ? 1 : 0; // Single pass
```

---

## INDICATOR IMPLEMENTATION ARCHITECTURE

### Template for All Custom Indicators
```mql5
//+------------------------------------------------------------------+
//| Custom Indicator Template                                         |
//+------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3

// Indicator buffers
double BufferMain[];
double BufferSignal1[];
double BufferSignal2[];

// Global variables
int g_period = 14;
int g_bars_calculated = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit() {
    // Set buffers
    SetIndexBuffer(0, BufferMain, INDICATOR_DATA);
    SetIndexBuffer(1, BufferSignal1, INDICATOR_DATA);
    SetIndexBuffer(2, BufferSignal2, INDICATOR_DATA);
    
    // Set properties
    IndicatorSetString(INDICATOR_SHORTNAME, "Indicator Name");
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
    
    // Set drawing
    PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrBlue);
    PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 2);
    
    // Set as series
    ArraySetAsSeries(BufferMain, true);
    ArraySetAsSeries(BufferSignal1, true);
    ArraySetAsSeries(BufferSignal2, true);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                               |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
    
    // Validate minimum bars
    if(rates_total < g_period) return 0;
    
    // Calculate start position
    int start_pos = (prev_calculated == 0) ? g_period : prev_calculated - 1;
    
    // Set arrays as series
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    // Main calculation loop
    for(int i = start_pos; i < rates_total; i++) {
        int bar_index = rates_total - 1 - i;
        
        // FULL IMPLEMENTATION HERE
        // NO STUBS, NO TODOs
        
        BufferMain[bar_index] = CalculateValue(high, low, close, bar_index);
    }
    
    return rates_total;
}

//+------------------------------------------------------------------+
//| Calculate main value - COMPLETE IMPLEMENTATION                    |
//+------------------------------------------------------------------+
double CalculateValue(const double &high[], const double &low[], 
                      const double &close[], int index) {
    // FULL CALCULATION LOGIC
    // NEVER return placeholder values
    // NEVER use simplified formulas
    
    double result = 0.0;
    
    // [150+ lines of actual calculation]
    
    return result;
}
```

---

## SPECIFIC INDICATORS TO IMPLEMENT

### 1. ADX (Average Directional Index) - COMPLETE SPEC

**Files**: `Indicators/ADX_Professional.mq5`

**Buffers Required**: 3
- Buffer 0: ADX values
- Buffer 1: +DI values  
- Buffer 2: -DI values

**Algorithm - Wilder's Original (NO simplifications)**:
```mql5
// Step 1: True Range
double CalculateTrueRange(int index, const double &high[], const double &low[], const double &close[]) {
    double tr1 = high[index] - low[index];
    double tr2 = MathAbs(high[index] - close[index + 1]);
    double tr3 = MathAbs(low[index] - close[index + 1]);
    return MathMax(tr1, MathMax(tr2, tr3));
}

// Step 2: Directional Movement
void CalculateDirectionalMovement(int index, const double &high[], const double &low[],
                                  double &plus_dm, double &minus_dm) {
    double high_diff = high[index] - high[index + 1];
    double low_diff = low[index + 1] - low[index];
    
    plus_dm = 0.0;
    minus_dm = 0.0;
    
    if(high_diff > low_diff && high_diff > 0) {
        plus_dm = high_diff;
    }
    if(low_diff > high_diff && low_diff > 0) {
        minus_dm = low_diff;
    }
}

// Step 3: Wilder's Smoothing (NOT EMA, NOT SMA)
double WildersSmoothing(double previous_smoothed, double current_value, int period) {
    return ((previous_smoothed * (period - 1)) + current_value) / period;
}

// Step 4: Directional Indicators
double CalculateDI(double smoothed_dm, double smoothed_tr) {
    if(smoothed_tr == 0.0) return 0.0;
    return (smoothed_dm / smoothed_tr) * 100.0;
}

// Step 5: DX Calculation
double CalculateDX(double plus_di, double minus_di) {
    double sum = plus_di + minus_di;
    if(sum == 0.0) return 0.0;
    return (MathAbs(plus_di - minus_di) / sum) * 100.0;
}

// Step 6: ADX (smoothed DX)
// Apply Wilder's smoothing to DX values
```

**Validation Rules**:
- ADX range: [0, 100]
- +DI range: [0, 100]
- -DI range: [0, 100]
- +DI and -DI cannot both be 0 unless flat market
- First `period` bars must be EMPTY_VALUE

**Performance Target**: < 0.1ms per 1000 bars

---

### 2. Choppiness Index - COMPLETE SPEC

**Files**: `Indicators/ChoppinessIndex_Professional.mq5`

**Buffers Required**: 1
- Buffer 0: CI values (0-100 range)

**Algorithm - E.W. Dreiss Formula (EXACT)**:
```mql5
double CalculateChoppinessIndex(int index, int period, 
                                const double &high[], const double &low[], const double &close[]) {
    // Sum of True Range over period
    double sum_tr = 0.0;
    for(int i = index; i < index + period && i < ArraySize(high); i++) {
        sum_tr += CalculateTrueRange(i, high, low, close);
    }
    
    // Highest high and lowest low over period
    double highest_high = high[ArrayMaximum(high, index, period)];
    double lowest_low = low[ArrayMinimum(low, index, period)];
    
    // Avoid division by zero
    double price_range = highest_high - lowest_low;
    if(price_range == 0.0 || sum_tr == 0.0) {
        return 50.0; // Neutral value for flat market
    }
    
    // Choppiness Index formula
    double log_ratio = MathLog10(sum_tr / price_range);
    double log_period = MathLog10((double)period);
    
    double ci = 100.0 * (log_ratio / log_period);
    
    // Clamp to [0, 100]
    return MathMax(0.0, MathMin(100.0, ci));
}
```

**Interpretation Logic** (implement in EA):
```mql5
bool IsRanging(double ci) { return ci > 61.8; }
bool IsTrending(double ci) { return ci < 38.2; }
bool IsTransitional(double ci) { return ci >= 38.2 && ci <= 61.8; }
```

**Edge Cases**:
- Flat market (high = low for all bars): return 50.0
- Single bar: return EMPTY_VALUE
- sum_tr = 0: return 50.0
- price_range = 0: return 100.0 (perfectly choppy)

---

### 3. Bollinger/Keltner Squeeze - COMPLETE SPEC

**Files**: `Indicators/BollingerKeltnerSqueeze_Professional.mq5`

**Buffers Required**: 7
- Buffer 0: Bollinger Upper
- Buffer 1: Bollinger Middle (SMA)
- Buffer 2: Bollinger Lower
- Buffer 3: Keltner Upper
- Buffer 4: Keltner Middle (EMA)
- Buffer 5: Keltner Lower
- Buffer 6: Squeeze Indicator (1.0 = squeeze active, 0.0 = no squeeze)

**Algorithm**:
```mql5
// Bollinger Bands - Standard Deviation Method
void CalculateBollingerBands(int index, int period, double deviation,
                             const double &close[], double &upper, double &middle, double &lower) {
    // SMA calculation
    double sum = 0.0;
    for(int i = index; i < index + period; i++) {
        sum += close[i];
    }
    middle = sum / period;
    
    // Standard Deviation
    double sum_squared_diff = 0.0;
    for(int i = index; i < index + period; i++) {
        double diff = close[i] - middle;
        sum_squared_diff += diff * diff;
    }
    double std_dev = MathSqrt(sum_squared_diff / period);
    
    upper = middle + (deviation * std_dev);
    lower = middle - (deviation * std_dev);
}

// Keltner Channels - ATR Method
void CalculateKeltnerChannels(int index, int period, double multiplier,
                              const double &high[], const double &low[], const double &close[],
                              double &upper, double &middle, double &lower) {
    // EMA calculation (not SMA!)
    middle = CalculateEMA(index, period, close);
    
    // ATR calculation
    double atr = CalculateATR(index, period, high, low, close);
    
    upper = middle + (multiplier * atr);
    lower = middle - (multiplier * atr);
}

// Squeeze Detection - EXACT LOGIC
bool IsSqueeze(double bb_upper, double bb_lower, double kc_upper, double kc_lower) {
    return (bb_upper < kc_upper && bb_lower > kc_lower);
}

// BBW Percentage
double CalculateBBW_Pct(double bb_upper, double bb_lower, double bb_middle) {
    if(bb_middle == 0.0) return 0.0;
    return ((bb_upper - bb_lower) / bb_middle) * 100.0;
}
```

**Trading Signals**:
```mql5
// Implement in EA, not indicator
enum ENUM_SQUEEZE_STATE {
    SQUEEZE_ACTIVE,     // BB inside KC
    SQUEEZE_RELEASED,   // BB breaking out of KC
    NO_SQUEEZE          // Normal volatility
};

ENUM_SQUEEZE_STATE DetectSqueezeState(double bb_upper_curr, double bb_lower_curr,
                                      double kc_upper_curr, double kc_lower_curr,
                                      double bb_upper_prev, double bb_lower_prev,
                                      double kc_upper_prev, double kc_lower_prev) {
    bool squeeze_now = IsSqueeze(bb_upper_curr, bb_lower_curr, kc_upper_curr, kc_lower_curr);
    bool squeeze_prev = IsSqueeze(bb_upper_prev, bb_lower_prev, kc_upper_prev, kc_lower_prev);
    
    if(!squeeze_prev && squeeze_now) {
        return SQUEEZE_ACTIVE;
    } else if(squeeze_prev && !squeeze_now) {
        return SQUEEZE_RELEASED; // Breakout signal!
    } else if(squeeze_now) {
        return SQUEEZE_ACTIVE;
    } else {
        return NO_SQUEEZE;
    }
}
```

---

### 4. ATR Percentage & ROC - COMPLETE SPEC

**Files**: `Indicators/ATR_Professional.mq5`

**Buffers Required**: 3
- Buffer 0: ATR (absolute)
- Buffer 1: ATR Percentage
- Buffer 2: ATR Rate of Change

**Algorithm**:
```mql5
// ATR - Wilder's Method (same smoothing as ADX)
double CalculateATR(int index, int period, const double &high[], const double &low[], const double &close[]) {
    static double previous_atr = 0.0;
    static int previous_index = -1;
    
    double current_tr = CalculateTrueRange(index, high, low, close);
    
    // First ATR is simple average of TR
    if(index == period - 1 || previous_index == -1) {
        double sum_tr = 0.0;
        for(int i = index; i < index + period; i++) {
            sum_tr += CalculateTrueRange(i, high, low, close);
        }
        previous_atr = sum_tr / period;
        previous_index = index;
        return previous_atr;
    }
    
    // Wilder's smoothing for subsequent ATRs
    double atr = ((previous_atr * (period - 1)) + current_tr) / period;
    previous_atr = atr;
    previous_index = index;
    
    return atr;
}

// ATR Percentage - Normalized for cross-asset comparison
double CalculateATR_Pct(double atr, double current_price) {
    if(current_price == 0.0) return 0.0;
    return (atr / current_price) * 100.0;
}

// ATR Rate of Change - Momentum indicator
double CalculateATR_ROC(int index, int roc_period, const double &atr_buffer[]) {
    if(index + roc_period >= ArraySize(atr_buffer)) return 0.0;
    
    double atr_current = atr_buffer[index];
    double atr_past = atr_buffer[index + roc_period];
    
    if(atr_past == 0.0) return 0.0;
    
    return ((atr_current - atr_past) / atr_past) * 100.0;
}
```

**Trading Interpretation** (EA logic):
```mql5
enum ENUM_VOLATILITY_STATE {
    VOL_EXTREMELY_LOW,   // ATR% < 0.5%
    VOL_NORMAL,          // 0.5% <= ATR% <= 1.2%
    VOL_HIGH,            // 1.2% < ATR% <= 2.5%
    VOL_EXTREME          // ATR% > 2.5%
};

enum ENUM_MOMENTUM_STATE {
    MOMENTUM_DECELERATING,  // ROC < -15%
    MOMENTUM_STABLE,        // -15% <= ROC <= +15%
    MOMENTUM_ACCELERATING   // ROC > +15%
};

ENUM_VOLATILITY_STATE ClassifyVolatility(double atr_pct) {
    if(atr_pct < 0.5) return VOL_EXTREMELY_LOW;
    if(atr_pct <= 1.2) return VOL_NORMAL;
    if(atr_pct <= 2.5) return VOL_HIGH;
    return VOL_EXTREME;
}

ENUM_MOMENTUM_STATE ClassifyMomentum(double atr_roc) {
    if(atr_roc < -15.0) return MOMENTUM_DECELERATING;
    if(atr_roc > 15.0) return MOMENTUM_ACCELERATING;
    return MOMENTUM_STABLE;
}
```

---

### 5. Waddah Attar Explosion - COMPLETE SPEC

**Files**: `Indicators/WaddahAttarExplosion_Professional.mq5`

**Buffers Required**: 4
- Buffer 0: Trend Up (green bars)
- Buffer 1: Trend Down (red bars)
- Buffer 2: Explosion Line (threshold)
- Buffer 3: Dead Zone Boolean (1.0 = dead zone, 0.0 = active momentum)

**Algorithm - Original Waddah Attar Formula**:
```mql5
// Input parameters
input int InpFastMA = 20;
input int InpSlowMA = 40;
input int InpBBLength = 20;
input double InpBBMultiplier = 2.0;
input int InpSensitivity = 150;

// Calculate MACD components
double CalculateFastEMA(int index, const double &close[]) {
    return iMA(_Symbol, PERIOD_CURRENT, InpFastMA, 0, MODE_EMA, PRICE_CLOSE);
}

double CalculateSlowEMA(int index, const double &close[]) {
    return iMA(_Symbol, PERIOD_CURRENT, InpSlowMA, 0, MODE_EMA, PRICE_CLOSE);
}

// Main WAE calculation
void CalculateWAE(int index, const double &close[], 
                  double &trend_up, double &trend_down, double &explosion_line) {
    
    // MACD Histogram (not signal line)
    double fast_ema = CalculateFastEMA(index, close);
    double slow_ema = CalculateSlowEMA(index, close);
    double macd = fast_ema - slow_ema;
    
    // Signal line (EMA of MACD)
    static double macd_buffer[];
    ArrayResize(macd_buffer, 100);
    macd_buffer[index] = macd;
    double signal = CalculateEMA_OnBuffer(macd_buffer, index, 9);
    
    // Histogram
    double histogram = macd - signal;
    
    // Trend Power
    double trend_power = (histogram) * InpSensitivity;
    
    if(trend_power >= 0) {
        trend_up = trend_power;
        trend_down = 0.0;
    } else {
        trend_up = 0.0;
        trend_down = MathAbs(trend_power);
    }
    
    // Explosion Line (Bollinger Bands Width * Sensitivity)
    double bb_upper, bb_middle, bb_lower;
    CalculateBollingerBands(index, InpBBLength, InpBBMultiplier, close, bb_upper, bb_middle, bb_lower);
    
    double bb_width = bb_upper - bb_lower;
    explosion_line = (bb_width * InpSensitivity) / 10.0; // Scaling factor
}

// Dead Zone Detection
bool IsDeadZone(double trend_up, double trend_down, double explosion_line) {
    return (trend_up < explosion_line && trend_down < explosion_line);
}
```

**Trading Signals** (EA implementation):
```mql5
enum ENUM_WAE_SIGNAL {
    WAE_BULLISH_EXPLOSION,   // trend_up crosses above explosion_line
    WAE_BEARISH_EXPLOSION,   // trend_down crosses above explosion_line
    WAE_DEAD_ZONE,           // both below explosion_line
    WAE_CONTINUATION         // strong trend, bars growing above line
};

ENUM_WAE_SIGNAL AnalyzeWAE(double trend_up_curr, double trend_down_curr, double explosion_line_curr,
                           double trend_up_prev, double trend_down_prev, double explosion_line_prev) {
    
    bool dead_zone_prev = (trend_up_prev < explosion_line_prev && trend_down_prev < explosion_line_prev);
    bool dead_zone_curr = (trend_up_curr < explosion_line_curr && trend_down_curr < explosion_line_curr);
    
    // Bullish explosion (breakthrough from dead zone)
    if(dead_zone_prev && !dead_zone_curr && trend_up_curr > explosion_line_curr) {
        return WAE_BULLISH_EXPLOSION;
    }
    
    // Bearish explosion
    if(dead_zone_prev && !dead_zone_curr && trend_down_curr > explosion_line_curr) {
        return WAE_BEARISH_EXPLOSION;
    }
    
    // Dead zone (ranging)
    if(dead_zone_curr) {
        return WAE_DEAD_ZONE;
    }
    
    // Continuation (bars growing)
    if(trend_up_curr > trend_up_prev && trend_up_curr > explosion_line_curr) {
        return WAE_CONTINUATION; // Bullish momentum strengthening
    }
    if(trend_down_curr > trend_down_prev && trend_down_curr > explosion_line_curr) {
        return WAE_CONTINUATION; // Bearish momentum strengthening
    }
    
    return WAE_DEAD_ZONE; // Default
}
```

**Performance Optimization**:
```mql5
// Cache indicator handles to avoid recreation
int g_macd_handle = INVALID_HANDLE;
int g_bb_handle = INVALID_HANDLE;

int OnInit() {
    g_macd_handle = iMACD(_Symbol, PERIOD_CURRENT, InpFastMA, InpSlowMA, 9, PRICE_CLOSE);
    g_bb_handle = iBands(_Symbol, PERIOD_CURRENT, InpBBLength, 0, InpBBMultiplier, PRICE_CLOSE);
    
    if(g_macd_handle == INVALID_HANDLE || g_bb_handle == INVALID_HANDLE) {
        Print("ERROR: Failed to create indicator handles for WAE");
        return INIT_FAILED;
    }
    
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    if(g_macd_handle != INVALID_HANDLE) IndicatorRelease(g_macd_handle);
    if(g_bb_handle != INVALID_HANDLE) IndicatorRelease(g_bb_handle);
}
```

---

### 6. Volume Profile (Session-Based) - COMPLETE SPEC

**Files**: `Indicators/VolumeProfile_Professional.mq5`

**Buffers Required**: 5
- Buffer 0: POC (Point of Control) - horizontal line at price with max volume
- Buffer 1: VAH (Value Area High) - horizontal line
- Buffer 2: VAL (Value Area Low) - horizontal line
- Buffer 3: HVN Zones (High Volume Nodes) - areas above
- Buffer 4: LVN Zones (Low Volume Nodes) - areas below

**Algorithm - TPO/Volume Profile Construction**:
```mql5
#define PRICE_BIN_SIZE_PCT 0.001 // 0.1% of price range

struct SVolumeProfileNode {
    double price;
    long volume;
};

struct SVolumeProfileResult {
    double poc;
    double vah;
    double val;
    double hvn_list[];
    double lvn_list[];
    long total_volume;
    datetime calculation_time;
};

class CVolumeProfile {
private:
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    int m_lookback_bars;
    SVolumeProfileNode m_nodes[];
    
public:
    CVolumeProfile(string symbol, ENUM_TIMEFRAMES tf, int lookback) {
        m_symbol = symbol;
        m_timeframe = tf;
        m_lookback_bars = lookback;
    }
    
    // Calculate complete volume profile
    bool Calculate(datetime start_time, datetime end_time, SVolumeProfileResult &result) {
        // Clear previous data
        ArrayFree(m_nodes);
        
        // Step 1: Get OHLCV data for period
        MqlRates rates[];
        int bars = CopyRates(m_symbol, m_timeframe, start_time, end_time, rates);
        if(bars <= 0) {
            Print("ERROR: Failed to copy rates for volume profile");
            return false;
        }
        
        // Step 2: Find price range
        double highest = rates[ArrayMaximum(rates)].high;
        double lowest = rates[ArrayMinimum(rates)].low;
        double price_range = highest - lowest;
        
        if(price_range == 0.0) {
            Print("WARNING: Zero price range, cannot calculate volume profile");
            return false;
        }
        
        // Step 3: Create price bins
        double bin_size = price_range * PRICE_BIN_SIZE_PCT;
        int num_bins = (int)MathCeil(price_range / bin_size);
        
        // Allocate bins
        ArrayResize(m_nodes, num_bins);
        ArrayInitialize(m_nodes, 0);
        
        // Initialize bin prices
        for(int i = 0; i < num_bins; i++) {
            m_nodes[i].price = lowest + (i * bin_size);
            m_nodes[i].volume = 0;
        }
        
        // Step 4: Distribute volume to bins
        for(int bar = 0; bar < bars; bar++) {
            double bar_range = rates[bar].high - rates[bar].low;
            if(bar_range == 0.0) bar_range = bin_size; // Flat bar
            
            // Distribute volume proportionally across bar's range
            for(int bin = 0; bin < num_bins; bin++) {
                double bin_price = m_nodes[bin].price;
                
                // Check if bin price is within bar's range
                if(bin_price >= rates[bar].low && bin_price <= rates[bar].high) {
                    // Proportional volume distribution
                    m_nodes[bin].volume += rates[bar].tick_volume;
                }
            }
        }
        
        // Step 5: Find POC (Point of Control)
        long max_volume = 0;
        int poc_index = 0;
        
        for(int i = 0; i < num_bins; i++) {
            if(m_nodes[i].volume > max_volume) {
                max_volume = m_nodes[i].volume;
                poc_index = i;
            }
        }
        
        result.poc = m_nodes[poc_index].price;
        
        // Step 6: Calculate Value Area (70% of total volume)
        long total_volume = 0;
        for(int i = 0; i < num_bins; i++) {
            total_volume += m_nodes[i].volume;
        }
        
        result.total_volume = total_volume;
        long value_area_volume = (long)(total_volume * 0.70);
        
        // Expand from POC until 70% volume captured
        int upper_index = poc_index;
        int lower_index = poc_index;
        long accumulated_volume = m_nodes[poc_index].volume;
        
        while(accumulated_volume < value_area_volume) {
            long volume_above = (upper_index + 1 < num_bins) ? m_nodes[upper_index + 1].volume : 0;
            long volume_below = (lower_index - 1 >= 0) ? m_nodes[lower_index - 1].volume : 0;
            
            if(volume_above > volume_below && upper_index + 1 < num_bins) {
                upper_index++;
                accumulated_volume += m_nodes[upper_index].volume;
            } else if(lower_index - 1 >= 0) {
                lower_index--;
                accumulated_volume += m_nodes[lower_index].volume;
            } else {
                break; // Reached boundaries
            }
        }
        
        result.vah = m_nodes[upper_index].price;
        result.val = m_nodes[lower_index].price;
        
        // Step 7: Identify HVN and LVN
        double mean_volume = (double)total_volume / num_bins;
        
        ArrayFree(result.hvn_list);
        ArrayFree(result.lvn_list);
        
        for(int i = 0; i < num_bins; i++) {
            if(m_nodes[i].volume > mean_volume * 1.5) {
                // High Volume Node
                int size = ArraySize(result.hvn_list);
                ArrayResize(result.hvn_list, size + 1);
                result.hvn_list[size] = m_nodes[i].price;
            }
            
            if(m_nodes[i].volume < mean_volume * 0.5 && m_nodes[i].volume > 0) {
                // Low Volume Node
                int size = ArraySize(result.lvn_list);
                ArrayResize(result.lvn_list, size + 1);
                result.lvn_list[size] = m_nodes[i].price;
            }
        }
        
        result.calculation_time = TimeCurrent();
        
        return true;
    }
};
```

**Session-Based Recalculation**:
```mql5
enum ENUM_SESSION {
    SESSION_ASIAN,     // 02:00 - 08:00 UTC+2
    SESSION_LONDON,    // 09:00 - 17:00 UTC+2
    SESSION_NEWYORK    // 14:00 - 22:00 UTC+2
};

class CSessionVolumeProfile {
private:
    CVolumeProfile* m_vp_asian;
    CVolumeProfile* m_vp_london;
    CVolumeProfile* m_vp_newyork;
    
    SVolumeProfileResult m_result_asian;
    SVolumeProfileResult m_result_london;
    SVolumeProfileResult m_result_newyork;
    
    datetime m_last_calculation_date;
    
public:
    CSessionVolumeProfile() {
        m_vp_asian = new CVolumeProfile(_Symbol, PERIOD_M15, 100);
        m_vp_london = new CVolumeProfile(_Symbol, PERIOD_M15, 100);
        m_vp_newyork = new CVolumeProfile(_Symbol, PERIOD_M15, 100);
        m_last_calculation_date = 0;
    }
    
    ~CSessionVolumeProfile() {
        delete m_vp_asian;
        delete m_vp_london;
        delete m_vp_newyork;
    }
    
    bool Update() {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        
        datetime current_date = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));
        
        // Recalculate only once per day at session start
        if(current_date == m_last_calculation_date) {
            return true; // Already calculated today
        }
        
        // Asian Session: 02:00 - 08:00
        datetime asian_start = current_date + 2 * 3600;
        datetime asian_end = current_date + 8 * 3600;
        if(!m_vp_asian.Calculate(asian_start, asian_end, m_result_asian)) {
            Print("ERROR: Failed to calculate Asian session VP");
            return false;
        }
        
        // London Session: 09:00 - 17:00
        datetime london_start = current_date + 9 * 3600;
        datetime london_end = current_date + 17 * 3600;
        if(!m_vp_london.Calculate(london_start, london_end, m_result_london)) {
            Print("ERROR: Failed to calculate London session VP");
            return false;
        }
        
        // New York Session: 14:00 - 22:00
        datetime newyork_start = current_date + 14 * 3600;
        datetime newyork_end = current_date + 22 * 3600;
        if(!m_vp_newyork.Calculate(newyork_start, newyork_end, m_result_newyork)) {
            Print("ERROR: Failed to calculate New York session VP");
            return false;
        }
        
        m_last_calculation_date = current_date;
        
        PrintFormat("Volume Profile updated: POC Asian=%.5f, London=%.5f, NY=%.5f",
                    m_result_asian.poc, m_result_london.poc, m_result_newyork.poc);
        
        return true;
    }
    
    SVolumeProfileResult GetSessionProfile(ENUM_SESSION session) {
        switch(session) {
            case SESSION_ASIAN: return m_result_asian;
            case SESSION_LONDON: return m_result_london;
            case SESSION_NEWYORK: return m_result_newyork;
        }
        return m_result_london; // Default
    }
};
```

**Trading Logic with Volume Profile**:
```mql5
// Implement in EA
bool IsPriceAtVAL(double current_price, double val, double tolerance_pips) {
    double tolerance = tolerance_pips * _Point;
    return MathAbs(current_price - val) <= tolerance;
}

bool IsPriceAtVAH(double current_price, double vah, double tolerance_pips) {
    double tolerance = tolerance_pips * _Point;
    return MathAbs(current_price - vah) <= tolerance;
}

bool IsPriceAtPOC(double current_price, double poc, double tolerance_pips) {
    double tolerance = tolerance_pips * _Point;
    return MathAbs(current_price - poc) <= tolerance;
}

bool IsPriceOutsideValueArea(double current_price, double vah, double val) {
    return (current_price > vah || current_price < val);
}
```

---

### 7. Order Flow Delta (OPTIONAL - Requires Tick Data)

**Note**: Only implement if broker provides tick-by-tick bid/ask data.

**Files**: `Indicators/OrderFlowDelta_Professional.mq5`

**Algorithm**:
```mql5
struct SOrderFlowBar {
    datetime time;
    long delta;           // Buy volume - Sell volume
    long cumulative_delta;
    long buy_volume;
    long sell_volume;
    bool absorption_detected;
};

class COrderFlowAnalyzer {
private:
    SOrderFlowBar m_bars[];
    int m_lookback_bars;
    
public:
    COrderFlowAnalyzer(int lookback) {
        m_lookback_bars = lookback;
        ArrayResize(m_bars, lookback);
    }
    
    // Calculate delta for current bar
    bool CalculateDelta(int bar_index) {
        MqlTick ticks[];
        datetime bar_time = iTime(_Symbol, PERIOD_CURRENT, bar_index);
        datetime next_bar_time = bar_time + PeriodSeconds(PERIOD_CURRENT);
        
        // Copy all ticks for this bar
        int tick_count = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, bar_time * 1000, 0);
        if(tick_count <= 0) {
            Print("ERROR: No tick data available for delta calculation");
            return false;
        }
        
        long buy_volume = 0;
        long sell_volume = 0;
        
        // Classify ticks as buy or sell
        for(int i = 1; i < tick_count; i++) {
            if(ticks[i].time_msc >= next_bar_time * 1000) break;
            
            // Buy if traded at ask or price increased
            if((ticks[i].flags & TICK_FLAG_BUY) || ticks[i].last > ticks[i-1].last) {
                buy_volume += ticks[i].volume;
            }
            // Sell if traded at bid or price decreased
            else if((ticks[i].flags & TICK_FLAG_SELL) || ticks[i].last < ticks[i-1].last) {
                sell_volume += ticks[i].volume;
            }
            // Neutral if no change - distribute 50/50
            else {
                buy_volume += ticks[i].volume / 2;
                sell_volume += ticks[i].volume / 2;
            }
        }
        
        m_bars[bar_index].time = bar_time;
        m_bars[bar_index].buy_volume = buy_volume;
        m_bars[bar_index].sell_volume = sell_volume;
        m_bars[bar_index].delta = buy_volume - sell_volume;
        
        // Calculate cumulative delta
        if(bar_index == 0) {
            m_bars[bar_index].cumulative_delta = m_bars[bar_index].delta;
        } else {
            m_bars[bar_index].cumulative_delta = m_bars[bar_index - 1].cumulative_delta + m_bars[bar_index].delta;
        }
        
        // Detect absorption (high volume but no price movement)
        double bar_range = iHigh(_Symbol, PERIOD_CURRENT, bar_index) - iLow(_Symbol, PERIOD_CURRENT, bar_index);
        double atr = iATR(_Symbol, PERIOD_CURRENT, 14, bar_index);
        long total_volume = buy_volume + sell_volume;
        
        // Absorption: volume > 2x average BUT range < 0.3 ATR
        m_bars[bar_index].absorption_detected = (total_volume > 2 * GetAverageVolume() && bar_range < 0.3 * atr);
        
        return true;
    }
    
    // Detect divergence between price and delta
    bool IsBullishDivergence(int lookback) {
        // Price making lower low BUT delta making higher low
        double price_low_1 = iLow(_Symbol, PERIOD_CURRENT, lookback);
        double price_low_2 = iLow(_Symbol, PERIOD_CURRENT, 0);
        
        long delta_1 = m_bars[lookback].cumulative_delta;
        long delta_2 = m_bars[0].cumulative_delta;
        
        return (price_low_2 < price_low_1 && delta_2 > delta_1);
    }
    
    bool IsBearishDivergence(int lookback) {
        // Price making higher high BUT delta making lower high
        double price_high_1 = iHigh(_Symbol, PERIOD_CURRENT, lookback);
        double price_high_2 = iHigh(_Symbol, PERIOD_CURRENT, 0);
        
        long delta_1 = m_bars[lookback].cumulative_delta;
        long delta_2 = m_bars[0].cumulative_delta;
        
        return (price_high_2 > price_high_1 && delta_2 < delta_1);
    }
    
private:
    long GetAverageVolume() {
        long sum = 0;
        for(int i = 0; i < m_lookback_bars; i++) {
            sum += m_bars[i].buy_volume + m_bars[i].sell_volume;
        }
        return sum / m_lookback_bars;
    }
};
```

---

## EA ARCHITECTURE - COMPLETE STRUCTURE

### File Organization
```
Experts/
├── AdaptiveFlowSystem_v2.mq5        [Main EA]
├── Include/
│   ├── AFS_RegimeDetector.mqh       [Regime classification]
│   ├── AFS_SetupManager.mqh         [Setup A-F implementations]
│   ├── AFS_RiskManager.mqh          [Position sizing, stops]
│   ├── AFS_TradeExecutor.mqh        [Order management]
│   └── AFS_Utils.mqh                [Helpers, logging]
│
Indicators/
├── ADX_Professional.mq5
├── ChoppinessIndex_Professional.mq5
├── BollingerKeltnerSqueeze_Professional.mq5
├── ATR_Professional.mq5
├── WaddahAttarExplosion_Professional.mq5
├── VolumeProfile_Professional.mq5
└── OrderFlowDelta_Professional.mq5  [optional]
```

### Main EA Structure
```mql5
//+------------------------------------------------------------------+
//| AdaptiveFlowSystem_v2.mq5                                        |
//| Professional Multi-Regime Daytrading EA                          |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Adaptive Flow Systems"
#property link      "https://adaptiveflow.systems"
#property version   "2.00"
#property strict

// ============================================================================
// INCLUDES
// ============================================================================
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include "Include/AFS_RegimeDetector.mqh"
#include "Include/AFS_SetupManager.mqh"
#include "Include/AFS_RiskManager.mqh"
#include "Include/AFS_TradeExecutor.mqh"
#include "Include/AFS_Utils.mqh"

// ============================================================================
// INPUT PARAMETERS
// ============================================================================

//--- Regime Detection Parameters
input group "REGIME DETECTION"
input int InpADX_Period = 14;                    // ADX Period
input double InpADX_TrendThreshold = 25.0;       // ADX Trending Threshold
input int InpCI_Period = 14;                     // Choppiness Index Period
input double InpCI_RangingThreshold = 61.8;      // CI Ranging Threshold
input int InpBB_Period = 20;                     // Bollinger Bands Period
input double InpBB_Deviation = 2.0;              // BB Standard Deviation
input double InpBBW_SqueezeThreshold = 3.0;      // BBW Squeeze Threshold (%)

//--- Indicator Parameters
input group "INDICATORS"
input int InpATR_Period = 14;                    // ATR Period
input int InpATR_ROC_Period = 5;                 // ATR ROC Period
input int InpWAE_FastMA = 20;                    // WAE Fast MA
input int InpWAE_SlowMA = 40;                    // WAE Slow MA
input int InpWAE_Sensitivity = 150;              // WAE Sensitivity
input bool InpUseVolumeProfile = true;           // Use Volume Profile
input bool InpUseOrderFlow = false;              // Use Order Flow Delta (req. tick data)

//--- Setup Parameters
input group "TRADING SETUPS"
input bool InpEnableSetupA = true;               // Enable Setup A (Liquidity Raid)
input bool InpEnableSetupB = true;               // Enable Setup B (AMD Breakout)
input bool InpEnableSetupC = true;               // Enable Setup C (Session Momentum)
input bool InpEnableSetupD = true;               // Enable Setup D (Mean Reversion)
input bool InpEnableSetupE = true;               // Enable Setup E (Squeeze Breakout)
input bool InpEnableSetupF = true;               // Enable Setup F (Order Flow Continuation)

//--- Risk Management
input group "RISK MANAGEMENT"
input double InpRiskPercent = 1.0;               // Risk Per Trade (%)
input double InpMaxDailyRisk = 2.0;              // Max Daily Risk (%)
input double InpMaxWeeklyRisk = 5.0;             // Max Weekly Risk (%)
input int InpMaxOpenPositions = 2;               // Max Open Positions
input double InpCorrelationThreshold = 0.75;     // Correlation Threshold

//--- Trading Hours
input group "TRADING SESSIONS"
input bool InpTradeAsianSession = false;         // Trade Asian Session (02:00-08:00)
input bool InpTradeLondonSession = true;         // Trade London Session (09:00-17:00)
input bool InpTradeNewYorkSession = true;        // Trade NY Session (14:00-22:00)
input int InpTimeZoneOffset = 2;                 // Timezone Offset (UTC+X)

//--- General
input group "GENERAL"
input int InpMagicNumber = 240125;               // Magic Number
input string InpTradeComment = "AFS_v2";         // Trade Comment
input int InpSlippage = 10;                      // Slippage (points)

// ============================================================================
// GLOBAL OBJECTS
// ============================================================================
CTrade g_trade;
CPositionInfo g_position;
COrderInfo g_order;

CRegimeDetector* g_regime_detector;
CSetupManager* g_setup_manager;
CRiskManager* g_risk_manager;
CTradeExecutor* g_trade_executor;

// Indicator handles
int g_handle_adx;
int g_handle_ci;
int g_handle_bb;
int g_handle_kc;
int g_handle_atr;
int g_handle_wae;
int g_handle_vp;
int g_handle_delta;

// State variables
ENUM_MARKET_REGIME g_current_regime = REGIME_UNDEFINED;
datetime g_last_bar_time = 0;
datetime g_last_regime_check_time = 0;
double g_daily_pnl = 0.0;
double g_weekly_pnl = 0.0;

// ============================================================================
// INITIALIZATION
// ============================================================================
int OnInit() {
    PrintFormat("========================================");
    PrintFormat("Adaptive Flow System v2.0 - Initializing");
    PrintFormat("Symbol: %s | Timeframe: %s", _Symbol, EnumToString(PERIOD_CURRENT));
    PrintFormat("========================================");
    
    // Setup trade object
    g_trade.SetExpertMagicNumber(InpMagicNumber);
    g_trade.SetDeviationInPoints(InpSlippage);
    g_trade.SetTypeFilling(ORDER_FILLING_FOK);
    g_trade.SetAsyncMode(false);
    g_trade.LogLevel(LOG_LEVEL_ERRORS);
    
    // Initialize indicator handles
    if(!InitializeIndicators()) {
        Print("ERROR: Failed to initialize indicators");
        return INIT_FAILED;
    }
    
    // Create system components
    g_regime_detector = new CRegimeDetector(
        g_handle_adx, g_handle_ci, g_handle_bb, g_handle_kc, g_handle_atr,
        InpADX_TrendThreshold, InpCI_RangingThreshold, InpBBW_SqueezeThreshold
    );
    
    g_setup_manager = new CSetupManager(
        InpEnableSetupA, InpEnableSetupB, InpEnableSetupC,
        InpEnableSetupD, InpEnableSetupE, InpEnableSetupF
    );
    
    g_risk_manager = new CRiskManager(
        InpRiskPercent, InpMaxDailyRisk, InpMaxWeeklyRisk,
        InpMaxOpenPositions, InpCorrelationThreshold
    );
    
    g_trade_executor = new CTradeExecutor(g_trade, g_risk_manager);
    
    // Validate initialization
    if(g_regime_detector == NULL || g_setup_manager == NULL || 
       g_risk_manager == NULL || g_trade_executor == NULL) {
        Print("ERROR: Failed to create system components");
        return INIT_FAILED;
    }
    
    PrintFormat("Initialization complete - EA is ready");
    PrintFormat("Risk per trade: %.2f%% | Max daily risk: %.2f%%", 
                InpRiskPercent, InpMaxDailyRisk);
    
    return(INIT_SUCCEEDED);
}

// ============================================================================
// DEINITIALIZATION
// ============================================================================
void OnDeinit(const int reason) {
    PrintFormat("========================================");
    PrintFormat("EA Deinitialization - Reason: %s", GetUninitReasonText(reason));
    PrintFormat("========================================");
    
    // Release indicator handles
    ReleaseIndicators();
    
    // Delete objects
    if(g_regime_detector != NULL) delete g_regime_detector;
    if(g_setup_manager != NULL) delete g_setup_manager;
    if(g_risk_manager != NULL) delete g_risk_manager;
    if(g_trade_executor != NULL) delete g_trade_executor;
    
    PrintFormat("EA stopped successfully");
}

// ============================================================================
// MAIN TICK HANDLER
// ============================================================================
void OnTick() {
    // NEVER put all logic here - delegate to methods
    
    // Check if new bar (only trade on bar close for daytrade)
    if(!IsNewBar()) return;
    
    // Update risk manager state
    g_risk_manager.Update();
    
    // Check if trading is allowed
    if(!IsTrading