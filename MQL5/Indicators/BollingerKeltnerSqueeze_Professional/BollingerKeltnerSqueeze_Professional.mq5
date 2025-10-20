//+------------------------------------------------------------------+
//| BollingerKeltnerSqueeze_Professional.mq5                   |
//| BB + KC usando iBands + iMA + iATR nativos - CONFIÁVEL          |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Adaptive Flow Systems"
#property link      "https://adaptiveflow.systems"
#property version   "2.00"
#property strict

#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots 7

#property indicator_label1  "BB Upper"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRoyalBlue
#property indicator_width1  1
#property indicator_style1  STYLE_DOT

#property indicator_label2  "BB Middle"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRoyalBlue
#property indicator_width2  1

#property indicator_label3  "BB Lower"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRoyalBlue
#property indicator_width3  1
#property indicator_style3  STYLE_DOT

#property indicator_label4  "KC Upper"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrCrimson
#property indicator_width4  1
#property indicator_style4  STYLE_DOT

#property indicator_label5  "KC Middle"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrCrimson
#property indicator_width5  1

#property indicator_label6  "KC Lower"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrCrimson
#property indicator_width6  1
#property indicator_style6  STYLE_DOT

#property indicator_label7  "Squeeze"
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrYellow
#property indicator_width7  3

input int InpBBPeriod = 20;
input double InpBBDeviation = 2.0;
input int InpKCPeriod = 20;
input double InpKCMultiplier = 1.5;

double g_buf_bb_upper[];
double g_buf_bb_middle[];
double g_buf_bb_lower[];
double g_buf_kc_upper[];
double g_buf_kc_middle[];
double g_buf_kc_lower[];
double g_buf_squeeze[];

int g_handle_bb = INVALID_HANDLE;
int g_handle_kc_ema = INVALID_HANDLE;
int g_handle_atr = INVALID_HANDLE;

int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, StringFormat("BB/KC Squeeze [BB:%d | KC:%d]", InpBBPeriod, InpKCPeriod));

   SetIndexBuffer(0, g_buf_bb_upper, INDICATOR_DATA);
   SetIndexBuffer(1, g_buf_bb_middle, INDICATOR_DATA);
   SetIndexBuffer(2, g_buf_bb_lower, INDICATOR_DATA);
   SetIndexBuffer(3, g_buf_kc_upper, INDICATOR_DATA);
   SetIndexBuffer(4, g_buf_kc_middle, INDICATOR_DATA);
   SetIndexBuffer(5, g_buf_kc_lower, INDICATOR_DATA);
   SetIndexBuffer(6, g_buf_squeeze, INDICATOR_DATA);

   ArraySetAsSeries(g_buf_bb_upper, true);
   ArraySetAsSeries(g_buf_bb_middle, true);
   ArraySetAsSeries(g_buf_bb_lower, true);
   ArraySetAsSeries(g_buf_kc_upper, true);
   ArraySetAsSeries(g_buf_kc_middle, true);
   ArraySetAsSeries(g_buf_kc_lower, true);
   ArraySetAsSeries(g_buf_squeeze, true);

   PlotIndexSetInteger(6, PLOT_ARROW, 159);
   PlotIndexSetDouble(6, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   // Criar handles nativos
   g_handle_bb = iBands(_Symbol, PERIOD_CURRENT, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   g_handle_kc_ema = iMA(_Symbol, PERIOD_CURRENT, InpKCPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_handle_atr = iATR(_Symbol, PERIOD_CURRENT, InpKCPeriod);

   if(g_handle_bb == INVALID_HANDLE || g_handle_kc_ema == INVALID_HANDLE || g_handle_atr == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create indicator handles");
      return(INIT_FAILED);
   }

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(g_handle_bb != INVALID_HANDLE) IndicatorRelease(g_handle_bb);
   if(g_handle_kc_ema != INVALID_HANDLE) IndicatorRelease(g_handle_kc_ema);
   if(g_handle_atr != INVALID_HANDLE) IndicatorRelease(g_handle_atr);
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
   if(rates_total < InpBBPeriod)
      return 0;

   // Copiar TODOS os dados disponíveis (não incremental - mais seguro)
   int to_copy = rates_total;

   // Copiar Bollinger Bands (buffer 1=upper, 0=base, 2=lower)
   if(CopyBuffer(g_handle_bb, 1, 0, to_copy, g_buf_bb_upper) <= 0)
   {
      Print("ERROR: Failed to copy BB upper");
      return 0;
   }
   if(CopyBuffer(g_handle_bb, 0, 0, to_copy, g_buf_bb_middle) <= 0)
   {
      Print("ERROR: Failed to copy BB middle");
      return 0;
   }
   if(CopyBuffer(g_handle_bb, 2, 0, to_copy, g_buf_bb_lower) <= 0)
   {
      Print("ERROR: Failed to copy BB lower");
      return 0;
   }

   // Copiar EMA (Keltner Middle)
   if(CopyBuffer(g_handle_kc_ema, 0, 0, to_copy, g_buf_kc_middle) <= 0)
   {
      Print("ERROR: Failed to copy KC EMA");
      return 0;
   }

   // Copiar ATR
   double atr_buffer[];
   ArraySetAsSeries(atr_buffer, true);
   if(CopyBuffer(g_handle_atr, 0, 0, to_copy, atr_buffer) <= 0)
   {
      Print("ERROR: Failed to copy ATR");
      return 0;
   }

   // Validar tamanho dos arrays copiados
   if(ArraySize(atr_buffer) < InpKCPeriod)
   {
      Print("ERROR: Insufficient data copied from indicators");
      return 0;
   }

   // Calcular Keltner Channels
   int start = prev_calculated - 1;
   if(start < InpKCPeriod) start = InpKCPeriod;

   for(int i = start; i >= 0; i--)
   {
      // Validar índice dentro dos limites
      if(i >= ArraySize(atr_buffer)) continue;

      g_buf_kc_upper[i] = g_buf_kc_middle[i] + (InpKCMultiplier * atr_buffer[i]);
      g_buf_kc_lower[i] = g_buf_kc_middle[i] - (InpKCMultiplier * atr_buffer[i]);

      // Detectar Squeeze: BB dentro de KC
      bool squeeze = (g_buf_bb_upper[i] < g_buf_kc_upper[i] && 
                      g_buf_bb_lower[i] > g_buf_kc_lower[i]);

      if(squeeze)
         g_buf_squeeze[i] = g_buf_bb_middle[i]; // Desenha ponto amarelo no meio
      else
         g_buf_squeeze[i] = EMPTY_VALUE;
   }

   return(rates_total);
}
