//+------------------------------------------------------------------+
//| AFS_PositionManager.mqh                                          |
//| Adaptive Flow System v2 - Position Manager                       |
//|                                                                  |
//| 🔥 Gerenciamento de posições abertas                             |
//| 🔥 Break-Even automático                                         |
//| 🔥 Trailing Stop dinâmico                                        |
//| 🔥 Partial Close (TP parcial)                                    |
//+------------------------------------------------------------------+
#ifndef __AFS_POSITION_MANAGER_MQH__
#define __AFS_POSITION_MANAGER_MQH__

#include <Trade\Trade.mqh>
#include "AFS_GlobalParameters.mqh"
#include "AFS_SymbolManager.mqh"
#include "AFS_TradeExecutionManager.mqh"  // FULL INCLUDE - não há dependência circular

// ============================================================================
// CLASS: CPositionManager
// ============================================================================

class CPositionManager
{
private:
   SGlobalParameters m_params;       // Direct struct copy (MQL5 doesn't support & references as members)
   SSetupParameters m_setup_params;  // Direct struct copy
   CSymbolManager* m_symbol_mgr;
   CTradeExecutionManager* m_execution_mgr;  // Ponteiro para tipo forward-declared
   
   CTrade m_trade;
   
public:
   // ========== CONSTRUCTOR ==========
   CPositionManager(const SGlobalParameters &params,
                    const SSetupParameters &setup_params,
                    CSymbolManager* symbol_mgr,
                    CTradeExecutionManager* execution_mgr)
   {
      m_params = params;             // Struct copy assignment
      m_setup_params = setup_params; // Struct copy assignment
      m_symbol_mgr = symbol_mgr;
      m_execution_mgr = execution_mgr;
      
      // Configure trade object
      m_trade.SetExpertMagicNumber(m_params.magic_number);
      m_trade.SetDeviationInPoints(10);
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
      m_trade.SetAsyncMode(false);
      m_trade.LogLevel(LOG_LEVEL_ERRORS);
   }
   
   ~CPositionManager() {}
   
   // ========== MAIN UPDATE ==========
   
   void UpdateAllPositions()
   {
      // Atualizar todas as posições abertas (chamar a cada tick ou OnTimer)
      
      int total_positions = PositionsTotal();
      
      for(int i = total_positions - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket <= 0) continue;
         
         // Filtrar por símbolo e magic number
         if(PositionGetString(POSITION_SYMBOL) != m_symbol_mgr->GetSymbol()) continue;
         if(PositionGetInteger(POSITION_MAGIC) != m_params.magic_number) continue;
         
         // Obter state
         STradeState state;
         if(!m_execution_mgr->GetTradeState(ticket, state)) {
            // State não encontrado - pode ser trade manual ou de sessão anterior
            continue;
         }
         
         // Atualizar posição
         UpdatePosition(ticket, state);
      }
   }
   
   void UpdatePosition(ulong ticket, STradeState &state)
   {
      // Atualizar uma posição específica
      
      if(!PositionSelectByTicket(ticket)) return;
      
      double current_price = (state.direction == DIR_LONG) ? 
                             m_symbol_mgr->GetBid() : m_symbol_mgr->GetAsk();
      
      double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double current_sl = PositionGetDouble(POSITION_SL);
      double current_tp = PositionGetDouble(POSITION_TP);
      
      // Calcular profit em R (Risk multiples)
      double risk_distance = MathAbs(entry_price - state.initial_sl);
      double profit_distance = (state.direction == DIR_LONG) ? 
                               (current_price - entry_price) : (entry_price - current_price);
      
      double profit_r = (risk_distance > 0) ? (profit_distance / risk_distance) : 0;
      
      // Obter parâmetros do setup
      int setup_index = (int)state.setup_type;
      if(setup_index < 0 || setup_index >= 6) return;
      
      // Selecionar params LONG ou SHORT
      bool is_long = (state.direction == DIR_LONG);
      
      // Break-Even
      if(!state.breakeven_activated)
      {
         double be_activation_r = is_long ? 
                                  m_setup_params.long_params.be_activation_r :
                                  m_setup_params.short_params.be_activation_r;
         
         if(profit_r >= be_activation_r)
         {
            if(MoveToBreakEven(ticket, state, entry_price)) {
               state.breakeven_activated = true;
               
               if(m_params.debug_log_management) {
                  PrintFormat("🔒 Break-Even ativado: ticket=%d profit=%.2fR", ticket, profit_r);
               }
            }
         }
      }
      
      // Trailing Stop
      if(state.breakeven_activated) // Só ativar TS após BE
      {
         bool ts_enabled = is_long ?
                          m_setup_params.long_params.ts_enabled :
                          m_setup_params.short_params.ts_enabled;
         
         if(ts_enabled)
         {
            double ts_activation_r = is_long ?
                                    m_setup_params.long_params.ts_activation_r :
                                    m_setup_params.short_params.ts_activation_r;
            
            if(profit_r >= ts_activation_r)
            {
               if(!state.trailing_activated) {
                  state.trailing_activated = true;
                  
                  if(m_params.debug_log_management) {
                     PrintFormat("📈 Trailing Stop ativado: ticket=%d profit=%.2fR", ticket, profit_r);
                  }
               }
               
               UpdateTrailingStop(ticket, state, current_price, entry_price, profit_r);
            }
         }
      }
      
      // TODO: Partial Close (TP parcial em múltiplos de R)
   }
   
   // ========== BREAK-EVEN ==========
   
   bool MoveToBreakEven(ulong ticket, const STradeState &state, double entry_price)
   {
      // Mover SL para break-even (com offset opcional)
      
      if(!PositionSelectByTicket(ticket)) return false;
      
      int setup_index = (int)state.setup_type;
      bool is_long = (state.direction == DIR_LONG);
      
      // Obter offset
      double offset_pips = is_long ?
                          m_setup_params.long_params.be_offset_pips :
                          m_setup_params.short_params.be_offset_pips;
      
      bool use_sl_fraction = is_long ?
                            m_setup_params.long_params.be_use_sl_fraction :
                            m_setup_params.short_params.be_use_sl_fraction;
      
      double offset_fraction = is_long ?
                              m_setup_params.long_params.be_offset_fraction :
                              m_setup_params.short_params.be_offset_fraction;
      
      double new_sl = entry_price;
      
      // Calcular offset
      if(use_sl_fraction)
      {
         // Offset como fração da distância entry-SL inicial
         double risk_distance = MathAbs(entry_price - state.initial_sl);
         double offset_distance = risk_distance * offset_fraction;
         
         new_sl = (is_long) ? (entry_price + offset_distance) : (entry_price - offset_distance);
      }
      else if(offset_pips > 0)
      {
         // Offset em pips
         double offset_price = m_symbol_mgr->PipsToPrice(offset_pips);
         
         new_sl = (is_long) ? (entry_price + offset_price) : (entry_price - offset_price);
      }
      
      // Normalizar preço
      new_sl = m_symbol_mgr->NormalizePrice(new_sl);
      
      // Verificar se novo SL é melhor que atual
      double current_sl = PositionGetDouble(POSITION_SL);
      
      if(is_long)
      {
         if(new_sl <= current_sl) return false; // Não mover para trás
      }
      else
      {
         if(new_sl >= current_sl) return false; // Não mover para trás
      }
      
      // Modificar posição
      double current_tp = PositionGetDouble(POSITION_TP);
      
      if(m_trade.PositionModify(ticket, new_sl, current_tp))
      {
         PrintFormat("✅ SL movido para Break-Even: ticket=%d new_sl=%.5f offset=%.1f pips",
                    ticket, new_sl, offset_pips);
         return true;
      }
      else
      {
         PrintFormat("❌ Falha ao mover SL para BE: ticket=%d error=%d",
                    ticket, m_trade.ResultRetcode());
         return false;
      }
   }
   
   // ========== TRAILING STOP ==========
   
   void UpdateTrailingStop(ulong ticket, const STradeState &state, 
                          double current_price, double entry_price, double profit_r)
   {
      // Atualizar trailing stop
      
      if(!PositionSelectByTicket(ticket)) return;
      
      int setup_index = (int)state.setup_type;
      bool is_long = (state.direction == DIR_LONG);
      
      double current_sl = PositionGetDouble(POSITION_SL);
      double current_tp = PositionGetDouble(POSITION_TP);
      
      // Calcular nova distância do SL
      bool use_atr = is_long ?
                    m_setup_params.long_params.ts_use_atr :
                    m_setup_params.short_params.ts_use_atr;
      
      double ts_distance_atr = is_long ?
                              m_setup_params.long_params.ts_distance_atr :
                              m_setup_params.short_params.ts_distance_atr;
      
      double ts_step_fraction = is_long ?
                               m_setup_params.long_params.ts_step_fraction :
                               m_setup_params.short_params.ts_step_fraction;
      
      double new_sl = current_sl;
      
      if(use_atr)
      {
         // Distância baseada em ATR
         int h_atr = iATR(m_symbol_mgr->GetSymbol(), m_params.timeframe, m_params.atr_period);
         double atr_buffer[];
         ArraySetAsSeries(atr_buffer, true);
         if(CopyBuffer(h_atr, 0, 0, 1, atr_buffer) <= 0) return;
         double atr = atr_buffer[0];
         IndicatorRelease(h_atr);
         
         double atr_distance = atr * ts_distance_atr;
         
         new_sl = (is_long) ? 
                  (current_price - atr_distance) : (current_price + atr_distance);
      }
      else
      {
         // Distância baseada em fração do risco inicial
         double risk_distance = MathAbs(entry_price - state.initial_sl);
         double step_distance = risk_distance * ts_step_fraction;
         
         // Calcular novo SL baseado no profit atual
         new_sl = (is_long) ?
                  (entry_price + (profit_r * risk_distance) - step_distance) :
                  (entry_price - (profit_r * risk_distance) + step_distance);
      }
      
      // Normalizar
      new_sl = m_symbol_mgr->NormalizePrice(new_sl);
      
      // Verificar se novo SL é melhor
      if(is_long)
      {
         if(new_sl <= current_sl) return; // Não mover para trás
      }
      else
      {
         if(new_sl >= current_sl) return; // Não mover para trás
      }
      
      // Modificar
      if(m_trade.PositionModify(ticket, new_sl, current_tp))
      {
         if(m_params.debug_log_management) {
            double sl_change_pips = m_symbol_mgr->PriceToPips(MathAbs(new_sl - current_sl));
            
            PrintFormat("📈 Trailing Stop atualizado: ticket=%d new_sl=%.5f (+%.1f pips) profit=%.2fR",
                       ticket, new_sl, sl_change_pips, profit_r);
         }
      }
   }
   
   // ========== PARTIAL CLOSE ==========
   
   bool PartialClose(ulong ticket, double close_percent, double profit_r_target)
   {
      // Fechar parcialmente uma posição (ex: 50% em 2R)
      
      if(!PositionSelectByTicket(ticket)) return false;
      
      double current_volume = PositionGetDouble(POSITION_VOLUME);
      double close_volume = current_volume * (close_percent / 100.0);
      
      // Normalizar lote
      close_volume = m_symbol_mgr->NormalizeLot(close_volume);
      
      if(close_volume < m_symbol_mgr->GetLotMin()) {
         PrintFormat("⚠️ Volume de fechamento parcial muito pequeno: %.2f", close_volume);
         return false;
      }
      
      // Verificar se restará volume mínimo
      double remaining_volume = current_volume - close_volume;
      if(remaining_volume < m_symbol_mgr->GetLotMin()) {
         // Fechar tudo
         close_volume = current_volume;
      }
      
      // Executar fechamento parcial
      ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      if(m_trade.PositionClosePartial(ticket, close_volume))
      {
         PrintFormat("✅ PARTIAL CLOSE: ticket=%d closed=%.2f lots (%.0f%%) at %.2fR remaining=%.2f lots",
                    ticket, close_volume, close_percent, profit_r_target, remaining_volume);
         return true;
      }
      else
      {
         PrintFormat("❌ Falha partial close: ticket=%d error=%d",
                    ticket, m_trade.ResultRetcode());
         return false;
      }
   }
   
   // ========== POSITION QUERIES ==========
   
   bool HasPosition(ENUM_SETUP_TYPE setup, ENUM_SIGNAL_DIRECTION direction)
   {
      // Verificar se há posição aberta para setup+direction
      
      int total = PositionsTotal();
      
      for(int i = 0; i < total; i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket <= 0) continue;
         
         if(PositionGetString(POSITION_SYMBOL) != m_symbol_mgr->GetSymbol()) continue;
         if(PositionGetInteger(POSITION_MAGIC) != m_params.magic_number) continue;
         
         // Verificar state
         STradeState state;
         if(m_execution_mgr->GetTradeState(ticket, state))
         {
            if(state.setup_type == setup && state.direction == direction) {
               return true;
            }
         }
      }
      
      return false;
   }
   
   int GetActivePositionCount()
   {
      // Contar posições ativas do EA
      
      int count = 0;
      int total = PositionsTotal();
      
      for(int i = 0; i < total; i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket <= 0) continue;
         
         if(PositionGetString(POSITION_SYMBOL) == m_symbol_mgr->GetSymbol() &&
            PositionGetInteger(POSITION_MAGIC) == m_params.magic_number)
         {
            count++;
         }
      }
      
      return count;
   }
   
   double GetTotalProfit()
   {
      // Calcular profit total (abertas + fechadas hoje)
      
      double total_profit = 0;
      int total = PositionsTotal();
      
      for(int i = 0; i < total; i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket <= 0) continue;
         
         if(PositionGetString(POSITION_SYMBOL) == m_symbol_mgr->GetSymbol() &&
            PositionGetInteger(POSITION_MAGIC) == m_params.magic_number)
         {
            total_profit += PositionGetDouble(POSITION_PROFIT);
         }
      }
      
      return total_profit;
   }
   
   // ========== EMERGENCY CLOSE ==========
   
   void CloseAllPositions(string reason = "Emergency close")
   {
      // Fechar todas as posições do EA
      
      PrintFormat("⚠️ FECHANDO TODAS AS POSIÇÕES: %s", reason);
      
      int total = PositionsTotal();
      int closed_count = 0;
      
      for(int i = total - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket <= 0) continue;
         
         if(PositionGetString(POSITION_SYMBOL) != m_symbol_mgr->GetSymbol()) continue;
         if(PositionGetInteger(POSITION_MAGIC) != m_params.magic_number) continue;
         
         if(m_trade.PositionClose(ticket))
         {
            closed_count++;
            PrintFormat("✅ Posição fechada: ticket=%d", ticket);
         }
         else
         {
            PrintFormat("❌ Falha ao fechar: ticket=%d error=%d", 
                       ticket, m_trade.ResultRetcode());
         }
      }
      
      PrintFormat("📊 Total fechadas: %d/%d", closed_count, total);
   }
   
   // ========== REPORTING ==========
   
   void PrintPositionReport()
   {
      PrintFormat("========================================");
      PrintFormat("POSITION MANAGER REPORT");
      PrintFormat("========================================");
      
      int total = PositionsTotal();
      int ea_positions = 0;
      
      for(int i = 0; i < total; i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket <= 0) continue;
         
         if(PositionGetString(POSITION_SYMBOL) != m_symbol_mgr->GetSymbol()) continue;
         if(PositionGetInteger(POSITION_MAGIC) != m_params.magic_number) continue;
         
         ea_positions++;
         
         double entry = PositionGetDouble(POSITION_PRICE_OPEN);
         double current_price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ?
                               m_symbol_mgr->GetBid() : m_symbol_mgr->GetAsk();
         double sl = PositionGetDouble(POSITION_SL);
         double tp = PositionGetDouble(POSITION_TP);
         double profit = PositionGetDouble(POSITION_PROFIT);
         double lots = PositionGetDouble(POSITION_VOLUME);
         
         // Calcular profit em R
         double risk_distance = MathAbs(entry - sl);
         double profit_distance = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ?
                                 (current_price - entry) : (entry - current_price);
         double profit_r = (risk_distance > 0) ? (profit_distance / risk_distance) : 0;
         
         PrintFormat("📊 Ticket=%d | Type=%s | Lots=%.2f | Entry=%.5f | Current=%.5f | SL=%.5f | TP=%.5f | Profit=$%.2f (%.2fR)",
                    ticket,
                    (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "LONG" : "SHORT",
                    lots,
                    entry,
                    current_price,
                    sl,
                    tp,
                    profit,
                    profit_r);
         
         // State info
         STradeState state;
         if(m_execution_mgr->GetTradeState(ticket, state))
         {
            PrintFormat("   Setup=%s | BE=%s | TS=%s",
                       EnumToString(state.setup_type),
                       state.breakeven_activated ? "✅" : "❌",
                       state.trailing_activated ? "✅" : "❌");
         }
      }
      
      if(ea_positions == 0) {
         PrintFormat("Nenhuma posição aberta");
      }
      
      PrintFormat("========================================");
   }
};

#endif // __AFS_POSITION_MANAGER_MQH__
