//+------------------------------------------------------------------+
//| AFS_RegimeDetector.mqh                                          |
//| Adaptive Flow System v2 - Regime Detector (REFACTORED)           |
//| Class CRegimeDetector: aggregates 8 indicators to classify       |
//| market regime: TRENDING / BREAKOUT / RANGING                     |
//|                                                                  |
//| 🔥 REFACTORED: Zero hardcode - all thresholds from SGlobalParameters |
//|                                                                  |
//| Usage (from EA):                                                 |
//|   CRegimeDetector det(params, hADX, hCI, hSqueeze, hATR, hWAE, hVP); |
//|   SRegimeSignals sig; double conf;                               |
//|   ENUM_MARKET_REGIME reg = det.Detect(sig, conf);                |
//+------------------------------------------------------------------+
#ifndef __AFS_REGIME_DETECTOR_MQH__
#define __AFS_REGIME_DETECTOR_MQH__

#include "AFS_GlobalParameters.mqh"

// ============================================================================
// ENUMS (use from GlobalParameters)
// ============================================================================
// ENUM_MARKET_REGIME already defined in AFS_GlobalParameters.mqh

// ============================================================================
// STRUCTS (signals snapshot)
// ============================================================================
#ifndef __SREGIME_SIGNALS_DEFINED__
#define __SREGIME_SIGNALS_DEFINED__
struct SRegimeSignals
{
   // ADX
   double adx;
   double plus_di;
   double minus_di;

   // Choppiness Index
   double ci;

   // Bollinger Keltner (BBW% and squeeze state)
   double bbw_pct;          // ((BBU-BBL)/BBM)*100
   bool   squeeze_now;      // 1 if BB inside KC (from indicator flag if available)
   bool   squeeze_prev;

   // ATR
   double atr;
   double atr_pct;
   double atr_roc;

   // WAE
   double wae_trend_up;
   double wae_trend_down;
   double wae_explosion;    // absolute explosion threshold

   // Volume Profile
   double poc;
   double vah;
   double val;

   // Price reference
   double price_close;

   // Votes for transparency
   int votes_trend;
   int votes_breakout;
   int votes_range;
   int votes_total;

   // Result
   ENUM_MARKET_REGIME regime;
   double confidence;      // 0..1
   datetime timestamp;
};
#endif

// ============================================================================
// HELPER: Safe CopyBuffer last value
// ============================================================================
class CBufferReader
{
public:
   static bool CopyLatest(const int handle, const int buffer, const int shift, double &out)
   {
      if(handle == INVALID_HANDLE) { out = 0.0; return false; }
      // Use dynamic array to avoid warnings: ArraySetAsSeries cannot be used on static arrays
      double tmp1[];
      if(ArrayResize(tmp1, 1) != 1) { out = 0.0; return false; }
      ArraySetAsSeries(tmp1, true); // Optimize array access
      int copied = CopyBuffer(handle, buffer, shift, 1, tmp1);
      if(copied <= 0) { out = 0.0; return false; }
      out = tmp1[0];
      return MathIsValidNumber(out);
   }

   static bool CopyTwo(const int handle, const int buffer, const int shift, double &curr, double &prev)
   {
      if(handle == INVALID_HANDLE) { curr = 0.0; prev = 0.0; return false; }
      // Use dynamic array to avoid warnings on static arrays
      double tmp2[];
      if(ArrayResize(tmp2, 2) != 2) { curr = 0.0; prev = 0.0; return false; }
      ArraySetAsSeries(tmp2, true); // Optimize array access
      int copied = CopyBuffer(handle, buffer, shift, 2, tmp2);
      if(copied < 2) { curr = 0.0; prev = 0.0; return false; }
      curr = tmp2[0];
      prev = tmp2[1];
      return (MathIsValidNumber(curr) && MathIsValidNumber(prev));
   }
};

// ============================================================================
// CLASS: CRegimeDetector
// ============================================================================
class CRegimeDetector
{
private:
   SGlobalParameters m_params;  // Direct struct copy (MQL5 doesn't support & references as members)
   
   int m_h_adx, m_h_ci, m_h_sq, m_h_atr, m_h_wae, m_h_vp;
   string m_symbol;
   ENUM_TIMEFRAMES m_tf;
   SRegimeSignals m_last;
   
   // Cache regime per bar (performance optimization)
   datetime m_cache_time;
   SRegimeSignals m_cache_signals;
   ENUM_MARKET_REGIME m_cache_regime;
   double m_cache_confidence;
   
public:
   CRegimeDetector(const SGlobalParameters &params,
                   const int h_adx,
                   const int h_ci,
                   const int h_squeeze,
                   const int h_atr,
                   const int h_wae,
                   const int h_vp,
                   const string symbol = "",
                   const ENUM_TIMEFRAMES tf = PERIOD_CURRENT)
   {
      m_params = params;  // Struct copy assignment
      m_h_adx = h_adx; m_h_ci = h_ci; m_h_sq = h_squeeze; m_h_atr = h_atr; m_h_wae = h_wae; m_h_vp = h_vp;
      m_symbol = (symbol == "" ? _Symbol : symbol);
      m_tf = tf;
      ZeroMemory(m_last);
      m_last.regime = REGIME_UNDEFINED; m_last.confidence = 0.0; m_last.timestamp = 0;
      m_cache_time = 0;
      ZeroMemory(m_cache_signals);
      m_cache_regime = REGIME_UNDEFINED;
      m_cache_confidence = 0.0;
   }
   ~CRegimeDetector() {}
   ENUM_MARKET_REGIME Detect(SRegimeSignals &out_signals, double &out_confidence)
   {
      // 🔥 CORREÇÃO #43: Cache por barra evita recálculo (zero logs nessa função)
      // 🔥 OTIMIZAÇÃO: Cache é checado primeiro (evita recálculos desnecessários)
      datetime bar_time = iTime(m_symbol, m_tf, 1);
      
      if(bar_time == m_cache_time && bar_time > 0) {
         // Cache hit - retornar valores já calculados
         out_signals = m_cache_signals;
         out_confidence = m_cache_confidence;
         return m_cache_regime;
      }
      
      // Cache miss - recalcular tudo
      SRegimeSignals s; ZeroMemory(s);
      s.timestamp = TimeCurrent();
      s.price_close = iClose(m_symbol, m_tf, 1);
      
      // 🔥 OTIMIZAÇÃO: Usar arrays de buffer pre-alocados (evita múltiplas alocações)
      double adx_buf[2], plus_di_buf[2], minus_di_buf[2];
      double ci_buf[2];
      double bb_upper[2], bb_middle[2], bb_lower[2], squeeze_buf[2];
      double atr_buf[2], atr_pct_buf[2], atr_roc_buf[2];
      double wae_up[2], wae_dn[2], wae_exp[2];
      double vp_poc[2], vp_vah[2], vp_val[2];
      
      // Copiar todos os buffers de uma vez (batch copy é mais rápido)
      bool copy_ok = true;
      
      copy_ok &= (CopyBuffer(m_h_adx, 0, 1, 2, adx_buf) == 2);
      copy_ok &= (CopyBuffer(m_h_adx, 1, 1, 2, plus_di_buf) == 2);
      copy_ok &= (CopyBuffer(m_h_adx, 2, 1, 2, minus_di_buf) == 2);
      
      copy_ok &= (CopyBuffer(m_h_ci, 0, 1, 2, ci_buf) == 2);
      
      copy_ok &= (CopyBuffer(m_h_sq, 0, 1, 2, bb_upper) == 2);
      copy_ok &= (CopyBuffer(m_h_sq, 1, 1, 2, bb_middle) == 2);
      copy_ok &= (CopyBuffer(m_h_sq, 2, 1, 2, bb_lower) == 2);
      copy_ok &= (CopyBuffer(m_h_sq, 6, 1, 2, squeeze_buf) == 2);
      
      copy_ok &= (CopyBuffer(m_h_atr, 0, 1, 2, atr_buf) == 2);
      copy_ok &= (CopyBuffer(m_h_atr, 1, 1, 2, atr_pct_buf) == 2);
      copy_ok &= (CopyBuffer(m_h_atr, 2, 1, 2, atr_roc_buf) == 2);
      
      copy_ok &= (CopyBuffer(m_h_wae, 0, 1, 2, wae_up) == 2);
      copy_ok &= (CopyBuffer(m_h_wae, 1, 1, 2, wae_dn) == 2);
      copy_ok &= (CopyBuffer(m_h_wae, 2, 1, 2, wae_exp) == 2);
      
      if(m_h_vp != INVALID_HANDLE) {
         copy_ok &= (CopyBuffer(m_h_vp, 0, 1, 2, vp_poc) == 2);
         copy_ok &= (CopyBuffer(m_h_vp, 1, 1, 2, vp_vah) == 2);
         copy_ok &= (CopyBuffer(m_h_vp, 2, 1, 2, vp_val) == 2);
      }
      
      if(!copy_ok) {
         // Erro ao copiar buffers - retornar último regime conhecido
         out_signals = m_cache_signals;
         out_confidence = m_cache_confidence;
         return m_cache_regime;
      }
      
      // Preencher estrutura com valores copiados
      s.adx = adx_buf[0];
      s.plus_di = plus_di_buf[0];
      s.minus_di = minus_di_buf[0];
      
      s.ci = ci_buf[0];
      
      double bbu = bb_upper[0];
      double bbm = bb_middle[0];
      double bbl = bb_lower[0];
      s.bbw_pct = (bbm != 0.0 && MathIsValidNumber(bbm) && MathIsValidNumber(bbu) && MathIsValidNumber(bbl))
                  ? ((bbu - bbl) / bbm) * 100.0 : 0.0;
      s.squeeze_now = (squeeze_buf[0] >= 0.5);
      s.squeeze_prev = (squeeze_buf[1] >= 0.5);
      
      s.atr = atr_buf[0];
      s.atr_pct = atr_pct_buf[0];
      s.atr_roc = atr_roc_buf[0];
      
      s.wae_trend_up = MathAbs(wae_up[0]);
      s.wae_trend_down = MathAbs(wae_dn[0]);
      s.wae_explosion = MathAbs(wae_exp[0]);
      double wae_explosion_prev = MathAbs(wae_exp[1]);
      
      if(m_h_vp != INVALID_HANDLE) {
         s.poc = vp_poc[0];
         s.vah = vp_vah[0];
         s.val = vp_val[0];
      }
      // ========== VOTING SYSTEM - 8 INDICATORS ==========
      int v_trend=0, v_breakout=0, v_range=0, v_total=0;
      
      // Vote 1: ADX (trend strength)
      if(MathIsValidNumber(s.adx)) { 
         v_total++; 
         if(s.adx > m_params.regime_adx_trend_threshold) 
            v_trend++; 
         else 
            v_range++; 
      }
      
      // Vote 2: Choppiness Index (trend vs range)
      if(MathIsValidNumber(s.ci)) { 
         v_total++; 
         if(s.ci < m_params.regime_ci_trend_threshold) 
            v_trend++; 
         else if(s.ci > m_params.regime_ci_ranging_threshold) 
            v_range++; 
         else 
            v_breakout++; 
      }
      
      // Vote 3: Bollinger/Keltner Squeeze (volatility compression/expansion)
      if(MathIsValidNumber(s.bbw_pct)) {
         v_total++;
         if(s.squeeze_prev && !s.squeeze_now) 
            v_breakout++; // Squeeze released = breakout
         else if(s.squeeze_now && s.bbw_pct <= m_params.regime_bbw_squeeze_threshold) 
            v_range++; // Active squeeze = ranging
         else 
            v_trend++;
      }
      
      // Vote 4: ATR% (volatility level)
      if(MathIsValidNumber(s.atr_pct)) {
         v_total++;
         if(s.atr_pct < m_params.regime_atr_pct_low_threshold) 
            v_range++; // Low volatility = ranging
         else if(s.atr_pct > m_params.regime_atr_pct_high_threshold) { 
            // High volatility: check CI to distinguish trend vs breakout
            if(s.ci < 50.0) 
               v_trend++; 
            else 
               v_breakout++; 
         }
         else 
            v_trend++; // Normal volatility = trending
      }
      
      // Vote 5: ATR ROC (momentum of volatility)
      if(MathIsValidNumber(s.atr_roc)) {
         v_total++;
         if(s.atr_roc > m_params.regime_atr_roc_accel_threshold) 
            v_breakout++; // Accelerating volatility = breakout
         else if(s.atr_roc < m_params.regime_atr_roc_decel_threshold) 
            v_range++; // Decelerating volatility = ranging
         else 
            v_trend++; // Stable volatility = trending
      }
      
      // Vote 6: WAE (Waddah Attar Explosion - momentum)
      bool wae_bull_cross = (MathAbs(wae_up_prev) <= wae_explosion_prev && MathAbs(wae_up) > s.wae_explosion);
      bool wae_bear_cross = (MathAbs(wae_dn_prev) <= wae_explosion_prev && MathAbs(wae_dn) > s.wae_explosion);
      v_total++;
      if(wae_bull_cross || wae_bear_cross) 
         v_breakout++; // Explosion cross = breakout
      else if( (s.wae_trend_up > s.wae_explosion) || (s.wae_trend_down > s.wae_explosion) ) 
         v_trend++; // Strong momentum above explosion = trending
      else 
         v_range++; // Dead zone (below explosion) = ranging
      
      // Vote 7: Volume Profile (price position relative to value area)
      if(MathIsValidNumber(s.price_close) && MathIsValidNumber(s.vah) && MathIsValidNumber(s.val)) {
         v_total++;
         if(s.price_close > s.vah || s.price_close < s.val) 
            v_trend++; // Outside value area = trending
         else 
            v_range++; // Inside value area = ranging
      }
      
      // Vote 8: DI Dominance (directional strength)
      if(MathIsValidNumber(s.plus_di) && MathIsValidNumber(s.minus_di)) {
         v_total++;
         double di_diff = MathAbs(s.plus_di - s.minus_di);
         if(s.adx > m_params.regime_adx_trend_threshold && di_diff > m_params.regime_di_dominance_threshold) 
            v_trend++; // Strong ADX + clear direction = trending
         else 
            v_range++; // Weak directional dominance = ranging
      }
      
      // ========== DETERMINE REGIME (majority vote) ==========
      int max_votes = v_trend; ENUM_MARKET_REGIME regime = REGIME_TRENDING;
      if(v_breakout > max_votes) { max_votes = v_breakout; regime = REGIME_BREAKOUT; }
      if(v_range    > max_votes) { max_votes = v_range;    regime = REGIME_RANGING; }
      s.votes_trend = v_trend; s.votes_breakout = v_breakout; s.votes_range = v_range; s.votes_total = v_total;
      s.regime = regime;
      s.confidence = (v_total > 0 ? (double)max_votes / (double)v_total : 0.0);
      m_last = s;
      out_signals = s;
      out_confidence = s.confidence;
      // PATCH: update cache
      m_cache_time = bar_time;
      m_cache_signals = s;
      m_cache_regime = regime;
      m_cache_confidence = s.confidence;
      return regime;
   }
   SRegimeSignals GetLastSignals() const { return m_last; }
};

#endif // __AFS_REGIME_DETECTOR_MQH__
