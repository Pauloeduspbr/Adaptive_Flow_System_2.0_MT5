//+------------------------------------------------------------------+
//| AdaptiveFlowSystem_v2.mq5                                        |
//| Adaptive Flow System v2 - Professional Institutional EA          |
//| Copyright 2025, Adaptive Flow Systems                            |
//| https://adaptiveflow.systems                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Adaptive Flow Systems"
#property link      "https://adaptiveflow.systems"
#property version   "2.00"
#property description "Multi-Regime Institutional Trading System"
#property description "6 Specialized Setups | 8 Professional Indicators"
#property description "Auto-Adaptive | Zero Hardcode | Full Backtest Support"

// ============================================================================
// INCLUDES
// ============================================================================
#include <Trade\Trade.mqh>
#include <AdaptiveFlowSystem\AFS_GlobalParameters.mqh>
#include <AdaptiveFlowSystem\AFS_SymbolManager.mqh>
#include <AdaptiveFlowSystem\AFS_RiskManager.mqh>
#include <AdaptiveFlowSystem\AFS_TimeFilter.mqh>
#include <AdaptiveFlowSystem\AFS_RegimeDetector.mqh>
#include <AdaptiveFlowSystem\AFS_SetupManager_v2.mqh>
#include <AdaptiveFlowSystem\AFS_TradeExecutionManager.mqh>
#include <AdaptiveFlowSystem\AFS_PositionManager.mqh>

// ============================================================================
// INPUT PARAMETERS - GENERAL
// ============================================================================
input group "========== GENERAL SETTINGS =========="
input string   InpSymbol = "";                          // Symbol (empty = current)
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M15;        // Timeframe
input int      InpMagicNumber = 240125;                 // Magic Number
input string   InpTradeComment = "AFS_v2";              // Trade Comment

// ============================================================================
// INPUT PARAMETERS - TIME FILTER
// ============================================================================
input group "========== TIME FILTER =========="
input bool     InpEnableTimeFilter = true;              // Enable Time Filter
input string   InpStartTime = "03:00";                  // Start Time (HH:MM)
input string   InpEndTime = "22:00";                    // End Time (HH:MM)
input int      InpTimezoneOffset = 2;                   // Timezone Offset (UTC+X)

input group "========== DAY FILTER =========="
input bool     InpTradeSunday = false;                  // Trade Sunday
input bool     InpTradeMonday = true;                   // Trade Monday
input bool     InpTradeTuesday = true;                  // Trade Tuesday
input bool     InpTradeWednesday = true;                // Trade Wednesday
input bool     InpTradeThursday = true;                 // Trade Thursday
input bool     InpTradeFriday = true;                   // Trade Friday
input bool     InpTradeSaturday = false;                // Trade Saturday

input group "========== SESSION FILTER =========="
input bool     InpTradeAsianSession = false;            // Trade Asian Session (02-08h)
input bool     InpTradeLondonSession = true;            // Trade London Session (09-17h)
input bool     InpTradeNewYorkSession = true;           // Trade New York Session (15-23h)

// ============================================================================
// INPUT PARAMETERS - RISK MANAGEMENT
// ============================================================================
input group "========== RISK MANAGEMENT =========="
input double   InpRiskPercentPerTrade = 1.0;            // Risk Per Trade (%)
input double   InpMaxDailyRiskPercent = 2.0;            // Max Daily Risk (%)
input double   InpMaxWeeklyRiskPercent = 5.0;           // Max Weekly Risk (%)
input double   InpMaxDrawdownPercent = 10.0;            // Max Drawdown (%)

input int      InpMaxSimultaneousSetups = 3;            // Max Simultaneous Setups
input int      InpMaxTradesPerDay = 5;                  // Max Trades Per Day
input int      InpMaxConsecutiveLosses = 3;             // Max Consecutive Losses (pause)

input double   InpCorrelationThreshold = 0.75;          // Correlation Threshold

input group "========== POSITION SIZING =========="
input bool     InpUseFixedLot = false;                  // Use Fixed Lot
input double   InpFixedLotSize = 0.01;                  // Fixed Lot Size
input double   InpLotMultiplier = 1.0;                  // Lot Multiplier
input double   InpMinLot = 0.01;                        // Min Lot
input double   InpMaxLot = 100.0;                       // Max Lot

// ============================================================================
// INPUT PARAMETERS - INDICATORS
// ============================================================================
input group "========== INDICATORS =========="
input int      InpADXPeriod = 14;                       // ADX Period
input int      InpCIPeriod = 14;                        // Choppiness Index Period
input int      InpBBPeriod = 20;                        // Bollinger Bands Period
input double   InpBBDeviation = 2.0;                    // BB Deviation
input int      InpKCPeriod = 20;                        // Keltner Channel Period
input double   InpKCMultiplier = 1.5;                   // KC ATR Multiplier
input int      InpATRPeriod = 14;                       // ATR Period
input int      InpATRROCPeriod = 5;                     // ATR ROC Period
input int      InpWAEFastMA = 20;                       // WAE Fast MA
input int      InpWAESlowMA = 40;                       // WAE Slow MA
input int      InpWAESensitivity = 150;                 // WAE Sensitivity
input bool     InpUseVolumeProfile = true;              // Use Volume Profile
input int      InpVPSessionBars = 100;                  // VP Session Bars

// ============================================================================
// INPUT PARAMETERS - REGIME DETECTION
// ============================================================================
input group "========== REGIME DETECTION =========="
input double   InpRegimeConfidenceMin = 0.50;           // Min Confidence (0-1)
input int      InpRegimeVotesMin = 5;                   // Min Votes Required

input double   InpRegimeADXTrendThreshold = 25.0;       // ADX > X = Trending
input double   InpRegimeCITrendThreshold = 38.2;        // CI < X = Trending
input double   InpRegimeCIRangingThreshold = 61.8;      // CI > X = Ranging
input double   InpRegimeBBWSqueezeThreshold = 3.0;      // BBW% < X = Squeeze
input double   InpRegimeATRPctLowThreshold = 0.5;       // ATR% < X = Low Vol
input double   InpRegimeATRPctHighThreshold = 1.2;      // ATR% > X = High Vol
input double   InpRegimeATRROCAccelThreshold = 15.0;    // ATR ROC > X = Accelerating
input double   InpRegimeATRROCDecelThreshold = -15.0;   // ATR ROC < X = Decelerating
input double   InpRegimeDIDominanceThreshold = 5.0;     // |+DI - -DI| > X = Strong Dir

// ============================================================================
// INPUT PARAMETERS - SETUP ENABLE/DISABLE
// ============================================================================
input group "========== SETUP ENABLE/DISABLE =========="
input bool     InpEnableSetupA = true;                  // Enable Setup A (Liquidity Raid)
input bool     InpEnableSetupB = false;                 // Enable Setup B (AMD Breakout)
input bool     InpEnableSetupC = false;                 // Enable Setup C (Session Momentum)
input bool     InpEnableSetupD = false;                 // Enable Setup D (Mean Reversion)
input bool     InpEnableSetupE = false;                 // Enable Setup E (Squeeze Breakout)
input bool     InpEnableSetupF = false;                 // Enable Setup F (Continuation)

// ============================================================================
// INPUT PARAMETERS - PENDING ORDERS
// ============================================================================
input group "========== PENDING ORDERS =========="
input int      InpPendingTimeoutBars = 10;              // Pending Timeout (bars)
input bool     InpCancelPendingOnRegimeChange = true;   // Cancel on Regime Change

// ============================================================================
// INPUT PARAMETERS - SETUP A (LIQUIDITY RAID)
// ============================================================================
input group "========== SETUP A - LIQUIDITY RAID =========="
input int      InpSetupA_LiqLookbackBars = 20;          // Lookback Bars (swing detection)

// SETUP A - LONG
input group "--- Setup A LONG ---"
input double   InpSetupA_LiqSweepPips_Long = 2.0;       // Sweep Threshold (pips) LONG
input double   InpSetupA_LiqSLBufferPips_Long = 8.0;    // SL Buffer (pips) LONG
input double   InpSetupA_LiqDIMargin_Long = 0.0;        // DI Margin LONG
input double   InpSetupA_LiqWAEThreshold_Long = 0.40;   // WAE Threshold (% explosion) LONG
input double   InpSetupA_BE_ActivationR_Long = 0.5;     // BE Activation (R) LONG
input double   InpSetupA_BE_OffsetPips_Long = 5.0;      // BE Offset (pips) LONG
input double   InpSetupA_TS_ActivationR_Long = 0.8;     // TS Activation (R) LONG
input double   InpSetupA_TS_DistanceATR_Long = 1.0;     // TS Distance (ATR) LONG
input double   InpSetupA_SL_ATRMultiplier_Long = 1.5;   // SL ATR Multiplier LONG
input double   InpSetupA_TP_RRRatio_Long = 5.0;         // TP Risk:Reward LONG
input bool     InpSetupA_TP_UseLevels_Long = true;      // TP Use POC/VAL LONG

// SETUP A - SHORT
input group "--- Setup A SHORT ---"
input double   InpSetupA_LiqSweepPips_Short = 2.0;      // Sweep Threshold (pips) SHORT
input double   InpSetupA_LiqSLBufferPips_Short = 8.0;   // SL Buffer (pips) SHORT
input double   InpSetupA_LiqDIMargin_Short = 0.0;       // DI Margin SHORT
input double   InpSetupA_LiqWAEThreshold_Short = 0.40;  // WAE Threshold (% explosion) SHORT
input double   InpSetupA_BE_ActivationR_Short = 0.5;    // BE Activation (R) SHORT
input double   InpSetupA_BE_OffsetPips_Short = 5.0;     // BE Offset (pips) SHORT
input double   InpSetupA_TS_ActivationR_Short = 0.8;    // TS Activation (R) SHORT
input double   InpSetupA_TS_DistanceATR_Short = 1.0;    // TS Distance (ATR) SHORT
input double   InpSetupA_SL_ATRMultiplier_Short = 1.5;  // SL ATR Multiplier SHORT
input double   InpSetupA_TP_RRRatio_Short = 5.0;        // TP Risk:Reward SHORT
input bool     InpSetupA_TP_UseLevels_Short = true;     // TP Use POC/VAL SHORT

// ============================================================================
// INPUT PARAMETERS - DEBUG & LOGS
// ============================================================================
input group "========== DEBUG & LOGS =========="
input bool     InpEnableDebugLogs = false;              // Enable Debug Logs
input bool     InpDebugLogSignals = false;              // Debug: Signals
input bool     InpDebugLogExecution = false;            // Debug: Execution
input bool     InpDebugLogManagement = false;           // Debug: BE/TS Management
input bool     InpEnableSetupLogs = true;               // Enable Setup Logs
input bool     InpEnableRegimeLogs = true;              // Enable Regime Logs

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================
SGlobalParameters g_params;
SSetupParameters g_setup_params[6];

CSymbolManager* g_symbol_mgr = NULL;
CRiskManager* g_risk_mgr = NULL;
CTimeFilter* g_time_filter = NULL;
CRegimeDetector* g_regime_detector = NULL;
CSetupManager* g_setup_mgr = NULL;
CTradeExecutionManager* g_execution_mgr = NULL;
CPositionManager* g_position_mgr = NULL;

// Indicator handles
int g_h_adx = INVALID_HANDLE;
int g_h_ci = INVALID_HANDLE;
int g_h_squeeze = INVALID_HANDLE;
int g_h_atr = INVALID_HANDLE;
int g_h_wae = INVALID_HANDLE;
int g_h_vp = INVALID_HANDLE;

// State variables
datetime g_last_bar_time = 0;
ENUM_MARKET_REGIME g_current_regime = REGIME_UNDEFINED;
double g_regime_confidence = 0.0;

// ============================================================================
// INITIALIZATION
// ============================================================================
int OnInit()
{
   PrintFormat("========================================");
   PrintFormat("ADAPTIVE FLOW SYSTEM v2.0 - INITIALIZING");
   PrintFormat("========================================");
   PrintFormat("Symbol: %s | Timeframe: %s", 
               (InpSymbol == "" ? _Symbol : InpSymbol), 
               EnumToString(InpTimeframe));
   
   // ========== STEP 1: POPULATE GLOBAL PARAMETERS ==========
   PopulateGlobalParameters();
   
   // ========== STEP 2: POPULATE SETUP PARAMETERS ==========
   PopulateSetupParameters();
   
   // ========== STEP 3: CREATE INDICATOR HANDLES ==========
   if(!CreateIndicatorHandles()) {
      Print("❌ ERROR: Failed to create indicator handles");
      return INIT_FAILED;
   }
   
   // ========== STEP 4: INITIALIZE MANAGERS ==========
   g_symbol_mgr = new CSymbolManager(g_params.symbol);
   if(g_symbol_mgr == NULL) {
      Print("❌ ERROR: Failed to create SymbolManager");
      return INIT_FAILED;
   }
   
   g_risk_mgr = new CRiskManager(g_params, g_symbol_mgr);
   if(g_risk_mgr == NULL) {
      Print("❌ ERROR: Failed to create RiskManager");
      return INIT_FAILED;
   }
   
   g_time_filter = new CTimeFilter(g_params);
   if(g_time_filter == NULL) {
      Print("❌ ERROR: Failed to create TimeFilter");
      return INIT_FAILED;
   }
   
   g_regime_detector = new CRegimeDetector(g_params, g_h_adx, g_h_ci, g_h_squeeze, 
                                           g_h_atr, g_h_wae, g_h_vp,
                                           g_params.symbol, g_params.timeframe);
   if(g_regime_detector == NULL) {
      Print("❌ ERROR: Failed to create RegimeDetector");
      return INIT_FAILED;
   }
   
   g_setup_mgr = new CSetupManager(g_params, g_setup_params[0], 
                                   g_params.symbol, g_params.timeframe);
   if(g_setup_mgr == NULL) {
      Print("❌ ERROR: Failed to create SetupManager");
      return INIT_FAILED;
   }
   
   g_execution_mgr = new CTradeExecutionManager(g_params, g_symbol_mgr, 
                                                g_risk_mgr, g_time_filter);
   if(g_execution_mgr == NULL) {
      Print("❌ ERROR: Failed to create TradeExecutionManager");
      return INIT_FAILED;
   }
   
   g_position_mgr = new CPositionManager(g_params, g_setup_params[0], 
                                         g_symbol_mgr, g_execution_mgr);
   if(g_position_mgr == NULL) {
      Print("❌ ERROR: Failed to create PositionManager");
      return INIT_FAILED;
   }
   
   // ========== STEP 5: VALIDATION ==========
   if(!ValidateConfiguration()) {
      Print("❌ ERROR: Configuration validation failed");
      return INIT_FAILED;
   }
   
   // ========== STEP 6: PRINT STATUS ==========
   PrintInitializationStatus();
   
   PrintFormat("========================================");
   PrintFormat("✅ INITIALIZATION COMPLETE - EA READY");
   PrintFormat("========================================");
   
   return INIT_SUCCEEDED;
}

// ============================================================================
// DEINITIALIZATION
// ============================================================================
void OnDeinit(const int reason)
{
   PrintFormat("========================================");
   PrintFormat("EA DEINITIALIZATION - Reason: %s", GetUninitReasonText(reason));
   PrintFormat("========================================");
   
   // Release indicator handles
   if(g_h_adx != INVALID_HANDLE) IndicatorRelease(g_h_adx);
   if(g_h_ci != INVALID_HANDLE) IndicatorRelease(g_h_ci);
   if(g_h_squeeze != INVALID_HANDLE) IndicatorRelease(g_h_squeeze);
   if(g_h_atr != INVALID_HANDLE) IndicatorRelease(g_h_atr);
   if(g_h_wae != INVALID_HANDLE) IndicatorRelease(g_h_wae);
   if(g_h_vp != INVALID_HANDLE) IndicatorRelease(g_h_vp);
   
   // Delete managers
   if(g_position_mgr != NULL) delete g_position_mgr;
   if(g_execution_mgr != NULL) delete g_execution_mgr;
   if(g_setup_mgr != NULL) delete g_setup_mgr;
   if(g_regime_detector != NULL) delete g_regime_detector;
   if(g_time_filter != NULL) delete g_time_filter;
   if(g_risk_mgr != NULL) delete g_risk_mgr;
   if(g_symbol_mgr != NULL) delete g_symbol_mgr;
   
   PrintFormat("✅ EA stopped successfully");
}

// ============================================================================
// MAIN TICK HANDLER
// ============================================================================
void OnTick()
{
   // Only process on new bar (daytrading strategy)
   if(!IsNewBar()) return;
   
   // ========== STAGE 1: UPDATE MANAGERS ==========
   g_risk_mgr.Update();
   g_position_mgr.UpdateAllPositions();
   
   // ========== STAGE 2: TIME FILTER ==========
   if(!g_time_filter.IsTradingAllowed()) {
      if(g_params.debug_log_signals) {
         PrintFormat("🕐 Trading not allowed - Time filter");
      }
      return;
   }
   
   // ========== STAGE 3: REGIME DETECTION ==========
   SRegimeSignals regime_signals;
   g_current_regime = g_regime_detector.Detect(regime_signals, g_regime_confidence);
   
   if(g_params.enable_regime_logs) {
      PrintFormat("📊 Regime: %s | Confidence: %.2f | Votes: T=%d B=%d R=%d",
                  EnumToString(g_current_regime),
                  g_regime_confidence,
                  regime_signals.votes_trend,
                  regime_signals.votes_breakout,
                  regime_signals.votes_range);
   }
   
   // Check minimum confidence
   if(g_regime_confidence < g_params.regime_confidence_min) {
      if(g_params.debug_log_signals) {
         PrintFormat("🚫 Regime confidence too low: %.2f < %.2f",
                    g_regime_confidence, g_params.regime_confidence_min);
      }
      return;
   }
   
   // ========== STAGE 4: SETUP EVALUATION ==========
   STradeSignal signals[];
   int signal_count = 0;
   
   g_setup_mgr.EvaluateAllSetups(regime_signals, g_current_regime, 
                                 g_regime_confidence, signals, signal_count);
   
   if(signal_count == 0) {
      // No signals - continue monitoring
      return;
   }
   
   if(g_params.debug_log_signals) {
      PrintFormat("✅ %d setup signals generated", signal_count);
   }
   
   // ========== STAGE 5: SIGNAL EXECUTION ==========
   g_execution_mgr.ProcessSignals(signals, signal_count);
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

bool IsNewBar()
{
   datetime current_bar_time = iTime(g_params.symbol, g_params.timeframe, 0);
   
   if(current_bar_time != g_last_bar_time) {
      g_last_bar_time = current_bar_time;
      return true;
   }
   
   return false;
}

void PopulateGlobalParameters()
{
   // General
   g_params.symbol = (InpSymbol == "" ? _Symbol : InpSymbol);
   g_params.timeframe = InpTimeframe;
   g_params.magic_number = InpMagicNumber;
   g_params.trade_comment = InpTradeComment;
   g_params.asset_type = ASSET_FOREX; // Auto-detected by SymbolManager
   
   // Time Filter
   g_params.enable_time_filter = InpEnableTimeFilter;
   g_params.start_time = InpStartTime;
   g_params.end_time = InpEndTime;
   g_params.timezone_offset = InpTimezoneOffset;
   
   // Day Filter
   g_params.trade_sunday = InpTradeSunday;
   g_params.trade_monday = InpTradeMonday;
   g_params.trade_tuesday = InpTradeTuesday;
   g_params.trade_wednesday = InpTradeWednesday;
   g_params.trade_thursday = InpTradeThursday;
   g_params.trade_friday = InpTradeFriday;
   g_params.trade_saturday = InpTradeSaturday;
   
   // Session Filter
   g_params.trade_asian_session = InpTradeAsianSession;
   g_params.trade_london_session = InpTradeLondonSession;
   g_params.trade_newyork_session = InpTradeNewYorkSession;
   
   // Risk Management
   g_params.risk_percent_per_trade = InpRiskPercentPerTrade;
   g_params.max_daily_risk_percent = InpMaxDailyRiskPercent;
   g_params.max_weekly_risk_percent = InpMaxWeeklyRiskPercent;
   g_params.max_drawdown_percent = InpMaxDrawdownPercent;
   g_params.max_simultaneous_setups = InpMaxSimultaneousSetups;
   g_params.max_trades_per_day = InpMaxTradesPerDay;
   g_params.max_consecutive_losses = InpMaxConsecutiveLosses;
   g_params.correlation_threshold = InpCorrelationThreshold;
   
   // Position Sizing
   g_params.use_fixed_lot = InpUseFixedLot;
   g_params.fixed_lot_size = InpFixedLotSize;
   g_params.lot_multiplier = InpLotMultiplier;
   g_params.min_lot = InpMinLot;
   g_params.max_lot = InpMaxLot;
   
   // Indicators
   g_params.adx_period = InpADXPeriod;
   g_params.ci_period = InpCIPeriod;
   g_params.bb_period = InpBBPeriod;
   g_params.bb_deviation = InpBBDeviation;
   g_params.kc_period = InpKCPeriod;
   g_params.kc_multiplier = InpKCMultiplier;
   g_params.atr_period = InpATRPeriod;
   g_params.atr_roc_period = InpATRROCPeriod;
   g_params.wae_fast_ma = InpWAEFastMA;
   g_params.wae_slow_ma = InpWAESlowMA;
   g_params.wae_sensitivity = InpWAESensitivity;
   g_params.use_volume_profile = InpUseVolumeProfile;
   g_params.vp_session_bars = InpVPSessionBars;
   
   // Regime Detection
   g_params.regime_confidence_min = InpRegimeConfidenceMin;
   g_params.regime_votes_min = InpRegimeVotesMin;
   g_params.regime_adx_trend_threshold = InpRegimeADXTrendThreshold;
   g_params.regime_ci_trend_threshold = InpRegimeCITrendThreshold;
   g_params.regime_ci_ranging_threshold = InpRegimeCIRangingThreshold;
   g_params.regime_bbw_squeeze_threshold = InpRegimeBBWSqueezeThreshold;
   g_params.regime_atr_pct_low_threshold = InpRegimeATRPctLowThreshold;
   g_params.regime_atr_pct_high_threshold = InpRegimeATRPctHighThreshold;
   g_params.regime_atr_roc_accel_threshold = InpRegimeATRROCAccelThreshold;
   g_params.regime_atr_roc_decel_threshold = InpRegimeATRROCDecelThreshold;
   g_params.regime_di_dominance_threshold = InpRegimeDIDominanceThreshold;
   
   // Setup Enable/Disable
   g_params.enable_setup_a = InpEnableSetupA;
   g_params.enable_setup_b = InpEnableSetupB;
   g_params.enable_setup_c = InpEnableSetupC;
   g_params.enable_setup_d = InpEnableSetupD;
   g_params.enable_setup_e = InpEnableSetupE;
   g_params.enable_setup_f = InpEnableSetupF;
   
   // Pending Orders
   g_params.pending_timeout_bars = InpPendingTimeoutBars;
   g_params.cancel_pending_on_regime_change = InpCancelPendingOnRegimeChange;
   
   // Debug & Logs
   g_params.enable_debug_logs = InpEnableDebugLogs;
   g_params.debug_log_signals = InpDebugLogSignals;
   g_params.debug_log_execution = InpDebugLogExecution;
   g_params.debug_log_management = InpDebugLogManagement;
   g_params.enable_setup_logs = InpEnableSetupLogs;
   g_params.enable_regime_logs = InpEnableRegimeLogs;
}

void PopulateSetupParameters()
{
   // Initialize all 6 setups with default values
   for(int i = 0; i < 6; i++) {
      ZeroMemory(g_setup_params[i]);
   }
   
   // ========== SETUP A: LIQUIDITY RAID ==========
   
   // Shared params
   g_setup_params[0].liq_lookback_bars = InpSetupA_LiqLookbackBars;
   
   // LONG params
   g_setup_params[0].long_params.liq_sweep_pips = InpSetupA_LiqSweepPips_Long;
   g_setup_params[0].long_params.liq_sl_buffer_pips = InpSetupA_LiqSLBufferPips_Long;
   g_setup_params[0].long_params.liq_di_margin = InpSetupA_LiqDIMargin_Long;
   g_setup_params[0].long_params.liq_wae_threshold = InpSetupA_LiqWAEThreshold_Long;
   g_setup_params[0].long_params.be_activation_r = InpSetupA_BE_ActivationR_Long;
   g_setup_params[0].long_params.be_offset_pips = InpSetupA_BE_OffsetPips_Long;
   g_setup_params[0].long_params.ts_enabled = true;
   g_setup_params[0].long_params.ts_activation_r = InpSetupA_TS_ActivationR_Long;
   g_setup_params[0].long_params.ts_use_atr = true;
   g_setup_params[0].long_params.ts_distance_atr = InpSetupA_TS_DistanceATR_Long;
   g_setup_params[0].long_params.sl_atr_multiplier = InpSetupA_SL_ATRMultiplier_Long;
   g_setup_params[0].long_params.tp_rr_ratio = InpSetupA_TP_RRRatio_Long;
   g_setup_params[0].long_params.tp_use_levels = InpSetupA_TP_UseLevels_Long;
   
   // SHORT params
   g_setup_params[0].short_params.liq_sweep_pips = InpSetupA_LiqSweepPips_Short;
   g_setup_params[0].short_params.liq_sl_buffer_pips = InpSetupA_LiqSLBufferPips_Short;
   g_setup_params[0].short_params.liq_di_margin = InpSetupA_LiqDIMargin_Short;
   g_setup_params[0].short_params.liq_wae_threshold = InpSetupA_LiqWAEThreshold_Short;
   g_setup_params[0].short_params.be_activation_r = InpSetupA_BE_ActivationR_Short;
   g_setup_params[0].short_params.be_offset_pips = InpSetupA_BE_OffsetPips_Short;
   g_setup_params[0].short_params.ts_enabled = true;
   g_setup_params[0].short_params.ts_activation_r = InpSetupA_TS_ActivationR_Short;
   g_setup_params[0].short_params.ts_use_atr = true;
   g_setup_params[0].short_params.ts_distance_atr = InpSetupA_TS_DistanceATR_Short;
   g_setup_params[0].short_params.sl_atr_multiplier = InpSetupA_SL_ATRMultiplier_Short;
   g_setup_params[0].short_params.tp_rr_ratio = InpSetupA_TP_RRRatio_Short;
   g_setup_params[0].short_params.tp_use_levels = InpSetupA_TP_UseLevels_Short;
   
   // TODO: Add Setup B-F parameters (similar structure)
}

bool CreateIndicatorHandles()
{
   string symbol = (InpSymbol == "" ? _Symbol : InpSymbol);
   
   // ADX
   g_h_adx = iADX(symbol, InpTimeframe, InpADXPeriod);
   if(g_h_adx == INVALID_HANDLE) {
      PrintFormat("❌ Failed to create ADX handle");
      return false;
   }
   
   // Choppiness Index (custom)
   g_h_ci = iCustom(symbol, InpTimeframe, "ChoppinessIndex_Professional/ChoppinessIndex_Professional",
                    InpCIPeriod);
   if(g_h_ci == INVALID_HANDLE) {
      PrintFormat("❌ Failed to create CI handle");
      return false;
   }
   
   // Bollinger/Keltner Squeeze (custom)
   g_h_squeeze = iCustom(symbol, InpTimeframe, "BollingerKeltnerSqueeze_Professional/BollingerKeltnerSqueeze_Professional",
                        InpBBPeriod, InpBBDeviation, InpKCPeriod, InpKCMultiplier);
   if(g_h_squeeze == INVALID_HANDLE) {
      PrintFormat("❌ Failed to create Squeeze handle");
      return false;
   }
   
   // ATR Professional (custom)
   g_h_atr = iCustom(symbol, InpTimeframe, "ATR_Professional/ATR_Professional",
                    InpATRPeriod, InpATRROCPeriod);
   if(g_h_atr == INVALID_HANDLE) {
      PrintFormat("❌ Failed to create ATR handle");
      return false;
   }
   
   // WAE (custom)
   g_h_wae = iCustom(symbol, InpTimeframe, "WaddahAttarExplosion_Professional/WaddahAttarExplosion_Professional",
                    InpWAEFastMA, InpWAESlowMA, InpBBPeriod, InpBBDeviation, InpWAESensitivity);
   if(g_h_wae == INVALID_HANDLE) {
      PrintFormat("❌ Failed to create WAE handle");
      return false;
   }
   
   // Volume Profile (custom) - optional
   if(InpUseVolumeProfile) {
      g_h_vp = iCustom(symbol, InpTimeframe, "VolumeProfile_Professional/VolumeProfile_Professional",
                      InpVPSessionBars);
      if(g_h_vp == INVALID_HANDLE) {
         PrintFormat("⚠️ Failed to create VP handle - continuing without VP");
         g_h_vp = INVALID_HANDLE;
      }
   }
   
   PrintFormat("✅ All indicator handles created successfully");
   return true;
}

bool ValidateConfiguration()
{
   // Validate critical parameters
   
   if(InpRiskPercentPerTrade <= 0 || InpRiskPercentPerTrade > 10) {
      PrintFormat("❌ Invalid risk per trade: %.2f%%", InpRiskPercentPerTrade);
      return false;
   }
   
   if(InpMaxDailyRiskPercent < InpRiskPercentPerTrade) {
      PrintFormat("❌ Max daily risk must be >= risk per trade");
      return false;
   }
   
   if(!InpEnableSetupA && !InpEnableSetupB && !InpEnableSetupC && 
      !InpEnableSetupD && !InpEnableSetupE && !InpEnableSetupF) {
      PrintFormat("❌ At least one setup must be enabled");
      return false;
   }
   
   return true;
}

void PrintInitializationStatus()
{
   PrintFormat("========================================");
   PrintFormat("CONFIGURATION STATUS");
   PrintFormat("========================================");
   PrintFormat("📊 Risk: %.2f%% per trade | Max daily: %.2f%% | Max weekly: %.2f%%",
               InpRiskPercentPerTrade, InpMaxDailyRiskPercent, InpMaxWeeklyRiskPercent);
   PrintFormat("📈 Max simultaneous setups: %d | Max trades/day: %d",
               InpMaxSimultaneousSetups, InpMaxTradesPerDay);
   PrintFormat("⏰ Trading hours: %s - %s (UTC%+d)",
               InpStartTime, InpEndTime, InpTimezoneOffset);
   PrintFormat("📅 Trading days: %s %s %s %s %s %s %s",
               InpTradeSunday ? "Sun" : "",
               InpTradeMonday ? "Mon" : "",
               InpTradeTuesday ? "Tue" : "",
               InpTradeWednesday ? "Wed" : "",
               InpTradeThursday ? "Thu" : "",
               InpTradeFriday ? "Fri" : "",
               InpTradeSaturday ? "Sat" : "");
   PrintFormat("🌏 Sessions: %s %s %s",
               InpTradeAsianSession ? "Asian" : "",
               InpTradeLondonSession ? "London" : "",
               InpTradeNewYorkSession ? "NY" : "");
   PrintFormat("🎯 Active Setups: %s%s%s%s%s%s",
               InpEnableSetupA ? "A " : "",
               InpEnableSetupB ? "B " : "",
               InpEnableSetupC ? "C " : "",
               InpEnableSetupD ? "D " : "",
               InpEnableSetupE ? "E " : "",
               InpEnableSetupF ? "F " : "");
}

string GetUninitReasonText(int reason)
{
   switch(reason)
   {
      case REASON_PROGRAM:     return "Program terminated";
      case REASON_REMOVE:      return "EA removed from chart";
      case REASON_RECOMPILE:   return "EA recompiled";
      case REASON_CHARTCHANGE: return "Chart symbol/period changed";
      case REASON_CHARTCLOSE:  return "Chart closed";
      case REASON_PARAMETERS:  return "Input parameters changed";
      case REASON_ACCOUNT:     return "Account changed";
      case REASON_TEMPLATE:    return "Template applied";
      case REASON_INITFAILED:  return "Initialization failed";
      case REASON_CLOSE:       return "Terminal closed";
      default:                 return "Unknown reason";
   }
}
