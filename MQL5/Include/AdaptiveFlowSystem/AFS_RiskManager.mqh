//+------------------------------------------------------------------+
//| AFS_RiskManager.mqh                                              |
//| Adaptive Flow System v2 - Risk Manager                           |
//|                                                                  |
//| 🔥 Gestão centralizada de risco                                  |
//| 🔥 Position sizing dinâmico                                      |
//| 🔥 Controle de exposição e drawdown                              |
//+------------------------------------------------------------------+
#ifndef __AFS_RISK_MANAGER_MQH__
#define __AFS_RISK_MANAGER_MQH__

#include "AFS_GlobalParameters.mqh"
#include "AFS_SymbolManager.mqh"

// ============================================================================
// STRUCTURES
// ============================================================================

struct SRiskMetrics
{
   double daily_pnl;
   double weekly_pnl;
   double monthly_pnl;
   double max_drawdown;
   double current_drawdown;
   
   int daily_trade_count;
   int weekly_trade_count;
   int monthly_trade_count;
   
   int consecutive_wins;
   int consecutive_losses;
   
   double total_risk_exposure;  // % do capital em risco
   int active_positions_count;
   
   datetime last_reset_daily;
   datetime last_reset_weekly;
   datetime last_reset_monthly;
};

// ============================================================================
// CLASS: CRiskManager
// ============================================================================

class CRiskManager
{
private:
   SGlobalParameters& m_params;
   CSymbolManager* m_symbol_mgr;
   
   SRiskMetrics m_metrics;
   
   // Trade history (para cálculo de consecutivas)
   bool m_last_trades[10];  // Últimos 10 trades (true=win, false=loss)
   int m_last_trade_index;
   
   // Drawdown tracking
   double m_equity_peak;
   double m_balance_start_day;
   double m_balance_start_week;
   double m_balance_start_month;
   
public:
   // ========== CONSTRUCTOR ==========
   CRiskManager(SGlobalParameters& params, CSymbolManager* symbol_mgr)
   {
      m_params = params;
      m_symbol_mgr = symbol_mgr;
      
      // Initialize metrics
      ZeroMemory(m_metrics);
      m_metrics.last_reset_daily = TimeCurrent();
      m_metrics.last_reset_weekly = TimeCurrent();
      m_metrics.last_reset_monthly = TimeCurrent();
      
      // Initialize trade history
      ArrayInitialize(m_last_trades, false);
      m_last_trade_index = 0;
      
      // Initialize balances
      m_equity_peak = AccountInfoDouble(ACCOUNT_EQUITY);
      m_balance_start_day = AccountInfoDouble(ACCOUNT_BALANCE);
      m_balance_start_week = m_balance_start_day;
      m_balance_start_month = m_balance_start_day;
   }
   
   ~CRiskManager() {}
   
   // ========== UPDATE METHODS ==========
   
   void Update()
   {
      // Atualizar métricas (chamar a cada tick ou OnTimer)
      
      // Check reset timers
      CheckDailyReset();
      CheckWeeklyReset();
      CheckMonthlyReset();
      
      // Update P&L
      UpdatePnL();
      
      // Update drawdown
      UpdateDrawdown();
      
      // Update exposure
      UpdateExposure();
   }
   
   void CheckDailyReset()
   {
      MqlDateTime dt_now, dt_last;
      TimeToStruct(TimeCurrent(), dt_now);
      TimeToStruct(m_metrics.last_reset_daily, dt_last);
      
      // Reset se mudou de dia
      if(dt_now.day != dt_last.day || dt_now.mon != dt_last.mon || dt_now.year != dt_last.year)
      {
         PrintFormat("📅 RESET DIÁRIO: PnL=%.2f, Trades=%d", 
                     m_metrics.daily_pnl, m_metrics.daily_trade_count);
         
         m_metrics.daily_pnl = 0;
         m_metrics.daily_trade_count = 0;
         m_metrics.last_reset_daily = TimeCurrent();
         m_balance_start_day = AccountInfoDouble(ACCOUNT_BALANCE);
      }
   }
   
   void CheckWeeklyReset()
   {
      MqlDateTime dt_now, dt_last;
      TimeToStruct(TimeCurrent(), dt_now);
      TimeToStruct(m_metrics.last_reset_weekly, dt_last);
      
      // Reset se mudou de semana (domingo = 0)
      if(dt_now.day_of_week == 0 && dt_last.day_of_week != 0)
      {
         PrintFormat("📅 RESET SEMANAL: PnL=%.2f, Trades=%d", 
                     m_metrics.weekly_pnl, m_metrics.weekly_trade_count);
         
         m_metrics.weekly_pnl = 0;
         m_metrics.weekly_trade_count = 0;
         m_metrics.last_reset_weekly = TimeCurrent();
         m_balance_start_week = AccountInfoDouble(ACCOUNT_BALANCE);
      }
   }
   
   void CheckMonthlyReset()
   {
      MqlDateTime dt_now, dt_last;
      TimeToStruct(TimeCurrent(), dt_now);
      TimeToStruct(m_metrics.last_reset_monthly, dt_last);
      
      // Reset se mudou de mês
      if(dt_now.mon != dt_last.mon || dt_now.year != dt_last.year)
      {
         PrintFormat("📅 RESET MENSAL: PnL=%.2f, Trades=%d", 
                     m_metrics.monthly_pnl, m_metrics.monthly_trade_count);
         
         m_metrics.monthly_pnl = 0;
         m_metrics.monthly_trade_count = 0;
         m_metrics.last_reset_monthly = TimeCurrent();
         m_balance_start_month = AccountInfoDouble(ACCOUNT_BALANCE);
      }
   }
   
   void UpdatePnL()
   {
      double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      
      m_metrics.daily_pnl = current_balance - m_balance_start_day;
      m_metrics.weekly_pnl = current_balance - m_balance_start_week;
      m_metrics.monthly_pnl = current_balance - m_balance_start_month;
   }
   
   void UpdateDrawdown()
   {
      double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
      
      // Atualizar pico
      if(current_equity > m_equity_peak) {
         m_equity_peak = current_equity;
      }
      
      // Calcular drawdown atual
      if(m_equity_peak > 0) {
         m_metrics.current_drawdown = ((m_equity_peak - current_equity) / m_equity_peak) * 100.0;
      }
      
      // Atualizar máximo drawdown
      if(m_metrics.current_drawdown > m_metrics.max_drawdown) {
         m_metrics.max_drawdown = m_metrics.current_drawdown;
      }
   }
   
   void UpdateExposure()
   {
      // Calcular exposição total (risco agregado de todas posições abertas)
      m_metrics.total_risk_exposure = CalculateTotalExposure();
      m_metrics.active_positions_count = PositionsTotal();
   }
   
   // ========== POSITION SIZING ==========
   
   double CalculatePositionSize(double entry, double sl, double risk_pct_override = -1)
   {
      // Calcular tamanho da posição baseado em risco percentual
      
      double risk_pct = (risk_pct_override > 0) ? risk_pct_override : m_params.risk_percent_per_trade;
      
      // Se usar lote fixo, retornar lote fixo
      if(m_params.use_fixed_lot) {
         double fixed_lot = m_params.fixed_lot_size;
         return m_symbol_mgr.NormalizeLot(fixed_lot);
      }
      
      // Calcular risco em dinheiro
      double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double risk_money = account_balance * (risk_pct / 100.0);
      
      // Calcular distância do SL em preço
      double risk_price = MathAbs(entry - sl);
      
      if(risk_price == 0) {
         PrintFormat("❌ Risk price zero: entry=%.5f sl=%.5f", entry, sl);
         return 0;
      }
      
      // Calcular valor do pip
      double pip_value_per_lot = m_symbol_mgr.GetPipValue(1.0);
      
      if(pip_value_per_lot == 0) {
         PrintFormat("❌ Pip value zero");
         return 0;
      }
      
      // Calcular pips de risco
      double risk_pips = m_symbol_mgr.PriceToPips(risk_price);
      
      // Calcular lotes: risk_money / (risk_pips * pip_value_per_pip)
      double lots = risk_money / (risk_pips * (pip_value_per_lot / m_symbol_mgr.GetContractSize()));
      
      // Aplicar multiplicador (se houver)
      lots *= m_params.lot_multiplier;
      
      // Normalizar
      lots = m_symbol_mgr.NormalizeLot(lots);
      
      // Aplicar limites min/max
      lots = MathMax(m_params.min_lot, lots);
      lots = MathMin(m_params.max_lot, lots);
      
      PrintFormat("💰 Position Size: %.2f lots | Risk: %.2f%% ($%.2f) | SL: %.1f pips", 
                  lots, risk_pct, risk_money, risk_pips);
      
      return lots;
   }
   
   double CalculateRiskPercent(double entry, double sl, double lots)
   {
      // Calcular risco percentual de uma posição
      
      double risk_price = MathAbs(entry - sl);
      double risk_pips = m_symbol_mgr.PriceToPips(risk_price);
      double pip_value_per_lot = m_symbol_mgr.GetPipValue(1.0);
      
      double risk_money = risk_pips * (pip_value_per_lot / m_symbol_mgr.GetContractSize()) * lots;
      
      double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      
      if(account_balance == 0) return 0;
      
      return (risk_money / account_balance) * 100.0;
   }
   
   // ========== RISK VALIDATION ==========
   
   bool CanOpenNewPosition(double risk_pct)
   {
      // Verificar se pode abrir nova posição
      
      // Check 1: Exposição total
      double new_exposure = m_metrics.total_risk_exposure + risk_pct;
      if(new_exposure > m_params.max_daily_risk_percent) {
         PrintFormat("🚫 Exposição máxima atingida: %.2f%% + %.2f%% > %.2f%%", 
                     m_metrics.total_risk_exposure, risk_pct, m_params.max_daily_risk_percent);
         return false;
      }
      
      // Check 2: Risco diário
      if(!IsWithinDailyLimit()) {
         return false;
      }
      
      // Check 3: Risco semanal
      if(!IsWithinWeeklyLimit()) {
         return false;
      }
      
      // Check 4: Drawdown
      if(IsDrawdownExceeded()) {
         return false;
      }
      
      // Check 5: Número de trades por dia
      if(m_metrics.daily_trade_count >= m_params.max_trades_per_day) {
         PrintFormat("🚫 Máximo de trades diários atingido: %d/%d", 
                     m_metrics.daily_trade_count, m_params.max_trades_per_day);
         return false;
      }
      
      // Check 6: Perdas consecutivas
      if(m_metrics.consecutive_losses >= m_params.max_consecutive_losses) {
         PrintFormat("🚫 Máximo de perdas consecutivas: %d/%d (PAUSE)", 
                     m_metrics.consecutive_losses, m_params.max_consecutive_losses);
         return false;
      }
      
      // Check 7: Margem disponível
      double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(free_margin < 100) { // TODO: Parametrizar
         PrintFormat("🚫 Margem insuficiente: %.2f", free_margin);
         return false;
      }
      
      return true;
   }
   
   bool IsWithinDailyLimit()
   {
      // PnL diário ultrapassou limite de perda?
      double daily_loss_limit = (m_params.max_daily_risk_percent / 100.0) * m_balance_start_day * -1;
      
      if(m_metrics.daily_pnl < daily_loss_limit) {
         PrintFormat("🚫 Limite de perda diária atingido: $%.2f < $%.2f", 
                     m_metrics.daily_pnl, daily_loss_limit);
         return false;
      }
      
      return true;
   }
   
   bool IsWithinWeeklyLimit()
   {
      // PnL semanal ultrapassou limite de perda?
      double weekly_loss_limit = (m_params.max_weekly_risk_percent / 100.0) * m_balance_start_week * -1;
      
      if(m_metrics.weekly_pnl < weekly_loss_limit) {
         PrintFormat("🚫 Limite de perda semanal atingido: $%.2f < $%.2f", 
                     m_metrics.weekly_pnl, weekly_loss_limit);
         return false;
      }
      
      return true;
   }
   
   bool IsDrawdownExceeded()
   {
      // Drawdown ultrapassou limite?
      if(m_metrics.current_drawdown > m_params.max_drawdown_percent) {
         PrintFormat("🚫 Drawdown máximo excedido: %.2f%% > %.2f%%", 
                     m_metrics.current_drawdown, m_params.max_drawdown_percent);
         return true;
      }
      
      return false;
   }
   
   // ========== EXPOSURE MANAGEMENT ==========
   
   double CalculateTotalExposure()
   {
      // Calcular exposição total (soma de todos os riscos ativos)
      double total_risk = 0;
      
      int total_positions = PositionsTotal();
      for(int i = 0; i < total_positions; i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket <= 0) continue;
         
         if(PositionGetString(POSITION_SYMBOL) != m_symbol_mgr.GetSymbol()) continue;
         
         double position_entry = PositionGetDouble(POSITION_PRICE_OPEN);
         double position_sl = PositionGetDouble(POSITION_SL);
         double position_lots = PositionGetDouble(POSITION_VOLUME);
         
         if(position_sl > 0) {
            double risk_pct = CalculateRiskPercent(position_entry, position_sl, position_lots);
            total_risk += risk_pct;
         }
      }
      
      return total_risk;
   }
   
   double GetRiskPerSetup(ENUM_SETUP_TYPE setup)
   {
      // Calcular risco de um setup específico (se houver posição aberta)
      // TODO: Implementar com magic number filtering
      return 0;
   }
   
   // ========== TRADE TRACKING ==========
   
   void RegisterTrade(bool is_win)
   {
      // Registrar resultado do trade (para consecutivas)
      m_last_trades[m_last_trade_index] = is_win;
      m_last_trade_index = (m_last_trade_index + 1) % 10;
      
      // Atualizar consecutivas
      if(is_win) {
         m_metrics.consecutive_wins++;
         m_metrics.consecutive_losses = 0;
      } else {
         m_metrics.consecutive_losses++;
         m_metrics.consecutive_wins = 0;
      }
      
      // Incrementar contadores
      m_metrics.daily_trade_count++;
      m_metrics.weekly_trade_count++;
      m_metrics.monthly_trade_count++;
      
      PrintFormat("📊 Trade registrado: %s | Consecutivas: W=%d L=%d", 
                  is_win ? "WIN ✅" : "LOSS ❌", 
                  m_metrics.consecutive_wins, 
                  m_metrics.consecutive_losses);
   }
   
   // ========== CORRELATION ==========
   
   bool IsCorrelatedWithOpenPositions(string symbol)
   {
      // TODO: Implementar cálculo de correlação
      // Verificar se há posições abertas em símbolos correlacionados
      // Ex: EURUSD correlacionado com GBPUSD
      
      return false; // Placeholder
   }
   
   // ========== GETTERS ==========
   
   SRiskMetrics GetMetrics() const { return m_metrics; }
   double GetDailyPnL() const { return m_metrics.daily_pnl; }
   double GetWeeklyPnL() const { return m_metrics.weekly_pnl; }
   double GetMonthlyPnL() const { return m_metrics.monthly_pnl; }
   double GetCurrentDrawdown() const { return m_metrics.current_drawdown; }
   double GetMaxDrawdown() const { return m_metrics.max_drawdown; }
   int GetDailyTradeCount() const { return m_metrics.daily_trade_count; }
   int GetActivePositionsCount() const { return m_metrics.active_positions_count; }
   double GetTotalExposure() const { return m_metrics.total_risk_exposure; }
   
   // ========== REPORTING ==========
   
   void PrintRiskReport()
   {
      PrintFormat("========================================");
      PrintFormat("RISK MANAGER REPORT");
      PrintFormat("========================================");
      PrintFormat("📊 P&L:");
      PrintFormat("  Daily: $%.2f", m_metrics.daily_pnl);
      PrintFormat("  Weekly: $%.2f", m_metrics.weekly_pnl);
      PrintFormat("  Monthly: $%.2f", m_metrics.monthly_pnl);
      PrintFormat("📉 Drawdown:");
      PrintFormat("  Current: %.2f%%", m_metrics.current_drawdown);
      PrintFormat("  Max: %.2f%%", m_metrics.max_drawdown);
      PrintFormat("📈 Trades:");
      PrintFormat("  Daily: %d", m_metrics.daily_trade_count);
      PrintFormat("  Weekly: %d", m_metrics.weekly_trade_count);
      PrintFormat("  Monthly: %d", m_metrics.monthly_trade_count);
      PrintFormat("🎯 Consecutivas:");
      PrintFormat("  Wins: %d", m_metrics.consecutive_wins);
      PrintFormat("  Losses: %d", m_metrics.consecutive_losses);
      PrintFormat("💼 Exposição:");
      PrintFormat("  Total Risk: %.2f%%", m_metrics.total_risk_exposure);
      PrintFormat("  Active Positions: %d", m_metrics.active_positions_count);
      PrintFormat("========================================");
   }
};

#endif // __AFS_RISK_MANAGER_MQH__
