//+------------------------------------------------------------------+
//| ATR_Professional.mq5                                       |
//| ATR usando iATR nativo + ATR% + ROC - CONFIÁVEL                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Adaptive Flow Systems"
#property link      "https://adaptiveflow.systems"
#property version   "2.00"
#property strict

#property indicator_separate_window
#property indicator_plots 3
#property indicator_buffers 3

#property indicator_label1  "ATR"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_width1  2

#property indicator_label2  "ATR%"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrange
#property indicator_width2  2

#property indicator_label3  "ATR ROC/10"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDodgerBlue
#property indicator_width3  1
#property indicator_style3  STYLE_DOT

// Nível zero para ROC
#property indicator_level1  0.0
#property indicator_levelcolor clrDimGray
#property indicator_levelstyle STYLE_DOT
#property indicator_levelwidth 1

input int InpATRPeriod = 14;
input int InpROCPeriod = 5;

double g_buf_atr[];
double g_buf_atr_pct[];
double g_buf_atr_roc[];

int g_handle_atr = INVALID_HANDLE;

int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, StringFormat("ATR Pro [P:%d | ROC:%d]", InpATRPeriod, InpROCPeriod));
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   SetIndexBuffer(0, g_buf_atr, INDICATOR_DATA);
   SetIndexBuffer(1, g_buf_atr_pct, INDICATOR_DATA);
   SetIndexBuffer(2, g_buf_atr_roc, INDICATOR_DATA);

   ArraySetAsSeries(g_buf_atr, true);
   ArraySetAsSeries(g_buf_atr_pct, true);
   ArraySetAsSeries(g_buf_atr_roc, true);

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   // Criar handle do iATR nativo
   g_handle_atr = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
   
   if(g_handle_atr == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create iATR handle");
      return(INIT_FAILED);
   }

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(g_handle_atr != INVALID_HANDLE)
   {
      IndicatorRelease(g_handle_atr);
      g_handle_atr = INVALID_HANDLE;
   }
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < InpATRPeriod + InpROCPeriod)
      return 0;

   ArraySetAsSeries(close, true);

   // Copiar TODOS os dados disponíveis (não incremental - mais seguro)
   int to_copy = rates_total;

   // Copiar ATR do indicador nativo
   if(CopyBuffer(g_handle_atr, 0, 0, to_copy, g_buf_atr) <= 0)
   {
      Print("ERROR: Failed to copy ATR buffer");
      return 0;
   }

   // Validar tamanho do buffer copiado
   if(ArraySize(g_buf_atr) < InpATRPeriod)
   {
      Print("ERROR: Insufficient ATR data copied");
      return 0;
   }

   // Calcular apenas novas barras
   int start = prev_calculated - 1;
   if(start < InpATRPeriod) start = InpATRPeriod;

   for(int i = start; i >= 0; i--)
   {
      // Validar índice dentro dos limites
      if(i >= rates_total) continue;
      // ATR%
      if(close[i] != 0.0)
         g_buf_atr_pct[i] = (g_buf_atr[i] / close[i]) * 100.0;
      else
         g_buf_atr_pct[i] = 0.0;

      // ATR ROC - ESCALAR POR 10 para equilibrar escala visual
      int past_idx = i + InpROCPeriod;
      if(past_idx < rates_total && g_buf_atr[past_idx] != 0.0 && g_buf_atr[past_idx] != EMPTY_VALUE)
         g_buf_atr_roc[i] = (((g_buf_atr[i] - g_buf_atr[past_idx]) / g_buf_atr[past_idx]) * 100.0) / 10.0;
      else
         g_buf_atr_roc[i] = 0.0;
   }

   return(rates_total);
}
