//+------------------------------------------------------------------+
//| Prop_News_Base.mq5                                               |
//| Institutional Dark News Terminal - Professional Base             |
//+------------------------------------------------------------------+
#property strict
#property version "1.00"

//================ THEME =================
color BG_MAIN        = (color)0x0B0F14;
color BG_PANEL       = (color)0x121821;
color BG_HEADER      = (color)0x161E27;
color BG_ROW         = (color)0x121821;
color BG_ROW_ALT     = (color)0x0F141B;
color BG_ROW_HOVER   = (color)0x1B2530;
color BORDER_LINE    = (color)0x1F2A36;

color TEXT_MAIN      = (color)0xE6EDF3;
color TEXT_SUB       = (color)0x7D8590;

color ACCENT_BLUE    = (color)0x2F81F7;
color ACCENT_RED     = (color)0xF85149;
color ACCENT_AMBER   = (color)0xD29922;

//================ LAYOUT =================
#define HEADER_H 56
#define ROW_H 30
#define MAX_VISIBLE 18

int winX=60;
int winY=30;
int winW=1100;
int winH=700;

int colTime=20;
int colCurr=120;
int colImpact=200;
int colCountdown=280;
int colEvent=360;

//================ SCROLL =================
int scrollTarget=0;
double smoothScroll=0;

//================ SORT =================
int sortMode=0;
bool sortAsc=true;

//================ DATA =================
struct NewsItem
{
   datetime time;
   string currency;
   string title;
   int impact;
};

NewsItem news[500];
int total=0;

//+------------------------------------------------------------------+
int OnInit()
{
   EventSetTimer(1);
   LoadCalendar();
   BuildUI();
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0,"base_");
}
//+------------------------------------------------------------------+

//================ LOAD =================
void LoadCalendar()
{
   total=0;

   MqlCalendarValue vals[];
   if(!CalendarValueHistory(vals,TimeCurrent(),TimeCurrent()+86400))
      return;

   for(int i=0;i<ArraySize(vals) && total<500;i++)
   {
      MqlCalendarEvent ev;
      if(!CalendarEventById(vals[i].event_id,ev)) continue;

      MqlCalendarCountry c;
      if(!CalendarCountryById(ev.country_id,c)) continue;

      news[total].time=vals[i].time;
      news[total].currency=c.currency;
      news[total].title=ev.name;
      news[total].impact=ev.importance;
      total++;
   }

   SortData();
}
//+------------------------------------------------------------------+
void SortData()
{
   for(int i=0;i<total-1;i++)
      for(int j=i+1;j<total;j++)
      {
         bool swap=false;

         if(sortMode==0)
            swap = sortAsc ? news[i].time>news[j].time :
                             news[i].time<news[j].time;

         if(sortMode==1)
            swap = sortAsc ? news[i].impact>news[j].impact :
                             news[i].impact<news[j].impact;

         if(sortMode==2)
            swap = sortAsc ? news[i].currency>news[j].currency :
                             news[i].currency<news[j].currency;

         if(swap)
         {
            NewsItem t=news[i];
            news[i]=news[j];
            news[j]=t;
         }
      }
}
//+------------------------------------------------------------------+

//================ UI =================
void BuildUI()
{
   CreateRect("base_bg",winX,winY,winW,winH,BG_MAIN);
   CreateRect("base_panel",winX,winY,winW,winH,BG_PANEL);
   CreateRect("base_header",winX,winY,winW,HEADER_H,BG_HEADER);

   CreateSeparator(winY+HEADER_H);

   CreateHeader("TIME",0,colTime);
   CreateHeader("CURR",2,colCurr);
   CreateHeader("IMPACT",1,colImpact);
   CreateHeader("T-",3,colCountdown);
   CreateHeader("EVENT",4,colEvent);

   CreateScrollbar();
}
//+------------------------------------------------------------------+
void CreateHeader(string text,int mode,int offset)
{
   string id="base_hdr_"+text;

   ObjectCreate(0,id,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,id,OBJPROP_XDISTANCE,winX+offset);
   ObjectSetInteger(0,id,OBJPROP_YDISTANCE,winY+20);

   string arrow="";
   if(sortMode==mode)
      arrow = sortAsc ? " ▲" : " ▼";

   ObjectSetString(0,id,OBJPROP_TEXT,text+arrow);
   ObjectSetString(0,id,OBJPROP_FONT,"Segoe UI");
   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,id,OBJPROP_COLOR,TEXT_SUB);
   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,true);
}
//+------------------------------------------------------------------+
void CreateSeparator(int y)
{
   CreateRect("base_sep",winX,y,winW,1,BORDER_LINE);
}
//+------------------------------------------------------------------+

//================ TIMER =================
void OnTimer()
{
   smoothScroll += (scrollTarget - smoothScroll)*0.18;
   Render();
}
//+------------------------------------------------------------------+

//================ RENDER =================
void Render()
{
   int baseY = winY + HEADER_H + 6;

   for(int i=0;i<MAX_VISIBLE;i++)
   {
      int index=i+(int)smoothScroll;
      string base="base_row_"+IntegerToString(i);

      if(index>=total)
      {
         ObjectsDeleteAll(0,base);
         continue;
      }

      int y=baseY+i*ROW_H;

      color rowColor = (i%2==0)?BG_ROW:BG_ROW_ALT;

      CreateRect(base+"_bg",winX,y,winW-8,ROW_H,rowColor);

      CreateLabel(base+"_time",
         TimeToString(news[index].time,TIME_MINUTES),
         winX+colTime,y+8,TEXT_MAIN);

      CreateLabel(base+"_curr",
         news[index].currency,
         winX+colCurr,y+8,TEXT_SUB);

      string impact="LOW";
      color ic=ACCENT_BLUE;
      if(news[index].impact==1){impact="MED";ic=ACCENT_AMBER;}
      if(news[index].impact==2){impact="HIGH";ic=ACCENT_RED;}

      CreateBadge(base+"_impact",impact,
                  winX+colImpact,y+6,ic);

      int seconds=(int)(news[index].time-TimeCurrent());
      string cd = seconds>0 ? IntegerToString(seconds) : "LIVE";

      CreateLabel(base+"_count",
                  cd,
                  winX+colCountdown,y+8,
                  seconds<=10?ACCENT_RED:TEXT_SUB);

      CreateLabel(base+"_event",
                  news[index].title,
                  winX+colEvent,y+8,TEXT_MAIN);
   }

   UpdateScrollbar();
   ChartRedraw();
}
//+------------------------------------------------------------------+

//================ SCROLL =================
void OnChartEvent(const int id,
                  const long &l,
                  const double &d,
                  const string &s)
{
   if(id==CHARTEVENT_MOUSE_WHEEL)
   {
      if(l<0 && scrollTarget<total-MAX_VISIBLE) scrollTarget++;
      if(l>0 && scrollTarget>0) scrollTarget--;
   }

   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      if(StringFind(s,"base_hdr_")==0)
      {
         if(StringFind(s,"TIME")>0) sortMode=0;
         if(StringFind(s,"IMPACT")>0) sortMode=1;
         if(StringFind(s,"CURR")>0) sortMode=2;

         sortAsc=!sortAsc;
         SortData();
         BuildUI();
      }
   }
}
//+------------------------------------------------------------------+

//================ HELPERS =================
void CreateRect(string name,int x,int y,int w,int h,color c)
{
   ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
}
//+------------------------------------------------------------------+
void CreateLabel(string name,string text,int x,int y,color c)
{
   ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetString(0,name,OBJPROP_FONT,"Segoe UI");
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
}
//+------------------------------------------------------------------+
void CreateBadge(string name,string text,int x,int y,color c)
{
   ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,70);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,18);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);

   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetString(0,name,OBJPROP_FONT,"Segoe UI");
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
}
//+------------------------------------------------------------------+
void CreateScrollbar()
{
   CreateRect("base_scroll_track",
              winX+winW-6,
              winY+HEADER_H,
              4,
              winH-HEADER_H,
              BORDER_LINE);
}
//+------------------------------------------------------------------+
void UpdateScrollbar()
{
   if(total<=MAX_VISIBLE) return;

   double ratio=(double)MAX_VISIBLE/total;
   int thumbH=(int)((winH-HEADER_H)*ratio);

   int scrollArea=winH-HEADER_H-thumbH;

   int thumbY=winY+HEADER_H+
              (int)(scrollArea*((double)scrollTarget/(total-MAX_VISIBLE)));

   CreateRect("base_scroll_thumb",
              winX+winW-6,
              thumbY,
              4,
              thumbH,
              ACCENT_BLUE);
}
//+------------------------------------------------------------------+