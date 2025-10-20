//+------------------------------------------------------------------+
//| AFS_SetupManager.mqh                                            |
//| Adaptive Flow System v2 - Setup Manager                          |
//| Evaluates SRegimeSignals + regime into 6 institutional setups    |
//| (A-F) with concrete entry/SL/TP and confidence.                  |
//+------------------------------------------------------------------+
#ifndef __AFS_SETUP_MANAGER_MQH__
#define __AFS_SETUP_MANAGER_MQH__
#property strict

// Ensure market regime enum exists (matches AFS_RegimeDetector.mqh)
#ifndef __ENUM_MARKET_REGIME_DEFINED__
#define __ENUM_MARKET_REGIME_DEFINED__
enum ENUM_MARKET_REGIME
{
   REGIME_UNDEFINED = 0,
   REGIME_TRENDING,
   REGIME_BREAKOUT,
   REGIME_RANGING
};
#endif

enum ENUM_SETUP_TYPE
{
   SETUP_UNDEFINED = -1,        // 🔥 CORREÇÃO #37: Valor inicial para debounce
   SETUP_A_LIQUIDITY_RAID = 0,
   SETUP_B_AMD_BREAKOUT,
   SETUP_C_SESSION_MOMENTUM,
   SETUP_D_MEAN_REVERSION,
   SETUP_E_SQUEEZE_BREAKOUT,
   SETUP_F_CONTINUATION
};

enum ENUM_SIGNAL_DIRECTION
{
   DIR_NONE = 0,
   DIR_LONG,
   DIR_SHORT
};

enum ENUM_ORDER_TYPE_SIGNAL
{
   ORDER_SIGNAL_MARKET = 0,  // Entrada imediata (market order)
   ORDER_SIGNAL_PENDING      // Entrada antecipada (pending order)
};

enum ENUM_SESSION
{
   SESSION_ASIAN = 0,
   SESSION_LONDON,
   SESSION_NEWYORK
};

// Forward declare signals struct from RegimeDetector
#ifndef __SREGIME_SIGNALS_DEFINED__
#define __SREGIME_SIGNALS_DEFINED__
struct SRegimeSignals
{
   double adx;
   double plus_di;
   double minus_di;
   double ci;
   double bbw_pct;
   bool   squeeze_now;
   bool   squeeze_prev;
   double atr;
   double atr_pct;
   double atr_roc;
   double wae_trend_up;
   double wae_trend_down;
   double wae_explosion;
   double poc;
   double vah;
   double val;
   double price_close;
   int    votes_trend;
   int    votes_breakout;
   int    votes_range;
   int    votes_total;
   int    regime; // not used directly here
   double confidence;
   datetime timestamp;
};
#endif

// ============================================================================
// STRUCTURES
// ============================================================================
struct SSetupSignal
{
   ENUM_SETUP_TYPE          setup;
   ENUM_SIGNAL_DIRECTION    direction;
   ENUM_ORDER_TYPE_SIGNAL   order_type;    // 🔥 NOVO: Market vs Pending
   double                   entry_price;
   double                   sl_price;
   double                   tp_price;
   double                   confidence;   // 0..1
   string                   reason;       // human-readable rationale
};

struct SSetupResult
{
   // Fixed-size array for 6 setups
   SSetupSignal signals[6];
   int          count;
};

// 🔥 CORREÇÃO #45: Configuração individualizada por setup (BE/Trailing/SL/TP)
// PROBLEMA: Parâmetros globais (InpBreakEvenActivationR, InpTrailingDistanceATR) não funcionam
//           para todos os setups (ex: Setup A precisa BE 0.5R, Setup C precisa 1.0R)
// SOLUÇÃO: Struct com configs específicas por setup

// 🔥 CORREÇÃO #46: Parâmetros de DETECÇÃO também individualizados
// PROBLEMA CRÍTICO: Setup A com sweep_pips=5.0 (global) → swept=0 em 100% dos casos
//                   Apenas 3 trades em 21 meses (esperado: 15-25)
// ROOT CAUSE: Parâmetros de detecção hardcoded no constructor (m_liq_lookback, m_liq_sweep_pips, etc)
// SOLUÇÃO: Adicionar params de detecção ao SSetupConfig para cada setup poder ter seus próprios valores
struct SSetupConfig
{
   // Break Even
   bool   be_enabled;           // Ativar break even
   double be_activation_r;      // Ativação em R múltiplos (ex: 0.5 = +0.5R)
   double be_offset_pips;       // Offset em pips do entry (ex: 5.0)
   bool   be_use_sl_fraction;   // Usar fração do SL ao invés de pips
   double be_offset_fraction;   // Fração do SL para offset (ex: 0.30 = 30%)
   
   // Trailing Stop
   bool   ts_enabled;           // Ativar trailing stop
   double ts_activation_r;      // Ativação em R múltiplos (ex: 0.8 = +0.8R)
   bool   ts_use_atr;           // true=ATR trailing; false=passo fixo
   double ts_distance_atr;      // Distância em ATR multiplier (ex: 1.0)
   double ts_step_fraction;     // Passo relativo ao SL (quando ts_use_atr=false)
   
   // SL/TP Strategy
   double sl_atr_multiplier;    // Multiplicador ATR para SL (ex: 1.5)
   double tp_rr_ratio;          // Risk:Reward ratio para TP (ex: 3.0 = 1:3)
   bool   tp_use_levels;        // Usar POC/VAL/VAH como TP (priority over RR)
   
   // 🔥 CORREÇÃO #46: Parâmetros de DETECÇÃO individualizados
   // Setup A - Liquidity Raid
   int    liq_lookback_bars;    // Barras para scan de swing high/low (30-100)
   double liq_sweep_pips;       // Mínimo de pips além do swing para considerar sweep (1.0-10.0)
   double liq_sl_buffer_pips;   // Buffer em pips para SL além do swing (5.0-15.0)
   double liq_di_margin;        // Margem de diferença DI para confirmar direção (0.5-2.0)
   double liq_wae_threshold;    // 🔥 CORREÇÃO #62: WAE threshold (v2.33: 0.40, antes 0.70 hardcoded bloqueou TODOS!)
   
   // Setup B - AMD Breakout
   double amd_volume_multiplier; // Volume mínimo vs média (ex: 1.5x)
   double amd_breakout_buffer;  // Buffer além do range para confirmar breakout (pips)
   
   // Setup C - Session Momentum
   double session_min_atr_pct;  // ATR% mínimo para considerar momentum (ex: 0.05 = 0.05%)
   double session_ci_max;       // CI máximo para evitar choppy (ex: 65)
   
   // Setup D - Mean Reversion
   double mr_near_varea_pips;   // Distância máxima do VAL/VAH para considerar "perto" (5-20 pips)
   double mr_rsi_ob_level;      // Nível RSI oversold/overbought (ex: 30/70)
   
   // Setup E - Squeeze Breakout
   double squeeze_min_duration_hours; // Mínimo de horas em squeeze (ex: 4.0)
   double squeeze_breakout_buffer;    // Buffer confirmação breakout (pips)
   
   // Setup F - Order Flow Continuation
   int    continuation_candle_confirm; // Velas de confirmação após delta divergence (1-3)
   double continuation_delta_threshold; // Delta threshold para divergence (ex: 10000 contratos)
};

// ============================================================================
// CLASS: CSetupManager
// ============================================================================
class CSetupManager
{
private:
   // Config
   bool m_enable[6];
   string m_symbol;
   ENUM_TIMEFRAMES m_tf;
   int m_time_offset_hours;   // UTC offset for session classification
   
   // 🔥 CORREÇÃO #45: Array de configurações por setup (A-F)
   SSetupConfig m_setup_configs[6];

   // Parameters (Setup A - Liquidity Raid)
   int    m_liq_lookback;     // bars for swing scan
   double m_liq_sweep_pips;   // min sweep beyond swing
   double m_liq_sl_buffer_pips;
   double m_liq_tp_rr;        // RR target if VP not available
   double m_liq_di_margin;    // 🔥 CORREÇÃO #34: Margem DI para Setup A (padrão 1.5)

   int    m_swing_left;       // swing definition left/right bars
   int    m_swing_right;

   double m_near_varea_pips;  // tolerance to VAH/VAL for MR

   double m_session_min_atr_pct;
   double m_session_ci_max;

   // Cached symbol properties
   double m_point;
   int    m_digits;
   
   // 🔥 CORREÇÃO #29: Parâmetros de confirmação de candle
   int m_candle_confirmation;
   bool m_debug_logs;
   
   // 🔥 CORREÇÃO #37: Debounce de logs (reduzir 836k linhas para ~5k)
   datetime m_last_setup_log_time;
   ENUM_SETUP_TYPE m_last_setup_logged;
   
   // 🔥 CORREÇÃO #29: Funções helper de confirmação de candle (privadas)
   bool HasCandleConfirmation_Short(double level, int required)
   {
      if(required <= 0) return true;  // Filtro desabilitado
      
      // 🔥 CORREÇÃO #39: BUG CRITICAL - Lógica estava verificando barras FUTURAS!
      // PROBLEMA: bars_to_check = required + 1, loop até i=2 quando required=1
      //           Verificava Bar[1] e Bar[2], mas Bar[2] é PASSADO (não confirmação NOVA!)
      // SOLUÇÃO: Verificar APENAS as últimas N barras FECHADAS (a partir de Bar[1])
      //           Se required=1 → verifica se Bar[1] fechou abaixo do nível
      //           Se required=2 → verifica se Bar[1] E Bar[2] fecharam abaixo
      
      int confirmed = 0;
      
      for(int i = 1; i <= required; i++) {  // ✅ Loop de 1 até required (não required+1!)
         double close_i = iClose(m_symbol, m_tf, i);
         if(close_i <= level) {
            confirmed++;
         } else {
            break;  // ✅ Se alguma barra NÃO confirma, aborta (requer confirmação consecutiva)
         }
      }
      
      bool result = (confirmed >= required);
      
      // � CORREÇÃO #43: Sem logs (função chamada milhares de vezes/dia)
      
      return result;
   }
   
   bool HasCandleConfirmation_Long(double level, int required)
   {
      if(required <= 0) return true;  // Filtro desabilitado
      
      // 🔥 CORREÇÃO #39: BUG CRITICAL - Lógica estava verificando barras FUTURAS!
      // PROBLEMA: bars_to_check = required + 1, loop até i=2 quando required=1
      //           Verificava Bar[1] e Bar[2], mas Bar[2] é PASSADO (não confirmação NOVA!)
      // SOLUÇÃO: Verificar APENAS as últimas N barras FECHADAS (a partir de Bar[1])
      //           Se required=1 → verifica se Bar[1] fechou acima do nível
      //           Se required=2 → verifica se Bar[1] E Bar[2] fecharam acima
      
      int confirmed = 0;
      
      for(int i = 1; i <= required; i++) {  // ✅ Loop de 1 até required (não required+1!)
         double close_i = iClose(m_symbol, m_tf, i);
         if(close_i >= level) {
            confirmed++;
         } else {
            break;  // ✅ Se alguma barra NÃO confirma, aborta (requer confirmação consecutiva)
         }
      }
      
      bool result = (confirmed >= required);
      
      // � CORREÇÃO #43: Sem logs (função chamada milhares de vezes/dia)
      
      return result;
   }

public:
   CSetupManager(
      const bool enableA = true,
      const bool enableB = true,
      const bool enableC = true,
      const bool enableD = true,
      const bool enableE = true,
      const bool enableF = true,
      const string symbol = "",
      const ENUM_TIMEFRAMES tf = PERIOD_CURRENT,
      const int tz_offset_hours = 2,
      const int candle_conf = 1,      // 🔥 CORREÇÃO #29
      const bool debug = true         // 🔥 CORREÇÃO #29
   )
   {
      m_enable[0]=enableA; m_enable[1]=enableB; m_enable[2]=enableC; m_enable[3]=enableD; m_enable[4]=enableE; m_enable[5]=enableF;
      m_symbol = (symbol=="" ? _Symbol : symbol);
      m_tf = tf;
      m_time_offset_hours = tz_offset_hours;
      m_candle_confirmation = candle_conf;  // 🔥 CORREÇÃO #29
      m_debug_logs = debug;                 // 🔥 CORREÇÃO #29
      
      // 🔥 CORREÇÃO #37: Inicializar debounce
      m_last_setup_log_time = 0;
      m_last_setup_logged = SETUP_UNDEFINED;

      // Defaults tuned for indices/metals; adjust per-asset later in EA inputs
      m_liq_lookback = 30;
      m_liq_sweep_pips = 5.0;
      m_liq_sl_buffer_pips = 8.0;
      m_liq_tp_rr = 1.5;
      m_liq_di_margin = 1.0;  // 🔥 CORREÇÃO #44.3: 1.5→1.0 (SHORT 0% win = DI muito restritivo!)
      m_swing_left = 2;
      m_swing_right = 2;
      m_near_varea_pips = 10.0;
      m_session_min_atr_pct = 0.05;  // 🔥 CORREÇÃO #42: 0.08% → 0.05% (5 basis points) - Mercado real USDJPY = 0.06%
      m_session_ci_max = 65.0;      // 🔥 CORREÇÃO #42: 50.0 → 65.0 - Mercado real CI = 62.84 (semi-ranging OK!)

      SymbolInfoDouble(m_symbol, SYMBOL_POINT, m_point);
      m_digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      if(m_point<=0.0){ m_point = _Point; }
      
      // 🔥 CORREÇÃO #45: Inicializar configs padrão por setup
      InitializeDefaultConfigs();
   }

   ~CSetupManager() {}
   
   // 🔥 CORREÇÃO #45: Inicializar configurações padrão (override via SetSetupConfig)
   void InitializeDefaultConfigs() {
      // Setup A - Liquidity Raid (conservador, BE early, trailing tight)
      // Exit Management
      m_setup_configs[0].be_enabled = true;
      m_setup_configs[0].be_activation_r = 0.5;     // BE em +0.5R
      m_setup_configs[0].be_offset_pips = 5.0;
      m_setup_configs[0].be_use_sl_fraction = true;
      m_setup_configs[0].be_offset_fraction = 0.30;  // 30% do SL
      m_setup_configs[0].ts_enabled = true;
      m_setup_configs[0].ts_activation_r = 0.8;      // Trailing em +0.8R
      m_setup_configs[0].ts_use_atr = true;
      m_setup_configs[0].ts_distance_atr = 1.0;      // 1.0x ATR
      m_setup_configs[0].ts_step_fraction = 0.15;
      m_setup_configs[0].sl_atr_multiplier = 1.5;    // SL 1.5x ATR
      m_setup_configs[0].tp_rr_ratio = 5.0;          // TP 1:5
      m_setup_configs[0].tp_use_levels = true;       // Priority POC/VAL
      // 🔥 CORREÇÃO #46: Detection Parameters
      m_setup_configs[0].liq_lookback_bars = 20;     // 🔥 CORREÇÃO #47: 50→20 (M15=5h, swings recentes)
      m_setup_configs[0].liq_sweep_pips = 2.0;       // 5.0→2.0 (CRÍTICO! Mais sensível)
      m_setup_configs[0].liq_sl_buffer_pips = 8.0;
      m_setup_configs[0].liq_di_margin = 0.0;        // 🔥 CORREÇÃO #48: 1.0→0.0 (DI só precisa dominar)
      
      // Setup B - AMD Breakout (moderado, BE 1.0R, trailing largo)
      // Exit Management
      m_setup_configs[1].be_enabled = true;
      m_setup_configs[1].be_activation_r = 1.0;      // BE em +1.0R
      m_setup_configs[1].be_offset_pips = 8.0;
      m_setup_configs[1].be_use_sl_fraction = true;
      m_setup_configs[1].be_offset_fraction = 0.40;
      m_setup_configs[1].ts_enabled = true;
      m_setup_configs[1].ts_activation_r = 1.5;      // Trailing em +1.5R
      m_setup_configs[1].ts_use_atr = true;
      m_setup_configs[1].ts_distance_atr = 1.2;      // 1.2x ATR (largo)
      m_setup_configs[1].ts_step_fraction = 0.20;
      m_setup_configs[1].sl_atr_multiplier = 1.0;    // SL 1.0x ATR
      m_setup_configs[1].tp_rr_ratio = 3.0;          // TP 1:3
      m_setup_configs[1].tp_use_levels = false;
      // 🔥 CORREÇÃO #46: Detection Parameters
      m_setup_configs[1].amd_volume_multiplier = 1.5;  // Volume 1.5x média
      m_setup_configs[1].amd_breakout_buffer = 5.0;    // Buffer 5 pips
      
      // Setup C - Session Momentum (agressivo, BE late, trailing largo)
      // Exit Management
      m_setup_configs[2].be_enabled = true;
      m_setup_configs[2].be_activation_r = 1.0;      // BE em +1.0R
      m_setup_configs[2].be_offset_pips = 10.0;
      m_setup_configs[2].be_use_sl_fraction = true;
      m_setup_configs[2].be_offset_fraction = 0.50;  // 50% do SL (permissivo)
      m_setup_configs[2].ts_enabled = true;
      m_setup_configs[2].ts_activation_r = 1.2;      // Trailing em +1.2R
      m_setup_configs[2].ts_use_atr = true;
      m_setup_configs[2].ts_distance_atr = 1.5;      // 1.5x ATR (muito largo!)
      m_setup_configs[2].ts_step_fraction = 0.25;
      m_setup_configs[2].sl_atr_multiplier = 1.0;    // SL 1.0x ATR
      m_setup_configs[2].tp_rr_ratio = 2.5;          // TP 1:2.5
      m_setup_configs[2].tp_use_levels = false;
      // 🔥 CORREÇÃO #46: Detection Parameters
      m_setup_configs[2].session_min_atr_pct = 0.05;   // ATR% mínimo 0.05% (5 basis points)
      m_setup_configs[2].session_ci_max = 65.0;        // CI máximo 65 (permite semi-ranging)
      
      // Setup D - Mean Reversion (muito conservador, BE 0.3R, sem trailing)
      // Exit Management
      m_setup_configs[3].be_enabled = true;
      m_setup_configs[3].be_activation_r = 0.3;      // BE em +0.3R (muito early!)
      m_setup_configs[3].be_offset_pips = 3.0;
      m_setup_configs[3].be_use_sl_fraction = true;
      m_setup_configs[3].be_offset_fraction = 0.20;  // 20% do SL
      m_setup_configs[3].ts_enabled = false;         // SEM trailing (mean reversion = TP fixo)
      m_setup_configs[3].ts_activation_r = 0.0;
      m_setup_configs[3].ts_use_atr = false;
      m_setup_configs[3].ts_distance_atr = 0.0;
      m_setup_configs[3].ts_step_fraction = 0.0;
      m_setup_configs[3].sl_atr_multiplier = 1.2;    // SL 1.2x ATR
      m_setup_configs[3].tp_rr_ratio = 1.5;          // TP 1:1.5 (POC target)
      m_setup_configs[3].tp_use_levels = true;       // Priority POC
      // 🔥 CORREÇÃO #46: Detection Parameters
      m_setup_configs[3].mr_near_varea_pips = 10.0;    // Max 10 pips do VAL/VAH
      m_setup_configs[3].mr_rsi_ob_level = 30.0;       // RSI < 30 (oversold) ou > 70 (overbought)
      
      // Setup E - Squeeze Breakout (moderado, BE 0.8R, trailing médio)
      // Exit Management
      m_setup_configs[4].be_enabled = true;
      m_setup_configs[4].be_activation_r = 0.8;      // BE em +0.8R
      m_setup_configs[4].be_offset_pips = 7.0;
      m_setup_configs[4].be_use_sl_fraction = true;
      m_setup_configs[4].be_offset_fraction = 0.35;
      m_setup_configs[4].ts_enabled = true;
      m_setup_configs[4].ts_activation_r = 1.2;      // Trailing em +1.2R
      m_setup_configs[4].ts_use_atr = true;
      m_setup_configs[4].ts_distance_atr = 1.0;      // 1.0x ATR
      m_setup_configs[4].ts_step_fraction = 0.18;
      m_setup_configs[4].sl_atr_multiplier = 1.2;    // SL 1.2x ATR
      m_setup_configs[4].tp_rr_ratio = 4.0;          // TP 1:4
      m_setup_configs[4].tp_use_levels = false;
      // 🔥 CORREÇÃO #46: Detection Parameters
      m_setup_configs[4].squeeze_min_duration_hours = 4.0;   // Mínimo 4 horas em squeeze
      m_setup_configs[4].squeeze_breakout_buffer = 5.0;      // Buffer 5 pips além da banda
      
      // Setup F - Continuation (agressivo, BE 0.6R, trailing TIGHT)
      // Exit Management
      m_setup_configs[5].be_enabled = true;
      m_setup_configs[5].be_activation_r = 0.6;      // BE em +0.6R
      m_setup_configs[5].be_offset_pips = 6.0;
      m_setup_configs[5].be_use_sl_fraction = true;
      m_setup_configs[5].be_offset_fraction = 0.30;
      m_setup_configs[5].ts_enabled = true;
      m_setup_configs[5].ts_activation_r = 1.0;      // Trailing em +1.0R
      m_setup_configs[5].ts_use_atr = true;
      m_setup_configs[5].ts_distance_atr = 0.5;      // 0.5x ATR (TIGHT!)
      m_setup_configs[5].ts_step_fraction = 0.12;
      m_setup_configs[5].sl_atr_multiplier = 0.5;    // SL 0.5x ATR (tight)
      m_setup_configs[5].tp_rr_ratio = 3.5;          // TP 1:3.5
      m_setup_configs[5].tp_use_levels = false;
      // 🔥 CORREÇÃO #46: Detection Parameters
      m_setup_configs[5].continuation_candle_confirm = 2;      // 2 velas de confirmação
      m_setup_configs[5].continuation_delta_threshold = 10000; // Delta min 10k contratos
   }
   
   // 🔥 CORREÇÃO #37 REVISADA: Debounce baseado no TIMEFRAME (1 log por barra)
   // M15 = 900s, H1 = 3600s, etc.
   bool ShouldLogSetup(ENUM_SETUP_TYPE setup) {
      datetime now = TimeCurrent();
      int period_seconds = PeriodSeconds(m_tf);  // M15 = 900, H1 = 3600, etc.
      
      // Logar apenas se: setup mudou OU passou 1 barra completa
      if(setup != m_last_setup_logged || (now - m_last_setup_log_time) >= period_seconds) {
         m_last_setup_log_time = now;
         m_last_setup_logged = setup;
         return true;
      }
      return false;
   }

   // 🔥 CORREÇÃO #45: GET/SET config por setup
   SSetupConfig GetSetupConfig(ENUM_SETUP_TYPE setup) const {
      int idx = (int)setup;
      if(idx < 0 || idx >= 6) {
         SSetupConfig empty;
         return empty;
      }
      return m_setup_configs[idx];
   }
   
   void SetSetupConfig(ENUM_SETUP_TYPE setup, const SSetupConfig &config) {
      int idx = (int)setup;
      if(idx >= 0 && idx < 6) {
         m_setup_configs[idx] = config;
      }
   }
   
   // Main evaluation: fills out result with up to 6 signals
   bool Evaluate(const SRegimeSignals &sig, const ENUM_MARKET_REGIME regime, SSetupResult &out)
   {
      out.count = 0;

      if(m_enable[0]) TrySetup_LiquidityRaid(sig, regime, out);
      if(m_enable[1]) TrySetup_AMDBreakout(sig, regime, out);
      if(m_enable[2]) TrySetup_SessionMomentum(sig, regime, out);
      if(m_enable[3]) TrySetup_MeanReversion(sig, regime, out);
      if(m_enable[4]) TrySetup_SqueezeBreakout(sig, regime, out);
      
      if(m_enable[5]) TrySetup_Continuation(sig, regime, out);

      return (out.count>0);
   }

private:
   // ========================= Helpers =========================
   // 🔥 CORREÇÃO: Usar _Point DIRETO (evita bug de m_point incorreto)
   double PipsToPrice(const double pips) const { return pips * _Point; }
   double NormalizeP(const double price) const { return NormalizeDouble(price, m_digits); }

   bool IsNear(const double price, const double level, const double tol_pips) const
   {
      if(!MathIsValidNumber(price) || !MathIsValidNumber(level)) return false;
      return (MathAbs(price - level) <= PipsToPrice(tol_pips));
   }

   int BarsAvailable() const { return (int)iBars(m_symbol, m_tf); }

   // 🔥 OTIMIZAÇÃO: Cache HIGH/LOW em arrays (1 chamada vs 90!)
   bool FindSwingHigh(const int lookback, int &out_shift, double &out_price) const
   {
      int bars = BarsAvailable();
      if(bars < lookback+3) {
         // 🔥 CORREÇÃO #43: Sem logs (função chamada milhares de vezes/dia)
         return false;
      }

      // 🚀 CACHE: Copiar todos os HIGHs de uma vez (MUITO mais rápido!)
      double highs[];
      ArrayResize(highs, lookback+2);
      ArraySetAsSeries(highs, true);
      
      int copied = CopyHigh(m_symbol, m_tf, 0, lookback+2, highs);
      if(copied != lookback+2) {
         // � CORREÇÃO #43: Sem logs (função chamada milhares de vezes/dia)
         return false;
      }

      double best= -DBL_MAX; int bestShift = -1;
      for(int shift=1; shift<=lookback; ++shift)
      {
         double h = highs[shift];      // 🚀 Array local (cache)
         double hL = highs[shift+1];   // 🚀 Array local (cache)
         double hR = highs[shift-1];   // 🚀 Array local (cache)
         if(h>best && h>hL && h>hR){ best=h; bestShift=shift; }
      }
      if(bestShift<0) {
         // � CORREÇÃO #43: Sem logs (hot path)
         return false;
      }
      // 🔥 CORREÇÃO #43: Sem logs de sucesso (polui demais)
      out_shift=bestShift; out_price=best; return true;
   }

   bool FindSwingLow(const int lookback, int &out_shift, double &out_price) const
   {
      int bars = BarsAvailable();
      if(bars < lookback+3) {
         // � CORREÇÃO #43: Sem logs (hot path)
         return false;
      }

      // 🚀 CACHE: Copiar todos os LOWs de uma vez (MUITO mais rápido!)
      double lows[];
      ArrayResize(lows, lookback+2);
      ArraySetAsSeries(lows, true);
      
      int copied = CopyLow(m_symbol, m_tf, 0, lookback+2, lows);
      if(copied != lookback+2) {
         // � CORREÇÃO #43: Sem logs (hot path)
         return false;
      }

      double best= DBL_MAX; int bestShift = -1;
      for(int shift=1; shift<=lookback; ++shift)
      {
         double l = lows[shift];      // 🚀 Array local (cache)
         double lL = lows[shift+1];   // 🚀 Array local (cache)
         double lR = lows[shift-1];   // 🚀 Array local (cache)
         if(l<best && l<lL && l<lR){ best=l; bestShift=shift; }
      }
      if(bestShift<0) {
         // � CORREÇÃO #43: Sem logs (hot path)
         return false;
      }
      // 🔥 CORREÇÃO #43: Sem logs de sucesso (polui demais)
      out_shift=bestShift; out_price=best; return true;
   }

   ENUM_SESSION GetSession(const datetime t) const
   {
      // 🔥 CORREÇÃO #41: FOREX 24H - EasyMarkets (UTC+2/+3 Cyprus time)
      // SESSÕES EM HORÁRIO DO BROKER (UTC+2):
      // - ASIAN:    02:00-08:00 (Tokyo 09:00-15:00 JST = UTC+9)
      // - LONDON:   09:00-17:00 (London 08:00-16:00 GMT = UTC+1 winter / UTC+0 summer)
      // - NEWYORK:  15:00-23:00 (NY 08:00-16:00 EST = UTC-5 / EDT = UTC-4)
      // OVERLAP London+NY: 15:00-17:00 (melhor liquidez!)
      // OBSERVAÇÃO: InpTimeZoneOffset deve ser 0 pois já estamos em horário do broker
      
      MqlDateTime dt; TimeToStruct(t, dt);
      int hour = dt.hour + m_time_offset_hours;
      if(hour<0) hour+=24; if(hour>=24) hour-=24;
      
      // Forex 24h: Domingo 22:00 BRT (01:00 UTC+2) - Sexta 18:00 BRT (23:00 UTC+2)
      if(hour>=2 && hour<8) return SESSION_ASIAN;      // 02:00-08:00 broker time
      if(hour>=9 && hour<17) return SESSION_LONDON;    // 09:00-17:00 broker time (overlap 15:00-17:00)
      if(hour>=15 && hour<23) return SESSION_NEWYORK;  // 15:00-23:00 broker time
      return SESSION_LONDON; // default para horários edge (00:00-02:00, 23:00-24:00)
   }

   // ========================= Setups =========================
   void PushSignal(SSetupResult &out, const ENUM_SETUP_TYPE setup, const ENUM_SIGNAL_DIRECTION dir,
                   const double entry, const double sl, const double tp, const double conf, const string reason,
                   const ENUM_ORDER_TYPE_SIGNAL order_type = ORDER_SIGNAL_MARKET) const
   {
      if(out.count>=6) return;
      int idx = out.count++;
      out.signals[idx].setup = setup;
      out.signals[idx].direction = dir;
      out.signals[idx].order_type = order_type;  // 🔥 NOVO
      out.signals[idx].entry_price = NormalizeP(entry);
      out.signals[idx].sl_price = NormalizeP(sl);
      out.signals[idx].tp_price = NormalizeP(tp);
      out.signals[idx].confidence = conf;
      out.signals[idx].reason = reason;
   }

   void TrySetup_LiquidityRaid(const SRegimeSignals &sig, const ENUM_MARKET_REGIME regime, SSetupResult &out)
   {
      // 🔥 CORREÇÃO #46: Usar parâmetros individualizados do config
      SSetupConfig cfg = m_setup_configs[0];  // Setup A index = 0
      
      // Institutional Stop Hunt: sweep prior swing then reverse
      // 🔥 CORREÇÃO #37 REVISADA: Debounce 1 log/barra (M15=900s, H1=3600s)
      // Cache the logging permission so multiple prints in this function don't
      // consume the debounce allowance and hide useful abort diagnostics.
      bool doLog = (m_debug_logs && ShouldLogSetup(SETUP_A_LIQUIDITY_RAID));
      if(doLog) {
         PrintFormat("🔍 [SETUP A] TrySetup_LiquidityRaid CHAMADA | regime=%d, ADX=%.2f, CI=%.2f, lookback=%d, sweep=%.1f pips", 
                     regime, sig.adx, sig.ci, cfg.liq_lookback_bars, cfg.liq_sweep_pips);
      }
      
      int shShift=0, slShift=0; double shPrice=0, slPrice=0;
      if(!FindSwingHigh(cfg.liq_lookback_bars, shShift, shPrice)) {
         if(doLog) PrintFormat("🚫 [SETUP A] ABORTADO: FindSwingHigh falhou");
         return;
      }
      if(!FindSwingLow(cfg.liq_lookback_bars, slShift, slPrice)) {
         if(doLog) PrintFormat("🚫 [SETUP A] ABORTADO: FindSwingLow falhou");
         return;
      }

      double c1 = iClose(m_symbol, m_tf, 1);
      double h1 = iHigh(m_symbol, m_tf, 1);
      double l1 = iLow(m_symbol, m_tf, 1);

      double sweepP = PipsToPrice(cfg.liq_sweep_pips);

      // 🔥🔥🔥 CORREÇÃO #34: RELAXAR CONDIÇÕES DE SETUP A (ROOT CAUSE DE ZERO ORDENS!)
      // PROBLEMA IDENTIFICADO:
      // 1. waeConfirmShort = (WAE↓ > Exp) → WAE↓=0.00 NUNCA passa (> 0.67)
      // 2. di_bearish = (+DI > -DI + 3.0) → Margem 3.0 muito rígida (10.09 vs 24.80)
      // 3. Combinação AND de 4 condições → Taxa de sucesso < 1%
      //
      // ANÁLISE MATEMÁTICA (dados reais do log):
      // - Bearish: WAE↓=0.00 < Exp=0.67 → FALHA SEMPRE ❌
      // - Bullish: +DI=10.09 < -DI+3.0=27.80 → FALHA SEMPRE ❌
      //
      // SOLUÇÃO:
      // 1. REMOVER confirmação WAE (muito restritivo, pouco confiável em low vol)
      // 2. REDUZIR margem DI: 3.0 → 1.5 (mais realista para mercados reais)
      // 3. Manter sweep + close (essência do liquidity raid)
      // 4. Adicionar logs COMPLETOS para diagnóstico
      
      // Bearish raid: pierce swing high then close back below swing
      bool sweptHigh = (h1 > shPrice + sweepP);
      bool closedBelow = (c1 < shPrice);
      // 🔥 CORREÇÃO #44.1: Adicionar confirmação de REJECTION (close abaixo do LOW anterior)
      double l2 = iLow(m_symbol, m_tf, 2);  // LOW de 2 barras atrás
      bool rejection = (c1 < l2);  // Close atual < LOW anterior = rejection confirmada
      bool di_bearish = (sig.minus_di > sig.plus_di + cfg.liq_di_margin);  // 🔥 CORREÇÃO #46: Margem individualizada
      
      // 🔥 CORREÇÃO #47: Log detalhado do DI para debug
      if(doLog && sweptHigh) {
         PrintFormat("🔍 [DEBUG DI] Bearish: -DI=%.2f > +DI=%.2f + margin=%.2f? → %.2f > %.2f = %s", 
                     sig.minus_di, sig.plus_di, cfg.liq_di_margin, sig.minus_di, (sig.plus_di + cfg.liq_di_margin), 
                     di_bearish ? "TRUE ✅" : "FALSE ❌");
      }
      
      // 🔥 CORREÇÃO #37: Log "Bearish check" REMOVIDO (polui log com 836k linhas)
      // MOTIVO: Logado a cada tick mesmo sem sinal gerado
      // ALTERNATIVA: Log no PushSignal mostra quando sinal é criado

      // 🔥 CORREÇÃO #58: SWEPT OPCIONAL + TREND FILTER EXPLÍCITO (v2.29)
      // PROBLEMA v2.26: validChecks >= 2 aceitava SHORT sem swept + sem trend validation (SHORT em uptrend!)
      // PROBLEMA v2.27/v2.28: swept OBRIGATÓRIO rejeitou 98% dos setups (6-8 trades em 14 meses!)
      // REALIDADE: 98.1% das reversões USDJPY M15 NÃO TÊM SWEPT! Swept é EXCEÇÃO, não REGRA!
      // SOLUÇÃO v2.29: VOLTAR swept OPCIONAL (2-de-3) MAS ADICIONAR trend_confirmed EXPLÍCITO
      //                Setup A = "MEAN REVERSION", NÃO "Liquidity Raid"!
      // Aceita: 2-de-3 (swept OR closedBelow OR rejection) + di_bearish + trend_confirmed
      
      int validChecks = (sweptHigh ? 1 : 0) + (closedBelow ? 1 : 0) + (rejection ? 1 : 0);
      bool trend_confirmed = (sig.plus_di < sig.minus_di);  // 🔥 NOVO: +DI < -DI (downtrend confirmado)
      
      // 🔥 CORREÇÃO #59.1: WAE Filter (momentum bearish obrigatório)
      // 🔥 CORREÇÃO #62: WAE threshold PARAMETERIZED - v2.33 (cfg.liq_wae_threshold)
      bool wae_bearish = (sig.wae_trend_down > sig.wae_explosion * cfg.liq_wae_threshold);  // Momentum down > threshold% explosion
      
      // 🔥 CORREÇÃO #59.2: ADX Filter (trend strength mínimo)
      bool adx_strong = (sig.adx > 20.0);  // ADX > 20 = trend confirmado (não ranging)
      
   if(validChecks >= 2 && di_bearish && trend_confirmed && wae_bearish && adx_strong)
      {
         double entry=c1;
         // 🔥 CORREÇÃO #44.2: SL baseado em ATR (não no HIGH arbitrário)
         // 🔥 CORREÇÃO #49.2: Reduzir SL de 1.5x para 1.0x ATR (stop outs 100%→70%)
         double atr = (sig.atr>0 ? sig.atr : PipsToPrice(20));
         double sl = entry + (1.0 * atr);  // SL = Entry + 1.0x ATR (tight: 20-28 pips)
         
         // 🔥 CORREÇÃO #59.3: TP FIXO 2.5R (POC/VAL BUGADO - atualiza 1x/dia causando R:R < 1.0!)
         // PROBLEMA: POC/VAL fixo por 24h → entry=141.54, POC=141.428 → TP=141.428 → R:R=0.21!
         // SOLUÇÃO: SEMPRE usar 2.5R para garantir BE +1.0R e TS +1.5R ativem!
         double tp = entry - (sl-entry)*2.5;  // TP fixo 2.5R (70 pips se SL=28 pips)
         
         double conf = 0.6 + 0.2*(sig.confidence);
         if(regime==REGIME_RANGING) conf+=0.05;
         
         PrintFormat("✅ [SETUP A] SELL REVERSAL: sweptHigh=%d closedBelow=%d rejection=%d validChecks=%d/3 di_bearish=%d trend_confirmed=%d wae_bearish=%d adx_strong=%d | entry=%.5f sl=%.5f tp=%.5f R:R=%.2f | ADX=%.2f WAE_down=%.2f WAE_exp=%.2f",
                     sweptHigh, closedBelow, rejection, validChecks, di_bearish, trend_confirmed, wae_bearish, adx_strong, entry, sl, tp, (tp!=entry ? MathAbs(entry-tp)/MathAbs(sl-entry) : 0), sig.adx, sig.wae_trend_down, sig.wae_explosion);
         
         PushSignal(out, SETUP_A_LIQUIDITY_RAID, DIR_SHORT, entry, sl, tp, MathMin(conf,0.95), "Bearish mean reversion (2/3 + trend + WAE + ADX)");
      }
      else if((sweptHigh || closedBelow || rejection) && doLog) {
         PrintFormat("🚫 [SETUP A] Bearish ABORTADO: sweptHigh=%d closedBelow=%d rejection=%d validChecks=%d/3 di_bearish=%d trend_confirmed=%d wae_bearish=%d adx_strong=%d | +DI=%.2f -DI=%.2f margin=%.2f ADX=%.2f WAE_down=%.2f WAE_exp=%.2f",
                     sweptHigh, closedBelow, rejection, validChecks, di_bearish, trend_confirmed, wae_bearish, adx_strong, sig.plus_di, sig.minus_di, cfg.liq_di_margin, sig.adx, sig.wae_trend_down, sig.wae_explosion);
      }

      // Bullish raid: pierce swing low then close back above swing
      bool sweptLow = (l1 < slPrice - sweepP);
      bool closedAbove = (c1 > slPrice);
      // 🔥 CORREÇÃO #44.4: Adicionar confirmação de REJECTION (close acima do HIGH anterior)
      double h2 = iHigh(m_symbol, m_tf, 2);  // HIGH de 2 barras atrás
      bool rejection_long = (c1 > h2);  // Close atual > HIGH anterior = rejection confirmada
      bool di_bullish = (sig.plus_di > sig.minus_di + cfg.liq_di_margin);  // 🔥 CORREÇÃO #46: Margem individualizada
      
      // 🔥 CORREÇÃO #47: Log detalhado do DI para debug
      if(doLog && sweptLow) {
         PrintFormat("🔍 [DEBUG DI] Bullish: +DI=%.2f > -DI=%.2f + margin=%.2f? → %.2f > %.2f = %s", 
                     sig.plus_di, sig.minus_di, cfg.liq_di_margin, sig.plus_di, (sig.minus_di + cfg.liq_di_margin), 
                     di_bullish ? "TRUE ✅" : "FALSE ❌");
      }
      
      // 🔥 CORREÇÃO #37: Log "Bullish check" REMOVIDO (polui log com 836k linhas)
      // MOTIVO: Logado a cada tick mesmo sem sinal gerado
      // ALTERNATIVA: Log no PushSignal mostra quando sinal é criado

      // 🔥 CORREÇÃO #58: SWEPT OPCIONAL + TREND FILTER EXPLÍCITO (v2.29)
      // PROBLEMA v2.26: validChecks >= 2 aceitava LONG sem swept + sem trend validation (LONG em downtrend!)
      // PROBLEMA v2.27/v2.28: swept OBRIGATÓRIO rejeitou 98% dos setups (6-8 trades em 14 meses!)
      // REALIDADE: 98.1% das reversões USDJPY M15 NÃO TÊM SWEPT! Swept é EXCEÇÃO, não REGRA!
      // SOLUÇÃO v2.29: VOLTAR swept OPCIONAL (2-de-3) MAS ADICIONAR trend_confirmed EXPLÍCITO
      //                Setup A = "MEAN REVERSION", NÃO "Liquidity Raid"!
      // Aceita: 2-de-3 (swept OR closedAbove OR rejection_long) + di_bullish + trend_confirmed
      
      int validChecks_long = (sweptLow ? 1 : 0) + (closedAbove ? 1 : 0) + (rejection_long ? 1 : 0);
      bool trend_confirmed_long = (sig.minus_di < sig.plus_di);  // 🔥 NOVO: -DI < +DI (uptrend confirmado)
      
      // 🔥 CORREÇÃO #59.1: WAE Filter (momentum bullish obrigatório)
      // 🔥 CORREÇÃO #62: WAE threshold PARAMETERIZED - v2.33 (cfg.liq_wae_threshold)
      bool wae_bullish = (sig.wae_trend_up > sig.wae_explosion * cfg.liq_wae_threshold);  // Momentum up > threshold% explosion
      
      // 🔥 CORREÇÃO #59.2: ADX Filter (trend strength mínimo)
      bool adx_strong_long = (sig.adx > 20.0);  // ADX > 20 = trend confirmado (não ranging)
      
      // 🔥 CORREÇÃO #47.1: LONG 0% WR v2.36 - SCORING SYSTEM (não ALL-OR-NOTHING!)
      // PROBLEMA v2.37 INICIAL: 8 filtros obrigatórios bloquearam 100% das ordens!
      // SOLUÇÃO v2.37.1: Sistema de pontuação - precisa MAIORIA dos filtros, não TODOS
      
      // FILTRO 1: ADX FORTE (> 25) = +2 pontos (peso maior)
      int score_long = 0;
      bool adx_very_strong = (sig.adx > 25.0);
      if(adx_very_strong) score_long += 2;
      
      // FILTRO 2: +DI DOMINANTE (> -DI + 5.0) = +2 pontos (peso maior)
      bool di_very_bullish = (sig.plus_di > sig.minus_di + 5.0);
      if(di_very_bullish) score_long += 2;
      
      // FILTRO 3: PREÇO ACIMA EMA200 H1 = +1 ponto
      double ema200_h1 = iMA(m_symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
      double close_h1 = iClose(m_symbol, PERIOD_H1, 0);
      bool above_ema200 = (close_h1 > ema200_h1);
      if(above_ema200) score_long += 1;
      
      // FILTRO 4: SWEPT LOW = +1 ponto (OPCIONAL, não obrigatório!)
      // MOTIVO: 98% das reversões NÃO TÊM swept (dado histórico)
      bool swept_low_bonus = sweptLow;
      if(swept_low_bonus) score_long += 1;
      
      // SCORE MÍNIMO: 3/6 pontos (50% + 1)
      // Exemplo aprovado: ADX forte (2) + DI dominante (2) = 4 pontos ✅
      // Exemplo aprovado: ADX forte (2) + EMA200 (1) + swept (1) = 4 pontos ✅
      // Exemplo rejeitado: Apenas EMA200 (1) + swept (1) = 2 pontos ❌
      bool long_quality_filter = (score_long >= 3);
      
      // LOG DETALHADO: Diagnóstico de rejeição LONG
      if(doLog && (sweptLow || closedAbove || rejection_long)) {
         PrintFormat("🔍 [SETUP A LONG] SCORE=%d/6 (min=3): ADX>25=%d(+2) DI_margin>5=%d(+2) EMA200=%d(+1) swept=%d(+1) | Filtros básicos: validChecks=%d/3 di_bullish=%d trend_confirmed=%d wae_bullish=%d adx_strong=%d",
                     score_long, adx_very_strong, di_very_bullish, above_ema200, swept_low_bonus,
                     validChecks_long, di_bullish, trend_confirmed_long, wae_bullish, adx_strong_long);
      }
      
   // 🔥 CORREÇÃO #48: USAR APENAS SCORING SYSTEM (remove validChecks conflict)
   // PROBLEMA: validChecks >= 2 bloqueava trades com SCORE 5/6 se apenas 1/3 checks OK
   // SOLUÇÃO: Se SCORE >= 3/6, ENTRAR! (ignora validChecks, di_bullish, trend, wae, adx)
   if(score_long >= 3 && long_quality_filter)
      {
         double entry=c1;
         // 🔥 CORREÇÃO #44.5: SL baseado em ATR (consistência com SHORT)
         // 🔥 CORREÇÃO #49.2: Reduzir SL de 1.5x para 1.0x ATR (stop outs 100%→70%)
         double atr = (sig.atr>0 ? sig.atr : PipsToPrice(20));
         double sl = entry - (1.0 * atr);  // SL = Entry - 1.0x ATR (tight: 20-28 pips)
         
         // 🔥 CORREÇÃO #59.3: TP FIXO 2.5R (POC/VAL BUGADO - atualiza 1x/dia causando R:R < 1.0!)
         // PROBLEMA: POC/VAL fixo por 24h → entry=141.54, VAH=141.828 → TP=141.828 → R:R=0.89!
         // SOLUÇÃO: SEMPRE usar 2.5R para garantir BE +1.0R e TS +1.5R ativem!
         double tp = entry + (entry-sl)*2.5;  // TP fixo 2.5R (70 pips se SL=28 pips)
         
         double conf = 0.6 + 0.2*(sig.confidence);
         if(regime==REGIME_RANGING) conf+=0.05;
         
         PrintFormat("✅ [SETUP A] BUY REVERSAL: SCORE=%d/6 (ADX>25=%d DI>5=%d EMA200=%d swept=%d) | sweptLow=%d closedAbove=%d rejection=%d validChecks=%d/3 | entry=%.5f sl=%.5f tp=%.5f R:R=%.2f | ADX=%.2f WAE_up=%.2f",
                     score_long, adx_very_strong, di_very_bullish, above_ema200, swept_low_bonus, sweptLow, closedAbove, rejection_long, validChecks_long, entry, sl, tp, (tp!=entry ? MathAbs(tp-entry)/MathAbs(entry-sl) : 0), sig.adx, sig.wae_trend_up);
         
         PushSignal(out, SETUP_A_LIQUIDITY_RAID, DIR_LONG, entry, sl, tp, MathMin(conf,0.95), "Bullish mean reversion (2/3 + trend + WAE + ADX)");
      }
      else if((sweptLow || closedAbove || rejection_long) && doLog) {
         // 🔥 CORREÇÃO #47.1: Log atualizado com SCORING SYSTEM
         double ema200_h1_log = iMA(m_symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
         double close_h1_log = iClose(m_symbol, PERIOD_H1, 0);
         bool adx_very_strong_log = (sig.adx > 25.0);
         bool di_very_bullish_log = (sig.plus_di > sig.minus_di + 5.0);
         bool above_ema200_log = (close_h1_log > ema200_h1_log);
         int score_log = (adx_very_strong_log ? 2 : 0) + (di_very_bullish_log ? 2 : 0) + (above_ema200_log ? 1 : 0) + (sweptLow ? 1 : 0);
         
         PrintFormat("🚫 [SETUP A] Bullish ABORTADO: SCORE=%d/6 (min=3) | sweptLow=%d closedAbove=%d rejection=%d validChecks=%d/3 | BÁSICOS: di_bullish=%d trend_confirmed=%d wae_bullish=%d adx_strong=%d | 🔥 SCORE LONG: ADX>25=%d(+2) DI>5=%d(+2) EMA200=%d(+1) swept=%d(+1)",
                     score_log, sweptLow, closedAbove, rejection_long, validChecks_long, di_bullish, trend_confirmed_long, wae_bullish, adx_strong_long,
                     adx_very_strong_log, di_very_bullish_log, above_ema200_log, sweptLow);
      }
   }

   void TrySetup_AMDBreakout(const SRegimeSignals &sig, const ENUM_MARKET_REGIME regime, SSetupResult &out)
   {
      // 🔥 CORREÇÃO #37 REVISADA: Debounce 1 log/barra
      if(m_debug_logs && ShouldLogSetup(SETUP_B_AMD_BREAKOUT)) {
         PrintFormat("🔍 [SETUP B] TrySetup_AMDBreakout CHAMADA | regime=%d, CI=%.2f, ATR%%=%.2f, squeeze_now=%d, BBW%%=%.2f",
                     regime, sig.ci, sig.atr_pct, sig.squeeze_now, sig.bbw_pct);
      }
      
      // 🔥 CORREÇÃO #41: RELAXAR FILTROS AMD (muito restritivo!)
      // ANTES: CI>61.8 (ranging) + ATR%<=1.0 (baixa vol) → RARO demais!
      // DEPOIS: CI>50.0 (semi-ranging OK) + ATR%<=1.5 (vol moderada OK)
      // AMD model heuristic: Accumulation (moderate CI + controlled volatility), Manipulation (wick sweep), Distribution (WAE explosion out of squeeze)
      bool accumulation = (sig.ci > 50.0 && sig.atr_pct <= 1.5);  // 🔥 Relaxado: CI 61.8→50.0, ATR 1.0→1.5
      bool release = (!sig.squeeze_now && sig.bbw_pct <= 15.0);    // 🔥 Relaxado: BBW 10.0→15.0 (bands podem estar mais abertas)
      bool waeLong = (sig.wae_trend_up > sig.wae_explosion * 0.7);  // 🔥 Relaxado: 70% threshold (antes 100%)
      bool waeShort = (sig.wae_trend_down > sig.wae_explosion * 0.7);  // 🔥 Relaxado: 70% threshold (antes 100%)

      if(m_debug_logs) {
         PrintFormat("🔍 [SETUP B] Checks: accumulation=%d (CI>61.8=%.2f, ATR%%<=1.0=%.2f), release=%d (!squeeze=%d, BBW%%<=10=%.2f), waeLong=%d, waeShort=%d",
                     accumulation, sig.ci, sig.atr_pct, release, !sig.squeeze_now, sig.bbw_pct, waeLong, waeShort);
      }

      if(accumulation && release && (waeLong || waeShort))
      {
         double c1 = iClose(m_symbol, m_tf, 1);
         double h1 = iHigh(m_symbol, m_tf, 1);
         double l1 = iLow(m_symbol, m_tf, 1);
         double atr = (sig.atr>0?sig.atr:PipsToPrice(20));

         // 🔥 CORREÇÃO #41: Margem DI realista (3.0 → 2.0)
         bool di_bullish = (sig.plus_di > sig.minus_di + 2.0);  // 🔥 Ajustado: 3.0→2.0
         bool di_bearish = (sig.minus_di > sig.plus_di + 2.0);  // 🔥 Ajustado: 3.0→2.0
         
         if(waeLong && di_bullish)
         {
            double entry = h1; // breakout of bar high
            double sl = l1 - 1.0*atr; // SL 1.0x ATR
            double tp = entry + (entry-sl)*3.0; // TP 3.0x RR (AMD realista)
            double conf = 0.55 + 0.25*(sig.confidence);
            if(regime==REGIME_BREAKOUT) conf += 0.1;
            PushSignal(out, SETUP_B_AMD_BREAKOUT, DIR_LONG, entry, sl, tp, MathMin(conf,0.98), "AMD breakout long: post-accumulation squeeze release with WAE+", ORDER_SIGNAL_PENDING);
         }
         if(waeShort && di_bearish)
         {
            double entry = l1; // breakout of bar low
            double sl = h1 + 1.0*atr; // SL 1.0x ATR
            double tp = entry - (sl-entry)*3.0; // TP 3.0x RR (AMD realista)
            double conf = 0.55 + 0.25*(sig.confidence);
            if(regime==REGIME_BREAKOUT) conf += 0.1;
            PushSignal(out, SETUP_B_AMD_BREAKOUT, DIR_SHORT, entry, sl, tp, MathMin(conf,0.98), "AMD breakout short: post-accumulation squeeze release with WAE-", ORDER_SIGNAL_PENDING);
         }
      }
   }

   void TrySetup_SessionMomentum(const SRegimeSignals &sig, const ENUM_MARKET_REGIME regime, SSetupResult &out)
   {
      // 🔥 CORREÇÃO #37 REVISADA: Debounce 1 log/barra
      if(m_debug_logs && ShouldLogSetup(SETUP_C_SESSION_MOMENTUM)) {
         PrintFormat("🔍 [SETUP C] TrySetup_SessionMomentum CHAMADA | regime=%d, ATR%%=%.2f, CI=%.2f",
                     regime, sig.atr_pct, sig.ci);
      }
      
      datetime t1 = iTime(m_symbol, m_tf, 1);
      ENUM_SESSION ses = GetSession(t1);
      
      // 🔥 CORREÇÃO #41: FOREX 24H - Permitir TODAS as sessões (Asian também tem momentum!)
      // USDJPY especialmente ativo em sessão Asian (Tokyo capital)
      // Removido filtro de sessão - momentum pode ocorrer a qualquer hora
      bool active_session = true;  // 🔥 FOREX 24H: todas sessões válidas

      if(!active_session) {
         if(m_debug_logs && ShouldLogSetup(SETUP_C_SESSION_MOMENTUM)) PrintFormat("🚫 [SETUP C] ABORTADO: Sessão inativa (ses=%d)", ses);
         return;
      }

      bool vol_ok = (sig.atr_pct >= m_session_min_atr_pct);
      bool trend_ok = (sig.ci <= m_session_ci_max);

      // Viés com validação DI forte (margem aumentada 2.0→3.0)
      bool longBias = (sig.wae_trend_up > sig.wae_explosion && sig.plus_di > sig.minus_di + 3.0);
      bool shortBias = (sig.wae_trend_down > sig.wae_explosion && sig.minus_di > sig.plus_di + 3.0);

      if(m_debug_logs) {
         PrintFormat("🔍 [SETUP C] Checks: vol_ok=%d (ATR%%>=%.1f), trend_ok=%d (CI<=%.1f), longBias=%d, shortBias=%d",
                     vol_ok, m_session_min_atr_pct, trend_ok, m_session_ci_max, longBias, shortBias);
      }

      if(vol_ok && trend_ok && (longBias || shortBias))
      {
         double c1 = iClose(m_symbol, m_tf, 1);
         double atr = (sig.atr>0?sig.atr:PipsToPrice(20));
         if(longBias)
         {
            double sl = c1 - 1.0*atr; // SL 1.0x ATR
            double tp = c1 + (c1-sl)*2.5; // TP 2.5x RR (momentum realista)
            double conf = 0.55 + 0.25*(sig.confidence);
            if(regime==REGIME_TRENDING) conf += 0.05;
            PushSignal(out, SETUP_C_SESSION_MOMENTUM, DIR_LONG, c1, sl, tp, MathMin(conf,0.95), "Session momentum long: high vol, low CI, WAE+/DI+");
         }
         if(shortBias)
         {
            double sl = c1 + 1.0*atr; // SL 1.0x ATR
            double tp = c1 - (sl-c1)*2.5; // TP 2.5x RR (momentum realista)
            double conf = 0.55 + 0.25*(sig.confidence);
            if(regime==REGIME_TRENDING) conf += 0.05;
            PushSignal(out, SETUP_C_SESSION_MOMENTUM, DIR_SHORT, c1, sl, tp, MathMin(conf,0.95), "Session momentum short: high vol, low CI, WAE-/DI-");
         }
      }
   }

   void TrySetup_MeanReversion(const SRegimeSignals &sig, const ENUM_MARKET_REGIME regime, SSetupResult &out)
   {
      // 🔥 CORREÇÃO #37 REVISADA: Debounce 1 log/barra
      if(m_debug_logs && ShouldLogSetup(SETUP_D_MEAN_REVERSION)) {
         PrintFormat("🔍 [SETUP D] TrySetup_MeanReversion CHAMADA | regime=%d, ADX=%.2f, CI=%.2f, +DI=%.2f, -DI=%.2f",
                     regime, sig.adx, sig.ci, sig.plus_di, sig.minus_di);
      }
      
      // 🔥🔥🔥 CORREÇÃO #31: ROOT CAUSE - Lógica invertida de CI bloqueava 100% dos casos!
      // PROBLEMA: sig.ci <= 61.8 ABORTAVA quando CI < 61.8 (trending)
      //           Mas código comentário dizia "only when clearly ranging" (CI >= 61.8)
      //           CONTRADIÇÃO: Estava bloqueando exatamente quando DEVERIA operar!
      // EVIDÊNCIA LOG: "CI=35.19 <= 61.8" → ABORTA (ERRADO! 35.19 é TREND, não RANGE!)
      // LÓGICA CORRETA:
      //   - CI < 61.8  → TREND/BREAKOUT → Mean Reversion NÃO funciona (abortar) ✅
      //   - CI >= 61.8 → RANGING        → Mean Reversion FUNCIONA (continuar) ✅
      // SOLUÇÃO: Inverter operador para < (ao invés de <=)
      if(sig.ci < 61.8) {  // 🔥 CORRIGIDO: < ao invés de <= (threshold inclusivo)
         if(m_debug_logs && ShouldLogSetup(SETUP_D_MEAN_REVERSION)) PrintFormat("🚫 [SETUP D] ABORTADO: CI=%.2f < 61.8 (não é ranging)", sig.ci);
         return; // only when clearly ranging (CI >= 61.8)
      }
      
      if(m_debug_logs) {
         PrintFormat("✅ [SETUP D] FILTRO CI PASSOU: %.2f >= 61.8 (ranging confirmado)", sig.ci);
      }

      // 🔥🔥 CORREÇÃO #4: Bloquear MR em QUALQUER tendência (ADX > 20)
      // PROBLEMA: MR operava com ADX 25-30 (ainda tendência fraca) → Perdas contra-tendência
      // SOLUÇÃO: Exigir range puro (ADX < 20) + CI > 61.8
      bool range_only = (sig.adx < 20.0);  // 🔥 ADX < 20 (range confirmado!)
      bool di_dominance = (MathAbs(sig.plus_di - sig.minus_di) > 3.0);  // Margem DI aumentada 2.0→3.0
      
      if(m_debug_logs) {
         PrintFormat("🔍 [SETUP D] FILTROS: range_only=%d (ADX %.2f < 20), di_dominance=%d (|+DI-(-DI)|=%.2f > 3.0)",
                     range_only, sig.adx, di_dominance, MathAbs(sig.plus_di - sig.minus_di));
      }
      
      if(!range_only || di_dominance) {
         if(m_debug_logs && ShouldLogSetup(SETUP_D_MEAN_REVERSION)) PrintFormat("🚫 [SETUP D] ABORTADO: range_only=%d OR di_dominance=%d", range_only, di_dominance);
         return; // 🔥 Bloqueia se ADX >= 20 OU DI domina
      }

      double c1 = iClose(m_symbol, m_tf, 1);

      // Use Value Area if available; otherwise use ATR-based bands
      bool haveVA = (MathIsValidNumber(sig.vah) && MathIsValidNumber(sig.val) && sig.vah>sig.val);

      if(haveVA)
      {
         if(IsNear(c1, sig.vah, m_near_varea_pips))
         {
            double entry=c1; double sl = sig.vah + PipsToPrice(8.0); double tp = (MathIsValidNumber(sig.poc)?sig.poc:(c1 - (sl-c1)*1.2));
            double conf = 0.55 + 0.2*(sig.confidence);
            PushSignal(out, SETUP_D_MEAN_REVERSION, DIR_SHORT, entry, sl, tp, MathMin(conf,0.9), "MR short: price near VAH, CI high");
         }
         else if(IsNear(c1, sig.val, m_near_varea_pips))
         {
            double entry=c1; double sl = sig.val - PipsToPrice(8.0); double tp = (MathIsValidNumber(sig.poc)?sig.poc:(c1 + (c1-sl)*1.2));
            double conf = 0.55 + 0.2*(sig.confidence);
            PushSignal(out, SETUP_D_MEAN_REVERSION, DIR_LONG, entry, sl, tp, MathMin(conf,0.9), "MR long: price near VAL, CI high");
         }
      }
      else
      {
         double atr = (sig.atr>0?sig.atr:PipsToPrice(20));
         // Approximate bands with ATR multiples around a running mean (use close)
         double upper = c1 + 1.5*atr;
         double lower = c1 - 1.5*atr;
         if(iHigh(m_symbol, m_tf, 1) >= upper)
         {
            double entry=c1; double sl = iHigh(m_symbol, m_tf, 1) + PipsToPrice(6.0); double tp = c1 - 1.2*atr;
            PushSignal(out, SETUP_D_MEAN_REVERSION, DIR_SHORT, entry, sl, tp, 0.55, "MR short: ATR upper touch");
         }
         else if(iLow(m_symbol, m_tf, 1) <= lower)
         {
            double entry=c1; double sl = iLow(m_symbol, m_tf, 1) - PipsToPrice(6.0); double tp = c1 + 1.2*atr;
            PushSignal(out, SETUP_D_MEAN_REVERSION, DIR_LONG, entry, sl, tp, 0.55, "MR long: ATR lower touch");
         }
      }
   }

   void TrySetup_SqueezeBreakout(const SRegimeSignals &sig, const ENUM_MARKET_REGIME regime, SSetupResult &out)
   {
      // 🔥 CORREÇÃO #37 REVISADA: Debounce 1 log/barra
      if(m_debug_logs && ShouldLogSetup(SETUP_E_SQUEEZE_BREAKOUT)) {
         PrintFormat("🔍 [SETUP E] TrySetup_SqueezeBreakout CHAMADA | regime=%d, squeeze_prev=%d, squeeze_now=%d, ADX=%.2f, CI=%.2f",
                     regime, sig.squeeze_prev, sig.squeeze_now, sig.adx, sig.ci);
      }
      
      // Require squeeze release (prev squeeze, now not), WAE above threshold, DI dominance, ADX filter, and close beyond previous bar range
      double c1 = iClose(m_symbol, m_tf, 1);
      double h1 = iHigh(m_symbol, m_tf, 1);
      double l1 = iLow(m_symbol, m_tf, 1);
      double atr = (sig.atr>0?sig.atr:PipsToPrice(20));

      bool squeeze_released = (sig.squeeze_prev && !sig.squeeze_now);
      bool adx_ok = (sig.adx >= 25.0); // 🔥 CORREÇÃO #41: ADX 28.0→25.0 (menos restritivo, tendência moderada OK)
      bool ci_ok  = (sig.ci <= 65.0);  // 🔥 CORREÇÃO #42: CI 55.0→65.0 (mercado real=62.84, permite semi-ranging)

      bool di_long = (sig.plus_di > sig.minus_di + 2.0);  // 🔥 CORREÇÃO #41: Margem DI 3.0→2.0 (realista)
      bool di_short= (sig.minus_di > sig.plus_di + 2.0);  // 🔥 CORREÇÃO #41: Margem DI 3.0→2.0 (realista)

   bool longBreak = (squeeze_released && adx_ok && ci_ok && di_long && sig.wae_trend_up > sig.wae_explosion && c1 > h1);
   bool shortBreak = (squeeze_released && adx_ok && ci_ok && di_short && sig.wae_trend_down > sig.wae_explosion && c1 < l1);

      if(m_debug_logs) {
         PrintFormat("🔍 [SETUP E] Checks: squeeze_released=%d, adx_ok=%d (>=28.0), ci_ok=%d (<=50.0), di_long=%d, di_short=%d, longBreak=%d, shortBreak=%d",
                     squeeze_released, adx_ok, ci_ok, di_long, di_short, longBreak, shortBreak);
      }

      if(!(longBreak||shortBreak)) {
         if(m_debug_logs && ShouldLogSetup(SETUP_E_SQUEEZE_BREAKOUT)) PrintFormat("🚫 [SETUP E] ABORTADO: Nenhuma breakout condition satisfeita");
         return;
      }

      if(longBreak)
      {
         double sl = c1 - 1.0*atr; double tp = c1 + (c1-sl)*3.0; // TP 3.0x RR (squeeze realista)
         double conf = 0.6 + 0.25*(sig.confidence); if(regime==REGIME_BREAKOUT) conf+=0.05;
         PushSignal(out, SETUP_E_SQUEEZE_BREAKOUT, DIR_LONG, c1, sl, tp, MathMin(conf,0.98), "Squeeze breakout long (release+ADX+DI+range)", ORDER_SIGNAL_PENDING);
      }
      if(shortBreak)
      {
         double sl = c1 + 1.0*atr; double tp = c1 - (sl-c1)*3.0; // TP 3.0x RR (squeeze realista)
         double conf = 0.6 + 0.25*(sig.confidence); if(regime==REGIME_BREAKOUT) conf+=0.05;
         PushSignal(out, SETUP_E_SQUEEZE_BREAKOUT, DIR_SHORT, c1, sl, tp, MathMin(conf,0.98), "Squeeze breakout short (release+ADX+DI+range)", ORDER_SIGNAL_PENDING);
      }
   }

   void TrySetup_Continuation(const SRegimeSignals &sig, const ENUM_MARKET_REGIME regime, SSetupResult &out)
   {
      // ============================================================================
      // SETUP F: CONTINUATION (BREAKOUT ENTRY) - 100% SIMÉTRICO LONG/SHORT
      // ============================================================================
      
      // 🔥 CORREÇÃO #37 REVISADA: Debounce 1 log/barra
      if(m_debug_logs && ShouldLogSetup(SETUP_F_CONTINUATION)) {
         PrintFormat("🔍 [SETUP F] TrySetup_Continuation CHAMADA | regime=%d, ADX=%.2f, CI=%.2f, +DI=%.2f, -DI=%.2f, WAE_up=%.2f, WAE_down=%.2f, WAE_expl=%.2f",
                     regime, sig.adx, sig.ci, sig.plus_di, sig.minus_di, sig.wae_trend_up, sig.wae_trend_down, sig.wae_explosion);
      }
      
      // 🔥 CORREÇÃO BUG #2: Validar se Setup F está HABILITADO antes de processar
      // ANTES: Setup F sempre gerava sinais (ignorava InpEnableSetupF)
      // DEPOIS: Bloqueia setup se desabilitado pelo usuário
      if(!m_enable[5]) {
         if(m_debug_logs && ShouldLogSetup(SETUP_F_CONTINUATION)) PrintFormat("🔍 [SETUP F] ABORTADO: m_enable[5]=false (Setup F desabilitado)");
         return;  // ✅ Early return se Setup F desabilitado (índice 5 = Setup F)
      }
      
      // 🔥 CORREÇÃO #30: Setup F (CONTINUATION) só funciona em TRENDING/BREAKOUT
      // PROBLEMA: Estava sendo chamado em RANGING (ADX=15.28) e SEMPRE falhava (ADX < 22)
      // SOLUÇÃO: Bloquear Setup F se regime não for TRENDING ou BREAKOUT
      if(regime != REGIME_TRENDING && regime != REGIME_BREAKOUT) {
         if(m_debug_logs && ShouldLogSetup(SETUP_F_CONTINUATION)) {
            PrintFormat("🚫 [SETUP F] ABORTADO: Setup Continuation requer TRENDING ou BREAKOUT (regime atual=%d)", regime);
         }
         return;  // ✅ Early return se regime inadequado
      }
      
      bool trend_regime = (regime==REGIME_TRENDING);
      
      // 🔥🔥 CORREÇÃO #23: Margem DI REALISTA (Root cause: 3.0 muito rígido!)
      // Margem DI: 2.0 pontos (ANTES: 3.0 - impossível em mercado real)
      // Exemplo: +DI=15.56 > -DI=26.62 nunca vai acontecer com margem 3.0!
      bool di_bullish = (sig.plus_di > sig.minus_di + 2.0);  // LONG: +DI domina (margem 2.0)
      bool di_bearish = (sig.minus_di > sig.plus_di + 2.0);  // SHORT: -DI domina (margem 2.0)
      
      // Componentes WAE/ADX/CI - CORREÇÃO #3 + #8 APLICADA!
      // 🔥 CORREÇÃO #8: FILTROS ASSIMÉTRICOS LONG vs SHORT
      // MOTIVO: SHORT piorou -55% após correções #3-5 (-R$ 7.33→-R$ 11.38)
      // SOLUÇÃO: Manter LONG restritivo (ADX 28, CI 50) e REVERTER SHORT (ADX 25, CI 60)
      
      // 🔥 CORREÇÃO #14: FILTROS SIMÉTRICOS (LONG = SHORT)
      // MOTIVO: Correção #8 (assimetria) PIOROU LONG (win rate 29%→19%)
      // SHORT com filtros relaxados = 33.3% win rate ✅
      // LONG com filtros rígidos = 19.0% win rate ❌
      // SOLUÇÃO: Usar MESMOS filtros (simetria) = SHORT config que funciona
      
      // 🔥🔥🔥 CORREÇÃO #23: FILTROS REALISTAS (Root Cause: WAE impossível!)
      // ANTES: WAE exigia 90% explosion (1.08 >= 1.41) → SEMPRE FALHA em volatilidade baixa!
      // ANTES: DI margin 3.0 muito rígido → LONG nunca passa (+DI=15 vs -DI=29)
      // DEPOIS: WAE 50% explosion + DI margin 2.0 (valores REAIS do mercado)
      
      // 🔥 CORREÇÃO #42: CI threshold baseado em mercado real (ADX=55.85, CI=62.84)
      // LONG: Filtros REALISTAS
      bool wae_long = (sig.wae_trend_up >= sig.wae_explosion * 0.5);    // 50% explosion (ANTES: 90%)
      bool adx_long_ok = (sig.adx >= 22.0);   // ADX 22 (ANTES: 25 - muitos sinais 22-24)
      bool ci_long_ok = (sig.ci < 65.0);      // 🔥 CORREÇÃO #42: CI 60→65 (mercado real=62.84)
      
      // SHORT: Filtros REALISTAS (simétricos)
      bool wae_short = (sig.wae_trend_down >= sig.wae_explosion * 0.5); // 50% explosion
      bool adx_short_ok = (sig.adx >= 22.0);  // ADX 22
      bool ci_short_ok = (sig.ci < 65.0);     // 🔥 CORREÇÃO #42: CI 60→65 (simétrico com LONG)
      
      // 🔥 DEBUG FILTROS
      PrintFormat("🔍 [SETUP F] FILTROS LONG: DI_bullish=%d (+DI=%.2f > -DI=%.2f+2.0), WAE=%d (%.2f >= %.2f*0.5), ADX=%d (%.2f >= 22), CI=%d (%.2f < 60)",
                  di_bullish, sig.plus_di, sig.minus_di, wae_long, sig.wae_trend_up, sig.wae_explosion, adx_long_ok, sig.adx, ci_long_ok, sig.ci);
      PrintFormat("🔍 [SETUP F] FILTROS SHORT: DI_bearish=%d (-DI=%.2f > +DI=%.2f+2.0), WAE=%d (%.2f >= %.2f*0.5), ADX=%d (%.2f >= 22), CI=%d (%.2f < 60)",
                  di_bearish, sig.minus_di, sig.plus_di, wae_short, sig.wae_trend_down, sig.wae_explosion, adx_short_ok, sig.adx, ci_short_ok, sig.ci);
      
      // 🔥🔥🔥 CORREÇÃO #25: Sistema de PRIORIDADE + Veto Cruzado
      // ROOT CAUSE: Log mostra WAE_up=2.28 (BULLISH!) mas SHORT executado (+DI=10, -DI=24)
      // PROBLEMA: OR logic permite AMBOS passarem (longCont=1, shortCont=1 simultâneo!)
      // EXEMPLO REAL: WAE bullish + DI bearish → EA abre SHORT (ERRADO!)
      // SOLUÇÃO: WAE tem prioridade (momentum REAL vs DI histórico defasado)
      //          Se WAE mostrar direção, VETAR direção oposta!
      
      // STEP 1: Detectar força WAE (momentum claro vs noise)
      double wae_threshold = sig.wae_explosion * 0.5;
      bool wae_bullish_strong = (sig.wae_trend_up >= wae_threshold);   // WAE+ forte
      bool wae_bearish_strong = (sig.wae_trend_down >= wae_threshold); // WAE- forte
      bool wae_neutral = (!wae_bullish_strong && !wae_bearish_strong); // WAE neutro (noise)
      
      // STEP 2: Filtros base (ADX + CI)
      bool adx_ok = (sig.adx >= 22.0);
      bool ci_ok = (sig.ci < 60.0);
      
      // STEP 3: Lógica de PRIORIDADE com Veto Cruzado
      bool longCont = false;
      bool shortCont = false;
      
      if(wae_bullish_strong && !wae_bearish_strong) {
         // WAE BULLISH dominante → LONG permitido, SHORT VETADO
         longCont = (adx_ok && ci_ok);
         shortCont = false;  // 🔥 VETO: Bloqueia SHORT quando WAE bullish!
         PrintFormat("🔍 [SETUP F] WAE BULLISH dominante (%.2f >= %.2f) → VETO SHORT!", sig.wae_trend_up, wae_threshold);
      }
      else if(wae_bearish_strong && !wae_bullish_strong) {
         // WAE BEARISH dominante → SHORT permitido, LONG VETADO
         shortCont = (adx_ok && ci_ok);
         longCont = false;  // 🔥 VETO: Bloqueia LONG quando WAE bearish!
         PrintFormat("🔍 [SETUP F] WAE BEARISH dominante (%.2f >= %.2f) → VETO LONG!", sig.wae_trend_down, wae_threshold);
      }
      else if(wae_neutral) {
         // WAE NEUTRO → Deixar DI decidir (backup indicator)
         longCont = (di_bullish && adx_ok && ci_ok);
         shortCont = (di_bearish && adx_ok && ci_ok);
         PrintFormat("🔍 [SETUP F] WAE NEUTRO → DI decide: LONG=%d (DI_bull=%d), SHORT=%d (DI_bear=%d)", 
                     longCont, di_bullish, shortCont, di_bearish);
      }
      else {
         // WAE AMBOS ativos (raro - conflito) → Bloquear tudo (ambiguidade)
         longCont = false;
         shortCont = false;
         PrintFormat("🔍 [SETUP F] WAE AMBÍGUO (both active) → VETO TOTAL!");
      }

      if(m_debug_logs && ShouldLogSetup(SETUP_F_CONTINUATION)) PrintFormat("🔍 [SETUP F] DECISÃO FINAL: longCont=%d, shortCont=%d", longCont, shortCont);

      if(!(longCont||shortCont)) {
         if(m_debug_logs && ShouldLogSetup(SETUP_F_CONTINUATION)) PrintFormat("🔍 [SETUP F] ABORTADO: Nenhum filtro passou ou veto ativo");
         return;
      }

      // ============================================================================
      // 🔥 CORREÇÃO DEFINITIVA: PENDING ORDER NO HIGH/LOW DE Bar[1] (BARRA FECHADA!)
      // ============================================================================
      // CONCEITO CORRETO (mql5.pdf):
      // - IsNewBar() retorna TRUE quando Bar[0] JÁ É UMA BARRA NOVA
      // - Bar[1] = Barra que ACABOU DE FECHAR (a que queremos usar!)
      // - Bar[0] = Barra nova que está COMEÇANDO agora
      // SOLUÇÃO: PENDING ORDER no HIGH/LOW de Bar[1] (barra recém-fechada)
      
      double h1 = iHigh(m_symbol, m_tf, 1);    // HIGH da barra FECHADA (Bar[1])
      double l1 = iLow(m_symbol, m_tf, 1);     // LOW da barra FECHADA (Bar[1])
      double c1 = iClose(m_symbol, m_tf, 1);   // CLOSE da barra FECHADA (Bar[1])
      double atr = (sig.atr>0 ? sig.atr : PipsToPrice(20));
      
      // 🔥 CORREÇÃO #40: CRITICAL BUG - Confirmation level estava ERRADO!
      // Precisamos do HIGH/LOW da barra ANTERIOR (Bar[2]) para validação de breakout
      double h2 = iHigh(m_symbol, m_tf, 2);    // HIGH Bar[2] (barra ANTERIOR)
      double l2 = iLow(m_symbol, m_tf, 2);     // LOW Bar[2] (barra ANTERIOR)

      // ============================================================================
      // SETUP F LONG: PENDING BUY STOP (100% SIMÉTRICO COM SHORT)
      // ============================================================================
      if(longCont)
      {
         // � CÁLCULO TRANSPARENTE (Step-by-Step):
         // 1. Entry = HIGH Bar[1] + 10 pips (breakout confirmation)
         // 2. SL = LOW Bar[1] - 0.8x ATR (proteção abaixo da estrutura)
         // 3. Risk = Entry - SL (distância em preço)
         // 4. TP = Entry + 4.0x Risk (reward 4:1)
         
         // 🔥 CORREÇÃO #21: Entry inteligente - se JÁ rompeu, entra AGORA!
         double buffer_pips = 10.0 * _Point;  // 10 pips = buffer de confirmação
         double entry_breakout = h1 + buffer_pips;  // Nível de breakout calculado
         double current_ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
         
         // 🔥🔥 CORREÇÃO #29+#40: FILTRO DE CONFIRMAÇÃO DE CANDLE (evita fake breakouts)
         // PROBLEMA #39: Verificava se Close[1] > entry_breakout (HIGH[1]+10pips) → IMPOSSÍVEL!
         // SOLUÇÃO #40: Verifica se Close[1] > HIGH[2] (breakout da barra ANTERIOR)
         // Isso garante que o breakout é REAL (candle fechou ACIMA do high anterior)
         if(!HasCandleConfirmation_Long(h2, m_candle_confirmation)) {
            if(m_debug_logs) {
               PrintFormat("🚫 [SETUP F LONG] AGUARDANDO confirmação: %d candles acima de %.5f (HIGH Bar[2])",
                           m_candle_confirmation, h2);
            }
            return;  // Bloqueia LONG até confirmação
         }
         
         if(m_debug_logs && m_candle_confirmation > 0) {
            PrintFormat("✅ [SETUP F LONG] Confirmação OK: %d+ candles acima de %.5f",
                        m_candle_confirmation, entry_breakout);
         }
         
         // Se preço JÁ está acima do breakout, usar preço ATUAL (entrada imediata)
         // Senão, usar nível de breakout (pending trigger)
         double entry = (current_ask >= entry_breakout) ? current_ask : entry_breakout;
         
         // SL: 1.5x ATR abaixo do LOW (USDJPY: ATR=10 pips → SL=15 pips)
         // 🔥 CORREÇÃO #15: 1.0x → 1.5x ATR (v2.07 SL 8-25 pips muito apertado!)
         // v2.07: Win rate 19% LONG com 1.0x ATR (stops por noise)
         // USDJPY spread+noise = 3-5 pips → SL 8 pips = stop out fácil
         // 1.5x ATR = sweet spot entre proteção e respiro
         double sl = l1 - (1.5 * atr);
         
         // 🔥 DEBUG LOG para monitorar SL real
         double sl_distance_pips = MathAbs(entry - sl) / _Point / 10.0;  // Distance em pips
         PrintFormat("🔍 DEBUG SL LONG: entry=%.5f, l1=%.5f, h1=%.5f, atr=%.5f(pips=%.1f), sl=%.5f, distance=%.1f pips", 
                     entry, l1, h1, atr, atr/_Point/10.0, sl, sl_distance_pips);
         
         // TP: 2.0x RR (se risco = 200 pips, TP = 400 pips) - REALISTA!
         // 🔥 CORREÇÃO #7: Ajustado para 2.0x RR (antes 1.8x) após redução do SL
         // Com SL menor (1.0x ATR), podemos manter RR saudável de 2:1
         double risk = entry - sl;  // LONG: entry > sl (positivo)
         double tp = entry + (2.0 * risk);  // TP 2:1 RR
         
         // Confidence scaling (0.55 base + regime bonus)
         double conf = 0.55 + 0.25*(sig.confidence);
         if(trend_regime) conf += 0.05;
         
         PushSignal(out, SETUP_F_CONTINUATION, DIR_LONG, entry, sl, tp, MathMin(conf,0.97),
                    "LONG Continuation: BUY STOP breakout HIGH+10pips, SL=LOW-1.2ATR, TP=2.5RR (CORRIGIDO)",
                    ORDER_SIGNAL_PENDING);
      }
      
      // ============================================================================
      // SETUP F SHORT: PENDING SELL STOP (ESPELHO MATEMÁTICO DO LONG)
      // ============================================================================
      if(shortCont)
      {
         // � CÁLCULO TRANSPARENTE (Step-by-Step) - IDÊNTICO AO LONG:
         // 1. Entry = LOW Bar[1] - 10 pips (breakdown confirmation)
         // 2. SL = HIGH Bar[1] + 0.8x ATR (proteção acima da estrutura)
         // 3. Risk = SL - Entry (distância em preço)
         // 4. TP = Entry - 4.0x Risk (reward 4:1)
         
         // 🔥 CORREÇÃO #21: Entry inteligente - se JÁ rompeu, entra AGORA!
         double buffer_pips = 10.0 * _Point;  // 10 pips = buffer de confirmação (IGUAL LONG)
         double entry_breakout = l1 - buffer_pips;  // Nível de breakdown calculado
         double current_bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
         
         // 🔥🔥 CORREÇÃO #29+#40: FILTRO DE CONFIRMAÇÃO DE CANDLE (evita fake breakdowns)
         // PROBLEMA #39: Verificava se Close[1] < entry_breakout (LOW[1]-10pips) → IMPOSSÍVEL!
         // SOLUÇÃO #40: Verifica se Close[1] < LOW[2] (breakdown da barra ANTERIOR)
         // Isso garante que o breakdown é REAL (candle fechou ABAIXO do low anterior)
         if(!HasCandleConfirmation_Short(l2, m_candle_confirmation)) {
            if(m_debug_logs) {
               PrintFormat("🚫 [SETUP F SHORT] AGUARDANDO confirmação: %d candles abaixo de %.5f (LOW Bar[2])",
                           m_candle_confirmation, l2);
            }
            return;  // Bloqueia SHORT até confirmação
         }
         
         if(m_debug_logs && m_candle_confirmation > 0) {
            PrintFormat("✅ [SETUP F SHORT] Confirmação OK: %d+ candles abaixo de %.5f",
                        m_candle_confirmation, entry_breakout);
         }
         
         // Se preço JÁ está abaixo do breakdown, usar preço ATUAL (entrada imediata)
         // Senão, usar nível de breakdown (pending trigger)
         double entry = (current_bid <= entry_breakout) ? current_bid : entry_breakout;
         
         // SL: 1.5x ATR acima do HIGH (USDJPY: ATR=10 pips → SL=15 pips)
         // 🔥 CORREÇÃO #15: 1.0x → 1.5x ATR (consistência com LONG)
         // v2.07: Win rate 33.3% SHORT com 1.0x ATR (BOM mas pode melhorar)
         // 1.5x ATR = margem adicional para noise sem comprometer RR
         // Stop mais largo = menos stop outs falsos = win rate maior
         double sl = h1 + (1.5 * atr);
         
         // 🔥 DEBUG LOG para monitorar SL real
         double sl_distance_pips = MathAbs(sl - entry) / _Point / 10.0;  // Distance em pips
         PrintFormat("🔍 DEBUG SL SHORT: entry=%.5f, l1=%.5f, h1=%.5f, atr=%.5f(pips=%.1f), sl=%.5f, distance=%.1f pips", 
                     entry, l1, h1, atr, atr/_Point/10.0, sl, sl_distance_pips);
         
         // TP: 2.0x RR (se risco = 200 pips, TP = 400 pips) - REALISTA!
         // 🔥 CORREÇÃO #7: Ajustado para 2.0x RR (antes 1.8x) após redução do SL
         // Com SL menor (1.0x ATR), podemos manter RR saudável de 2:1
         double risk = sl - entry;  // SHORT: sl > entry (positivo)
         double tp = entry - (2.0 * risk);  // TP 2:1 RR
         
         // Confidence scaling (0.55 base + regime bonus) - IDÊNTICO LONG
         double conf = 0.55 + 0.25*(sig.confidence);
         if(trend_regime) conf += 0.05;
         
         PushSignal(out, SETUP_F_CONTINUATION, DIR_SHORT, entry, sl, tp, MathMin(conf,0.97),
                    "SHORT Continuation: SELL STOP breakdown LOW-10pips, SL=HIGH+1.2ATR, TP=2.5RR (CORRIGIDO)",
                    ORDER_SIGNAL_PENDING);
      }
   }
};

#endif // __AFS_SETUP_MANAGER_MQH__
