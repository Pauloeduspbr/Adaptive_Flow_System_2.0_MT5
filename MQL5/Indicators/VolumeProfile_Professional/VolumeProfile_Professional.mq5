//+------------------------------------------------------------------+
//| VolumeProfile_Professional.mq5                             |
//| Volume Profile com POC/VAH/VAL - Session Based - OTIMIZADO      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Adaptive Flow Systems"
#property link      "https://adaptiveflow.systems"
#property version   "2.00"
#property strict

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots 3

#property indicator_label1  "POC"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMagenta
#property indicator_width1  3
#property indicator_style1  STYLE_SOLID

#property indicator_label2  "VAH"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_width2  2
#property indicator_style2  STYLE_DASH

#property indicator_label3  "VAL"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrOrangeRed
#property indicator_width3  2
#property indicator_style3  STYLE_DASH

input int InpLookbackBars = 100;
input int InpBinSizePips = 10;
input bool InpUseSessionBased = true;

double g_buf_poc[];
double g_buf_vah[];
double g_buf_val[];

datetime g_last_calculation_date = 0;
double g_cached_poc = 0.0;
double g_cached_vah = 0.0;
double g_cached_val = 0.0;

struct SVolumeNode
{
   double price;
   long volume;
};

int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, StringFormat("Volume Profile [Bars:%d]", InpLookbackBars));

   SetIndexBuffer(0, g_buf_poc, INDICATOR_DATA);
   SetIndexBuffer(1, g_buf_vah, INDICATOR_DATA);
   SetIndexBuffer(2, g_buf_val, INDICATOR_DATA);

   ArraySetAsSeries(g_buf_poc, true);
   ArraySetAsSeries(g_buf_vah, true);
   ArraySetAsSeries(g_buf_val, true);

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);

   return(INIT_SUCCEEDED);
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
   if(rates_total < InpLookbackBars)
      return 0;

   ArraySetAsSeries(time, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(tick_volume, true);

   // Recalcular apenas 1x por dia
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime current_date = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));

   bool need_recalc = (current_date != g_last_calculation_date);

   if(need_recalc)
   {
      // Calcular volume profile
      if(!CalculateVolumeProfile(InpLookbackBars, high, low, tick_volume))
      {
         Print("ERROR: Failed to calculate volume profile");
         return 0;
      }

      g_last_calculation_date = current_date;
   }

   // Preencher buffers com valores cached
   int start = prev_calculated - 1;
   if(start < 0) start = 0;

   for(int i = start; i >= 0; i--)
   {
      g_buf_poc[i] = g_cached_poc;
      g_buf_vah[i] = g_cached_vah;
      g_buf_val[i] = g_cached_val;
   }

   return(rates_total);
}

bool CalculateVolumeProfile(int lookback, const double &high[], const double &low[], const long &tick_vol[])
{
   // Encontrar range de preço
   double highest = high[0];
   double lowest = low[0];

   for(int i = 1; i < lookback && i < ArraySize(high); i++)
   {
      if(high[i] > highest) highest = high[i];
      if(low[i] < lowest) lowest = low[i];
   }

   double price_range = highest - lowest;
   if(price_range == 0.0)
   {
      Print("WARNING: Zero price range for volume profile");
      return false;
   }

   // Calcular bin size
   double bin_size = InpBinSizePips * _Point;
   int num_bins = (int)MathCeil(price_range / bin_size);

   if(num_bins <= 0 || num_bins > 10000)
   {
      PrintFormat("ERROR: Invalid bin count %d", num_bins);
      return false;
   }

   // Criar array de nodes
   SVolumeNode nodes[];
   ArrayResize(nodes, num_bins);

   for(int i = 0; i < num_bins; i++)
   {
      nodes[i].price = lowest + (i * bin_size);
      nodes[i].volume = 0;
   }

   // Distribuir volume
   for(int bar = 0; bar < lookback && bar < ArraySize(high); bar++)
   {
      double bar_high = high[bar];
      double bar_low = low[bar];
      long bar_volume = tick_vol[bar];

      for(int bin = 0; bin < num_bins; bin++)
      {
         if(nodes[bin].price >= bar_low && nodes[bin].price <= bar_high)
         {
            nodes[bin].volume += bar_volume;
         }
      }
   }

   // Encontrar POC
   long max_volume = 0;
   int poc_index = 0;

   for(int i = 0; i < num_bins; i++)
   {
      if(nodes[i].volume > max_volume)
      {
         max_volume = nodes[i].volume;
         poc_index = i;
      }
   }

   g_cached_poc = nodes[poc_index].price;

   // Calcular Value Area (70%)
   long total_volume = 0;
   for(int i = 0; i < num_bins; i++)
      total_volume += nodes[i].volume;

   long value_area_volume = (long)(total_volume * 0.70);

   int upper_idx = poc_index;
   int lower_idx = poc_index;
   long accumulated_volume = nodes[poc_index].volume;

   while(accumulated_volume < value_area_volume)
   {
      long vol_above = (upper_idx + 1 < num_bins) ? nodes[upper_idx + 1].volume : 0;
      long vol_below = (lower_idx - 1 >= 0) ? nodes[lower_idx - 1].volume : 0;

      if(vol_above > vol_below && upper_idx + 1 < num_bins)
      {
         upper_idx++;
         accumulated_volume += nodes[upper_idx].volume;
      }
      else if(lower_idx - 1 >= 0)
      {
         lower_idx--;
         accumulated_volume += nodes[lower_idx].volume;
      }
      else
      {
         break;
      }
   }

   g_cached_vah = nodes[upper_idx].price;
   g_cached_val = nodes[lower_idx].price;

   PrintFormat("Volume Profile updated: POC=%.5f | VAH=%.5f | VAL=%.5f", 
               g_cached_poc, g_cached_vah, g_cached_val);

   return true;
}
