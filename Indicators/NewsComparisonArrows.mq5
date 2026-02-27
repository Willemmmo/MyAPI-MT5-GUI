//+------------------------------------------------------------------+
//| NewsComparisonArrows.mq5                                         |
//| Gebaseerd op NewsComparisonDashboard structuur                   |
//| Tekent nieuws pijlen op chart (verleden + toekomst)              |
//+------------------------------------------------------------------+
#property copyright "NewsComparisonArrows"
#property version   "3.00"
#property indicator_chart_window
#property indicator_plots 0

//+------------------------------------------------------------------+
// Inputs
//+------------------------------------------------------------------+
input int    DaysBack        = 10;
input int    DaysForward     = 3;
input bool   UseHighImpact   = true;
input bool   UseMediumImpact = true;
input bool   UseLowImpact    = false;
input int    ATR_Period      = 14;
input double ATR_Multiplier  = 0.4;
input int    RefreshSeconds  = 120;

//+------------------------------------------------------------------+
// Struct (zelfde stijl als dashboard)
//+------------------------------------------------------------------+
struct NewsEvent
{
   string   currency;
   string   name;
   string   impact;
   datetime event_time;
   double   forecast;
   double   actual;
};

//+------------------------------------------------------------------+
NewsEvent events[];
ulong     drawn_ids[];
int       atrHandle = INVALID_HANDLE;
datetime  last_refresh = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   atrHandle = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
   if(atrHandle == INVALID_HANDLE)
      return INIT_FAILED;

   EventSetTimer(RefreshSeconds);
   FetchCalendar();
   DrawArrows();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0,"NCA_");
   if(atrHandle!=INVALID_HANDLE)
      IndicatorRelease(atrHandle);
}

int OnCalculate(const int r,const int p,const datetime&t[],
                const double&o[],const double&h[],
                const double&l[],const double&c[],
                const long&tv[],const long&v[],
                const int&s[])
{
   return r;
}

void OnTimer()
{
   FetchCalendar();
   DrawArrows();
}

//+------------------------------------------------------------------+
// Currency helpers
//+------------------------------------------------------------------+
string BaseCurrency()  { return StringSubstr(_Symbol,0,3); }
string QuoteCurrency() { return StringSubstr(_Symbol,3,3); }

//+------------------------------------------------------------------+
// Impact filter
//+------------------------------------------------------------------+
bool ImpactAllowed(ENUM_CALENDAR_EVENT_IMPORTANCE imp)
{
   if(imp==CALENDAR_IMPORTANCE_HIGH     && UseHighImpact)   return true;
   if(imp==CALENDAR_IMPORTANCE_MODERATE && UseMediumImpact) return true;
   if(imp==CALENDAR_IMPORTANCE_LOW      && UseLowImpact)    return true;
   return false;
}

//+------------------------------------------------------------------+
// Fetch calendar (zoals dashboard maar historisch)
//+------------------------------------------------------------------+
void FetchCalendar()
{
   ArrayResize(events,0);

   datetime from = TimeCurrent() - DaysBack*86400;
   datetime to   = TimeCurrent() + DaysForward*86400;

   MqlCalendarValue values[];
   if(!CalendarValueHistory(values,from,to))
      return;

   for(int i=0;i<ArraySize(values);i++)
   {
      MqlCalendarEvent   event_info;
      MqlCalendarCountry country_info;

      if(!CalendarEventById(values[i].event_id,event_info))      continue;
      if(!CalendarCountryById(event_info.country_id,country_info)) continue;

      string cur = country_info.currency;

      if(cur!=BaseCurrency() && cur!=QuoteCurrency())
         continue;

      if(!ImpactAllowed(event_info.importance))
         continue;

      if(values[i].forecast_value==LONG_MIN ||
         values[i].actual_value  ==LONG_MIN)
         continue;

      double factor = MathPow(10,event_info.digits);

      int idx = ArraySize(events);
      ArrayResize(events,idx+1);

      events[idx].currency   = cur;
      events[idx].name       = event_info.name;
      events[idx].impact     = EnumToString(event_info.importance);
      events[idx].event_time = values[i].time;
      events[idx].forecast   = values[i].forecast_value/factor;
      events[idx].actual     = values[i].actual_value/factor;
   }
}

//+------------------------------------------------------------------+
// Draw arrows
//+------------------------------------------------------------------+
void DrawArrows()
{
   ObjectsDeleteAll(0,"NCA_");

   for(int i=0;i<ArraySize(events);i++)
   {
      int bar = iBarShift(_Symbol,PERIOD_CURRENT,events[i].event_time,false);
      if(bar<0 || bar>=Bars(_Symbol,PERIOD_CURRENT))
         continue;

      double atr[];
      if(CopyBuffer(atrHandle,0,bar,1,atr)<=0)
         continue;

      double price;
      int arrow;
      color clr;

      if(events[i].actual > events[i].forecast)
      {
         price = iLow(_Symbol,PERIOD_CURRENT,bar)
                 - atr[0]*ATR_Multiplier;
         arrow = 233;
         clr   = clrLime;
      }
      else if(events[i].actual < events[i].forecast)
      {
         price = iHigh(_Symbol,PERIOD_CURRENT,bar)
                 + atr[0]*ATR_Multiplier;
         arrow = 234;
         clr   = clrRed;
      }
      else
      {
         price = iClose(_Symbol,PERIOD_CURRENT,bar);
         arrow = 241;
         clr   = clrOrange;
      }

      string name="NCA_"+IntegerToString(i);

      if(ObjectCreate(0,name,OBJ_ARROW,0,
         iTime(_Symbol,PERIOD_CURRENT,bar),price))
      {
         ObjectSetInteger(0,name,OBJPROP_ARROWCODE,arrow);
         ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
         ObjectSetInteger(0,name,OBJPROP_WIDTH,2);
      }
   }

   ChartRedraw();
}
//+------------------------------------------------------------------+