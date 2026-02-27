//+------------------------------------------------------------------+
//|                    NewsPairArrows_V2_PRO                         |
//|                 Build 5640 SAFE VERSION                          |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_plots 0

//================ INPUTS =================//
input int    DaysBack        = 10;
input int    DaysForward     = 3;
input bool   UseHighImpact   = true;
input bool   UseMediumImpact = true;
input bool   UseLowImpact    = false;
input int    ATR_Period      = 14;
input double ATR_Multiplier  = 0.4;

//================ GLOBALS =================//
datetime last_update=0;
ulong drawnEvents[];
int atrHandle=INVALID_HANDLE;

//+------------------------------------------------------------------+
int OnInit()
{
   atrHandle = iATR(_Symbol,PERIOD_CURRENT,ATR_Period);
   if(atrHandle==INVALID_HANDLE)
      return(INIT_FAILED);

   EventSetTimer(120);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();

   if(atrHandle!=INVALID_HANDLE)
      IndicatorRelease(atrHandle);
}
//+------------------------------------------------------------------+
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
   return(rates_total);
}
//+------------------------------------------------------------------+
void OnTimer()
{
   if(TimeCurrent()-last_update>300)
   {
      LoadNews();
      last_update=TimeCurrent();
   }
}
//+------------------------------------------------------------------+
bool EventAlreadyDrawn(ulong id)
{
   for(int i=0;i<ArraySize(drawnEvents);i++)
      if(drawnEvents[i]==id)
         return true;

   return false;
}
//+------------------------------------------------------------------+
void AddDrawnEvent(ulong id)
{
   int size=ArraySize(drawnEvents);
   ArrayResize(drawnEvents,size+1);
   drawnEvents[size]=id;
}
//+------------------------------------------------------------------+
bool ImpactAllowed(int importance)
{
   if(importance==2 && UseHighImpact) return true;
   if(importance==1 && UseMediumImpact) return true;
   if(importance==0 && UseLowImpact) return true;
   return false;
}
//+------------------------------------------------------------------+
void ProcessCurrency(string currency)
{
   datetime from = TimeCurrent()-DaysBack*86400;
   datetime to   = TimeCurrent()+DaysForward*86400;

   MqlCalendarValue values[];
   int total = CalendarValueHistory(values,from,to,currency);

   if(total<=0)
      return;

   for(int i=0;i<total;i++)
   {
      if(EventAlreadyDrawn(values[i].event_id))
         continue;

      MqlCalendarEvent event;
      if(!CalendarEventById(values[i].event_id,event))
         continue;

      if(!ImpactAllowed(event.importance))
         continue;

      if(values[i].forecast_value==LONG_MIN ||
         values[i].actual_value==LONG_MIN)
         continue;

      double factor=MathPow(10,event.digits);

      double forecast=values[i].forecast_value/factor;
      double actual  =values[i].actual_value/factor;

      datetime news_time=values[i].time;

      int bar=iBarShift(_Symbol,PERIOD_CURRENT,news_time,true);
      if(bar<0)
         continue;

      double atr[];
      if(CopyBuffer(atrHandle,0,bar,1,atr)<=0)
         continue;

      double price;
      color clr;
      int arrow;

      if(actual>forecast)
      {
         price=iLow(_Symbol,PERIOD_CURRENT,bar)
               - atr[0]*ATR_Multiplier;
         clr=clrLime;
         arrow=233;
      }
      else if(actual<forecast)
      {
         price=iHigh(_Symbol,PERIOD_CURRENT,bar)
               + atr[0]*ATR_Multiplier;
         clr=clrRed;
         arrow=234;
      }
      else
      {
         price=iClose(_Symbol,PERIOD_CURRENT,bar);
         clr=clrOrange;
         arrow=241;
      }

      string name="NEWS_PRO_"+IntegerToString(values[i].event_id);

      if(ObjectCreate(0,name,OBJ_ARROW,0,news_time,price))
      {
         ObjectSetInteger(0,name,OBJPROP_ARROWCODE,arrow);
         ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
         ObjectSetInteger(0,name,OBJPROP_WIDTH,2);
      }

      AddDrawnEvent(values[i].event_id);
   }
}
//+------------------------------------------------------------------+
void LoadNews()
{
   string base  = StringSubstr(_Symbol,0,3);
   string quote = StringSubstr(_Symbol,3,3);

   ProcessCurrency(base);
   ProcessCurrency(quote);
}
//+------------------------------------------------------------------+