//+------------------------------------------------------------------+
//| ChoppinessIndex_Profissional.mq5                                    |
//| FIX: Inversão lógica + escala correta                           |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Adaptive Flow Systems"
#property link      "https://adaptiveflow.systems"
#property version   "3.00"
#property strict

#property indicator_separate_window
#property indicator_plots   1
#property indicator_buffers 5
#property indicator_minimum 0
#property indicator_maximum 100

#property indicator_label1  "CI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrOrange
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

// NÍVEIS CORRETOS (fórmula Dreiss INVERTIDA)
#property indicator_level1  20.0   // Ranging FORTE (não trending!)
#property indicator_level2  38.2   // Ranging moderado
#property indicator_level3  61.8   // Trending moderado
#property indicator_level4  80.0   // Trending FORTE (não ranging!)
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT

// -------------------------------------------------------------------
// PARÂMETROS
// -------------------------------------------------------------------
input int    InpPeriod        = 14;        // Período Dreiss
input bool   InpInvertScale   = true;      // Inverter para lógica intuitiva (RECOMENDADO)
input double InpSensitivity   = 1.0;       // Sensibilidade (0.8-1.5)
input bool   InpAdaptiveScale = false;     // Escala adaptativa
input int    InpCalibPeriod   = 200;       // Janela calibração
input int    InpDigits        = 2;

// -------------------------------------------------------------------
// BUFFERS
// -------------------------------------------------------------------
double g_buf_ci[];
double g_buf_tr[];
double g_buf_sumtr[];
double g_buf_pricerange[];
double g_buf_raw_ci[];

double g_ci_min = 0.0;
double g_ci_max = 100.0;

// -------------------------------------------------------------------
// TRUE RANGE
// -------------------------------------------------------------------
double CalculateTrueRange(const int idx, const double &high[], const double &low[], const double &close[])
{
   int prev = idx + 1;
   
   // VALIDAÇÃO CRÍTICA: Verificar limites do array
   if(prev >= (int)ArraySize(close) || prev < 0)
      return (high[idx] - low[idx]);
   
   if(idx >= (int)ArraySize(high) || idx >= (int)ArraySize(low) || idx < 0)
      return 0.0;

   double tr1 = high[idx] - low[idx];
   double tr2 = MathAbs(high[idx] - close[prev]);
   double tr3 = MathAbs(low[idx] - close[prev]);
   return MathMax(tr1, MathMax(tr2, tr3));
}

// -------------------------------------------------------------------
// INVERSÃO INTUITIVA
// -------------------------------------------------------------------
// Fórmula Dreiss: CI alto = choppy, CI baixo = trending
// InpInvertScale=true: inverte para CI alto = trending (mais intuitivo)
double InvertIfNeeded(const double ci_value, const bool invert)
{
   if(!invert)
      return ci_value;
   
   // Inverte em torno de 50: trending vira alto, ranging vira baixo
   return 100.0 - ci_value;
}

// -------------------------------------------------------------------
// INIT
// -------------------------------------------------------------------
int OnInit()
{
   if(InpPeriod < 2)
   {
      Print("ERRO: InpPeriod >= 2");
      return(INIT_FAILED);
   }

   string label = StringFormat("Choppiness [%d]", InpPeriod);
   if(InpInvertScale)
      label += " (Inverted)";
   if(InpAdaptiveScale)
      label += " Adaptive";
   
   IndicatorSetString(INDICATOR_SHORTNAME, label);
   IndicatorSetInteger(INDICATOR_DIGITS, InpDigits);

   SetIndexBuffer(0, g_buf_ci, INDICATOR_DATA);
   SetIndexBuffer(1, g_buf_tr, INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, g_buf_sumtr, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, g_buf_pricerange, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, g_buf_raw_ci, INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrOrange);
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 2);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpPeriod);

   IndicatorSetDouble(INDICATOR_MINIMUM, 0.0);
   IndicatorSetDouble(INDICATOR_MAXIMUM, 100.0);

   ArraySetAsSeries(g_buf_ci, true);
   ArraySetAsSeries(g_buf_tr, true);
   ArraySetAsSeries(g_buf_sumtr, true);
   ArraySetAsSeries(g_buf_pricerange, true);
   ArraySetAsSeries(g_buf_raw_ci, true);

   return(INIT_SUCCEEDED);
}

// -------------------------------------------------------------------
// CALCULATE
// -------------------------------------------------------------------
int OnCalculate(
   const int        rates_total,
   const int        prev_calculated,
   const datetime  &time[],
   const double    &open[],
   const double    &high[],
   const double    &low[],
   const double    &close[],
   const long      &tick_volume[],
   const long      &volume[],
   const int       &spread[])
{
   if(rates_total < InpPeriod + 1)
      return 0;

   // CRÍTICO: Configurar arrays de preço como series
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   
   ArraySetAsSeries(g_buf_ci, true);
   ArraySetAsSeries(g_buf_tr, true);
   ArraySetAsSeries(g_buf_sumtr, true);
   ArraySetAsSeries(g_buf_pricerange, true);
   ArraySetAsSeries(g_buf_raw_ci, true);

   // CÁLCULO INCREMENTAL CORRETO: Apenas novas barras
   int start = prev_calculated - 1;
   if(start < InpPeriod) start = InpPeriod;
   
   // Loop de 0 (barra atual) até start (barras já calculadas)
   for(int i = 0; i < start; i++)
   {
      // Calcular TR para esta barra
      g_buf_tr[i] = CalculateTrueRange(i, high, low, close);
   }
   
   // Loop principal: de start até 0 (arrays series)
   for(int i = start; i >= 0 && !IsStopped(); i--)
   {
      double sum_tr = 0.0;
      double hhv = -DBL_MAX;
      double llv = DBL_MAX;

      // Janela: [i .. i+InpPeriod-1]
      for(int j = 0; j < InpPeriod; j++)
      {
         int k = i + j;
         if(k >= rates_total) break;

         sum_tr += g_buf_tr[k];
         if(high[k] > hhv) hhv = high[k];
         if(low[k] < llv) llv = low[k];
      }

      double price_range = hhv - llv;
      g_buf_sumtr[i] = sum_tr;
      g_buf_pricerange[i] = price_range;

      // EDGE CASES
      if(hhv == llv && sum_tr == 0.0)
      {
         g_buf_raw_ci[i] = 50.0;
         continue;
      }

      if(price_range <= 0.0)
      {
         g_buf_raw_ci[i] = 100.0;
         continue;
      }

      if(sum_tr <= 0.0)
      {
         g_buf_raw_ci[i] = 0.0;
         continue;
      }

      // FÓRMULA DREISS EXATA
      double ratio = sum_tr / price_range;
      double log_ratio = MathLog10(ratio);
      double log_period = MathLog10((double)InpPeriod);
      
      if(log_period <= 0.0)
      {
         g_buf_raw_ci[i] = 50.0;
         continue;
      }

      double ci_raw = 100.0 * (log_ratio / log_period);
      ci_raw = 50.0 + (ci_raw - 50.0) * InpSensitivity;
      ci_raw = MathMax(0.0, MathMin(100.0, ci_raw));
      g_buf_raw_ci[i] = ci_raw;
   }

   // CALIBRAÇÃO ADAPTATIVA (opcional)
   if(InpAdaptiveScale && rates_total >= InpCalibPeriod + InpPeriod)
   {
      int calib_start = MathMin(InpCalibPeriod, rates_total - InpPeriod);
      g_ci_min = DBL_MAX;
      g_ci_max = -DBL_MAX;

      for(int i=0; i<calib_start; i++)
      {
         int bi = i;
         double val = g_buf_raw_ci[bi];
         
         if(val == EMPTY_VALUE) continue;
         
         if(val < g_ci_min) g_ci_min = val;
         if(val > g_ci_max) g_ci_max = val;
      }

      double range = g_ci_max - g_ci_min;
      g_ci_min -= range * 0.05;
      g_ci_max += range * 0.05;
   }
   else
   {
      g_ci_min = 0.0;
      g_ci_max = 100.0;
   }

   // NORMALIZAÇÃO + INVERSÃO
   // Iterar de start até 0 (arrays series)
   for(int i = start; i >= 0; i--)
   {
      if(g_buf_raw_ci[i] == EMPTY_VALUE)
      {
         g_buf_ci[i] = EMPTY_VALUE;
         continue;
      }

      double ci_normalized = g_buf_raw_ci[i];
      
      // Normalizar se adaptativo
      if(InpAdaptiveScale && g_ci_max > g_ci_min)
      {
         ci_normalized = 100.0 * (g_buf_raw_ci[i] - g_ci_min) / (g_ci_max - g_ci_min);
         ci_normalized = MathMax(0.0, MathMin(100.0, ci_normalized));
      }
      
      // INVERSÃO INTUITIVA
      g_buf_ci[i] = InvertIfNeeded(ci_normalized, InpInvertScale);
   }

   // Primeiras barras (período inicial sem dados suficientes)
   for(int i = rates_total - 1; i > start; i--)
   {
      g_buf_ci[i] = EMPTY_VALUE;
      g_buf_raw_ci[i] = EMPTY_VALUE;
   }

   return(rates_total);
}
//+------------------------------------------------------------------+