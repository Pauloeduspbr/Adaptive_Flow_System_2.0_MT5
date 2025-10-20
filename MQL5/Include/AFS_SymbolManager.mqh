//+------------------------------------------------------------------+
//| AFS_SymbolManager.mqh                                            |
//| Adaptive Flow System v2 - Symbol Properties Manager              |
//|                                                                  |
//| 🔥 Gerencia propriedades específicas do ativo                    |
//| 🔥 Adaptação automática: Forex / Índices / Metais / Cripto / B3 |
//| 🔥 ZERO HARDCODE - Tudo baseado em SymbolInfo                    |
//+------------------------------------------------------------------+
#ifndef __AFS_SYMBOL_MANAGER_MQH__
#define __AFS_SYMBOL_MANAGER_MQH__

#include "AFS_GlobalParameters.mqh"

// ============================================================================
// CLASS: CSymbolManager
// ============================================================================

class CSymbolManager
{
private:
   string m_symbol;
   ENUM_ASSET_TYPE m_asset_type;
   
   // Cached symbol properties (atualizadas no Init)
   double m_point;
   int    m_digits;
   double m_tick_size;
   double m_tick_value;
   double m_contract_size;
   double m_lot_min;
   double m_lot_max;
   double m_lot_step;
   double m_margin_required;
   double m_spread_current;
   
   // Pricing
   double m_bid;
   double m_ask;
   
   // Cache control
   datetime m_last_update;
   int m_update_interval_seconds;
   
public:
   // ========== CONSTRUCTOR ==========
   CSymbolManager(string symbol = "", int update_interval = 1)
   {
      m_symbol = (symbol == "" ? _Symbol : symbol);
      m_update_interval_seconds = update_interval;
      m_last_update = 0;
      
      // Auto-detect asset type
      m_asset_type = DetectAssetType(m_symbol);
      
      // Initialize properties
      UpdateProperties();
   }
   
   ~CSymbolManager() {}
   
   // ========== PROPERTY UPDATES ==========
   
   void UpdateProperties()
   {
      // Cache symbol properties (chama apenas quando necessário)
      datetime current_time = TimeCurrent();
      if(current_time - m_last_update < m_update_interval_seconds) {
         return; // Cache ainda válido
      }
      
      m_point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      m_digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      m_tick_size = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      m_tick_value = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
      m_contract_size = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      m_lot_min = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      m_lot_max = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      m_lot_step = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      
      // Margin (para 1 lote)
      if(!OrderCalcMargin(ORDER_TYPE_BUY, m_symbol, 1.0, SymbolInfoDouble(m_symbol, SYMBOL_ASK), m_margin_required)) {
         m_margin_required = 0;
      }
      
      m_last_update = current_time;
   }
   
   void UpdatePrices()
   {
      // Update bid/ask (chama a cada tick se necessário)
      m_bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      m_ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      m_spread_current = m_ask - m_bid;
   }
   
   // ========== ASSET TYPE DETECTION ==========
   
   ENUM_ASSET_TYPE DetectAssetType(string symbol)
   {
      // Forex major pairs
      if(StringFind(symbol, "EUR") >= 0 || StringFind(symbol, "USD") >= 0 ||
         StringFind(symbol, "GBP") >= 0 || StringFind(symbol, "JPY") >= 0 ||
         StringFind(symbol, "AUD") >= 0 || StringFind(symbol, "NZD") >= 0 ||
         StringFind(symbol, "CAD") >= 0 || StringFind(symbol, "CHF") >= 0)
      {
         return ASSET_FOREX;
      }
      
      // Metals (Gold, Silver)
      if(StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "XAG") >= 0 ||
         StringFind(symbol, "GOLD") >= 0 || StringFind(symbol, "SILVER") >= 0)
      {
         return ASSET_METALS;
      }
      
      // Indices
      if(StringFind(symbol, "NAS") >= 0 || StringFind(symbol, "SPX") >= 0 ||
         StringFind(symbol, "DAX") >= 0 || StringFind(symbol, "FTSE") >= 0 ||
         StringFind(symbol, "DOW") >= 0 || StringFind(symbol, "NDX") >= 0)
      {
         return ASSET_INDICES;
      }
      
      // Crypto
      if(StringFind(symbol, "BTC") >= 0 || StringFind(symbol, "ETH") >= 0 ||
         StringFind(symbol, "XRP") >= 0 || StringFind(symbol, "LTC") >= 0)
      {
         return ASSET_CRYPTO;
      }
      
      // B3 Stocks (termina com 3, 4, 11, F, etc)
      int len = StringLen(symbol);
      if(len >= 5) {
         string last_char = StringSubstr(symbol, len-1, 1);
         if(last_char == "3" || last_char == "4" || last_char == "F" ||
            StringFind(symbol, "11") == len-2)
         {
            return ASSET_STOCKS_B3;
         }
      }
      
      // Default
      return ASSET_FOREX;
   }
   
   // ========== PRICE NORMALIZATION ==========
   
   double NormalizePrice(double price)
   {
      return NormalizeDouble(price, m_digits);
   }
   
   double NormalizeLot(double lot)
   {
      // Clamp to min/max
      lot = MathMax(m_lot_min, lot);
      lot = MathMin(m_lot_max, lot);
      
      // Round to step
      lot = MathFloor(lot / m_lot_step) * m_lot_step;
      
      // Ensure minimum
      if(lot < m_lot_min) lot = m_lot_min;
      
      return lot;
   }
   
   // ========== CONVERSIONS ==========
   
   double PipsToPrice(double pips)
   {
      // Convert pips to price units
      // Para pares JPY: 1 pip = 0.01 (2 dígitos)
      // Para outros Forex: 1 pip = 0.0001 (4 dígitos)
      // Para índices/metais/cripto: usar m_point
      
      if(m_asset_type == ASSET_FOREX) {
         // JPY pairs have 2 decimal places
         if(StringFind(m_symbol, "JPY") >= 0) {
            return pips * 0.01; // 1 pip = 0.01
         } else {
            return pips * 0.0001; // 1 pip = 0.0001
         }
      }
      
      // Para outros ativos, usar point
      return pips * m_point;
   }
   
   double PriceToPips(double price_distance)
   {
      // Convert price distance to pips
      if(m_asset_type == ASSET_FOREX) {
         if(StringFind(m_symbol, "JPY") >= 0) {
            return price_distance / 0.01;
         } else {
            return price_distance / 0.0001;
         }
      }
      
      return price_distance / m_point;
   }
   
   double GetPipValue(double lots)
   {
      // Calculate pip value in account currency
      // pip_value = (tick_value / tick_size) * lots
      
      if(m_tick_size == 0) return 0;
      
      double pip_value = (m_tick_value / m_tick_size) * lots;
      
      return pip_value;
   }
   
   // ========== VALIDATION ==========
   
   bool ValidateOrderParams(double entry, double sl, double tp, ENUM_SIGNAL_DIRECTION direction)
   {
      // Validar se entry, sl, tp são válidos
      
      if(entry <= 0 || sl <= 0 || tp <= 0) {
         PrintFormat("❌ Preços inválidos: entry=%.5f sl=%.5f tp=%.5f", entry, sl, tp);
         return false;
      }
      
      // Validar spread (evitar execuções em spread alto)
      UpdatePrices();
      double spread_pips = PriceToPips(m_spread_current);
      double max_spread = 5.0; // TODO: Parametrizar
      
      if(spread_pips > max_spread) {
         PrintFormat("⚠️ Spread muito alto: %.1f pips (max: %.1f)", spread_pips, max_spread);
         return false;
      }
      
      // Validar SL/TP direction
      if(direction == DIR_LONG) {
         if(sl >= entry) {
            PrintFormat("❌ SL inválido LONG: SL %.5f >= Entry %.5f", sl, entry);
            return false;
         }
         if(tp <= entry) {
            PrintFormat("❌ TP inválido LONG: TP %.5f <= Entry %.5f", tp, entry);
            return false;
         }
      }
      else if(direction == DIR_SHORT) {
         if(sl <= entry) {
            PrintFormat("❌ SL inválido SHORT: SL %.5f <= Entry %.5f", sl, entry);
            return false;
         }
         if(tp >= entry) {
            PrintFormat("❌ TP inválido SHORT: TP %.5f >= Entry %.5f", tp, entry);
            return false;
         }
      }
      
      // Validar distâncias mínimas (stop level)
      int stop_level = (int)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
      double min_distance = stop_level * m_point;
      
      if(MathAbs(entry - sl) < min_distance) {
         PrintFormat("❌ SL muito próximo: %.5f < %.5f (min stop level)", 
                     MathAbs(entry - sl), min_distance);
         return false;
      }
      
      if(MathAbs(entry - tp) < min_distance) {
         PrintFormat("❌ TP muito próximo: %.5f < %.5f (min stop level)", 
                     MathAbs(entry - tp), min_distance);
         return false;
      }
      
      return true;
   }
   
   bool ValidateLotSize(double lots)
   {
      if(lots < m_lot_min) {
         PrintFormat("❌ Lote abaixo do mínimo: %.2f < %.2f", lots, m_lot_min);
         return false;
      }
      
      if(lots > m_lot_max) {
         PrintFormat("❌ Lote acima do máximo: %.2f > %.2f", lots, m_lot_max);
         return false;
      }
      
      // Verificar margem disponível
      double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      double required_margin = m_margin_required * lots;
      
      if(required_margin > free_margin) {
         PrintFormat("❌ Margem insuficiente: req=%.2f, free=%.2f", 
                     required_margin, free_margin);
         return false;
      }
      
      return true;
   }
   
   // ========== SYMBOL-SPECIFIC ADJUSTMENTS ==========
   
   double AdjustSLForSymbol(double sl_atr_multiplier, double atr)
   {
      // Ajustar SL baseado no tipo de ativo
      double sl_distance = sl_atr_multiplier * atr;
      
      // Ajustes específicos por tipo de ativo
      switch(m_asset_type)
      {
         case ASSET_FOREX:
            // Forex: usar SL como especificado
            break;
            
         case ASSET_INDICES:
            // Índices: SL pode ser mais apertado (movimentos rápidos)
            sl_distance *= 0.8;
            break;
            
         case ASSET_METALS:
            // Metais (ouro): SL mais largo (volatilidade alta)
            sl_distance *= 1.2;
            break;
            
         case ASSET_CRYPTO:
            // Cripto: SL muito mais largo (extrema volatilidade)
            sl_distance *= 1.5;
            break;
            
         case ASSET_STOCKS_B3:
            // Ações B3: SL padrão
            break;
      }
      
      return sl_distance;
   }
   
   double AdjustTPForSymbol(double tp_rr_ratio, double risk)
   {
      // Ajustar TP baseado no tipo de ativo
      double tp_distance = tp_rr_ratio * risk;
      
      // Ajustes específicos por tipo de ativo
      switch(m_asset_type)
      {
         case ASSET_FOREX:
            // Forex: usar TP como especificado
            break;
            
         case ASSET_INDICES:
            // Índices: TP mais agressivo (tendências fortes)
            tp_distance *= 1.1;
            break;
            
         case ASSET_METALS:
            // Metais: TP conservador (reversões rápidas)
            tp_distance *= 0.9;
            break;
            
         case ASSET_CRYPTO:
            // Cripto: TP muito agressivo (movimentos explosivos)
            tp_distance *= 1.3;
            break;
            
         case ASSET_STOCKS_B3:
            // Ações B3: TP padrão
            break;
      }
      
      return tp_distance;
   }
   
   // ========== GETTERS ==========
   
   string GetSymbol() const { return m_symbol; }
   ENUM_ASSET_TYPE GetAssetType() const { return m_asset_type; }
   double GetPoint() const { return m_point; }
   int GetDigits() const { return m_digits; }
   double GetTickSize() const { return m_tick_size; }
   double GetTickValue() const { return m_tick_value; }
   double GetContractSize() const { return m_contract_size; }
   double GetLotMin() const { return m_lot_min; }
   double GetLotMax() const { return m_lot_max; }
   double GetLotStep() const { return m_lot_step; }
   double GetMarginRequired() const { return m_margin_required; }
   double GetBid() const { return m_bid; }
   double GetAsk() const { return m_ask; }
   double GetSpread() const { return m_spread_current; }
   
   // ========== HELPERS ==========
   
   void PrintSymbolInfo()
   {
      PrintFormat("========================================");
      PrintFormat("Symbol: %s", m_symbol);
      PrintFormat("Asset Type: %s", EnumToString(m_asset_type));
      PrintFormat("Point: %.5f | Digits: %d", m_point, m_digits);
      PrintFormat("Tick Size: %.5f | Tick Value: %.2f", m_tick_size, m_tick_value);
      PrintFormat("Contract Size: %.2f", m_contract_size);
      PrintFormat("Lot Min: %.2f | Max: %.2f | Step: %.2f", m_lot_min, m_lot_max, m_lot_step);
      PrintFormat("Margin (1 lot): %.2f", m_margin_required);
      PrintFormat("Current Bid: %.5f | Ask: %.5f | Spread: %.5f (%.1f pips)", 
                  m_bid, m_ask, m_spread_current, PriceToPips(m_spread_current));
      PrintFormat("========================================");
   }
};

#endif // __AFS_SYMBOL_MANAGER_MQH__
