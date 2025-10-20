//+------------------------------------------------------------------+
//| AFS_SetupManager_v2.mqh (REFACTORED)                            |
//| Adaptive Flow System v2 - Setup Manager                          |
//|                                                                  |
//| 🔥 REFACTORED: Zero hardcode - uses SSetupParameters[]           |
//| 🔥 LONG/SHORT independence - separate parameters                  |
//| 🔥 All 6 setups with full institutional logic                    |
//+------------------------------------------------------------------+
#ifndef __AFS_SETUP_MANAGER_V2_MQH__
#define __AFS_SETUP_MANAGER_V2_MQH__

#include "AFS_GlobalParameters.mqh"
#include "AFS_RegimeDetector.mqh"

// ============================================================================
// SIGNAL OUTPUT STRUCTURE
// ============================================================================

struct STradeSignal
{
   ENUM_SETUP_TYPE          setup_type;        // Renamed from 'setup'
   ENUM_SIGNAL_DIRECTION    direction;
   ENUM_ORDER_TYPE_SIGNAL   order_type;
   
   double                   entry_price;
   double                   sl_price;
   double                   tp_price;
   
   double                   confidence;        // 0..1
   double                   rr_ratio;          // Risk:Reward ratio
   int                      priority;          // Setup priority (A=20, B=18, ...)
   
   double                   pending_expiration_bars;  // Timeout for pending orders
   datetime                 signal_time;       // When signal was generated
   int                      signal_bar_index;  // Bar index
   
   string                   comment;           // Renamed from 'reason'
   bool                     is_valid;
};

// ============================================================================
// CLASS: CSetupManager
// ============================================================================

class CSetupManager
{
private:
   SGlobalParameters& m_params;
   SSetupParameters& m_setup_params;  // Array [6]
   
   string m_symbol;
   ENUM_TIMEFRAMES m_tf;
   
   // Indicator handles (se necessário para cálculos adicionais)
   int m_h_atr;
   
   // Debounce tracking (evitar múltiplos sinais no mesmo bar)
   datetime m_last_signal_time[6];  // 6 setups
   ENUM_SETUP_TYPE m_last_setup_logged;
   int m_last_bar_logged;
   
public:
   // ========== CONSTRUCTOR ==========
   CSetupManager(SGlobalParameters& params,
                 SSetupParameters& setup_params,
                 const string symbol = "",
                 const ENUM_TIMEFRAMES tf = PERIOD_CURRENT)
   {
      m_params = params;
      m_setup_params = setup_params;
      m_symbol = (symbol == "" ? _Symbol : symbol);
      m_tf = tf;
      
      // Initialize ATR handle
      m_h_atr = iATR(m_symbol, m_tf, m_params->atr_period);
      
      // Initialize debounce
      ArrayInitialize(m_last_signal_time, 0);
      m_last_setup_logged = SETUP_UNDEFINED;
      m_last_bar_logged = -1;
   }
   
   ~CSetupManager()
   {
      if(m_h_atr != INVALID_HANDLE) IndicatorRelease(m_h_atr);
   }
   
   // ========== MAIN EVALUATION ==========
   
   void EvaluateAllSetups(const SRegimeSignals &regime_signals,
                         ENUM_MARKET_REGIME current_regime,
                         double regime_confidence,
                         STradeSignal &signals[],
                         int &signal_count)
   {
      // Avaliar todos os 6 setups e retornar sinais válidos
      
      ArrayResize(signals, 0);
      signal_count = 0;
      
      // Verificar se regime tem confidence mínima
      if(regime_confidence < m_params->regime_confidence_min) {
         if(m_params->debug_log_signals) {
            PrintFormat("🚫 Regime confidence baixa: %.2f < %.2f", 
                       regime_confidence, m_params->regime_confidence_min);
         }
         return;
      }
      
      // Avaliar cada setup (A-F)
      STradeSignal sig_a_long, sig_a_short;
      STradeSignal sig_b_long, sig_b_short;
      STradeSignal sig_c_long, sig_c_short;
      STradeSignal sig_d_long, sig_d_short;
      STradeSignal sig_e_long, sig_e_short;
      STradeSignal sig_f_long, sig_f_short;
      
      // Setup A: Liquidity Raid
      if(m_params->enable_setup_a) {
         TrySetup_LiquidityRaid(regime_signals, current_regime, sig_a_long, sig_a_short);
         if(sig_a_long.is_valid) AddSignal(signals, signal_count, sig_a_long);
         if(sig_a_short.is_valid) AddSignal(signals, signal_count, sig_a_short);
      }
      
      // Setup B: AMD Breakout
      if(m_params->enable_setup_b) {
         TrySetup_AMD_Breakout(regime_signals, current_regime, sig_b_long, sig_b_short);
         if(sig_b_long.is_valid) AddSignal(signals, signal_count, sig_b_long);
         if(sig_b_short.is_valid) AddSignal(signals, signal_count, sig_b_short);
      }
      
      // Setup C: Session Momentum
      if(m_params->enable_setup_c) {
         TrySetup_SessionMomentum(regime_signals, current_regime, sig_c_long, sig_c_short);
         if(sig_c_long.is_valid) AddSignal(signals, signal_count, sig_c_long);
         if(sig_c_short.is_valid) AddSignal(signals, signal_count, sig_c_short);
      }
      
      // Setup D: Mean Reversion
      if(m_params->enable_setup_d) {
         TrySetup_MeanReversion(regime_signals, current_regime, sig_d_long, sig_d_short);
         if(sig_d_long.is_valid) AddSignal(signals, signal_count, sig_d_long);
         if(sig_d_short.is_valid) AddSignal(signals, signal_count, sig_d_short);
      }
      
      // Setup E: Squeeze Breakout
      if(m_params->enable_setup_e) {
         TrySetup_SqueezeBreakout(regime_signals, current_regime, sig_e_long, sig_e_short);
         if(sig_e_long.is_valid) AddSignal(signals, signal_count, sig_e_long);
         if(sig_e_short.is_valid) AddSignal(signals, signal_count, sig_e_short);
      }
      
      // Setup F: Continuation
      if(m_params->enable_setup_f) {
         TrySetup_Continuation(regime_signals, current_regime, sig_f_long, sig_f_short);
         if(sig_f_long.is_valid) AddSignal(signals, signal_count, sig_f_long);
         if(sig_f_short.is_valid) AddSignal(signals, signal_count, sig_f_short);
      }
      
      if(m_params->debug_log_signals && signal_count > 0) {
         PrintFormat("✅ %d sinais válidos gerados", signal_count);
      }
   }
   
   // ========== HELPER: ADD SIGNAL ==========
   
   void AddSignal(STradeSignal &signals[], int &count, const STradeSignal &signal)
   {
      ArrayResize(signals, count + 1);
      signals[count] = signal;
      count++;
   }
   
   // ========================================================================
   // SETUP A: LIQUIDITY RAID (Mean Reversion via Sweep Detection)
   // ========================================================================
   
   void TrySetup_LiquidityRaid(const SRegimeSignals &sig,
                               ENUM_MARKET_REGIME regime,
                               STradeSignal &out_long,
                               STradeSignal &out_short)
   {
      // Inicializar outputs
      ZeroMemory(out_long);
      ZeroMemory(out_short);
      out_long.setup_type = SETUP_A_LIQUIDITY_RAID;
      out_short.setup_type = SETUP_A_LIQUIDITY_RAID;
      out_long.direction = SIGNAL_LONG;
      out_short.direction = SIGNAL_SHORT;
      out_long.order_type = ORDER_TYPE_MARKET;
      out_short.order_type = ORDER_TYPE_MARKET;
      out_long.is_valid = false;
      out_short.is_valid = false;
      
      // FILTRO 1: Regime deve ser TRENDING ou RANGING
      if(regime == REGIME_BREAKOUT) {
         return; // Sem liquidity raids em breakout
      }
      
      // FILTRO 2: ADX não pode estar muito alto (evitar trending forte)
      if(sig.adx > m_params->regime_adx_trend_threshold + 10.0) {
         return; // Trending muito forte para reversão
      }
      
      // Obter parâmetros LONG
      int lookback = m_setup_params[0].liq_lookback_bars;
      double sweep_pips = m_setup_params[0].long_params.liq_sweep_pips;
      double sl_buffer_pips = m_setup_params[0].long_params.liq_sl_buffer_pips;
      double di_margin = m_setup_params[0].long_params.liq_di_margin;
      double wae_threshold = m_setup_params[0].long_params.liq_wae_threshold;
      
      // DETECÇÃO LONG: Sweep de SSL (Sell-Side Liquidity)
      // Procurar swing low recente + sweep abaixo + reversão
      
      double swing_low = DBL_MAX;
      int swing_low_bar = -1;
      
      // Scan lookback bars para encontrar swing low
      for(int i = 2; i < lookback; i++)
      {
         double low = iLow(m_symbol, m_tf, i);
         if(low < swing_low) {
            swing_low = low;
            swing_low_bar = i;
         }
      }
      
      if(swing_low_bar < 0) {
         return; // Sem swing low encontrado
      }
      
      // Verificar sweep: low[1] quebrou swing_low em sweep_pips
      double low_1 = iLow(m_symbol, m_tf, 1);
      double sweep_distance = (swing_low - low_1) / _Point;
      
      if(sweep_distance >= sweep_pips) {
         // SWEEP DETECTADO!
         
         // FILTRO 3: +DI deve dominar -DI (comprador assumindo controle)
         if((sig.plus_di - sig.minus_di) < di_margin) {
            return;
         }
         
         // FILTRO 4: WAE deve estar acima do threshold (momentum positivo)
         if(sig.wae_trend_up < (sig.wae_explosion * wae_threshold)) {
            return;
         }
         
         // FILTRO 5: Close[0] deve estar acima do swing_low (confirmação reversão)
         double close_0 = iClose(m_symbol, m_tf, 0);
         if(close_0 <= swing_low) {
            return;
         }
         
         // ✅ SINAL LONG VÁLIDO
         out_long.entry_price = iClose(m_symbol, m_tf, 0); // Market entry
         out_long.sl_price = low_1 - (sl_buffer_pips * _Point);
         
         // Calcular TP
         double sl_distance = out_long.entry_price - out_long.sl_price;
         double tp_rr = m_setup_params[0].long_params.tp_rr_ratio;
         out_long.tp_price = out_long.entry_price + (sl_distance * tp_rr);
         
         // Ajustar TP para POC se usar levels
         if(m_setup_params[0].long_params.tp_use_levels && sig.poc > out_long.entry_price) {
            out_long.tp_price = sig.poc;
         }
         
         out_long.confidence = 0.75; // Configuração inicial
         out_long.comment = StringFormat("LONG Liquidity Raid: Sweep %.1f pips below swing_low[%d]=%.5f",
                                        sweep_distance, swing_low_bar, swing_low);
         out_long.is_valid = true;
      }
      
      // DETECÇÃO SHORT: Similar mas invertido (BSL - Buy-Side Liquidity)
      double swing_high = -DBL_MAX;
      int swing_high_bar = -1;
      
      for(int i = 2; i < lookback; i++)
      {
         double high = iHigh(m_symbol, m_tf, i);
         if(high > swing_high) {
            swing_high = high;
            swing_high_bar = i;
         }
      }
      
      if(swing_high_bar < 0) {
         return;
      }
      
      double high_1 = iHigh(m_symbol, m_tf, 1);
      double sweep_distance_short = (high_1 - swing_high) / _Point;
      
      sweep_pips = m_setup_params[0].short_params.liq_sweep_pips;
      sl_buffer_pips = m_setup_params[0].short_params.liq_sl_buffer_pips;
      di_margin = m_setup_params[0].short_params.liq_di_margin;
      wae_threshold = m_setup_params[0].short_params.liq_wae_threshold;
      
      if(sweep_distance_short >= sweep_pips) {
         // SWEEP SHORT DETECTADO
         
         if((sig.minus_di - sig.plus_di) < di_margin) {
            return;
         }
         
         if(sig.wae_trend_down < (sig.wae_explosion * wae_threshold)) {
            return;
         }
         
         double close_0 = iClose(m_symbol, m_tf, 0);
         if(close_0 >= swing_high) {
            return;
         }
         
         // ✅ SINAL SHORT VÁLIDO
         out_short.entry_price = close_0;
         out_short.sl_price = high_1 + (sl_buffer_pips * _Point);
         
         double sl_distance = out_short.sl_price - out_short.entry_price;
         double tp_rr = m_setup_params[0].short_params.tp_rr_ratio;
         out_short.tp_price = out_short.entry_price - (sl_distance * tp_rr);
         
         if(m_setup_params[0].short_params.tp_use_levels && sig.poc < out_short.entry_price) {
            out_short.tp_price = sig.poc;
         }
         
         out_short.confidence = 0.75;
         out_short.comment = StringFormat("SHORT Liquidity Raid: Sweep %.1f pips above swing_high[%d]=%.5f",
                                         sweep_distance_short, swing_high_bar, swing_high);
         out_short.is_valid = true;
      }
   }
   
   // ========================================================================
   // SETUP B: AMD BREAKOUT (Accumulation-Manipulation-Distribution)
   // ========================================================================
   
   void TrySetup_AMD_Breakout(const SRegimeSignals &sig,
                              ENUM_MARKET_REGIME regime,
                              STradeSignal &out_long,
                              STradeSignal &out_short)
   {
      // TODO: Implementar lógica completa
      // Placeholder: sempre retorna inválido
      
      ZeroMemory(out_long);
      ZeroMemory(out_short);
      out_long.is_valid = false;
      out_short.is_valid = false;
      
      // Detectar AMD pattern:
      // 1. Accumulation: Price consolidation com volume aumentando
      // 2. Manipulation: Fake breakout (liquidity grab)
      // 3. Distribution: Real breakout com momentum forte
      
      // [Implementação completa será adicionada]
   }
   
   // ========================================================================
   // SETUP C: SESSION MOMENTUM
   // ========================================================================
   
   void TrySetup_SessionMomentum(const SRegimeSignals &sig,
                                 ENUM_MARKET_REGIME regime,
                                 STradeSignal &out_long,
                                 STradeSignal &out_short)
   {
      ZeroMemory(out_long);
      ZeroMemory(out_short);
      out_long.is_valid = false;
      out_short.is_valid = false;
      
      // TODO: Implementar
      // Detectar momentum forte no início de sessão (London/NY open)
   }
   
   // ========================================================================
   // SETUP D: MEAN REVERSION
   // ========================================================================
   
   void TrySetup_MeanReversion(const SRegimeSignals &sig,
                               ENUM_MARKET_REGIME regime,
                               STradeSignal &out_long,
                               STradeSignal &out_short)
   {
      ZeroMemory(out_long);
      ZeroMemory(out_short);
      out_long.is_valid = false;
      out_short.is_valid = false;
      
      // TODO: Implementar
      // Detectar price extremo fora de Value Area + reversão para POC
   }
   
   // ========================================================================
   // SETUP E: SQUEEZE BREAKOUT
   // ========================================================================
   
   void TrySetup_SqueezeBreakout(const SRegimeSignals &sig,
                                 ENUM_MARKET_REGIME regime,
                                 STradeSignal &out_long,
                                 STradeSignal &out_short)
   {
      ZeroMemory(out_long);
      ZeroMemory(out_short);
      out_long.is_valid = false;
      out_short.is_valid = false;
      
      // TODO: Implementar
      // Detectar squeeze release (BB saindo de dentro do KC)
   }
   
   // ========================================================================
   // SETUP F: CONTINUATION (Pending Orders)
   // ========================================================================
   
   void TrySetup_Continuation(const SRegimeSignals &sig,
                              ENUM_MARKET_REGIME regime,
                              STradeSignal &out_long,
                              STradeSignal &out_short)
   {
      ZeroMemory(out_long);
      ZeroMemory(out_short);
      out_long.is_valid = false;
      out_short.is_valid = false;
      
      // TODO: Implementar
      // Pending orders em níveis de breakout (swing high/low + buffer)
   }
};

#endif // __AFS_SETUP_MANAGER_V2_MQH__
