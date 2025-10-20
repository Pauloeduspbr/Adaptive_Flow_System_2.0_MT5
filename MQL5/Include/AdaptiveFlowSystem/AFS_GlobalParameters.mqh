//+------------------------------------------------------------------+
//| AFS_GlobalParameters.mqh                                         |
//| Adaptive Flow System v2 - PARÂMETROS GLOBAIS CENTRALIZADOS       |
//|                                                                  |
//| 🔥 CRITICAL: TODOS os parâmetros do EA em um único lugar         |
//| 🔥 ZERO HARDCODE - Tudo parametrizável para backtest/otimização |
//+------------------------------------------------------------------+
#ifndef __AFS_GLOBAL_PARAMETERS_MQH__
#define __AFS_GLOBAL_PARAMETERS_MQH__

// ============================================================================
// ENUMERATIONS (Todos os enums usados no sistema)
// ============================================================================

// Market Regime
enum ENUM_MARKET_REGIME
{
   REGIME_UNDEFINED = 0,
   REGIME_TRENDING,
   REGIME_BREAKOUT,
   REGIME_RANGING
};

// Setup Types
enum ENUM_SETUP_TYPE
{
   SETUP_UNDEFINED = -1,
   SETUP_A_LIQUIDITY_RAID = 0,
   SETUP_B_AMD_BREAKOUT,
   SETUP_C_SESSION_MOMENTUM,
   SETUP_D_MEAN_REVERSION,
   SETUP_E_SQUEEZE_BREAKOUT,
   SETUP_F_CONTINUATION
};

// Signal Direction
enum ENUM_SIGNAL_DIRECTION
{
   DIR_NONE = 0,
   DIR_LONG,
   DIR_SHORT
};

// Order Type Signal
enum ENUM_ORDER_TYPE_SIGNAL
{
   ORDER_SIGNAL_MARKET = 0,   // Entrada imediata
   ORDER_SIGNAL_PENDING       // Entrada antecipada (BUY STOP / SELL STOP)
};

// Trading Sessions
enum ENUM_SESSION
{
   SESSION_ASIAN = 0,    // 02:00-08:00 broker time
   SESSION_LONDON,       // 09:00-17:00 broker time
   SESSION_NEWYORK       // 15:00-23:00 broker time
};

// Asset Type (para ajustes específicos)
enum ENUM_ASSET_TYPE
{
   ASSET_FOREX = 0,      // Forex (EURUSD, USDJPY, etc)
   ASSET_INDICES,        // Índices (NAS100, SPX500, DAX40)
   ASSET_METALS,         // Metais (XAUUSD, XAGUSD)
   ASSET_CRYPTO,         // Cripto (BTCUSD, ETHUSD)
   ASSET_STOCKS_B3       // Ações B3 (PETR4, VALE3)
};

// ============================================================================
// GLOBAL PARAMETERS STRUCTURE
// ============================================================================

struct SGlobalParameters
{
   // ========== GENERAL SETTINGS ==========
   string   symbol;                    // Símbolo negociado
   ENUM_TIMEFRAMES timeframe;          // Timeframe operacional
   int      magic_number;              // Magic number base
   string   trade_comment;             // Comentário das ordens
   ENUM_ASSET_TYPE asset_type;        // Tipo de ativo
   
   // ========== TIME FILTER ==========
   bool     enable_time_filter;        // Ativar filtro de horário
   string   start_time;                // Horário início (formato "HH:MM")
   string   end_time;                  // Horário fim (formato "HH:MM")
   int      timezone_offset;           // Offset timezone (UTC+X)
   
   // Day of Week Filter
   bool     trade_sunday;
   bool     trade_monday;
   bool     trade_tuesday;
   bool     trade_wednesday;
   bool     trade_thursday;
   bool     trade_friday;
   bool     trade_saturday;
   
   // ========== SESSION FILTER ==========
   bool     trade_asian_session;       // Operar sessão asiática
   bool     trade_london_session;      // Operar sessão londrina
   bool     trade_newyork_session;     // Operar sessão nova york
   
   // ========== RISK MANAGEMENT ==========
   double   risk_percent_per_trade;    // Risco por trade (% do capital)
   double   max_daily_risk_percent;    // Risco máx diário (%)
   double   max_weekly_risk_percent;   // Risco máx semanal (%)
   double   max_drawdown_percent;      // Drawdown máximo (%)
   
   int      max_simultaneous_setups;   // Máx setups ativos simultaneamente
   int      max_trades_per_day;        // Máx trades por dia
   int      max_consecutive_losses;    // Máx perdas consecutivas (pause)
   
   double   correlation_threshold;     // Threshold correlação entre ativos
   
   // Position Sizing
   bool     use_fixed_lot;             // Usar lote fixo?
   double   fixed_lot_size;            // Tamanho lote fixo
   double   lot_multiplier;            // Multiplicador de lote (após win/loss)
   double   min_lot;                   // Lote mínimo permitido
   double   max_lot;                   // Lote máximo permitido
   
   // ========== INDICATOR PARAMETERS ==========
   // ADX
   int      adx_period;
   double   adx_trend_threshold;       // ADX > X = trending
   
   // Choppiness Index
   int      ci_period;
   double   ci_ranging_threshold;      // CI > X = ranging
   double   ci_trending_threshold;     // CI < X = trending
   
   // Bollinger Bands
   int      bb_period;
   double   bb_deviation;
   double   bbw_squeeze_threshold;     // BBW% < X = squeeze
   
   // Keltner Channels
   int      kc_period;
   double   kc_multiplier;
   
   // ATR
   int      atr_period;
   double   atr_low_volatility_pct;    // ATR% < X = low vol
   double   atr_high_volatility_pct;   // ATR% > X = high vol
   int      atr_roc_period;
   double   atr_roc_acceleration;      // ROC > X = acceleration
   double   atr_roc_deceleration;      // ROC < -X = deceleration
   
   // Waddah Attar Explosion
   int      wae_fast_ma;
   int      wae_slow_ma;
   int      wae_sensitivity;
   double   wae_explosion_threshold;   // Threshold % da explosion line
   
   // Volume Profile
   bool     use_volume_profile;
   int      vp_session_bars;           // Barras por sessão
   double   vp_near_tolerance_pips;    // Tolerância "perto" de VAH/VAL
   
   // ========== REGIME DETECTION ==========
   double   regime_confidence_min;     // Confidence mínima (0-1)
   int      regime_votes_min;          // Votos mínimos necessários
   
   // Regime Thresholds (para voting system)
   double   regime_adx_trend_threshold;      // ADX > X = trending (ex: 25.0)
   double   regime_ci_trend_threshold;       // CI < X = trending (ex: 38.2)
   double   regime_ci_ranging_threshold;     // CI > X = ranging (ex: 61.8)
   double   regime_bbw_squeeze_threshold;    // BBW% < X = squeeze (ex: 3.0)
   double   regime_atr_pct_low_threshold;    // ATR% < X = low volatility (ex: 0.5)
   double   regime_atr_pct_high_threshold;   // ATR% > X = high volatility (ex: 1.2)
   double   regime_atr_roc_accel_threshold;  // ATR ROC > X = accelerating (ex: 15.0)
   double   regime_atr_roc_decel_threshold;  // ATR ROC < X = decelerating (ex: -15.0)
   double   regime_di_dominance_threshold;   // |+DI - -DI| > X = strong direction (ex: 5.0)
   
   // ========== SETUP ENABLE/DISABLE ==========
   bool     enable_setup_a;
   bool     enable_setup_b;
   bool     enable_setup_c;
   bool     enable_setup_d;
   bool     enable_setup_e;
   bool     enable_setup_f;
   
   // ========== PENDING ORDERS ==========
   int      pending_timeout_bars;      // Timeout em barras
   bool     cancel_pending_on_regime_change; // Cancelar pending se regime mudar
   
   // ========== BREAK-EVEN & TRAILING ==========
   // (Estes serão individualizados por setup, mas valores globais default)
   bool     use_break_even;
   double   be_activation_r_default;   // Default: ativar BE em +XR
   double   be_offset_pips_default;    // Default: offset em pips
   
   bool     use_trailing_stop;
   double   ts_activation_r_default;   // Default: ativar TS em +XR
   double   ts_distance_atr_default;   // Default: distância ATR
   
   // ========== LOGS & DEBUG ==========
   bool     enable_debug_logs;         // Logs detalhados
   bool     debug_log_signals;         // Logs de sinais gerados
   bool     debug_log_execution;       // Logs de execução de ordens
   bool     debug_log_management;      // Logs de gerenciamento (BE/TS)
   bool     enable_setup_logs;         // Logs por setup
   bool     enable_regime_logs;        // Logs de regime
   int      log_level;                 // 0=Errors, 1=Warnings, 2=Info, 3=Debug
};

// ============================================================================
// SETUP-SPECIFIC PARAMETERS (6 setups × 2 direções)
// ============================================================================

// Sub-estrutura para parâmetros LONG
struct SSetupParamsLong
{
   // Break-Even
   bool   be_enabled;
   double be_activation_r;
   double be_offset_pips;
   bool   be_use_sl_fraction;
   double be_offset_fraction;
   
   // Trailing Stop
   bool   ts_enabled;
   double ts_activation_r;
   bool   ts_use_atr;
   double ts_distance_atr;
   double ts_step_fraction;
   
   // SL/TP
   double sl_atr_multiplier;
   double tp_rr_ratio;
   bool   tp_use_levels;          // Usar POC/VAH/VAL como TP
   
   // Detection Filters (Setup-Specific)
   double liq_sweep_pips;         // Setup A: sweep threshold (pips)
   double liq_sl_buffer_pips;     // Setup A: SL buffer (pips)
   double liq_di_margin;          // Setup A: +DI - -DI margin
   double liq_wae_threshold;      // Setup A: WAE threshold (% explosion)
   
   double di_margin;              // Generic: Margem DI necessária
   double wae_threshold;          // Generic: WAE threshold (% explosion)
   double adx_min;                // ADX mínimo
   double adx_max;                // ADX máximo (0 = sem limite)
   double ci_max;                 // CI máximo
   int    candle_confirmation;    // Candles de confirmação
   double scoring_threshold;      // Score mínimo (ex: 3.0/6.0)
};

// Sub-estrutura para parâmetros SHORT
struct SSetupParamsShort
{
   // Break-Even
   bool   be_enabled;
   double be_activation_r;
   double be_offset_pips;
   bool   be_use_sl_fraction;
   double be_offset_fraction;
   
   // Trailing Stop
   bool   ts_enabled;
   double ts_activation_r;
   bool   ts_use_atr;
   double ts_distance_atr;
   double ts_step_fraction;
   
   // SL/TP
   double sl_atr_multiplier;
   double tp_rr_ratio;
   bool   tp_use_levels;
   
   // Detection Filters (Setup-Specific)
   double liq_sweep_pips;         // Setup A: sweep threshold (pips)
   double liq_sl_buffer_pips;     // Setup A: SL buffer (pips)
   double liq_di_margin;          // Setup A: -DI - +DI margin
   double liq_wae_threshold;      // Setup A: WAE threshold (% explosion)
   
   double di_margin;              // Generic: Margem DI necessária
   double wae_threshold;          // Generic: WAE threshold (% explosion)
   double adx_min;                // ADX mínimo
   double adx_max;                // ADX máximo (0 = sem limite)
   double ci_max;                 // CI máximo
   int    candle_confirmation;    // Candles de confirmação
   double scoring_threshold;      // Score mínimo (ex: 3.0/6.0)
};

struct SSetupParameters
{
   // ========== LONG/SHORT PARAMETERS ==========
   SSetupParamsLong long_params;
   SSetupParamsShort short_params;
   
   // ========== SHARED PARAMETERS (não variam LONG/SHORT) ==========
   
   // Setup A - Liquidity Raid
   int    liq_lookback_bars;
   double liq_sweep_pips;
   double liq_sl_buffer_pips;
   
   // Setup B - AMD Breakout
   double amd_volume_multiplier;
   double amd_breakout_buffer_pips;
   
   // Setup C - Session Momentum
   double session_min_atr_pct;
   double session_ci_max;
   double session_di_margin;
   
   // Setup D - Mean Reversion
   double mr_near_varea_pips;
   double mr_rsi_ob_level;
   double mr_rsi_os_level;
   
   // Setup E - Squeeze Breakout
   double squeeze_min_duration_hours;
   double squeeze_breakout_buffer_pips;
   double squeeze_adx_min;
   double squeeze_ci_max;
   
   // Setup F - Continuation
   double continuation_breakout_buffer_pips;
   double continuation_adx_min;
   double continuation_ci_max;
};

// ============================================================================
// GLOBAL SINGLETON INSTANCE
// ============================================================================

// ============================================================================
// GLOBAL PARAMETER INSTANCES
// ============================================================================
// IMPORTANTE: Estas variáveis NÃO são declaradas aqui com 'extern'.
// O EA principal (AdaptiveFlowSystem_v2.mq5) deve declarar:
//    SGlobalParameters g_params;
//    SSetupParameters g_setup_params[6];
// E passar ponteiros (&g_params, g_setup_params) para os managers.
// MQL5 não permite 'extern' com ponteiros para structs.
// ============================================================================

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Converter string "HH:MM" para minutos desde meia-noite
int TimeStringToMinutes(string time_str)
{
   int hour = (int)StringSubstr(time_str, 0, 2);
   int minute = (int)StringSubstr(time_str, 3, 2);
   return hour * 60 + minute;
}

// Verificar se hora atual está no range permitido
bool IsWithinTradingHours(string start_time, string end_time, int tz_offset = 0)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   int current_minutes = (dt.hour + tz_offset) * 60 + dt.min;
   int start_minutes = TimeStringToMinutes(start_time);
   int end_minutes = TimeStringToMinutes(end_time);
   
   // Handle overnight ranges (ex: 22:00 - 02:00)
   if(end_minutes < start_minutes) {
      return (current_minutes >= start_minutes || current_minutes <= end_minutes);
   }
   
   return (current_minutes >= start_minutes && current_minutes <= end_minutes);
}

// Verificar se dia da semana está permitido
bool IsTradingDayAllowed(SGlobalParameters &params)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   switch(dt.day_of_week)
   {
      case 0: return params.trade_sunday;
      case 1: return params.trade_monday;
      case 2: return params.trade_tuesday;
      case 3: return params.trade_wednesday;
      case 4: return params.trade_thursday;
      case 5: return params.trade_friday;
      case 6: return params.trade_saturday;
   }
   
   return false;
}

// Verificar se sessão atual está permitida
bool IsSessionAllowed(SGlobalParameters &params, ENUM_SESSION session)
{
   switch(session)
   {
      case SESSION_ASIAN: return params.trade_asian_session;
      case SESSION_LONDON: return params.trade_london_session;
      case SESSION_NEWYORK: return params.trade_newyork_session;
   }
   return false;
}

// Get current session
ENUM_SESSION GetCurrentSession(int tz_offset = 0)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int hour = dt.hour + tz_offset;
   
   if(hour < 0) hour += 24;
   if(hour >= 24) hour -= 24;
   
   // Broker time (UTC+2 típico para Cyprus)
   if(hour >= 2 && hour < 8) return SESSION_ASIAN;
   if(hour >= 9 && hour < 17) return SESSION_LONDON;
   if(hour >= 15 && hour < 23) return SESSION_NEWYORK;
   
   return SESSION_LONDON; // Default
}

// Validar se pode operar (horário + dia + sessão)
bool CanTrade(SGlobalParameters &params)
{
   // Filtro de dia da semana
   if(!IsTradingDayAllowed(params)) {
      return false;
   }
   
   // Filtro de horário
   if(params.enable_time_filter) {
      if(!IsWithinTradingHours(params.start_time, params.end_time, params.timezone_offset)) {
         return false;
      }
   }
   
   // Filtro de sessão
   ENUM_SESSION current_session = GetCurrentSession(params.timezone_offset);
   if(!IsSessionAllowed(params, current_session)) {
      return false;
   }
   
   return true;
}

// Normalizar lote de acordo com especificações do símbolo
double NormalizeLot(double lot, string symbol)
{
   double lot_min = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double lot_max = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   
   // Clamp
   lot = MathMax(lot_min, lot);
   lot = MathMin(lot_max, lot);
   
   // Round to step
   lot = MathFloor(lot / lot_step) * lot_step;
   
   // Ensure minimum
   if(lot < lot_min) lot = lot_min;
   
   return lot;
}

#endif // __AFS_GLOBAL_PARAMETERS_MQH__
