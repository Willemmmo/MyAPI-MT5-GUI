//+------------------------------------------------------------------+
//|  DemoCleanGUI.mq5  —  CleanGUI demo EA                             |
//|  Gebruik dit als startpunt voor je eigen EA                      |
//+------------------------------------------------------------------+
#property copyright "MyAPI"
#property version   "1.00"
#property strict

#include <MyAPI\CleanGUI\CleanGUI_Manager.mqh>

//--- Input parameters
input int    InpPanelX      = 20;
input int    InpPanelY      = 30;
input int    InpPanelWidth  = 540;
input int    InpPanelHeight = 380;

CCleanGUI_Manager *gui;

int OnInit()
  {
   gui = new CCleanGUI_Manager(
            "CleanGUI Dashboard",
            InpPanelX, InpPanelY,
            InpPanelWidth, InpPanelHeight
         );

   // Tab labels aanpassen naar wens
   gui.SetAllTabLabels(
      "Tab 1","Tab 2","Tab 3","Tab 4","Tab 5",
      "Tab 6","Tab 7","Tab 8","Tab 9","Tab 10"
   );

   gui.SetSymbol(_Symbol, EnumToString((ENUM_TIMEFRAMES)Period()));
   gui.Show();
   gui.Redraw();
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   if(gui != NULL) { delete gui; gui = NULL; }
  }

void OnTick()
  {
   // Voeg hier je tick-logica toe
   // gui.UpdateFromMarket();
  }

void OnChartEvent(const int id, const long &lparam,
                  const double &dparam, const string &sparam)
  {
   if(gui != NULL) gui.OnEvent(id, lparam, dparam, sparam);
  }
//+------------------------------------------------------------------+