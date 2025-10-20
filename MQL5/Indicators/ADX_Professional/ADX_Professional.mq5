//+------------------------------------------------------------------+
//| ADX_Professional.mq5                                       |
//| ADX Wilder usando iADX nativo - CONFIÁVEL                        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Adaptive Flow Systems"
#property link      "https://adaptiveflow.systems"
#property version   "2.00"
#property strict

#property indicator_separate_window
#property indicator_plots 3
#property indicator_buffers 3

#property indicator_label1 "ADX"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrDodgerBlue
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2

#property indicator_label2 "+DI"
#property indicator_type2 DRAW_LINE
#property indicator_color2 clrLimeGreen
#property indicator_style2 STYLE_SOLID
#property indicator_width2 1

#property indicator_label3 "-DI"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrTomato
#property indicator_style3 STYLE_SOLID
#property indicator_width3 1

#property indicator_level1 20.0
#property indicator_level2 25.0
#property indicator_level3 40.0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT

input int InpPeriod = 14;

double g_buf_adx[];
double g_buf_plus_di[];
double g_buf_minus_di[];

int g_handle_adx = INVALID_HANDLE;

int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, StringFormat("ADX (Wilder) [%d]", InpPeriod));
   IndicatorSetInteger(INDICATOR_DIGITS, 2);

   SetIndexBuffer(0, g_buf_adx, INDICATOR_DATA);
   SetIndexBuffer(1, g_buf_plus_di, INDICATOR_DATA);
   SetIndexBuffer(2, g_buf_minus_di, INDICATOR_DATA);

   ArraySetAsSeries(g_buf_adx, true);
   ArraySetAsSeries(g_buf_plus_di, true);
   ArraySetAsSeries(g_buf_minus_di, true);

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   // Criar handle do iADX nativo
   g_handle_adx = iADX(_Symbol, PERIOD_CURRENT, InpPeriod);
   
   if(g_handle_adx == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create iADX handle");
      return(INIT_FAILED);
   }

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(g_handle_adx != INVALID_HANDLE)
   {
      IndicatorRelease(g_handle_adx);
      g_handle_adx = INVALID_HANDLE;
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
   if(rates_total < InpPeriod * 2)
      return 0;

   // Copiar TODOS os dados disponíveis (não incremental - mais seguro)
   int to_copy = rates_total;

   // Copiar buffers do iADX
   // Buffer 0 = MAIN_LINE (ADX)
   // Buffer 1 = PLUSDI_LINE (+DI)
   // Buffer 2 = MINUSDI_LINE (-DI)
   
   if(CopyBuffer(g_handle_adx, 0, 0, to_copy, g_buf_adx) <= 0)
   {
      Print("ERROR: Failed to copy ADX buffer");
      return 0;
   }
   
   if(CopyBuffer(g_handle_adx, 1, 0, to_copy, g_buf_plus_di) <= 0)
   {
      Print("ERROR: Failed to copy +DI buffer");
      return 0;
   }
   
   if(CopyBuffer(g_handle_adx, 2, 0, to_copy, g_buf_minus_di) <= 0)
   {
      Print("ERROR: Failed to copy -DI buffer");
      return 0;
   }

   return(rates_total);
}
