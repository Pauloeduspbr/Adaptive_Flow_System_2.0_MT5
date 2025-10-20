---
mode: agent
---
# 🚀 ADAPTIVE FLOW SYSTEM 2.0 - MQL5 DEVELOPMENT PROMPT

## ⚠️ REGRAS CRÍTICAS - LEIA ANTES DE COMEÇAR

### 🚨 ZERO TOLERÂNCIA PARA:

#### ❌ ESTRATÉGIAS/CONCEITOS SIMPLES
```
PROIBIDO:
"Vamos usar um cruzamento de médias móveis simples..."
"Quando RSI > 70, vende..."
"Suporte e resistência básicos..."

OBRIGATÓRIO:
Implementação COMPLETA dos 6 setups institucionais (A-F)
Lógica de liquidity hunting (BSL/SSL)
Order Blocks com validação multi-timeframe
AMD patterns (Accumulation/Manipulation/Distribution)
```

#### ❌ EXEMPLOS DE CÓDIGO INCOMPLETOS
```mql5
// INACEITÁVEL:
void CalculateIndicator() {
    // TODO: implement calculation
    // ... rest of code
}

// OBRIGATÓRIO:
void CalculateIndicator() {
    // [150+ linhas com TODA a lógica]
    double sum = 0.0;
    for(int i = 0; i < period; i++) {
        sum += buffer[i];
    }
    // ... implementação COMPLETA até o return
}
```

#### ❌ CONCEITOS PELA METADE
```
PROIBIDO:
"ADX acima de 25 indica tendência"

OBRIGATÓRIO:
"ADX > 25 + +DI > -DI + CI < 38.2 + BBW > 5% + Price acima POC por > 2h + Delta alinhado = 
REGIME TRENDING confirmado com 92% de precisão histórica em backtests de 18 meses"
```

#### ❌ DESORGANIZAÇÃO LÓGICA
```mql5
// PROIBIDO - Tudo no OnTick():
void OnTick() {
    double adx = iADX(...);
    if(adx > 25) {
        // 500 linhas de código aqui
    }
}

// OBRIGATÓRIO - Arquitetura Modular:
void OnTick() {
    if(!IsNewBar()) return;
    
    UpdateRegime();
    ScanSetups();
    ExecuteTrades();
}

// Cada função com 100+ linhas de implementação COMPLETA
```

---

## 📋 CONTEXTO DO PROJETO

### Sistema de Trading Profissional
**Nome**: Adaptive Flow System 2.0  
**Plataforma**: MetaTrader 5 (MQL5)  
**Tipo**: Expert Advisor institucional para daytrade  
**Ativos**: Índices (NAS100, DAX, SPX500), Metais (XAUUSD, XAGUSD), Forex Majors

### Arquitetura Core
```
3 REGIMES AUTO-DETECTADOS → 6 SETUPS ESPECIALIZADOS

TRENDING (40% tempo):
├─ Setup A: Liquidity Raid + OB Retest
├─ Setup C: Session Open Momentum
└─ Setup F: Order Flow Continuation

BREAKOUT (20% tempo):
├─ Setup B: AMD Compression Breakout
└─ Setup E: Squeeze Breakout

RANGING (40% tempo):
└─ Setup D: Mean Reversion Pro
```

### Performance Targets
- **Win Rate**: 62-70%
- **Risk:Reward**: 1:2.5 médio
- **Drawdown Máximo**: < 8%
- **Expectativa**: +1.15R a +1.50R por trade
- **Latência**: < 50ms por decisão de trade

---

## 🎯 FASE 1: IMPLEMENTAÇÃO DE INDICADORES (COMEÇAR AQUI)

### OBJETIVO
Criar **8 indicadores customizados MQL5** com precisão profissional, 100% completos, testados e otimizados.

### PRIORIDADE DE DESENVOLVIMENTO
```
1. ADX_Professional.mq5              [CRÍTICO - Base do regime detection]
2. ChoppinessIndex_Professional.mq5  [CRÍTICO - Complementa ADX]
3. BollingerKeltnerSqueeze_Professional.mq5  [ALTO - Squeeze detection]
4. ATR_Professional.mq5              [ALTO - Volatilidade normalizada]
5. WaddahAttarExplosion_Professional.mq5     [MÉDIO - Momentum]
6. VolumeProfile_Professional.mq5    [ALTO - Zonas institucionais]
7. OrderFlowDelta_Professional.mq5   [OPCIONAL - Requer tick data]
```

---

## 📐 ESPECIFICAÇÕES TÉCNICAS COMPLETAS

### INDICADOR 1: ADX PROFESSIONAL

**Arquivo**: `Indicators/ADX_Professional.mq5`

#### Propriedades do Indicador
```mql5
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3

// Plot 0: ADX (linha principal)
#property indicator_label1  "ADX"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

// Plot 1: +DI
#property indicator_label2  "+DI"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLimeGreen
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

// Plot 2: -DI
#property indicator_label3  "-DI"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

// Níveis horizontais
#property indicator_level1 20.0
#property indicator_level2 25.0
#property indicator_level3 40.0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT
```

#### Parâmetros de Entrada
```mql5
input int InpADXPeriod = 14;  // ADX Period (padrão Wilder)
```

#### Buffers Globais
```mql5
double BufferADX[];      // Buffer 0: ADX values
double BufferPlusDI[];   // Buffer 1: +DI values
double BufferMinusDI[];  // Buffer 2: -DI values

// Buffers auxiliares (não plotados)
double BufferTR[];       // True Range
double BufferPlusDM[];   // +DM (directional movement)
double BufferMinusDM[];  // -DM
double BufferDX[];       // DX (directional index)

// Buffers smoothed (Wilder)
double BufferSmoothedTR[];
double BufferSmoothedPlusDM[];
double BufferSmoothedMinusDM[];
```

#### Função OnInit() - COMPLETA
```mql5
int OnInit() {
    // Validação de parâmetros
    if(InpADXPeriod < 2) {
        PrintFormat("ERROR: Invalid ADX period %d. Must be >= 2. Using default 14.", InpADXPeriod);
        InpADXPeriod = 14;
    }
    
    // Set indicator buffers (3 plotados + 7 auxiliares = 10 total)
    IndicatorSetInteger(INDICATOR_DIGITS, 2);
    IndicatorSetString(INDICATOR_SHORTNAME, StringFormat("ADX(%d)", InpADXPeriod));
    
    // Buffers principais (plotados)
    SetIndexBuffer(0, BufferADX, INDICATOR_DATA);
    SetIndexBuffer(1, BufferPlusDI, INDICATOR_DATA);
    SetIndexBuffer(2, BufferMinusDI, INDICATOR_DATA);
    
    // Buffers auxiliares (calculations only)
    SetIndexBuffer(3, BufferTR, INDICATOR_CALCULATIONS);
    SetIndexBuffer(4, BufferPlusDM, INDICATOR_CALCULATIONS);
    SetIndexBuffer(5, BufferMinusDM, INDICATOR_CALCULATIONS);
    SetIndexBuffer(6, BufferSmoothedTR, INDICATOR_CALCULATIONS);
    SetIndexBuffer(7, BufferSmoothedPlusDM, INDICATOR_CALCULATIONS);
    SetIndexBuffer(8, BufferSmoothedMinusDM, INDICATOR_CALCULATIONS);
    SetIndexBuffer(9, BufferDX, INDICATOR_CALCULATIONS);
    
    // Set as series (mais recente = index 0)
    ArraySetAsSeries(BufferADX, true);
    ArraySetAsSeries(BufferPlusDI, true);
    ArraySetAsSeries(BufferMinusDI, true);
    ArraySetAsSeries(BufferTR, true);
    ArraySetAsSeries(BufferPlusDM, true);
    ArraySetAsSeries(BufferMinusDM, true);
    ArraySetAsSeries(BufferSmoothedTR, true);
    ArraySetAsSeries(BufferSmoothedPlusDM, true);
    ArraySetAsSeries(BufferSmoothedMinusDM, true);
    ArraySetAsSeries(BufferDX, true);
    
    // Set empty value
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
    
    // Set plot labels
    PlotIndexSetString(0, PLOT_LABEL, "ADX");
    PlotIndexSetString(1, PLOT_LABEL, "+DI");
    PlotIndexSetString(2, PLOT_LABEL, "-DI");
    
    return(INIT_SUCCEEDED);
}
```

#### Função OnCalculate() - COMPLETA
```mql5
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
    
    // Validação de dados mínimos
    if(rates_total < InpADXPeriod * 2) {
        PrintFormat("WARNING: Insufficient bars (%d). Need at least %d bars.", 
                    rates_total, InpADXPeriod * 2);
        return 0;
    }
    
    // Set arrays as series
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    // Determinar posição inicial de cálculo
    int start_pos;
    if(prev_calculated == 0) {
        // Primeiro cálculo
        start_pos = InpADXPeriod * 2; // Precisa de 2x período para smoothing
        
        // Inicializar buffers com EMPTY_VALUE
        ArrayInitialize(BufferADX, 0.0);
        ArrayInitialize(BufferPlusDI, 0.0);
        ArrayInitialize(BufferMinusDI, 0.0);
    } else {
        start_pos = prev_calculated - 1;
    }
    
    // ========================================================================
    // STEP 1: CALCULAR TRUE RANGE (TR)
    // ========================================================================
    for(int i = start_pos; i < rates_total && !IsStopped(); i++) {
        int bar = rates_total - 1 - i; // Converter para índice series
        
        if(bar == rates_total - 1) {
            // Primeira barra: TR = high - low
            BufferTR[bar] = high[bar] - low[bar];
        } else {
            // TR = max(high-low, |high-close[prev]|, |low-close[prev]|)
            double hl = high[bar] - low[bar];
            double hc = MathAbs(high[bar] - close[bar + 1]);
            double lc = MathAbs(low[bar] - close[bar + 1]);
            
            BufferTR[bar] = MathMax(hl, MathMax(hc, lc));
        }
    }
    
    // ========================================================================
    // STEP 2: CALCULAR DIRECTIONAL MOVEMENT (+DM, -DM)
    // ========================================================================
    for(int i = start_pos; i < rates_total && !IsStopped(); i++) {
        int bar = rates_total - 1 - i;
        
        if(bar == rates_total - 1) {
            // Primeira barra: sem movimento direcional
            BufferPlusDM[bar] = 0.0;
            BufferMinusDM[bar] = 0.0;
        } else {
            double high_diff = high[bar] - high[bar + 1];
            double low_diff = low[bar + 1] - low[bar];
            
            BufferPlusDM[bar] = 0.0;
            BufferMinusDM[bar] = 0.0;
            
            // +DM se high subiu mais que low desceu
            if(high_diff > low_diff && high_diff > 0) {
                BufferPlusDM[bar] = high_diff;
            }
            
            // -DM se low desceu mais que high subiu
            if(low_diff > high_diff && low_diff > 0) {
                BufferMinusDM[bar] = low_diff;
            }
        }
    }
    
    // ========================================================================
    // STEP 3: WILDER'S SMOOTHING (TR, +DM, -DM)
    // ========================================================================
    for(int i = start_pos; i < rates_total && !IsStopped(); i++) {
        int bar = rates_total - 1 - i;
        
        if(bar >= rates_total - InpADXPeriod) {
            // Primeiros 'period' valores: média simples
            double sum_tr = 0.0;
            double sum_plus_dm = 0.0;
            double sum_minus_dm = 0.0;
            
            for(int j = 0; j < InpADXPeriod; j++) {
                sum_tr += BufferTR[bar + j];
                sum_plus_dm += BufferPlusDM[bar + j];
                sum_minus_dm += BufferMinusDM[bar + j];
            }
            
            BufferSmoothedTR[bar] = sum_tr / InpADXPeriod;
            BufferSmoothedPlusDM[bar] = sum_plus_dm / InpADXPeriod;
            BufferSmoothedMinusDM[bar] = sum_minus_dm / InpADXPeriod;
        } else {
            // Wilder's smoothing: Current = ((Previous * (n-1)) + Current) / n
            BufferSmoothedTR[bar] = ((BufferSmoothedTR[bar + 1] * (InpADXPeriod - 1)) + BufferTR[bar]) / InpADXPeriod;
            BufferSmoothedPlusDM[bar] = ((BufferSmoothedPlusDM[bar + 1] * (InpADXPeriod - 1)) + BufferPlusDM[bar]) / InpADXPeriod;
            BufferSmoothedMinusDM[bar] = ((BufferSmoothedMinusDM[bar + 1] * (InpADXPeriod - 1)) + BufferMinusDM[bar]) / InpADXPeriod;
        }
    }
    
    // ========================================================================
    // STEP 4: CALCULAR +DI e -DI
    // ========================================================================
    for(int i = start_pos; i < rates_total && !IsStopped(); i++) {
        int bar = rates_total - 1 - i;
        
        if(BufferSmoothedTR[bar] != 0.0) {
            BufferPlusDI[bar] = (BufferSmoothedPlusDM[bar] / BufferSmoothedTR[bar]) * 100.0;
            BufferMinusDI[bar] = (BufferSmoothedMinusDM[bar] / BufferSmoothedTR[bar]) * 100.0;
        } else {
            BufferPlusDI[bar] = 0.0;
            BufferMinusDI[bar] = 0.0;
        }
        
        // Clamp to [0, 100]
        BufferPlusDI[bar] = MathMax(0.0, MathMin(100.0, BufferPlusDI[bar]));
        BufferMinusDI[bar] = MathMax(0.0, MathMin(100.0, BufferMinusDI[bar]));
    }
    
    // ========================================================================
    // STEP 5: CALCULAR DX (Directional Index)
    // ========================================================================
    for(int i = start_pos; i < rates_total && !IsStopped(); i++) {
        int bar = rates_total - 1 - i;
        
        double sum = BufferPlusDI[bar] + BufferMinusDI[bar];
        
        if(sum != 0.0) {
            double diff = MathAbs(BufferPlusDI[bar] - BufferMinusDI[bar]);
            BufferDX[bar] = (diff / sum) * 100.0;
        } else {
            BufferDX[bar] = 0.0;
        }
    }
    
    // ========================================================================
    // STEP 6: CALCULAR ADX (Smoothed DX)
    // ========================================================================
    for(int i = start_pos; i < rates_total && !IsStopped(); i++) {
        int bar = rates_total - 1 - i;
        
        if(bar >= rates_total - (InpADXPeriod * 2)) {
            // Primeiro ADX: média simples de DX
            double sum_dx = 0.0;
            
            for(int j = 0; j < InpADXPeriod; j++) {
                sum_dx += BufferDX[bar + j];
            }
            
            BufferADX[bar] = sum_dx / InpADXPeriod;
        } else {
            // Wilder's smoothing no ADX
            BufferADX[bar] = ((BufferADX[bar + 1] * (InpADXPeriod - 1)) + BufferDX[bar]) / InpADXPeriod;
        }
        
        // Clamp final
        BufferADX[bar] = MathMax(0.0, MathMin(100.0, BufferADX[bar]));
    }
    
    return rates_total;
}
```

#### Validação do Indicador
```mql5
// Adicionar ao final do arquivo (fora de OnCalculate)

//+------------------------------------------------------------------+
//| Função de teste/debug                                            |
//+------------------------------------------------------------------+
void DebugPrintValues(int bar) {
    PrintFormat("Bar[%d]: ADX=%.2f, +DI=%.2f, -DI=%.2f, TR=%.5f, DX=%.2f",
                bar,
                BufferADX[bar],
                BufferPlusDI[bar],
                BufferMinusDI[bar],
                BufferTR[bar],
                BufferDX[bar]);
}
```

---

### INDICADOR 2: CHOPPINESS INDEX PROFESSIONAL

**Arquivo**: `Indicators/ChoppinessIndex_Professional.mq5`

#### Propriedades
```mql5
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_label1  "Choppiness Index"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrOrange
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

// Níveis críticos
#property indicator_level1 38.2  // Trending threshold
#property indicator_level2 50.0  // Neutral
#property indicator_level3 61.8  // Ranging threshold
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT

#property indicator_minimum 0.0
#property indicator_maximum 100.0
```

#### Implementação COMPLETA
```mql5
input int InpCIPeriod = 14;  // Choppiness Index Period

double BufferCI[];
double BufferTR[];  // True Range (auxiliar)

int OnInit() {
    if(InpCIPeriod < 2) {
        PrintFormat("ERROR: Invalid CI period %d. Using default 14.", InpCIPeriod);
        InpCIPeriod = 14;
    }
    
    IndicatorSetInteger(INDICATOR_DIGITS, 2);
    IndicatorSetString(INDICATOR_SHORTNAME, StringFormat("CI(%d)", InpCIPeriod));
    
    SetIndexBuffer(0, BufferCI, INDICATOR_DATA);
    SetIndexBuffer(1, BufferTR, INDICATOR_CALCULATIONS);
    
    ArraySetAsSeries(BufferCI, true);
    ArraySetAsSeries(BufferTR, true);
    
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
    
    return(INIT_SUCCEEDED);
}

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
    
    if(rates_total < InpCIPeriod + 1) return 0;
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    int start_pos = (prev_calculated == 0) ? InpCIPeriod : prev_calculated - 1;
    
    // ========================================================================
    // STEP 1: CALCULAR TRUE RANGE
    // ========================================================================
    for(int i = start_pos; i < rates_total && !IsStopped(); i++) {
        int bar = rates_total - 1 - i;
        
        if(bar == rates_total - 1) {
            BufferTR[bar] = high[bar] - low[bar];
        } else {
            double hl = high[bar] - low[bar];
            double hc = MathAbs(high[bar] - close[bar + 1]);
            double lc = MathAbs(low[bar] - close[bar + 1]);
            BufferTR[bar] = MathMax(hl, MathMax(hc, lc));
        }
    }
    
    // ========================================================================
    // STEP 2: CALCULAR CHOPPINESS INDEX
    // ========================================================================
    for(int i = start_pos; i < rates_total && !IsStopped(); i++) {
        int bar = rates_total - 1 - i;
        
        // Sum of True Range over period
        double sum_tr = 0.0;
        for(int j = 0; j < InpCIPeriod && (bar + j) < rates_total; j++) {
            sum_tr += BufferTR[bar + j];
        }
        
        // Highest high and lowest low over period
        double highest_high = high[bar];
        double lowest_low = low[bar];
        
        for(int j = 1; j < InpCIPeriod && (bar + j) < rates_total; j++) {
            if(high[bar + j] > highest_high) highest_high = high[bar + j];
            if(low[bar + j] < lowest_low) lowest_low = low[bar + j];
        }
        
        double price_range = highest_high - lowest_low;
        
        // Edge cases
        if(price_range == 0.0 || sum_tr == 0.0) {
            BufferCI[bar] = 50.0; // Neutral for flat market
            continue;
        }
        
        // Choppiness Index formula
        double log_ratio = MathLog10(sum_tr / price_range);
        double log_period = MathLog10((double)InpCIPeriod);
        
        if(log_period == 0.0) {
            BufferCI[bar] = 50.0;
            continue;
        }
        
        double ci = 100.0 * (log_ratio / log_period);
        
        // Clamp to [0, 100]
        BufferCI[bar] = MathMax(0.0, MathMin(100.0, ci));
    }
    
    return rates_total;
}
```

---

### INDICADOR 3: BOLLINGER/KELTNER SQUEEZE

**Arquivo**: `Indicators/BollingerKeltnerSqueeze_Professional.mq5`

#### Propriedades
```mql5
#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   5

// Bollinger Bands
#property indicator_label1  "BB Upper"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_width1  1

#property indicator_label2  "BB Middle"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGray
#property indicator_width2  1

#property indicator_label3  "BB Lower"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDodgerBlue
#property indicator_width3  1

// Keltner Channels
#property indicator_label4  "KC Upper"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrOrange
#property indicator_width4  1
#property indicator_style4  STYLE_DOT

#property indicator_label5  "KC Lower"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrOrange
#property indicator_width5  1
#property indicator_style5  STYLE_DOT
```

#### Implementação COMPLETA
```mql5
input int InpBBPeriod = 20;           // Bollinger Period
input double InpBBDeviation = 2.0;    // BB Standard Deviation
input int InpKCPeriod = 20;           // Keltner Period
input double InpKCMultiplier = 2.0;   // KC ATR Multiplier
input int InpATRPeriod = 14;          // ATR Period

double BufferBB_Upper[];
double BufferBB_Middle[];
double BufferBB_Lower[];
double BufferKC_Upper[];
double BufferKC_Lower[];
double BufferKC_Middle[];  // Auxiliar
double BufferSqueeze[];     // Auxiliar (1.0 = squeeze ativo)

int g_handle_atr = INVALID_HANDLE;

int OnInit() {
    if(InpBBPeriod < 2 || InpKCPeriod < 2 || InpATRPeriod < 2) {
        Print("ERROR: Invalid periods");
        return INIT_FAILED;
    }
    
    // Criar handle do ATR
    g_handle_atr = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
    if(g_handle_atr == INVALID_HANDLE) {
        Print("ERROR: Failed to create ATR indicator");
        return INIT_FAILED;
    }
    
    IndicatorSetString(INDICATOR_SHORTNAME, StringFormat("BB-KC Squeeze(%d,%d)", InpBBPeriod, InpKCPeriod));
    
    // Buffers plotados
    SetIndexBuffer(0, BufferBB_Upper, INDICATOR_DATA);
    SetIndexBuffer(1, BufferBB_Middle, INDICATOR_DATA);
    SetIndexBuffer(2, BufferBB_Lower, INDICATOR_DATA);
    SetIndexBuffer(3, BufferKC_Upper, INDICATOR_DATA);
    SetIndexBuffer(4, BufferKC_Lower, INDICATOR_DATA);
    
    // Buffers auxiliares
    SetIndexBuffer(5, BufferKC_Middle, INDICATOR_CALCULATIONS);
    SetIndexBuffer(6, BufferSqueeze, INDICATOR_CALCULATIONS);
    
    ArraySetAsSeries(BufferBB_Upper, true);
    ArraySetAsSeries(BufferBB_Middle, true);
    ArraySetAsSeries(BufferBB_Lower, true);
    ArraySetAsSeries(BufferKC_Upper, true);
    ArraySetAsSeries(BufferKC_Lower, true);
    ArraySetAsSeries(BufferKC_Middle, true);
    ArraySetAsSeries(BufferSqueeze, true);
    
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    if(g_handle_atr != INVALID_HANDLE) {
        IndicatorRelease(g_handle_atr);
        g_handle_atr = INVALID_HANDLE;
    }
}

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
    
    int min_bars = MathMax(InpBBPeriod, InpKCPeriod) + InpATRPeriod;
    if(rates_total < min_bars) return 0;
    
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    int start_pos = (prev_calculated == 0) ? min_bars : prev_calculated - 1;
    
    // Copiar ATR
    double atr_buffer[];
    ArraySetAsSeries(atr_buffer, true);
    int copied = CopyBuffer(g_handle_atr, 0, 0, rates_total, atr_buffer);
    if(copied <= 0) {
        PrintFormat("ERROR: Failed to copy ATR buffer, error=%d", GetLastError());
        return 0;
    }
    
    // ========================================================================
    // CALCULAR BOLLINGER BANDS
    // ========================================================================
    for(int i = start_pos; i < rates_total && !IsStopped(); i++) {
        int bar = rates_total - 1 - i;
        
        // SMA
        double sum = 0.0;
        for(int j = 0; j < InpBBPeriod; j++) {
            sum += close[bar + j];
        }
        BufferBB_Middle[bar] = sum / InpBBPeriod;
        
        // Standard Deviation
        double sum_squared_diff = 0.0;
        for(int j = 0; j < InpBBPeriod; j++) {
            double diff = close[bar + j] - BufferBB_Middle[bar];
            sum_squared_diff += diff * diff;
        }
        double std_dev = MathSqrt(sum_squared_diff / InpBBPeriod);
        
        BufferBB_Upper[bar] = BufferBB_Middle[bar] + (InpBBDeviation * std_dev);
        BufferBB_Lower[bar] = BufferBB_Middle[bar] - (InpBBDeviation * std_dev);
    }
    
    // ========================================================================
    // CALCULAR KELTNER CHANNELS
    // ========================================================================
    for(int i = start_pos; i < rates_total && !IsStopped(); i++) {
        int bar = rates_total - 1 - i;
        
        // EMA (não SMA!)
        BufferKC_Middle[bar] = CalculateEMA(close, bar, InpKCPeriod);
        
        // KC bands usando ATR
        double atr_value = atr_buffer[bar];
        BufferKC_Upper[bar] = BufferKC_Middle[bar] + (InpKCMultiplier * atr_value);
        BufferKC_Lower[bar] = BufferKC_Middle[bar] - (InpKCMultiplier * atr_value);
        
        // Detectar squeeze: BB dentro de KC
        bool squeeze = (BufferBB_Upper[bar] < BufferKC_Upper[bar] && 
                       BufferBB_Lower[bar] > BufferKC_Lower[bar]);
        
        BufferSqueeze[bar] = squeeze ? 1.0 : 0.0;
    }
    
    return rates_total;
}

//+------------------------------------------------------------------+
//| Calcula EMA manualmente (método iterativo)                       |
//+------------------------------------------------------------------+
double CalculateEMA(const double &array[], int bar, int period) {
    if(bar >= ArraySize(array) - period) {
        // Primeiro EMA: usar SMA
        double sum = 0.0;
        for(int i = 0; i < period; i++) {
            sum += array[bar + i];
        }
        return sum / period;
    }
    
    // EMA recursivo: EMA = (Close * K) + (EMA_prev * (1 - K))
    // K = 2 / (period + 1)
    double k = 2.0 / (period + 1.0);
    double ema_prev = CalculateEMA(array, bar + 1, period);
    
    return (array[bar] * k) + (ema_prev * (1.0 - k));
}

//+------------------------------------------------------------------+
//| Função auxiliar: BBW Percentage                                  |
//+------------------------------------------------------------------+
double GetBBW_Percentage(int bar) {
    if(BufferBB_Middle[bar] == 0.0) return 0.0;
    return ((BufferBB_Upper[bar] - BufferBB_Lower[bar]) / BufferBB_Middle[bar]) * 100.0;
}

//+------------------------------------------------------------------+
//| Função auxiliar: Is Squeeze Active                               |
//+------------------------------------------------------------------+
bool IsSqueezeActive(int bar) {
    return BufferSqueeze[bar] == 1.0;
}
```

---

### INDICADOR 4: ATR PROFESSIONAL

**Arquivo**: `Indicators/ATR_Professional.mq5`

```mql5
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_label1  "ATR"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLimeGreen
#property indicator_width1  2

#property indicator_label2  "ATR%"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrange
#property indicator_width2  1

#property indicator_label3  "ATR ROC"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDodgerBlue
#property indicator_width3  1

input int InpATRPeriod = 14;
input int InpROCPeriod = 5;

double BufferATR[];
double BufferATR_Pct[];
double BufferATR_ROC[];
double BufferTR[];  // Auxiliar

int OnInit() {
    if(InpATRPeriod < 2 || InpROCPeriod < 1) {
        Print("ERROR: Invalid periods");
        return INIT_FAILED;
    }
    
    IndicatorSetString(INDICATOR_SHORTNAME, StringFormat("ATR(%d) + ROC(%d)", InpATRPeriod, InpROCPeriod));
    
    SetIndexBuffer(0, BufferATR, INDICATOR_DATA);
    SetIndexBuffer(1, BufferATR_Pct, INDICATOR_DATA);
    SetIndexBuffer(2, BufferATR_ROC, INDICATOR_DATA);
    SetIndexBuffer(3, BufferTR, INDICATOR_CALCULATIONS);
    
    ArraySetAsSeries(BufferATR, true);
    ArraySetAsSeries(BufferATR_Pct, true);
    ArraySetAsSeries(BufferATR_ROC, true);
    ArraySetAsSeries(BufferTR, true);
    
    PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, InpATRPeriod);
    PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, InpATRPeriod + InpROCPeriod);
    
    return(INIT_SUCCEEDED);
}

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
    
    if(rates_total < InpATRPeriod + InpROCPeriod) return 0;
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    int start_pos = (prev_calculated == 0) ? InpATRPeriod : prev_calculated - 1;
    
    // ========================================================================
    // STEP 1: TRUE RANGE
    // ========================================================================
    for(int i = start_pos; i < rates_total && !IsStopped(); i++) {
        int bar = rates_total - 1 - i;
        
        if(bar == rates_total - 1) {
            BufferTR[bar] = high[bar] - low[bar];
        } else {
            double hl = high[bar] - low[bar];
            double hc = MathAbs(high[bar] - close[bar + 1]);
            double lc = MathAbs(low[bar] - close[bar + 1]);
            BufferTR[bar] = MathMax(hl, MathMax(hc, lc));
        }
    }
    
    // ========================================================================
    // STEP 2: ATR (Wilder's Smoothing)
    // ========================================================================
    for(int i = start_pos; i < rates_total && !IsStopped(); i++) {
        int bar = rates_total - 1 - i;
        
        if(bar >= rates_total - InpATRPeriod) {
            // Primeiro ATR: média simples
            double sum_tr = 0.0;
            for(int j = 0; j < InpATRPeriod; j++) {
                sum_tr += BufferTR[bar + j];
            }
            BufferATR[bar] = sum_tr / InpATRPeriod;
        } else {
            // Wilder's smoothing
            BufferATR[bar] = ((BufferATR[bar + 1] * (InpATRPeriod - 1)) + BufferTR[bar]) / InpATRPeriod;
        }
        
        // ATR Percentage (normalized)
        if(close[bar] != 0.0) {
            BufferATR_Pct[bar] = (BufferATR[bar] / close[bar]) * 100.0;
        } else {
            BufferATR_Pct[bar] = 0.0;
        }
    }
    
    // ========================================================================
    // STEP 3: ATR RATE OF CHANGE
    // ========================================================================
    for(int i = start_pos; i < rates_total && !IsStopped(); i++) {
        int bar = rates_total - 1 - i;
        
        if(bar + InpROCPeriod >= rates_total) {
            BufferATR_ROC[bar] = 0.0;
            continue;
        }
        
        double atr_current = BufferATR[bar];
        double atr_past = BufferATR[bar + InpROCPeriod];
        
        if(atr_past != 0.0) {
            BufferATR_ROC[bar] = ((atr_current - atr_past) / atr_past) * 100.0;
        } else {
            BufferATR_ROC[bar] = 0.0;
        }
    }
    
    return rates_total;
}
```

---

### INDICADOR 5: WADDAH ATTAR EXPLOSION

**Arquivo**: `Indicators/WaddahAttarExplosion_Professional.mq5`

```mql5
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   3

#property indicator_label1  "Trend Up"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrLimeGreen
#property indicator_width1  3

#property indicator_label2  "Trend Down"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrRed
#property indicator_width2  3

#property indicator_label3  "Explosion Line"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrYellow
#property indicator_width3  2

input int InpFastMA = 20;
input int InpSlowMA = 40;
input int InpSignalPeriod = 9;
input int InpBBLength = 20;
input double InpBBMultiplier = 2.0;
input int InpSensitivity = 150;

double BufferTrendUp[];
double BufferTrendDown[];
double BufferExplosionLine[];
double BufferDeadZone[];  // Auxiliar

int g_handle_macd = INVALID_HANDLE;
int g_handle_bb = INVALID_HANDLE;

int OnInit() {
    if(InpFastMA >= InpSlowMA) {
        Print("ERROR: Fast MA must be < Slow MA");
        return INIT_FAILED;
    }
    
    // Criar handles
    g_handle_macd = iMACD(_Symbol, PERIOD_CURRENT, InpFastMA, InpSlowMA, InpSignalPeriod, PRICE_CLOSE);
    g_handle_bb = iBands(_Symbol, PERIOD_CURRENT, InpBBLength, 0, InpBBMultiplier, PRICE_CLOSE);
    
    if(g_handle_macd == INVALID_HANDLE || g_handle_bb == INVALID_HANDLE) {
        Print("ERROR: Failed to create indicator handles");
        return INIT_FAILED;
    }
    
    IndicatorSetString(INDICATOR_SHORTNAME, StringFormat("WAE(%d,%d,%d)", InpFastMA, InpSlowMA, InpSensitivity));
    
    SetIndexBuffer(0, BufferTrendUp, INDICATOR_DATA);
    SetIndexBuffer(1, BufferTrendDown, INDICATOR_DATA);
    SetIndexBuffer(2, BufferExplosionLine, INDICATOR_DATA);
    SetIndexBuffer(3, BufferDeadZone, INDICATOR_CALCULATIONS);
    
    ArraySetAsSeries(BufferTrendUp, true);
    ArraySetAsSeries(BufferTrendDown, true);
    ArraySetAsSeries(BufferExplosionLine, true);
    ArraySetAsSeries(BufferDeadZone, true);
    
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    if(g_handle_macd != INVALID_HANDLE) IndicatorRelease(g_handle_macd);
    if(g_handle_bb != INVALID_HANDLE) IndicatorRelease(g_handle_bb);
}

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
    
    int min_bars = MathMax(InpSlowMA, InpBBLength) + InpSignalPeriod;
    if(rates_total < min_bars) return 0;
    
    int start_pos = (prev_calculated == 0) ? min_bars : prev_calculated - 1;
    
    // Copiar buffers
    double macd_main[], macd_signal[], bb_upper[], bb_lower[], bb_middle[];
    ArraySetAsSeries(macd_main, true);
    ArraySetAsSeries(macd_signal, true);
    ArraySetAsSeries(bb_upper, true);
    ArraySetAsSeries(bb_lower, true);
    ArraySetAsSeries(bb_middle, true);
    
    if(CopyBuffer(g_handle_macd, 0, 0, rates_total, macd_main) <= 0 ||
       CopyBuffer(g_handle_macd, 1, 0, rates_total, macd_signal) <= 0 ||
       CopyBuffer(g_handle_bb, 0, 0, rates_total, bb_middle) <= 0 ||
       CopyBuffer(g_handle_bb, 1, 0, rates_total, bb_upper) <= 0 ||
       CopyBuffer(g_handle_bb, 2, 0, rates_total, bb_lower) <= 0) {
        PrintFormat("ERROR: Failed to copy indicator buffers");
        return 0;
    }
    
    // ========================================================================
    // CALCULAR WAE
    // ========================================================================
    for(int i = start_pos; i < rates_total && !IsStopped(); i++) {
        int bar = rates_total - 1 - i;
        
        // MACD Histogram
        double histogram = macd_main[bar] - macd_signal[bar];
        
        // Trend Power
        double trend_power = histogram * InpSensitivity;
        
        if(trend_power >= 0) {
            BufferTrendUp[bar] = trend_power;
            BufferTrendDown[bar] = 0.0;
        } else {
            BufferTrendUp[bar] = 0.0;
            BufferTrendDown[bar] = MathAbs(trend_power);
        }
        
        // Explosion Line (Bollinger Width scaled)
        double bb_width = bb_upper[bar] - bb_lower[bar];
        BufferExplosionLine[bar] = (bb_width * InpSensitivity) / 10.0;
        
        // Dead Zone detection
        bool dead_zone = (BufferTrendUp[bar] < BufferExplosionLine[bar] && 
                         BufferTrendDown[bar] < BufferExplosionLine[bar]);
        BufferDeadZone[bar] = dead_zone ? 1.0 : 0.0;
    }
    
    return rates_total;
}

//+------------------------------------------------------------------+
//| Função auxiliar: Detectar explosão                               |
//+------------------------------------------------------------------+
bool IsExplosion(int bar) {
    if(bar + 1 >= ArraySize(BufferTrendUp)) return false;
    
    bool dead_zone_prev = BufferDeadZone[bar + 1] == 1.0;
    bool dead_zone_curr = BufferDeadZone[bar] == 1.0;
    
    // Transição de dead zone para ativo
    return (dead_zone_prev && !dead_zone_curr);
}
```

---

### INDICADOR 6: VOLUME PROFILE (SIMPLIFICADO)

**Arquivo**: `Indicators/VolumeProfile_Professional.mq5`

**NOTA**: Volume Profile é complexo. Implementação completa requer 500+ linhas. Aqui está versão funcional:

```mql5
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_label1  "POC"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_width1  2
#property indicator_style1  STYLE_SOLID

#property indicator_label2  "VAH"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLimeGreen
#property indicator_width2  1
#property indicator_style2  STYLE_DOT

#property indicator_label3  "VAL"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_width3  1
#property indicator_style3  STYLE_DOT

input int InpLookbackBars = 500;        // Lookback Bars
input double InpValueAreaPct = 70.0;    // Value Area Percentage

double BufferPOC[];
double BufferVAH[];
double BufferVAL[];

struct SPriceNode {
    double price;
    long volume;
};

SPriceNode g_profile_nodes[];
int g_num_nodes = 0;

int OnInit() {
    IndicatorSetString(INDICATOR_SHORTNAME, StringFormat("VP(%d)", InpLookbackBars));
    
    SetIndexBuffer(0, BufferPOC, INDICATOR_DATA);
    SetIndexBuffer(1, BufferVAH, INDICATOR_DATA);
    SetIndexBuffer(2, BufferVAL, INDICATOR_DATA);
    
    ArraySetAsSeries(BufferPOC, true);
    ArraySetAsSeries(BufferVAH, true);
    ArraySetAsSeries(BufferVAL, true);
    
    return(INIT_SUCCEEDED);
}

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
    
    if(rates_total < InpLookbackBars) return 0;
    
    // Recalcular apenas em nova barra
    static datetime last_time = 0;
    if(time[rates_total - 1] == last_time) return rates_total;
    last_time = time[rates_total - 1];
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(tick_volume, true);
    
    // ========================================================================
    // CONSTRUIR VOLUME PROFILE
    // ========================================================================
    
    // 1. Encontrar range de preços
    double highest = high[0];
    double lowest = low[0];
    
    for(int i = 1; i < InpLookbackBars && i < rates_total; i++) {
        if(high[i] > highest) highest = high[i];
        if(low[i] < lowest) lowest = low[i];
    }
    
    double price_range = highest - lowest;
    if(price_range == 0.0) return rates_total;
    
    // 2. Criar bins de preço (0.1% do range)
    double bin_size = price_range * 0.001;
    g_num_nodes = (int)MathCeil(price_range / bin_size);
    
    if(g_num_nodes > 10000) g_num_nodes = 10000; // Limite de segurança
    
    ArrayResize(g_profile_nodes, g_num_nodes);
    
    // Inicializar nodes
    for(int i = 0; i < g_num_nodes; i++) {
        g_profile_nodes[i].price = lowest + (i * bin_size);
        g_profile_nodes[i].volume = 0;
    }
    
    // 3. Distribuir volume nos bins
    for(int bar = 0; bar < InpLookbackBars && bar < rates_total; bar++) {
        // Para cada bin, verificar se preço da barra intersecta
        for(int node = 0; node < g_num_nodes; node++) {
            double node_price = g_profile_nodes[node].price;
            
            if(node_price >= low[bar] && node_price <= high[bar]) {
                g_profile_nodes[node].volume += tick_volume[bar];
            }
        }
    }
    
    // 4. Encontrar POC (max volume)
    long max_volume = 0;
    int poc_index = 0;
    
    for(int i = 0; i < g_num_nodes; i++) {
        if(g_profile_nodes[i].volume > max_volume) {
            max_volume = g_profile_nodes[i].volume;
            poc_index = i;
        }
    }
    
    double poc_price = g_profile_nodes[poc_index].price;
    
    // 5. Calcular Value Area (70% do volume)
    long total_volume = 0;
    for(int i = 0; i < g_num_nodes; i++) {
        total_volume += g_profile_nodes[i].volume;
    }
    
    long value_area_volume = (long)(total_volume * (InpValueAreaPct / 100.0));
    
    // Expandir do POC até capturar 70%
    int upper_idx = poc_index;
    int lower_idx = poc_index;
    long accumulated = g_profile_nodes[poc_index].volume;
    
    while(accumulated < value_area_volume) {
        long vol_above = (upper_idx + 1 < g_num_nodes) ? g_profile_nodes[upper_idx + 1].volume : 0;
        long vol_below = (lower_idx - 1 >= 0) ? g_profile_nodes[lower_idx - 1].volume : 0;
        
        if(vol_above > vol_below && upper_idx + 1 < g_num_nodes) {
            upper_idx++;
            accumulated += g_profile_nodes[upper_idx].volume;
        } else if(lower_idx - 1 >= 0) {
            lower_idx--;
            accumulated += g_profile_nodes[lower_idx].volume;
        } else {
            break;
        }
    }
    
    double vah_price = g_profile_nodes[upper_idx].price;
    double val_price = g_profile_nodes[lower_idx].price;
    
    // 6. Preencher buffers (linhas horizontais)
    for(int i = 0; i < rates_total && !IsStopped(); i++) {
        BufferPOC[i] = poc_price;
        BufferVAH[i] = vah_price;
        BufferVAL[i] = val_price;
    }
    
    PrintFormat("Volume Profile: POC=%.5f, VAH=%.5f, VAL=%.5f (Total Vol=%d)", 
                poc_price, vah_price, val_price, total_volume);
    
    return rates_total;
}
```

---

## 🎯 CHECKLIST DE DESENVOLVIMENTO - FASE 1

### Antes de Começar Cada Indicador:
```
☐ Ler especificação técnica COMPLETA (fórmulas, edge cases)
☐ Entender saídas esperadas (buffers, ranges, validações)
☐ Planejar estrutura de código (funções auxiliares)
☐ Definir casos de teste (trending, ranging, flat market)
```

### Durante Implementação:
```
☐ Escrever OnInit() COMPLETO (todos os buffers, validações)
☐ Implementar OnCalculate() com TODA lógica (zero TODOs)
☐ Adicionar tratamento de erros (edge cases, divisão por zero)
☐ Implementar funções auxiliares COMPLETAS
☐ Adicionar comentários explicativos nas fórmulas complexas
☐ Validar ranges de saída (clamps quando necessário)
```

### Após Implementação:
```
☐ Compilar no MetaEditor (zero warnings)
☐ Adicionar ao gráfico e verificar visualmente
☐ Testar em dados trending (ADX > 40)
☐ Testar em dados ranging (flat, consolidação)
☐ Testar edge cases (1 barra, dados faltando, flat market)
☐ Comparar valores com TradingView/calculadora manual
☐ Verificar performance (sem lag em 10k barras)
☐ Documentar parâmetros e interpretação
```

---

## 🚀 COMANDO DE INÍCIO - COPIE NO COPILOT

```
INÍCIO DA FASE 1: IMPLEMENTAÇÃO DE INDICADORES MQL5

Contexto:
- Sistema: Adaptive Flow System 2.0 para MetaTrader 5
- Objetivo: Implementar 8 indicadores customizados 100% completos
- Prioridade: ADX → CI → BB/KC → ATR → WAE → VP
- Requisitos: Código production-ready, sem simplificações, zero TODOs

TAREFA IMEDIATA:
Implementar ADX_Professional.mq5 seguindo EXATAMENTE a especificação em development-prompt-mql5.md

Arquivo: Indicators/ADX_Professional.mq5

Deve incluir:
1. Propriedades completas (3 plots, 3 níveis horizontais)
2. OnInit() com validação de períodos e setup de 10 buffers
3. OnCalculate() com implementação COMPLETA:
   - True Range calculation
   - Directional Movement (+DM, -DM)
   - Wilder's Smoothing (não EMA comum)
   - +DI e -DI calculation
   - DX calculation
   - ADX (smoothed DX)
4. Funções auxiliares se necessário
5. Tratamento de edge cases (flat market, primeira barra)
6. Validação de ranges [0, 100]
7. Comentários em fórmulas complexas

REGRAS INACEITÁVEIS:
❌ Código incompleto (// TODO, // rest of code)
❌ Fórmulas simplificadas (usar Wilder exato)
❌ Sem tratamento de erros
❌ Buffers mal dimensionados
❌ Lógica no OnTick (apenas indicador puro)

Compile e teste antes de prosseguir para próximo indicador.

COMECE AGORA! 🔥
```

---

## 📊 MÉTRICAS DE SUCESSO - FASE 1

### Indicadores Completos:
```
✅ ADX_Professional.mq5           [3 buffers, Wilder smoothing]
✅ ChoppinessIndex_Professional.mq5  [CI formula exata]
✅ BollingerKeltnerSqueeze_Professional.mq5  [7 buffers, squeeze detection]
✅ ATR_Professional.mq5           [ATR + % + ROC]
✅ WaddahAttarExplosion_Professional.mq5  [MACD + BB fusion]
✅ VolumeProfile_Professional.mq5  [POC, VAH, VAL]
```

### Critérios de Qualidade:
```
☐ Todos compilam sem erros/warnings
☐ Plotam corretamente no gráfico
☐ Valores validados vs TradingView
☐ Performance < 100ms para 10k barras
☐ Edge cases tratados (flat, gaps, 1 barra)
☐ Código comentado em partes complexas
☐ Zero linhas de código incompleto
```

---

## 🔄 PRÓXIMAS FASES (APÓS INDICADORES)

**FASE 2**: Regime Detector (Arquivo: Include/AFS_RegimeDetector.mqh)  
**FASE 3**: Setup Manager - 6 setups (Include/AFS_SetupManager.mqh)  
**FASE 4**: Risk Manager (Include/AFS_RiskManager.mqh)  
**FASE 5**: EA Principal (Experts/AdaptiveFlowSystem_v2.mq5)  
**FASE 6**: Backtesting no Strategy Tester  
**FASE 7**: Otimização e refinamento

---

**AGORA COMECE O DESENVOLVIMENTO! NÃO HÁ MAIS NADA A DISCUTIR. CÓDIGO COMPLETO OU NADA.** 🚀