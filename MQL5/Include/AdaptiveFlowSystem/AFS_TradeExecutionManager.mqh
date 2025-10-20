//+------------------------------------------------------------------+
//| AFS_TradeExecutionManager.mqh                                    |
//| Adaptive Flow System v2 - Trade Execution Manager                |
//|                                                                  |
//| 🔥 Pipeline de processamento de sinais                           |
//| 🔥 Filtro de duplicatas e conflitos                              |
//| 🔥 Priorização e execução inteligente                            |
//+------------------------------------------------------------------+
#ifndef __AFS_TRADE_EXECUTION_MANAGER_MQH__
#define __AFS_TRADE_EXECUTION_MANAGER_MQH__

#include <Trade\Trade.mqh>
#include "AFS_GlobalParameters.mqh"
#include "AFS_SymbolManager.mqh"
#include "AFS_RiskManager.mqh"
#include "AFS_TimeFilter.mqh"

// ============================================================================
// STRUCTURES
// ============================================================================

struct STradeSignal
{
   ENUM_SETUP_TYPE setup_type;
   ENUM_SIGNAL_DIRECTION direction;
   ENUM_ORDER_TYPE_SIGNAL order_type;
   
   double entry_price;
   double sl_price;
   double tp_price;
   
   double confidence;
   double rr_ratio;
   int priority;
   
   double pending_expiration_bars;
   
   datetime signal_time;
   int signal_bar_index;
   
   string comment;
   bool is_valid;
};

struct STradeState
{
   ulong ticket;
   ENUM_SETUP_TYPE setup_type;
   ENUM_SIGNAL_DIRECTION direction;
   ENUM_ORDER_TYPE_SIGNAL order_type;
   
   datetime open_time;
   datetime last_modification;
   
   bool breakeven_activated;
   bool trailing_activated;
   
   double initial_sl;
   double initial_tp;
   double current_sl;
   double current_tp;
   
   int expiration_bar;
   bool is_active;
};

// ============================================================================
// CLASS: CTradeExecutionManager
// ============================================================================

class CTradeExecutionManager
{
private:
   SGlobalParameters m_params;  // Direct struct copy (MQL5 doesn't support & references as members)
   CSymbolManager* m_symbol_mgr;
   CRiskManager* m_risk_mgr;
   CTimeFilter* m_time_filter;
   
   CTrade m_trade;
   
   STradeState m_trade_states[100]; // Max 100 posições simultâneas
   int m_trade_state_count;
   
   // Cooldown tracking
   datetime m_last_trade_time_per_setup[6]; // 6 setups
   int m_last_trade_bar_per_setup[6];
   
   // Signal processing
   STradeSignal m_pending_signals[20]; // Buffer de sinais pendentes
   int m_pending_signal_count;
   
public:
   // ========== CONSTRUCTOR ==========
   CTradeExecutionManager(const SGlobalParameters &params, 
                          CSymbolManager* symbol_mgr,
                          CRiskManager* risk_mgr,
                          CTimeFilter* time_filter)
   {
      m_params = params;  // Struct copy assignment
      m_symbol_mgr = symbol_mgr;
      m_risk_mgr = risk_mgr;
      m_time_filter = time_filter;
      
      // Configure trade object
      m_trade.SetExpertMagicNumber(m_params.magic_number);
      m_trade.SetDeviationInPoints(10); // TODO: Parametrizar
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
      m_trade.SetAsyncMode(false);
      m_trade.LogLevel(LOG_LEVEL_ERRORS);
      
      // Initialize arrays
      ZeroMemory(m_trade_states);
      m_trade_state_count = 0;
      
      ArrayInitialize(m_last_trade_time_per_setup, 0);
      ArrayInitialize(m_last_trade_bar_per_setup, 0);
      
      ZeroMemory(m_pending_signals);
      m_pending_signal_count = 0;
   }
   
   ~CTradeExecutionManager() {}
   
   // ========== MAIN PROCESSING PIPELINE ==========
   
   void ProcessSignals(STradeSignal &signals[], int signal_count)
   {
      // Pipeline de 6 estágios
      
      if(signal_count == 0) return;
      
      // Stage 1: Atualizar estado de todas as posições
      UpdateTradeStates();
      
      // Stage 2: Gerenciar ordens pendentes (expiração, cancelamento)
      ManagePendingOrders();
      
      // Stage 3: Filtrar sinais (duplicatas, cooldown, conflitos)
      STradeSignal filtered_signals[];
      int filtered_count = FilterSignals(signals, signal_count, filtered_signals);
      
      if(filtered_count == 0) {
         if(m_params.debug_log_signals) {
            PrintFormat("🚫 Todos os sinais filtrados (%d sinais rejeitados)", signal_count);
         }
         return;
      }
      
      // Stage 4: Priorizar sinais (score-based)
      PrioritizeSignals(filtered_signals, filtered_count);
      
      // Stage 5: Executar sinais (até limite de exposição)
      for(int i = 0; i < filtered_count; i++)
      {
         if(!ExecuteSignal(filtered_signals[i])) {
            break; // Parar se limite de risco atingido
         }
      }
      
      // Stage 6: Atualizar state tracking
      UpdateTradeStates();
   }
   
   // ========== STAGE 1: UPDATE STATES ==========
   
   void UpdateTradeStates()
   {
      // Atualizar estados de todas as posições/ordens
      
      // Limpar estados de trades fechados
      for(int i = m_trade_state_count - 1; i >= 0; i--)
      {
         if(!m_trade_states[i].is_active) continue;
         
         ulong ticket = m_trade_states[i].ticket;
         
         // Check se posição ainda existe
         if(!PositionSelectByTicket(ticket) && !OrderSelect(ticket)) {
            // Trade fechado - remover do tracking
            m_trade_states[i].is_active = false;
            
            if(m_params.debug_log_execution) {
               PrintFormat("🔄 Trade state removido: ticket=%d", ticket);
            }
         }
      }
   }
   
   // ========== STAGE 2: MANAGE PENDING ORDERS ==========
   
   void ManagePendingOrders()
   {
      // Gerenciar expiração e cancelamento de ordens pendentes
      
      for(int i = 0; i < m_trade_state_count; i++)
      {
         if(!m_trade_states[i].is_active) continue;
         
         if(m_trade_states[i].order_type != ORDER_SIGNAL_PENDING) continue;
         
         ulong ticket = m_trade_states[i].ticket;
         
         if(!OrderSelect(ticket)) {
            m_trade_states[i].is_active = false;
            continue;
         }
         
         // Check 1: Expiração por bars
         int current_bar = iBars(m_symbol_mgr->GetSymbol(), m_params.timeframe);
         int bars_elapsed = current_bar - m_trade_states[i].expiration_bar;
         
         if(bars_elapsed >= m_params.pending_timeout_bars) {
            if(CancelPendingOrder(ticket)) {
               PrintFormat("⏰ Ordem pendente expirada: ticket=%d (%d bars)", 
                          ticket, bars_elapsed);
            }
            continue;
         }
         
         // Check 2: Cancelar se regime mudou (opcional)
         if(m_params.cancel_pending_on_regime_change) {
            // TODO: Implementar detecção de mudança de regime
         }
      }
   }
   
   bool CancelPendingOrder(ulong ticket)
   {
      if(!OrderSelect(ticket)) return false;
      
      if(m_trade.OrderDelete(ticket)) {
         // Remover do tracking
         for(int i = 0; i < m_trade_state_count; i++) {
            if(m_trade_states[i].ticket == ticket) {
               m_trade_states[i].is_active = false;
               break;
            }
         }
         return true;
      }
      
      return false;
   }
   
   // ========== STAGE 3: FILTER SIGNALS ==========
   
   int FilterSignals(STradeSignal &input_signals[], int input_count, 
                     STradeSignal &output_signals[])
   {
      // Filtrar sinais inválidos/duplicados/conflitos
      
      ArrayResize(output_signals, 0);
      int output_count = 0;
      
      for(int i = 0; i < input_count; i++)
      {
         STradeSignal signal = input_signals[i];
         
         if(!signal.is_valid) {
            if(m_params.debug_log_signals) {
               PrintFormat("🚫 Signal filtered: Setup=%s - Invalid", 
                          EnumToString(signal.setup_type));
            }
            continue;
         }
         
         // Filter 1: Duplicata (setup já tem posição ativa)?
         if(HasActiveTradeForSetup(signal.setup_type, signal.direction)) {
            if(m_params.debug_log_signals) {
               PrintFormat("🚫 Signal filtered: Setup=%s Dir=%s - Duplicate", 
                          EnumToString(signal.setup_type), 
                          EnumToString(signal.direction));
            }
            continue;
         }
         
         // Filter 2: Cooldown (mesmo bar)?
         if(IsInCooldown(signal.setup_type, signal.signal_bar_index)) {
            if(m_params.debug_log_signals) {
               PrintFormat("🚫 Signal filtered: Setup=%s - Cooldown", 
                          EnumToString(signal.setup_type));
            }
            continue;
         }
         
         // Filter 3: Conflito direcional (LONG vs SHORT no mesmo símbolo)?
         if(HasDirectionalConflict(signal.direction)) {
            if(m_params.debug_log_signals) {
               PrintFormat("🚫 Signal filtered: Setup=%s Dir=%s - Directional conflict", 
                          EnumToString(signal.setup_type), 
                          EnumToString(signal.direction));
            }
            continue;
         }
         
         // Filter 4: Time filter
         if(!m_time_filter.IsTradingAllowed()) {
            if(m_params.debug_log_signals) {
               PrintFormat("🚫 Signal filtered: Setup=%s - Time not allowed", 
                          EnumToString(signal.setup_type));
            }
            continue;
         }
         
         // Sinal passou todos os filtros
         ArrayResize(output_signals, output_count + 1);
         output_signals[output_count] = signal;
         output_count++;
      }
      
      return output_count;
   }
   
   bool HasActiveTradeForSetup(ENUM_SETUP_TYPE setup, ENUM_SIGNAL_DIRECTION direction)
   {
      // Verificar se já existe posição/ordem para este setup+direction
      
      for(int i = 0; i < m_trade_state_count; i++)
      {
         if(!m_trade_states[i].is_active) continue;
         
         if(m_trade_states[i].setup_type == setup && 
            m_trade_states[i].direction == direction) {
            return true;
         }
      }
      
      return false;
   }
   
   bool IsInCooldown(ENUM_SETUP_TYPE setup, int current_bar)
   {
      // Verificar se já executou trade neste setup no mesmo bar
      
      int setup_index = (int)setup;
      
      if(setup_index < 0 || setup_index >= 6) return false;
      
      return (m_last_trade_bar_per_setup[setup_index] == current_bar);
   }
   
   bool HasDirectionalConflict(ENUM_SIGNAL_DIRECTION direction)
   {
      // Verificar se há posição na direção oposta no mesmo símbolo
      
      for(int i = 0; i < m_trade_state_count; i++)
      {
         if(!m_trade_states[i].is_active) continue;
         
         // Conflito: LONG vs SHORT
         if(direction == DIR_LONG && m_trade_states[i].direction == DIR_SHORT) {
            return true;
         }
         
         if(direction == DIR_SHORT && m_trade_states[i].direction == DIR_LONG) {
            return true;
         }
      }
      
      return false;
   }
   
   // ========== STAGE 4: PRIORITIZE SIGNALS ==========
   
   void PrioritizeSignals(STradeSignal &signals[], int signal_count)
   {
      // Ordenar sinais por score (maior score = maior prioridade)
      
      // Calcular scores
      for(int i = 0; i < signal_count; i++)
      {
         signals[i].priority = CalculateSignalScore(signals[i]);
      }
      
      // Bubble sort (simples mas eficiente para poucos sinais)
      for(int i = 0; i < signal_count - 1; i++)
      {
         for(int j = 0; j < signal_count - i - 1; j++)
         {
            if(signals[j].priority < signals[j + 1].priority)
            {
               // Swap
               STradeSignal temp = signals[j];
               signals[j] = signals[j + 1];
               signals[j + 1] = temp;
            }
         }
      }
      
      if(m_params.debug_log_signals)
      {
         PrintFormat("📊 Sinais priorizados (%d sinais):", signal_count);
         for(int i = 0; i < signal_count; i++)
         {
            PrintFormat("  %d. Setup=%s Dir=%s Score=%d Conf=%.2f RR=%.2f",
                       i + 1,
                       EnumToString(signals[i].setup_type),
                       EnumToString(signals[i].direction),
                       signals[i].priority,
                       signals[i].confidence,
                       signals[i].rr_ratio);
         }
      }
   }
   
   int CalculateSignalScore(const STradeSignal &signal)
   {
      // Calcular score de prioridade (0-100)
      
      int score = 0;
      
      // Componente 1: Confidence (0-50 pontos)
      score += (int)(signal.confidence * 50.0);
      
      // Componente 2: RR Ratio (0-30 pontos)
      double rr_normalized = MathMin(signal.rr_ratio / 5.0, 1.0); // Cap em 5R
      score += (int)(rr_normalized * 30.0);
      
      // Componente 3: Setup priority (0-20 pontos)
      // Prioridade por setup: A=20, B=18, C=16, D=14, E=12, F=10
      switch(signal.setup_type)
      {
         case SETUP_A_LIQUIDITY_RAID: score += 20; break;
         case SETUP_B_AMD_BREAKOUT: score += 18; break;
         case SETUP_C_SESSION_MOMENTUM: score += 16; break;
         case SETUP_D_MEAN_REVERSION: score += 14; break;
         case SETUP_E_SQUEEZE_BREAKOUT: score += 12; break;
         case SETUP_F_CONTINUATION: score += 10; break;
      }
      
      return score;
   }
   
   // ========== STAGE 5: EXECUTE SIGNALS ==========
   
   bool ExecuteSignal(STradeSignal &signal)
   {
      // Executar sinal (market order ou pending order)
      
      // Validar risco
      double entry = signal.entry_price;
      double sl = signal.sl_price;
      double tp = signal.tp_price;
      
      // Calcular lote
      double lots = m_risk_mgr.CalculatePositionSize(entry, sl);
      
      if(lots <= 0) {
         PrintFormat("❌ Lote inválido: %.2f", lots);
         return false;
      }
      
      // Calcular risco percentual
      double risk_pct = m_risk_mgr.CalculateRiskPercent(entry, sl, lots);
      
      // Validar se pode abrir
      if(!m_risk_mgr.CanOpenNewPosition(risk_pct)) {
         PrintFormat("🚫 Limite de risco atingido - Signal cancelado");
         return false;
      }
      
      // Validar parâmetros da ordem
      if(!m_symbol_mgr.ValidateOrderParams(entry, sl, tp, signal.direction)) {
         PrintFormat("❌ Parâmetros de ordem inválidos");
         return false;
      }
      
      // Executar ordem
      ulong ticket = 0;
      
      if(signal.order_type == ORDER_SIGNAL_MARKET)
      {
         ticket = ExecuteMarketOrder(signal, lots);
      }
      else if(signal.order_type == ORDER_SIGNAL_PENDING)
      {
         ticket = ExecutePendingOrder(signal, lots);
      }
      
      if(ticket > 0)
      {
         // Registrar trade no tracking
         RegisterTrade(ticket, signal);
         
         // Atualizar cooldown
         int setup_index = (int)signal.setup_type;
         m_last_trade_time_per_setup[setup_index] = TimeCurrent();
         m_last_trade_bar_per_setup[setup_index] = signal.signal_bar_index;
         
         return true;
      }
      
      return false;
   }
   
   ulong ExecuteMarketOrder(const STradeSignal &signal, double lots)
   {
      // Executar ordem a mercado
      
      ENUM_ORDER_TYPE order_type = (signal.direction == DIR_LONG) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      
      double entry = (signal.direction == DIR_LONG) ? 
                     m_symbol_mgr.GetAsk() : m_symbol_mgr.GetBid();
      
      if(m_trade.PositionOpen(m_symbol_mgr.GetSymbol(),
                              order_type,
                              lots,
                              entry,
                              signal.sl_price,
                              signal.tp_price,
                              signal.comment))
      {
         ulong ticket = m_trade.ResultOrder();
         
         PrintFormat("✅ MARKET ORDER EXECUTED | Ticket=%d Setup=%s Dir=%s Lots=%.2f Entry=%.5f SL=%.5f TP=%.5f RR=%.2f",
                    ticket,
                    EnumToString(signal.setup_type),
                    EnumToString(signal.direction),
                    lots,
                    entry,
                    signal.sl_price,
                    signal.tp_price,
                    signal.rr_ratio);
         
         return ticket;
      }
      else
      {
         PrintFormat("❌ Market order failed: %d - %s", 
                    m_trade.ResultRetcode(), 
                    m_trade.ResultRetcodeDescription());
         return 0;
      }
   }
   
   ulong ExecutePendingOrder(const STradeSignal &signal, double lots)
   {
      // Executar ordem pendente (Buy Stop, Sell Stop, etc)
      
      ENUM_ORDER_TYPE order_type;
      
      if(signal.direction == DIR_LONG)
      {
         // LONG: Buy Stop (entry acima do preço) ou Buy Limit (entry abaixo)
         double current_price = m_symbol_mgr.GetAsk();
         order_type = (signal.entry_price > current_price) ? ORDER_TYPE_BUY_STOP : ORDER_TYPE_BUY_LIMIT;
      }
      else
      {
         // SHORT: Sell Stop (entry abaixo do preço) ou Sell Limit (entry acima)
         double current_price = m_symbol_mgr.GetBid();
         order_type = (signal.entry_price < current_price) ? ORDER_TYPE_SELL_STOP : ORDER_TYPE_SELL_LIMIT;
      }
      
      // Calcular expiração
      datetime expiration = 0;
      if(m_params.pending_timeout_bars > 0)
      {
         int bar_seconds = PeriodSeconds(m_params.timeframe);
         expiration = TimeCurrent() + (m_params.pending_timeout_bars * bar_seconds);
      }
      
      if(m_trade.OrderOpen(m_symbol_mgr.GetSymbol(),
                          order_type,
                          lots,
                          0,
                          signal.entry_price,
                          signal.sl_price,
                          signal.tp_price,
                          ORDER_TIME_SPECIFIED,
                          expiration,
                          signal.comment))
      {
         ulong ticket = m_trade.ResultOrder();
         
         PrintFormat("✅ PENDING ORDER PLACED | Ticket=%d Type=%s Setup=%s Lots=%.2f Entry=%.5f SL=%.5f TP=%.5f Exp=%d bars",
                    ticket,
                    EnumToString(order_type),
                    EnumToString(signal.setup_type),
                    lots,
                    signal.entry_price,
                    signal.sl_price,
                    signal.tp_price,
                    m_params.pending_timeout_bars);
         
         return ticket;
      }
      else
      {
         PrintFormat("❌ Pending order failed: %d - %s", 
                    m_trade.ResultRetcode(), 
                    m_trade.ResultRetcodeDescription());
         return 0;
      }
   }
   
   void RegisterTrade(ulong ticket, const STradeSignal &signal)
   {
      // Registrar trade no tracking
      
      // Encontrar slot vazio
      int slot = -1;
      for(int i = 0; i < 100; i++)
      {
         if(!m_trade_states[i].is_active) {
            slot = i;
            break;
         }
      }
      
      if(slot < 0) {
         PrintFormat("⚠️ Trade states array full!");
         return;
      }
      
      // Preencher state
      m_trade_states[slot].ticket = ticket;
      m_trade_states[slot].setup_type = signal.setup_type;
      m_trade_states[slot].direction = signal.direction;
      m_trade_states[slot].order_type = signal.order_type;
      m_trade_states[slot].open_time = TimeCurrent();
      m_trade_states[slot].last_modification = TimeCurrent();
      m_trade_states[slot].breakeven_activated = false;
      m_trade_states[slot].trailing_activated = false;
      m_trade_states[slot].initial_sl = signal.sl_price;
      m_trade_states[slot].initial_tp = signal.tp_price;
      m_trade_states[slot].current_sl = signal.sl_price;
      m_trade_states[slot].current_tp = signal.tp_price;
      m_trade_states[slot].expiration_bar = iBars(m_symbol_mgr->GetSymbol(), m_params.timeframe);
      m_trade_states[slot].is_active = true;
      
      if(slot >= m_trade_state_count) {
         m_trade_state_count = slot + 1;
      }
   }
   
   // ========== GETTERS ==========
   
   int GetActiveTradeCount() const { return m_trade_state_count; }
   
   bool GetTradeState(ulong ticket, STradeState &state)
   {
      for(int i = 0; i < m_trade_state_count; i++)
      {
         if(m_trade_states[i].ticket == ticket && m_trade_states[i].is_active) {
            state = m_trade_states[i];
            return true;
         }
      }
      return false;
   }
   
   void GetAllActiveStates(STradeState &states[], int &count)
   {
      ArrayResize(states, 0);
      count = 0;
      
      for(int i = 0; i < m_trade_state_count; i++)
      {
         if(m_trade_states[i].is_active) {
            ArrayResize(states, count + 1);
            states[count] = m_trade_states[i];
            count++;
         }
      }
   }
};

#endif // __AFS_TRADE_EXECUTION_MANAGER_MQH__
