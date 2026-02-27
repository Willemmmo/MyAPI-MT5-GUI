//+------------------------------------------------------------------+
//|  GUIManager.mqh  —  Public GUI API entry point                   |
//|  MyAPI v2.0.0                                                    |
//|                                                                  |
//|  USAGE:                                                          |
//|    #include <MyAPI/GUI/GUIManager.mqh>                           |
//|    CGUIManager* gui;                                             |
//|    OnInit()        { gui = new CGUIManager(); gui.Show(); }      |
//|    OnDeinit()      { delete gui; }                               |
//|    OnTick()        { gui.UpdateFromMarket(); gui.Redraw(); }     |
//|    OnChartEvent()  { gui.OnEvent(id,lp,dp,sp); }                |
//+------------------------------------------------------------------+
#ifndef GUIMANAGER_MQH
#define GUIMANAGER_MQH
#include "GUIPanel.mqh"

//+------------------------------------------------------------------+
//| CGUIManager — single public entry point for the GUI              |
//+------------------------------------------------------------------+
class CGUIManager
  {
private:
   CGUIPanel     *m_panel;
   long           m_chartID;
   bool           m_mouseDown;
   bool           m_scrollHandled;
   datetime       m_lastTick;
   int            m_refreshSecs;

   static int     ToInt(long v) { return (int)v; }

public:
                  CGUIManager(string title      = "MyAPI Dashboard",
                              int    x          = 20,
                              int    y          = 30,
                              int    width      = 540,
                              int    height     = 380,
                              string prefix     = "MYAPI_",
                              long   chartID    = 0,
                              int    refreshSec = 1)
     : m_chartID(chartID == 0 ? ChartID() : chartID),
       m_mouseDown(false), m_scrollHandled(false), m_lastTick(0), m_refreshSecs(refreshSec)
     {
      m_panel = new CGUIPanel(m_chartID, prefix, title, x, y, width, height);
     }

                 ~CGUIManager()
     {
      if(m_panel != NULL) { delete m_panel; m_panel = NULL; }
     }

   //--- Tab labels
   void           SetTabLabel(int i, string lbl)
     { if(m_panel != NULL) m_panel.SetTabLabel(i, lbl); }

   void           SetAllTabLabels(string t0,string t1,string t2,string t3,string t4,
                                  string t5,string t6,string t7,string t8,string t9)
     {
      SetTabLabel(0,t0); SetTabLabel(1,t1); SetTabLabel(2,t2); SetTabLabel(3,t3);
      SetTabLabel(4,t4); SetTabLabel(5,t5); SetTabLabel(6,t6); SetTabLabel(7,t7);
      SetTabLabel(8,t8); SetTabLabel(9,t9);
     }

   int            GetActiveTab() const
     { return m_panel != NULL ? m_panel.GetActiveTab() : 0; }

   //--- Status bar
   void           SetSymbol(string sym, string tf)
     { if(m_panel != NULL) m_panel.SetSymbol(sym, tf); }

   void           SetStatusData(bool conn, string price, string spread, string ver)
     { if(m_panel != NULL) m_panel.SetStatusData(conn, price, spread, ver); }

   //--- Account / Overview
   void           SetAccountData(double bal, double eq, double pnl,
                                 double mu, double fm, double wr)
     {
      if(m_panel != NULL && m_panel.Content() != NULL)
         m_panel.Content().SetAccountData(bal, eq, pnl, mu, fm, wr);
     }

   void           SetEquityCurve(double &data[], int cnt)
     {
      if(m_panel != NULL && m_panel.Content() != NULL)
         m_panel.Content().SetEquityCurve(data, cnt);
     }

   //--- Positions
   void           ClearPositions()
     { if(m_panel != NULL && m_panel.Content() != NULL) m_panel.Content().ClearPositions(); }

   void           AddPosition(string sym, string type, double lots,
                              double op, double cp, double sl, double tp,
                              double pnl, ulong tk = 0)
     {
      if(m_panel != NULL && m_panel.Content() != NULL)
         m_panel.Content().AddPosition(sym, type, lots, op, cp, sl, tp, pnl, tk);
     }

   //--- Orders
   void           ClearOrders()
     { if(m_panel != NULL && m_panel.Content() != NULL) m_panel.Content().ClearOrders(); }

   void           AddOrder(string sym, string type, double lots, double at, double sl, double tp)
     {
      if(m_panel != NULL && m_panel.Content() != NULL)
         m_panel.Content().AddOrder(sym, type, lots, at, sl, tp);
     }

   //--- History
   void           ClearHistory()
     { if(m_panel != NULL && m_panel.Content() != NULL) m_panel.Content().ClearHistory(); }

   void           AddHistory(string date, string sym, string type, double lots,
                             double op, double cp, double pnl)
     {
      if(m_panel != NULL && m_panel.Content() != NULL)
         m_panel.Content().AddHistory(date, sym, type, lots, op, cp, pnl);
     }

   //--- Risk
   void           SetRiskData(double rpt, double dd, double dll,
                              double lot, double sharpe, double exp)
     {
      if(m_panel != NULL && m_panel.Content() != NULL)
         m_panel.Content().SetRiskData(rpt, dd, dll, lot, sharpe, exp);
     }

   //--- Signals
   void           ClearSignals()
     { if(m_panel != NULL && m_panel.Content() != NULL) m_panel.Content().ClearSignals(); }

   void           AddSignal(string time, string sym, string dir, int stars, string src)
     {
      if(m_panel != NULL && m_panel.Content() != NULL)
         m_panel.Content().AddSignal(time, sym, dir, stars, src);
     }

   //--- News
   void           ClearNews()
     { if(m_panel != NULL && m_panel.Content() != NULL) m_panel.Content().ClearNews(); }

   void           AddNews(string time, string impact, string cur, string title, string detail)
     {
      if(m_panel != NULL && m_panel.Content() != NULL)
         m_panel.Content().AddNews(time, impact, cur, title, detail);
     }

   //--- Logging
   void           Log(string msg, string lvl = "info")
     {
      if(m_panel == NULL || m_panel.Content() == NULL) return;
      string ts = TimeToString(TimeCurrent(), TIME_SECONDS);
      if(StringLen(ts) >= 8) ts = StringSubstr(ts, StringLen(ts) - 8, 8);
      m_panel.Content().AddLog(ts, lvl, msg);
     }

   void           LogOk   (string msg) { Log(msg, "ok");   }
   void           LogWarn (string msg) { Log(msg, "warn"); }
   void           LogErr  (string msg) { Log(msg, "err");  }
   void           LogInfo (string msg) { Log(msg, "info"); }

   //--- Settings
   void           SetSettings(int magic, double risk, int maxP, bool autoT, bool notif)
     {
      if(m_panel != NULL && m_panel.Content() != NULL)
         m_panel.Content().SetSettings(magic, risk, maxP, autoT, notif);
     }

   //--- About
   void           SetVersionInfo(string ver, string bd)
     {
      if(m_panel != NULL && m_panel.Content() != NULL)
         m_panel.Content().SetVersionInfo(ver, bd);
     }

   //--- Auto-fill from live MT5 market data (throttled)
   void           UpdateFromMarket(string symbol = "")
     {
      if(TimeCurrent() - m_lastTick < (datetime)((long)m_refreshSecs)) return;
      m_lastTick = TimeCurrent();
      if(symbol == "") symbol = _Symbol;

      double bal  = AccountInfoDouble(ACCOUNT_BALANCE);
      double eq   = AccountInfoDouble(ACCOUNT_EQUITY);
      double mu   = AccountInfoDouble(ACCOUNT_MARGIN);
      double fm   = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      SetAccountData(bal, eq, eq - bal, mu, fm, 0.0);

      double bid    = SymbolInfoDouble(symbol, SYMBOL_BID);
      int    digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      double point  = SymbolInfoDouble(symbol, SYMBOL_POINT);
      int    spr    = (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
      SetStatusData(true,
                    DoubleToString(bid, digits),
                    DoubleToString(spr * point / 10.0, 1),
                    "MyAPI v2.0");

      ClearPositions();
      for(int i = 0; i < PositionsTotal(); i++)
        {
         ulong  tk  = PositionGetTicket(i);
         string sym = PositionGetString(POSITION_SYMBOL);
         int    pt  = (int)PositionGetInteger(POSITION_TYPE);
         double lot = PositionGetDouble(POSITION_VOLUME);
         double op  = PositionGetDouble(POSITION_PRICE_OPEN);
         double cp  = PositionGetDouble(POSITION_PRICE_CURRENT);
         double sl  = PositionGetDouble(POSITION_SL);
         double tp  = PositionGetDouble(POSITION_TP);
         double pnl = PositionGetDouble(POSITION_PROFIT);
         AddPosition(sym, pt == POSITION_TYPE_BUY ? "BUY" : "SELL",
                     lot, op, cp, sl, tp, pnl, tk);
        }

      ClearOrders();
      for(int i = 0; i < OrdersTotal(); i++)
        {
         ulong tk = OrderGetTicket(i);
         if(!OrderSelect(tk)) continue;
         string sym  = OrderGetString(ORDER_SYMBOL);
         int    ot   = (int)OrderGetInteger(ORDER_TYPE);
         double lot  = OrderGetDouble(ORDER_VOLUME_INITIAL);
         double at   = OrderGetDouble(ORDER_PRICE_OPEN);
         double sl   = OrderGetDouble(ORDER_SL);
         double tp   = OrderGetDouble(ORDER_TP);
         string ts   = "?";
         switch(ot)
           {
            case ORDER_TYPE_BUY_LIMIT:  ts = "BUY LIMIT";  break;
            case ORDER_TYPE_SELL_LIMIT: ts = "SELL LIMIT"; break;
            case ORDER_TYPE_BUY_STOP:   ts = "BUY STOP";   break;
            case ORDER_TYPE_SELL_STOP:  ts = "SELL STOP";  break;
           }
         AddOrder(sym, ts, lot, at, sl, tp);
        }

      //--- Load real closed trade history (last 90 days)
      ClearHistory();
      datetime histFrom = TimeCurrent() - 90 * 86400;
      HistorySelect(histFrom, TimeCurrent());
      int total = HistoryDealsTotal();
      for(int i = total - 1; i >= 0 && GetHistoryCount() < 100; i--)
        {
         ulong  ticket = HistoryDealGetTicket(i);
         if(ticket == 0) continue;
         int    entry  = (int)HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT) continue;

         string sym    = HistoryDealGetString(ticket,  DEAL_SYMBOL);
         int    dt     = (int)HistoryDealGetInteger(ticket, DEAL_TYPE);
         double lot    = HistoryDealGetDouble(ticket,  DEAL_VOLUME);
         double price  = HistoryDealGetDouble(ticket,  DEAL_PRICE);
         double pnl    = HistoryDealGetDouble(ticket,  DEAL_PROFIT)
                       + HistoryDealGetDouble(ticket,  DEAL_SWAP)
                       + HistoryDealGetDouble(ticket,  DEAL_COMMISSION);
         datetime tm   = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         string   tstr = TimeToString(tm, TIME_DATE | TIME_MINUTES);
         // Shorten: "2025.02.25 09:14" → "25.02 09:14"
         string   day  = StringSubstr(tstr, 8, 2) + "." + StringSubstr(tstr, 5, 2);
         string   hm   = StringSubstr(tstr, 11, 5);
         string   date = day + " " + hm;

         string   type = (dt == DEAL_TYPE_BUY) ? "BUY" : "SELL";

         // Find the matching entry deal to get open price
         double openPrice = price;
         ulong  posID     = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
         for(int j = 0; j < total; j++)
           {
            ulong  tk2 = HistoryDealGetTicket(j);
            if(tk2 == 0) continue;
            if((ulong)HistoryDealGetInteger(tk2, DEAL_POSITION_ID) != posID) continue;
            int en2 = (int)HistoryDealGetInteger(tk2, DEAL_ENTRY);
            if(en2 == DEAL_ENTRY_IN)
              { openPrice = HistoryDealGetDouble(tk2, DEAL_PRICE); break; }
           }

         AddHistory(date, sym, type, lot, openPrice, price, pnl);
        }
     }

   int GetHistoryCount()
     {
      if(m_panel != NULL && m_panel.Content() != NULL)
         return m_panel.Content().GetHistCount();
      return 0;
     }

   //--- Content area coords
   int GetContentX()      const { return m_panel != NULL ? m_panel.GetContentX()      : 0; }
   int GetContentY()      const { return m_panel != NULL ? m_panel.GetContentY()      : 0; }
   int GetContentWidth()  const { return m_panel != NULL ? m_panel.GetContentWidth()  : 0; }
   int GetContentHeight() const { return m_panel != NULL ? m_panel.GetContentHeight() : 0; }

   //--- Lifecycle
   void Show()   { if(m_panel != NULL) m_panel.Show(); }
   void Hide()   { if(m_panel != NULL) m_panel.Hide(); }
   void Redraw() { if(m_panel != NULL) m_panel.Redraw(); }

   //--- Event dispatcher — call from OnChartEvent
   //
   //  In MT5, clicks on OBJ_RECTANGLE_LABEL/OBJ_LABEL fire CHARTEVENT_OBJECT_CLICK,
   //  NOT CHARTEVENT_CLICK. Drag detection must use CHARTEVENT_MOUSE_MOVE button state.
   //  This dispatcher handles all three cases correctly.
   //
   void OnEvent(const int id, const long &lparam,
                const double &dparam, const string &sparam)
     {
      if(m_panel == NULL) return;
      int mx = ToInt(lparam);
      int my = (int)dparam;

      switch(id)
        {
         case CHARTEVENT_MOUSE_MOVE:
           {
            bool btnHeld = ((int)StringToInteger(sparam) & 1) != 0;
            if(!btnHeld)
              {
               // Button released — clear all flags
               if(m_mouseDown) { m_panel.OnMouseUp(mx, my); }
               m_mouseDown     = false;
               m_scrollHandled = false;
              }
            else if(btnHeld && m_scrollHandled)
              {
               // Scrollbar click in progress — ignore drag
              }
            else if(btnHeld && !m_mouseDown)
              {
               m_mouseDown = true;
               m_panel.OnMouseDown(mx, my);
              }
            else if(btnHeld && m_mouseDown)
              {
               m_panel.OnMouseMove(mx, my);
              }
           }
           break;

         case CHARTEVENT_CLICK:
           // Click on empty chart area
           m_mouseDown = true;
           m_panel.OnMouseDown(mx, my);
           break;

         case CHARTEVENT_OBJECT_CLICK:
           if(m_panel != NULL && m_panel.Content() != NULL)
             {
              if(m_panel.Content().OnScrollbarClick(sparam))
                { m_mouseDown = false; m_scrollHandled = true; m_panel.Redraw(); break; }
              if(m_panel.Content().OnButtonClick(sparam))
                { m_mouseDown = false; m_scrollHandled = true; break; }
             }
           m_mouseDown = true;
           m_panel.OnMouseDown(mx, my);
           break;

         case CHARTEVENT_MOUSE_WHEEL:
           // lparam=x, dparam=y, sparam contains delta (as string of integer)
           if(m_panel != NULL && m_panel.Content() != NULL)
             {
              int wheelDelta = (int)StringToInteger(sparam);
              // Normalize: MT5 gives ±120 per notch, we want ±1
              int steps = wheelDelta / 120;
              if(steps == 0) steps = (wheelDelta > 0) ? 1 : -1;
              if(m_panel.Content().OnMouseWheel(mx, my, steps))
                { m_panel.Redraw(); }
             }
           break;
        }
     }
  };

#endif
//+------------------------------------------------------------------+