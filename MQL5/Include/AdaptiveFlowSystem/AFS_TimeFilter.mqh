//+------------------------------------------------------------------+
//| AFS_TimeFilter.mqh                                               |
//| Adaptive Flow System v2 - Time Filter                            |
//|                                                                  |
//| 🔥 Filtro de horário e sessões                                   |
//| 🔥 Controle de dias da semana                                    |
//| 🔥 Detecção de sessões (Asian/London/NY)                         |
//+------------------------------------------------------------------+
#ifndef __AFS_TIME_FILTER_MQH__
#define __AFS_TIME_FILTER_MQH__

#include "AFS_GlobalParameters.mqh"

// ============================================================================
// CLASS: CTimeFilter
// ============================================================================

class CTimeFilter
{
private:
   SGlobalParameters* m_params;
   
   ENUM_SESSION m_current_session;
   datetime m_session_last_check;
   
public:
   // ========== CONSTRUCTOR ==========
   CTimeFilter(SGlobalParameters* params)
   {
      m_params = params;
      m_current_session = SESSION_NONE;
      m_session_last_check = 0;
   }
   
   ~CTimeFilter() {}
   
   // ========== MAIN VALIDATION ==========
   
   bool IsTradingAllowed()
   {
      // Validação completa (chamar antes de processar sinais)
      
      if(!m_params.enable_time_filter) {
         return true; // Time filter desabilitado
      }
      
      // Check 1: Dia da semana permitido?
      if(!IsTradingDay()) {
         return false;
      }
      
      // Check 2: Dentro do horário?
      if(!IsWithinTradingHours()) {
         return false;
      }
      
      // Check 3: Sessão permitida?
      if(!IsSessionAllowed()) {
         return false;
      }
      
      return true;
   }
   
   // ========== DAY OF WEEK FILTER ==========
   
   bool IsTradingDay()
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      
      // day_of_week: 0=Sunday, 1=Monday, ..., 6=Saturday
      switch(dt.day_of_week)
      {
         case 0: return m_params.trade_sunday;
         case 1: return m_params.trade_monday;
         case 2: return m_params.trade_tuesday;
         case 3: return m_params.trade_wednesday;
         case 4: return m_params.trade_thursday;
         case 5: return m_params.trade_friday;
         case 6: return m_params.trade_saturday;
      }
      
      return false;
   }
   
   ENUM_DAY_OF_WEEK GetCurrentDayOfWeek()
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      
      switch(dt.day_of_week)
      {
         case 0: return DAY_SUNDAY;
         case 1: return DAY_MONDAY;
         case 2: return DAY_TUESDAY;
         case 3: return DAY_WEDNESDAY;
         case 4: return DAY_THURSDAY;
         case 5: return DAY_FRIDAY;
         case 6: return DAY_SATURDAY;
      }
      
      return DAY_MONDAY; // Default
   }
   
   // ========== HOURLY RANGE FILTER ==========
   
   bool IsWithinTradingHours()
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      
      int current_minutes = dt.hour * 60 + dt.min;
      
      int start_minutes = TimeStringToMinutes(m_params.start_time);
      int end_minutes = TimeStringToMinutes(m_params.end_time);
      
      // Handle overnight range (e.g., 22:00 - 02:00)
      if(end_minutes < start_minutes)
      {
         // Overnight: current >= start OR current <= end
         return (current_minutes >= start_minutes || current_minutes <= end_minutes);
      }
      else
      {
         // Normal range: start <= current <= end
         return (current_minutes >= start_minutes && current_minutes <= end_minutes);
      }
   }
   
   // ========== SESSION DETECTION ==========
   
   ENUM_SESSION DetectCurrentSession()
   {
      // Detectar sessão atual baseado no horário do broker
      // Assumindo timezone_offset = +2 (broker típico)
      
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      
      int current_hour = dt.hour;
      
      // Ajustar para UTC (se necessário)
      // current_hour -= m_params.timezone_offset;
      // if(current_hour < 0) current_hour += 24;
      
      // Sessões (horário do broker UTC+2):
      // Asian: 02:00 - 08:00
      // London: 09:00 - 17:00
      // New York: 15:00 - 23:00
      
      bool is_asian = (current_hour >= 2 && current_hour < 8);
      bool is_london = (current_hour >= 9 && current_hour < 17);
      bool is_newyork = (current_hour >= 15 && current_hour < 23);
      
      // Prioridade: Overlap > London > NY > Asian
      if(is_london && is_newyork) {
         return SESSION_OVERLAP_LONDON_NY;
      }
      
      if(is_london) {
         return SESSION_LONDON;
      }
      
      if(is_newyork) {
         return SESSION_NEWYORK;
      }
      
      if(is_asian) {
         return SESSION_ASIAN;
      }
      
      return SESSION_NONE;
   }
   
   ENUM_SESSION GetCurrentSession()
   {
      // Cache session detection (evitar cálculo repetido no mesmo minuto)
      datetime current_time = TimeCurrent();
      
      if(current_time - m_session_last_check >= 60) { // Atualizar a cada minuto
         m_current_session = DetectCurrentSession();
         m_session_last_check = current_time;
      }
      
      return m_current_session;
   }
   
   bool IsSessionAllowed()
   {
      ENUM_SESSION session = GetCurrentSession();
      
      switch(session)
      {
         case SESSION_ASIAN:
            return m_params.trade_asian_session;
            
         case SESSION_LONDON:
            return m_params.trade_london_session;
            
         case SESSION_NEWYORK:
            return m_params.trade_newyork_session;
            
         case SESSION_OVERLAP_LONDON_NY:
            // Overlap permitido se ambas sessões permitidas
            return (m_params.trade_london_session && m_params.trade_newyork_session);
            
         case SESSION_NONE:
            return false; // Fora de todas as sessões
      }
      
      return false;
   }
   
   bool IsSessionOverlap()
   {
      return (GetCurrentSession() == SESSION_OVERLAP_LONDON_NY);
   }
   
   // ========== NEWS FILTER (FUTURE) ==========
   
   bool IsNewsTime()
   {
      // TODO: Implementar integração com calendário econômico
      // Verificar se há evento de high impact nas próximas X minutos
      
      return false; // Placeholder
   }
   
   // ========== TIME UTILITIES ==========
   
   string GetSessionName(ENUM_SESSION session)
   {
      switch(session)
      {
         case SESSION_ASIAN: return "Asian";
         case SESSION_LONDON: return "London";
         case SESSION_NEWYORK: return "New York";
         case SESSION_OVERLAP_LONDON_NY: return "London+NY Overlap";
         case SESSION_NONE: return "None";
      }
      return "Unknown";
   }
   
   int GetMinutesUntilSessionEnd()
   {
      // Calcular quantos minutos faltam para o fim da sessão atual
      ENUM_SESSION session = GetCurrentSession();
      
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      
      int current_minutes = dt.hour * 60 + dt.min;
      int end_minutes = 0;
      
      switch(session)
      {
         case SESSION_ASIAN:
            end_minutes = 8 * 60; // 08:00
            break;
            
         case SESSION_LONDON:
            end_minutes = 17 * 60; // 17:00
            break;
            
         case SESSION_NEWYORK:
            end_minutes = 23 * 60; // 23:00
            break;
            
         case SESSION_OVERLAP_LONDON_NY:
            end_minutes = 17 * 60; // Termina quando London fecha
            break;
            
         default:
            return 0;
      }
      
      return end_minutes - current_minutes;
   }
   
   bool IsNearSessionEnd(int minutes_threshold)
   {
      // Verificar se está próximo do fim da sessão
      // Útil para evitar abrir trades perto do fechamento
      
      int minutes_remaining = GetMinutesUntilSessionEnd();
      
      if(minutes_remaining <= 0) return false;
      
      return (minutes_remaining <= minutes_threshold);
   }
   
   // ========== REPORTING ==========
   
   void PrintTimeFilterStatus()
   {
      PrintFormat("========================================");
      PrintFormat("TIME FILTER STATUS");
      PrintFormat("========================================");
      
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      
      PrintFormat("⏰ Current Time: %02d:%02d:%02d", dt.hour, dt.min, dt.sec);
      PrintFormat("📅 Day: %s", EnumToString(GetCurrentDayOfWeek()));
      PrintFormat("🌏 Session: %s", GetSessionName(GetCurrentSession()));
      
      PrintFormat("✅ Trading Allowed: %s", IsTradingAllowed() ? "YES" : "NO");
      PrintFormat("  - Day allowed: %s", IsTradingDay() ? "YES" : "NO");
      PrintFormat("  - Hours allowed: %s", IsWithinTradingHours() ? "YES" : "NO");
      PrintFormat("  - Session allowed: %s", IsSessionAllowed() ? "YES" : "NO");
      
      PrintFormat("📊 Session Config:");
      PrintFormat("  - Asian: %s", m_params.trade_asian_session ? "ON" : "OFF");
      PrintFormat("  - London: %s", m_params.trade_london_session ? "ON" : "OFF");
      PrintFormat("  - New York: %s", m_params.trade_newyork_session ? "ON" : "OFF");
      
      PrintFormat("🕐 Trading Hours: %s - %s", m_params.start_time, m_params.end_time);
      
      PrintFormat("📆 Trading Days:");
      PrintFormat("  Sun=%s Mon=%s Tue=%s Wed=%s Thu=%s Fri=%s Sat=%s",
                  m_params.trade_sunday ? "ON" : "OFF",
                  m_params.trade_monday ? "ON" : "OFF",
                  m_params.trade_tuesday ? "ON" : "OFF",
                  m_params.trade_wednesday ? "ON" : "OFF",
                  m_params.trade_thursday ? "ON" : "OFF",
                  m_params.trade_friday ? "ON" : "OFF",
                  m_params.trade_saturday ? "ON" : "OFF");
      
      if(GetCurrentSession() != SESSION_NONE) {
         int minutes_left = GetMinutesUntilSessionEnd();
         PrintFormat("⏳ Minutes until session end: %d", minutes_left);
      }
      
      PrintFormat("========================================");
   }
};

#endif // __AFS_TIME_FILTER_MQH__
