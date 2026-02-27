//+------------------------------------------------------------------+
//|  DemoGUI.mq5  —  Demo EA for MyAPI GUI v2.0                     |
//|                                                                  |
//|  INSTALL:                                                        |
//|  1. Copy the 5 .mqh files into:                                 |
//|       MQL5/Include/MyAPI/GUI/                                    |
//|  2. Copy this file into:                                         |
//|       MQL5/Experts/MyAPI/                                        |
//|  3. Compile & attach to any chart                               |
//+------------------------------------------------------------------+
#property copyright "MyAPI"
#property version   "2.00"
#property strict

#include <MyAPI/GUI/GUIManager.mqh>

//--- EA inputs
input int    InpMagicNumber   = 12345;   // Magic Number
input double InpRiskPct       = 1.0;     // Risk per Trade (%)
input int    InpMaxPositions  = 5;       // Max Open Positions
input bool   InpAutoTrading   = true;    // Enable Auto-Trading
input bool   InpNotifications = false;   // Enable Notifications
input int    InpPanelX        = 20;      // Panel X
input int    InpPanelY        = 30;      // Panel Y
input int    InpPanelWidth    = 540;     // Panel Width
input int    InpPanelHeight   = 380;     // Panel Height

CGUIManager *gui;
datetime     g_lastRefresh = 0;

//+------------------------------------------------------------------+
int OnInit()
  {
   gui = new CGUIManager(
            "MyAPI Dashboard",
            InpPanelX, InpPanelY,
            InpPanelWidth, InpPanelHeight
         );

   gui.SetAllTabLabels(
      "Overview","Positions","Orders","History","Risk",
      "Signals","News","Settings","Logs","About"
   );

   string tf = PeriodToStr((ENUM_TIMEFRAMES)Period());
   gui.SetSymbol(_Symbol, tf);
   gui.SetVersionInfo("2.0.0", TimeToString(TimeCurrent(), TIME_DATE));
   gui.SetSettings(InpMagicNumber, InpRiskPct, InpMaxPositions,
                   InpAutoTrading, InpNotifications);

   LoadDemoData();

   gui.Show();

   // Enable mouse move events so drag and button-hover work
   // The '1' at the end means: all subwindows
   ChartSetInteger(ChartID(), CHART_EVENT_MOUSE_MOVE, 1);

   gui.LogInfo("EA initialized — MyAPI Dashboard v2.0.0");
   gui.LogOk  ("GUI loaded successfully");

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(gui != NULL) { delete gui; gui = NULL; }
   ChartRedraw();
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   if(gui == NULL) return;
   if(TimeCurrent() - g_lastRefresh < 1) return;
   g_lastRefresh = TimeCurrent();

   gui.UpdateFromMarket(_Symbol);

   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   gui.SetRiskData(InpRiskPct, 4.2, bal * 0.02,
                   bal * InpRiskPct / 100.0 / 1000.0, 1.84, 3.0);
   gui.Redraw();
  }

//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam,
                  const double &dparam, const string &sparam)
  {
   if(gui != NULL) gui.OnEvent(id, lparam, dparam, sparam);
  }

//+------------------------------------------------------------------+
void LoadDemoData()
  {
   //--- Overview
   gui.SetAccountData(10420.0, 10218.0, -202.40, 310.0, 9908.0, 68.4);
   double curve[14] = {48,52,49,55,53,60,57,63,61,66,64,70,68,74};
   gui.SetEquityCurve(curve, 14);

   //--- Positions
   gui.ClearPositions();
   gui.AddPosition("EURUSD", "BUY",  0.10, 1.08412, 1.08380, 1.08200, 1.08700,  -3.20, 10284);
   gui.AddPosition("GBPUSD", "SELL", 0.20, 1.26810, 1.26740, 1.27100, 1.26400, +14.00, 10283);
   gui.AddPosition("USDJPY", "BUY",  0.05, 149.820, 149.755, 149.500, 150.500,  -2.18, 10282);

   //--- Orders
   gui.ClearOrders();
   gui.AddOrder("EURUSD", "BUY LIMIT",  0.10, 1.08100, 1.07900, 1.08600);
   gui.AddOrder("XAUUSD", "SELL STOP",  0.05, 1978.00, 1985.00, 1960.00);

   //--- History
   gui.ClearHistory();
   gui.AddHistory("25.02 09:14", "EURUSD", "SELL", 0.10, 1.08620, 1.08410, +21.00);
   gui.AddHistory("24.02 16:42", "GBPJPY", "BUY",  0.20, 189.120, 188.980, -18.40);
   gui.AddHistory("24.02 11:07", "USDJPY", "BUY",  0.10, 149.440, 149.820, +25.30);
   gui.AddHistory("23.02 14:22", "EURUSD", "BUY",  0.15, 1.08110, 1.08380, +40.50);
   gui.AddHistory("23.02 09:05", "GBPUSD", "SELL", 0.10, 1.26950, 1.26700, +25.00);

   //--- Risk
   gui.SetRiskData(1.0, 4.2, 200.0, 0.12, 1.84, 3.0);

   //--- Signals
   gui.ClearSignals();
   gui.AddSignal("09:32", "EURUSD", "BUY",  4, "MA Cross");
   gui.AddSignal("09:15", "GBPUSD", "SELL", 3, "RSI Div");
   gui.AddSignal("08:58", "USDJPY", "BUY",  5, "Breakout");
   gui.AddSignal("08:30", "XAUUSD", "BUY",  3, "Support");
   gui.AddSignal("08:10", "EURJPY", "SELL", 2, "Trend");

   //--- News
   gui.ClearNews();
   gui.AddNews("14:30 UTC", "HIGH", "USD", "Fed Interest Rate Decision",
               "Forecast: 5.50%  |  Previous: 5.50%");
   gui.AddNews("09:00 UTC", "MED",  "EUR", "ECB Monthly Bulletin",
               "Published monthly");
   gui.AddNews("12:30 UTC", "LOW",  "GBP", "UK Claimant Count Change",
               "Forecast: 5.3K  |  Previous: 14.1K");

   //--- Settings
   gui.SetSettings(InpMagicNumber, InpRiskPct, InpMaxPositions,
                   InpAutoTrading, InpNotifications);

   //--- Logs
   gui.LogOk  ("Buy EURUSD 0.10 @ 1.08412 — ticket #10284");
   gui.LogInfo ("Signal detected: MA Cross on EURUSD H1");
   gui.LogWarn ("Spread elevated on GBPUSD: 2.4 pips");
   gui.LogOk   ("Sell GBPUSD 0.20 @ 1.26810 — ticket #10283");
   gui.LogInfo ("Session open — London market active");
   gui.LogOk   ("Buy USDJPY 0.05 @ 149.820 — ticket #10282");
   gui.LogInfo ("Risk check passed — drawdown 4.20%");
   gui.LogErr  ("Connection retry #1 — reconnected OK");
  }

//+------------------------------------------------------------------+
string PeriodToStr(ENUM_TIMEFRAMES tf)
  {
   switch(tf)
     {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN";
      default:         return "?";
     }
  }
//+------------------------------------------------------------------+