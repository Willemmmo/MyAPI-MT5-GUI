//+------------------------------------------------------------------+
//| NewsComparisonDashboard_Institutional.mq5                        |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_plots 1
#property indicator_label1 "dummy"
#property indicator_type1 DRAW_NONE
#property strict

double dummyBuffer[];

//================ PANEL =================
int PanelWidth=1100;
int PanelHeight=600;

int g_panelX=30;
int g_panelY=30;

int g_minWidth=900;
int g_minHeight=400;

bool g_resizing=false;
int g_resizeStartX=0;
int g_resizeStartY=0;

string g_tabs[5]={"USD","EUR","GBP","JPY","CAD"};
string g_currentTab="USD";

int g_scroll=0;

//================ NEWS =================
struct NewsItem
{
   string currency;
   string title;
   datetime time;
   double forecast;
   int impact;
};

NewsItem g_news[200];
int g_total=0;

//================ INIT =================
int OnInit()
{
   SetIndexBuffer(0,dummyBuffer,INDICATOR_DATA);
   EventSetTimer(1);
   CreatePanel();
   CreateTabs();
   LoadCalendar();
   DrawTable();
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0,"");
   EventKillTimer();
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
   LoadCalendar();
   DrawTable();
}
//+------------------------------------------------------------------+

//================ CALENDAR =================
void LoadCalendar()
{
   g_total=0;

   MqlCalendarValue values[];
   datetime from=TimeCurrent();
   datetime to=TimeCurrent()+86400;

   if(!CalendarValueHistory(values,from,to))
      return;

   int count=ArraySize(values);

   for(int i=0;i<count && g_total<200;i++)
   {
      MqlCalendarEvent event;
      if(!CalendarEventById(values[i].event_id,event))
         continue;

      if(event.currency!=g_currentTab)
         continue;

      g_news[g_total].currency=event.currency;
      g_news[g_total].title=event.name;
      g_news[g_total].time=values[i].time;
      g_news[g_total].forecast=values[i].forecast;
      g_news[g_total].impact=event.importance;

      g_total++;
   }

   // SORT OP TIJD
   for(int i=0;i<g_total-1;i++)
   {
      for(int j=i+1;j<g_total;j++)
      {
         if(g_news[j].time<g_news[i].time)
         {
            NewsItem tmp=g_news[i];
            g_news[i]=g_news[j];
            g_news[j]=tmp;
         }
      }
   }
}

//================ PANEL =================
void CreatePanel()
{
   if(ObjectFind(0,"bg")<0)
      ObjectCreate(0,"bg",OBJ_RECTANGLE_LABEL,0,0,0);

   ObjectSetInteger(0,"bg",OBJPROP_XDISTANCE,g_panelX);
   ObjectSetInteger(0,"bg",OBJPROP_YDISTANCE,g_panelY);
   ObjectSetInteger(0,"bg",OBJPROP_XSIZE,PanelWidth);
   ObjectSetInteger(0,"bg",OBJPROP_YSIZE,PanelHeight);
   ObjectSetInteger(0,"bg",OBJPROP_COLOR,clrBlack);

   if(ObjectFind(0,"titlebar")<0)
      ObjectCreate(0,"titlebar",OBJ_RECTANGLE_LABEL,0,0,0);

   ObjectSetInteger(0,"titlebar",OBJPROP_XDISTANCE,g_panelX);
   ObjectSetInteger(0,"titlebar",OBJPROP_YDISTANCE,g_panelY);
   ObjectSetInteger(0,"titlebar",OBJPROP_XSIZE,PanelWidth);
   ObjectSetInteger(0,"titlebar",OBJPROP_YSIZE,40);
   ObjectSetInteger(0,"titlebar",OBJPROP_COLOR,C'20,20,20');

   CreateLabel("title",
               g_panelX+15,
               g_panelY+12,
               "News Dashboard Institutional",
               clrWhite,12);
}

//================ TABS =================
void CreateTabs()
{
   int startX=g_panelX+15;
   int y=g_panelY+50;

   for(int i=0;i<5;i++)
   {
      string name="tab_"+g_tabs[i];

      if(ObjectFind(0,name)<0)
         ObjectCreate(0,name,OBJ_BUTTON,0,0,0);

      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,startX+i*100);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,name,OBJPROP_XSIZE,90);
      ObjectSetInteger(0,name,OBJPROP_YSIZE,28);
      ObjectSetString(0,name,OBJPROP_TEXT,g_tabs[i]);

      if(g_currentTab==g_tabs[i])
         ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'0,100,180');
      else
         ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'40,40,40');
   }
}

//================ TABLE =================
void DrawTable()
{
   int startY=g_panelY+100;
   int rowH=30;

   for(int i=0;i<g_total;i++)
   {
      int y=startY+(i-g_scroll)*rowH;

      if(y<startY || y>g_panelY+PanelHeight-40)
         continue;

      // GRID
      string grid="grid_"+IntegerToString(i);
      if(ObjectFind(0,grid)<0)
         ObjectCreate(0,grid,OBJ_RECTANGLE_LABEL,0,0,0);

      ObjectSetInteger(0,grid,OBJPROP_XDISTANCE,g_panelX+10);
      ObjectSetInteger(0,grid,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,grid,OBJPROP_XSIZE,PanelWidth-20);
      ObjectSetInteger(0,grid,OBJPROP_YSIZE,1);
      ObjectSetInteger(0,grid,OBJPROP_COLOR,C'50,50,50');

      // TITLE
      CreateLabel("t"+IntegerToString(i),
                  g_panelX+20,
                  y+6,
                  g_news[i].title,
                  clrWhite,9);

      // FORECAST
      string fc=DoubleToString(g_news[i].forecast,2);
      CreateLabel("f"+IntegerToString(i),
                  g_panelX+550,
                  y+6,
                  fc,
                  clrWhite,9);

      // COUNTDOWN
      int sec=(int)(g_news[i].time-TimeCurrent());
      if(sec<0) sec=0;
      string cd=IntegerToString(sec/60)+"m "+
                IntegerToString(sec%60)+"s";

      CreateLabel("c"+IntegerToString(i),
                  g_panelX+700,
                  y+6,
                  cd,
                  clrWhite,9);

      // IMPACT
      color ic=clrGreen;
      if(g_news[i].impact==1) ic=clrOrange;
      if(g_news[i].impact>=2) ic=clrRed;

      // HIGH IMPACT PULSE
      if(g_news[i].impact>=2 && (TimeCurrent()%2)==0)
         ic=clrWhite;

      string impactTxt="LOW";
      if(g_news[i].impact==1) impactTxt="MED";
      if(g_news[i].impact>=2) impactTxt="HIGH";

      CreateLabel("imp"+IntegerToString(i),
                  g_panelX+850,
                  y+6,
                  impactTxt,
                  ic,9);
   }

   ChartRedraw();
}

//================ LABEL =================
void CreateLabel(string name,int x,int y,string text,color c,int size)
{
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);

   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
}

//================ EVENTS =================
void OnChartEvent(const int id,const long &l,const double &d,const string &s)
{
   if(id==CHARTEVENT_MOUSE_WHEEL)
   {
      if(l<0 && g_scroll<g_total-1) g_scroll++;
      if(l>0 && g_scroll>0) g_scroll--;
      DrawTable();
   }

   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      if(StringFind(s,"tab_")==0)
      {
         g_currentTab=StringSubstr(s,4);
         g_scroll=0;
         LoadCalendar();
         DrawTable();
      }
   }

   if(id==CHARTEVENT_MOUSE_MOVE && g_resizing)
   {
      PanelWidth=MathMax(g_minWidth,
                  PanelWidth+((int)l-g_resizeStartX));
      PanelHeight=MathMax(g_minHeight,
                   PanelHeight+((int)d-g_resizeStartY));

      g_resizeStartX=(int)l;
      g_resizeStartY=(int)d;

      CreatePanel();
      CreateTabs();
      DrawTable();
   }
}
//+------------------------------------------------------------------+