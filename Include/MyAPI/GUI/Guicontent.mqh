//+------------------------------------------------------------------+
//|  GUIContent.mqh  —  Per-tab content renderer                     |
//|  MyAPI v2.0.0                                                    |
//+------------------------------------------------------------------+
#ifndef GUICONTENT_MQH
#define GUICONTENT_MQH
#include "GUIBase.mqh"
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//|  Data structures                                                  |
//+------------------------------------------------------------------+
struct SPosition
  {
   string   symbol;
   string   type;
   double   lots;
   double   openPrice;
   double   currentPrice;
   double   sl;
   double   tp;
   double   pnl;
   ulong    ticket;
  };

struct SOrder
  {
   string   symbol;
   string   type;
   double   lots;
   double   atPrice;
   double   sl;
   double   tp;
  };

struct SHistoryTrade
  {
   string   date;
   string   symbol;
   string   type;
   double   lots;
   double   openPrice;
   double   closePrice;
   double   pnl;
  };

struct SSignal
  {
   string   time;
   string   symbol;
   string   direction;
   int      stars;
   string   source;
  };

struct SNewsItem
  {
   string   time;
   string   impact;
   string   currency;
   string   title;
   string   detail;
  };

struct SLogLine
  {
   string   timestamp;
   string   level;
   string   message;
  };

//+------------------------------------------------------------------+
//|  CGUIContent — standalone content renderer (no base inheritance) |
//+------------------------------------------------------------------+
class CGUIContent
  {
private:
   long           m_chartID;
   string         m_prefix;

   //--- Trade execution
   CTrade         m_trade;

   //--- Content area geometry
   int            m_cx, m_cy, m_cw, m_ch;
   int            m_activeTab;

   //--- Overview data
   double         m_balance;
   double         m_equity;
   double         m_openPnL;
   double         m_marginUsed;
   double         m_marginFree;
   double         m_winRate;
   double         m_equityCurve[14];

   //--- Positions
   SPosition      m_positions[10];
   int            m_posCount;

   //--- Orders
   SOrder         m_orders[10];
   int            m_orderCount;

   //--- History
   SHistoryTrade  m_history[100];  // store up to 100 real trades
   int            m_histCount;

   //--- History sort/filter state
   int            m_histSortCol;   // which column is sorted (-1 = none)
   bool           m_histSortAsc;   // true = ascending
   int            m_histSortClickY; // y-position of header for hit-test

   //--- Scroll offsets (first visible row per tab)
   int            m_scrollPos;
   int            m_scrollPosArr[4];

   //--- Thumb drag state
   bool           m_thumbDragging;
   int            m_thumbDragTab;
   int            m_thumbDragStartY;   // mouse Y when drag started
   int            m_thumbDragStartSc;  // scroll offset when drag started

   //--- Risk
   double         m_riskPerTrade;
   double         m_maxDrawdown;
   double         m_dailyLossLimit;
   double         m_lotSizeCalc;
   double         m_sharpeRatio;
   double         m_exposure;

   //--- Signals
   SSignal        m_signals[10];
   int            m_sigCount;

   //--- News
   SNewsItem      m_news[10];
   int            m_newsCount;

   //--- Logs
   SLogLine       m_logs[50];
   int            m_logCount;

   //--- Settings
   int            m_magicNumber;
   double         m_settingsRisk;
   int            m_maxPositions;
   bool           m_autoTrading;
   bool           m_notifications;

   //--- About
   string         m_version;
   string         m_buildDate;

   //+----------------------------------------------------------------+
   //|  Own draw primitives (duplicate of CGUIBase helpers)           |
   //|  Required because CGUIContent is standalone (no inheritance)   |
   //+----------------------------------------------------------------+
   void           R(string tag, int x, int y, int w, int h,
                    color bg, color brd, int bw = 1, int z = 10)
     {
      string n = m_prefix + "c_" + tag;
      if(ObjectFind(m_chartID, n) < 0)
        {
         ObjectCreate(m_chartID, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
         ObjectSetInteger(m_chartID, n, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(m_chartID, n, OBJPROP_HIDDEN,     true);
        }
      ObjectSetInteger(m_chartID, n, OBJPROP_CORNER,       CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartID, n, OBJPROP_XDISTANCE,    x);
      ObjectSetInteger(m_chartID, n, OBJPROP_YDISTANCE,    y);
      ObjectSetInteger(m_chartID, n, OBJPROP_XSIZE,        MathMax(1, w));
      ObjectSetInteger(m_chartID, n, OBJPROP_YSIZE,        MathMax(1, h));
      ObjectSetInteger(m_chartID, n, OBJPROP_BGCOLOR,      bg);
      ObjectSetInteger(m_chartID, n, OBJPROP_BORDER_COLOR, brd);
      ObjectSetInteger(m_chartID, n, OBJPROP_BORDER_TYPE,  BORDER_FLAT);
      ObjectSetInteger(m_chartID, n, OBJPROP_WIDTH,        bw);
      ObjectSetInteger(m_chartID, n, OBJPROP_ZORDER,       z);
     }

   void           L(string tag, int x, int y, string text,
                    color clr, int fs = 9, string font = "Segoe UI",
                    int z = 11, int anchor = ANCHOR_LEFT_UPPER)
     {
      string n = m_prefix + "c_" + tag;
      if(ObjectFind(m_chartID, n) < 0)
        {
         ObjectCreate(m_chartID, n, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(m_chartID, n, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(m_chartID, n, OBJPROP_HIDDEN,     true);
        }
      ObjectSetInteger(m_chartID, n, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartID, n, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(m_chartID, n, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(m_chartID, n, OBJPROP_COLOR,     clr);
      ObjectSetInteger(m_chartID, n, OBJPROP_FONTSIZE,  fs);
      ObjectSetString (m_chartID, n, OBJPROP_FONT,      font);
      ObjectSetString (m_chartID, n, OBJPROP_TEXT,      text);
      ObjectSetInteger(m_chartID, n, OBJPROP_ANCHOR,    anchor);
      ObjectSetInteger(m_chartID, n, OBJPROP_ZORDER,    z);
     }

   void           ClearContent()
     {
      string search = m_prefix + "c_";
      int total = ObjectsTotal(m_chartID);
      for(int i = total - 1; i >= 0; i--)
        {
         string name = ObjectName(m_chartID, i);
         if(StringFind(name, search) == 0)
            ObjectDelete(m_chartID, name);
        }
     }

   //--- Helpers
   color          PnLColor(double v) { return v >= 0.0 ? COL_GREEN : COL_RED; }

   color          BadgeColor(string type)
     {
      if(StringFind(type, "BUY")  >= 0) return COL_GREEN;
      if(StringFind(type, "SELL") >= 0) return COL_RED;
      return COL_YELLOW;
     }

   string         Stars(int n)
     {
      string s = "";
      for(int i = 0; i < 5; i++) s += (i < n) ? "* " : ". ";
      return s;
     }

   string         SignedStr(double v, int digits = 2)
     {
      string s = DoubleToString(MathAbs(v), digits);
      return (v >= 0.0) ? ("+" + s) : ("-" + s);
     }

   //--- Stat card (used in Overview + Risk)
   void           DrawCard(string tag, int x, int y, int w, int h,
                           string lbl, string val, color valCol,
                           string sub = "", color subCol = COL_GREEN)
     {
      R("card_" + tag, x, y, w, h, COL_BG_CARD, COL_BORDER_CARD, 1, 10);
      L("clbl_" + tag, x + 8, y + 6,  lbl, COL_TEXT_LABEL, 8, "Segoe UI",  11);
      L("cval_" + tag, x + 8, y + 20, val, valCol,         11, "Courier New", 11);
      if(sub != "")
         L("csub_" + tag, x + 8, y + h - 13, sub, subCol, 8, "Segoe UI", 11);
     }

   //--- Table header row
   void           DrawHeader(string tag, int y, int rh,
                             int &colX[], int &colW[], string &hdrs[], int cols)
     {
      R("th_" + tag, m_cx, y, m_cw, rh, COL_BG_CARD, COL_BORDER_CARD, 1, 10);
      for(int c = 0; c < cols; c++)
         L("th_" + tag + IntegerToString(c),
           colX[c] + 4, y + (rh - 8) / 2,
           hdrs[c], COL_TEXT_LABEL, 8, "Segoe UI", 11);
      R("thl_" + tag, m_cx, y + rh - 1, m_cw, 1, COL_BORDER_CARD, COL_BORDER_CARD, 0, 10);
     }

   //--- Table data row
   void           DrawRow(string tag, int row, int y, int rh,
                          int &colX[], string &cells[], color &clrs[], int cols)
     {
      R("tr_" + tag + IntegerToString(row),
        m_cx, y, m_cw, rh, COL_BG_CONTENT, COL_BORDER_CARD, 0, 10);
      for(int c = 0; c < cols; c++)
         L("td_" + tag + IntegerToString(row) + "_" + IntegerToString(c),
           colX[c] + 4, y + (rh - 8) / 2,
           cells[c], clrs[c], 9, "Courier New", 11);
      R("trl_" + tag + IntegerToString(row),
        m_cx, y + rh - 1, m_cw, 1, C'30,45,70', C'30,45,70', 0, 10);
     }

   //+----------------------------------------------------------------+
   //|  Scrollbar helpers                                              |
   //+----------------------------------------------------------------+

   //--- Draw a vertical scrollbar on the right edge of the content area
   //    tabIdx: 0=Positions,1=Orders,2=History,3=Logs
   //    totalRows: total number of rows in the list
   //    rowH: pixel height of one row
   //    headerH: pixel height of the header above the list
   //--- Helper: create a fresh rect (delete first so creation order = visual order)
   void           SBRect(string n, int x, int y, int w, int h,
                         color bg, color brd, int bw, bool clickable=false)
     {
      if(ObjectFind(m_chartID, n) >= 0) ObjectDelete(m_chartID, n);
      ObjectCreate(m_chartID, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartID, n, OBJPROP_SELECTABLE,   clickable);
      ObjectSetInteger(m_chartID, n, OBJPROP_HIDDEN,       true);
      ObjectSetInteger(m_chartID, n, OBJPROP_CORNER,       CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartID, n, OBJPROP_XDISTANCE,    x);
      ObjectSetInteger(m_chartID, n, OBJPROP_YDISTANCE,    y);
      ObjectSetInteger(m_chartID, n, OBJPROP_XSIZE,        MathMax(1,w));
      ObjectSetInteger(m_chartID, n, OBJPROP_YSIZE,        MathMax(1,h));
      ObjectSetInteger(m_chartID, n, OBJPROP_BGCOLOR,      bg);
      ObjectSetInteger(m_chartID, n, OBJPROP_BORDER_COLOR, brd);
      ObjectSetInteger(m_chartID, n, OBJPROP_BORDER_TYPE,  BORDER_FLAT);
      ObjectSetInteger(m_chartID, n, OBJPROP_WIDTH,        bw);
      ObjectSetInteger(m_chartID, n, OBJPROP_ZORDER,       50);
     }

   void           SBLabel(string n, int x, int y, string txt, color clr)
     {
      if(ObjectFind(m_chartID, n) >= 0) ObjectDelete(m_chartID, n);
      ObjectCreate(m_chartID, n, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartID, n, OBJPROP_SELECTABLE,  false);
      ObjectSetInteger(m_chartID, n, OBJPROP_HIDDEN,      true);
      ObjectSetInteger(m_chartID, n, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartID, n, OBJPROP_XDISTANCE,   x);
      ObjectSetInteger(m_chartID, n, OBJPROP_YDISTANCE,   y);
      ObjectSetString (m_chartID, n, OBJPROP_TEXT,        txt);
      ObjectSetInteger(m_chartID, n, OBJPROP_COLOR,       clr);
      ObjectSetInteger(m_chartID, n, OBJPROP_FONTSIZE,    9);
      ObjectSetString (m_chartID, n, OBJPROP_FONT,        "Segoe UI Bold");
      ObjectSetInteger(m_chartID, n, OBJPROP_ANCHOR,      ANCHOR_CENTER);
      ObjectSetInteger(m_chartID, n, OBJPROP_ZORDER,      51);
     }

   //--- Draw scrollbar AFTER all rows so it is always on top visually
   void           DrawScrollbar(int tabIdx, int totalRows, int rowH, int headerH)
     {
      int sbW    = 14;
      int sbX    = m_cx + m_cw - sbW;
      int sbY    = m_cy + headerH;
      int sbH    = m_ch - headerH;
      int arrowH = 16;
      if(sbH < 30) return;

      int visRows = sbH / MathMax(rowH, 1);
      if(totalRows <= visRows) return;

      string pfx = m_prefix + "c_sb" + IntegerToString(tabIdx);

      // Track
      SBRect(pfx+"trk", sbX, sbY, sbW, sbH, C'18,25,45', C'70,110,190', 1);

      // Up arrow
      SBRect(pfx+"up",  sbX, sbY, sbW, arrowH, C'45,80,150', C'100,150,240', 1, true);
      SBLabel(pfx+"ula", sbX+sbW/2, sbY+arrowH/2, "^", C'220,240,255');

      // Down arrow
      SBRect(pfx+"dn",  sbX, sbY+sbH-arrowH, sbW, arrowH, C'45,80,150', C'100,150,240', 1, true);
      SBLabel(pfx+"dla", sbX+sbW/2, sbY+sbH-arrowH/2, "v", C'220,240,255');

      // Thumb
      int trackH    = sbH - arrowH*2;
      int thumbH    = MathMax(20, (int)((double)visRows/totalRows*trackH));
      int maxScroll = totalRows - visRows;
      int sc        = m_scrollPosArr[tabIdx];
      int thumbY    = sbY + arrowH +
                      (maxScroll>0 ? (int)((double)sc/maxScroll*(trackH-thumbH)) : 0);

      SBRect(pfx+"thm", sbX+1, thumbY,   sbW-2, thumbH,   C'70,130,220', C'130,180,255', 1);
      SBRect(pfx+"thl", sbX+2, thumbY+1, sbW-4, 3,        C'180,220,255', C'180,220,255', 0);
     }

   //--- Handle scrollbar arrow click or mouse wheel
   //    Returns true if scroll state changed
   bool           OnScroll(int tabIdx, int mx, int my, int delta,
                           int totalRows, int rowH, int headerH)
     {
      int sbW   = 14;
      int sbX   = m_cx + m_cw - sbW;
      int sbY   = m_cy + headerH;
      int sbH   = m_ch - headerH;
      int visR  = sbH / MathMax(rowH, 1);
      int maxSc = MathMax(0, totalRows - visR);
      int arrowH = 16;

      if(delta != 0)
        {
         m_scrollPosArr[tabIdx] = (int)MathMax(0, MathMin(maxSc, m_scrollPosArr[tabIdx] - delta));
         return true;
        }

      // Click on up arrow
      if(mx >= sbX && mx <= sbX + sbW && my >= sbY && my <= sbY + arrowH)
        { m_scrollPosArr[tabIdx] = MathMax(0, m_scrollPosArr[tabIdx] - 1); return true; }

      // Click on down arrow
      if(mx >= sbX && mx <= sbX + sbW && my >= sbY + sbH - arrowH && my <= sbY + sbH)
        { m_scrollPosArr[tabIdx] = MathMin(maxSc, m_scrollPosArr[tabIdx] + 1); return true; }

      return false;
     }

   //--- Clamp scroll position for a tab
   void           ClampScroll(int tabIdx, int totalRows, int rowH, int headerH)
     {
      int visR  = (m_ch - headerH) / MathMax(rowH, 1);
      int maxSc = MathMax(0, totalRows - visR);
      m_scrollPosArr[tabIdx] = (int)MathMax(0, MathMin(maxSc, m_scrollPosArr[tabIdx]));
     }

   //+----------------------------------------------------------------+
   //|  Tab renderers                                                  |
   //+----------------------------------------------------------------+
   void           DrawOverview()
     {
      int cw3  = (m_cw - 20) / 3;
      int cardH = 58;
      int gap   = 6;
      int r1y   = m_cy + 4;
      int r2y   = r1y + cardH + gap;

      DrawCard("bal",  m_cx + 2,           r1y, cw3, cardH,
               "BALANCE", "$" + DoubleToString(m_balance, 0), COL_TEXT_VALUE,
               "+2.1% today", COL_GREEN);

      double floatPnL = m_equity - m_balance;
      DrawCard("eq",   m_cx + 4 + cw3,     r1y, cw3, cardH,
               "EQUITY", "$" + DoubleToString(m_equity, 0), COL_TEXT_VALUE,
               SignedStr(floatPnL, 0) + " float",
               floatPnL >= 0.0 ? COL_GREEN : COL_RED);

      DrawCard("pnl",  m_cx + 6 + cw3 * 2, r1y, cw3, cardH,
               "OPEN P&L",
               (m_openPnL >= 0.0 ? "+" : "") + DoubleToString(m_openPnL, 2),
               PnLColor(m_openPnL),
               IntegerToString(m_posCount) + " positions", COL_TEXT_MUTED);

      double mPct = (m_equity > 0.0) ? m_marginUsed / m_equity * 100.0 : 0.0;
      double fPct = 100.0 - mPct;

      DrawCard("mu",   m_cx + 2,           r2y, cw3, cardH,
               "MARGIN USED", "$" + DoubleToString(m_marginUsed, 0), COL_TEXT_VALUE,
               DoubleToString(mPct, 1) + "%", COL_TEXT_MUTED);

      DrawCard("fm",   m_cx + 4 + cw3,     r2y, cw3, cardH,
               "FREE MARGIN", "$" + DoubleToString(m_marginFree, 0), COL_GREEN,
               DoubleToString(fPct, 1) + "% free", COL_GREEN);

      DrawCard("wr",   m_cx + 6 + cw3 * 2, r2y, cw3, cardH,
               "WIN RATE", DoubleToString(m_winRate, 1) + "%", COL_BLUE,
               "last 30 days", COL_TEXT_MUTED);

      //--- Equity curve mini-bar-chart
      int chartY = r2y + cardH + 10;
      int chartH = 54;
      int chartW = m_cw - 4;
      R("eq_wrap", m_cx + 2, chartY, chartW, chartH + 22, COL_BG_CARD, COL_BORDER_CARD, 1, 10);
      L("eq_lbl",  m_cx + 10, chartY + 6, "EQUITY CURVE  —  Last 14 Sessions",
        COL_TEXT_LABEL, 8, "Segoe UI", 11);

      double maxV = m_equityCurve[0], minV = m_equityCurve[0];
      for(int i = 1; i < 14; i++)
        {
         if(m_equityCurve[i] > maxV) maxV = m_equityCurve[i];
         if(m_equityCurve[i] < minV) minV = m_equityCurve[i];
        }
      double range = (maxV - minV) > 0.0 ? (maxV - minV) : 1.0;

      int barAreaX = m_cx + 8;
      int barAreaY = chartY + 18;
      int barAreaW = chartW - 16;
      int barW     = MathMax(2, barAreaW / 14 - 2);

      for(int i = 0; i < 14; i++)
        {
         double pct  = (m_equityCurve[i] - minV) / range;
         int    barH = MathMax(3, (int)(pct * chartH));
         int    bx   = barAreaX + i * (barAreaW / 14);
         int    by   = barAreaY + chartH - barH;
         // Gradient: darker early bars, brighter later bars
         int    b    = 100 + (int)(80.0 * i / 13.0);
         color  bc   = (color)(b | (((int)(b * 1.3)) << 8) | (255 << 16));
         R("eqbar" + IntegerToString(i), bx, by, barW, barH, COL_BLUE, COL_BLUE, 0, 11);
        }
     }

   //--- Draw a clickable action button for the positions table
   //    Object name encodes action + row so OnButtonClick can identify it
   void           DrawPosBtn(string action, int row, int x, int y,
                             int w, int h, color bg, color tc, string lbl)
     {
      string tag   = "pb_" + action + IntegerToString(row);
      string nRect = m_prefix + "c_" + tag + "_bg";
      string nText = m_prefix + "c_" + tag + "_lbl";

      // Background — always recreate so it is on top
      if(ObjectFind(m_chartID, nRect) >= 0) ObjectDelete(m_chartID, nRect);
      ObjectCreate(m_chartID, nRect, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartID, nRect, OBJPROP_SELECTABLE,   true);
      ObjectSetInteger(m_chartID, nRect, OBJPROP_HIDDEN,       true);
      ObjectSetInteger(m_chartID, nRect, OBJPROP_CORNER,       CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartID, nRect, OBJPROP_XDISTANCE,    x);
      ObjectSetInteger(m_chartID, nRect, OBJPROP_YDISTANCE,    y);
      ObjectSetInteger(m_chartID, nRect, OBJPROP_XSIZE,        w);
      ObjectSetInteger(m_chartID, nRect, OBJPROP_YSIZE,        h);
      ObjectSetInteger(m_chartID, nRect, OBJPROP_BGCOLOR,      bg);
      ObjectSetInteger(m_chartID, nRect, OBJPROP_BORDER_COLOR, tc);
      ObjectSetInteger(m_chartID, nRect, OBJPROP_BORDER_TYPE,  BORDER_FLAT);
      ObjectSetInteger(m_chartID, nRect, OBJPROP_WIDTH,        1);
      ObjectSetInteger(m_chartID, nRect, OBJPROP_ZORDER,       20);

      // Label — ANCHOR_CENTER at exact pixel center of button rectangle
      // Font size 7 fits cleanly inside btnH=18
      if(ObjectFind(m_chartID, nText) >= 0) ObjectDelete(m_chartID, nText);
      ObjectCreate(m_chartID, nText, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartID, nText, OBJPROP_SELECTABLE,  false);
      ObjectSetInteger(m_chartID, nText, OBJPROP_HIDDEN,      true);
      ObjectSetInteger(m_chartID, nText, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartID, nText, OBJPROP_XDISTANCE,   x + w / 2);
      ObjectSetInteger(m_chartID, nText, OBJPROP_YDISTANCE,   y + h / 2);
      ObjectSetString (m_chartID, nText, OBJPROP_TEXT,        lbl);
      ObjectSetInteger(m_chartID, nText, OBJPROP_COLOR,       tc);
      ObjectSetInteger(m_chartID, nText, OBJPROP_FONTSIZE,    7);
      ObjectSetString (m_chartID, nText, OBJPROP_FONT,        "Segoe UI Bold");
      ObjectSetInteger(m_chartID, nText, OBJPROP_ANCHOR,      ANCHOR_CENTER);
      ObjectSetInteger(m_chartID, nText, OBJPROP_ZORDER,      21);
     }

   //--- Positions tab
   void           DrawPositions()
     {
      if(m_posCount == 0)
        {
         L("nopos", m_cx + m_cw / 2, m_cy + 60, "No open positions",
           COL_TEXT_MUTED, 10, "Segoe UI", 11, ANCHOR_CENTER);
         return;
        }

      // 7 data columns + 1 actions column
      int cols   = 8;
      int rh     = 28;   // taller rows so buttons fit comfortably
      int hh     = 20;
      int btnW   = 38;   // wide enough for "Close" / "Copy"
      int btnH   = 18;   // height fits font size 8
      int btnGap = 4;

      string hdrs[] = {"Symbol","Type","Lots","Open","Current","S/L","T/P","P&L"};
      // Last column is narrower — buttons live to the right of P&L
      int pct[]     = {14,10,8,11,11,10,10,10};
      int colX[8], colW[8];
      int acc = m_cx;
      for(int c = 0; c < cols; c++)
        { colW[c] = m_cw * pct[c] / 100; colX[c] = acc; acc += colW[c]; }

      // Button area starts after last column (leave 10px for scrollbar)
      int sbW      = 10;
      int btnAreaX = colX[7] + colW[7] + 2;

      DrawHeader("p", m_cy + 2, hh, colX, colW, hdrs, cols);
      ClampScroll(0, m_posCount, rh, hh + 2);

      int sc = m_scrollPosArr[0];
      int y = m_cy + 2 + hh;
      for(int r = sc; r < m_posCount; r++)
        {
         string cells[8];
         color  clrs[8];
         cells[0] = m_positions[r].symbol;
         cells[1] = m_positions[r].type;
         cells[2] = DoubleToString(m_positions[r].lots, 2);
         cells[3] = DoubleToString(m_positions[r].openPrice, 5);
         cells[4] = DoubleToString(m_positions[r].currentPrice, 5);
         cells[5] = DoubleToString(m_positions[r].sl, 5);
         cells[6] = DoubleToString(m_positions[r].tp, 5);
         cells[7] = (m_positions[r].pnl >= 0.0 ? "+" : "") +
                    DoubleToString(m_positions[r].pnl, 2);
         clrs[0] = COL_TEXT_VALUE;
         clrs[1] = BadgeColor(m_positions[r].type);
         clrs[2] = COL_TEXT_VALUE;
         clrs[3] = COL_TEXT_VALUE;
         clrs[4] = COL_TEXT_VALUE;
         clrs[5] = COL_TEXT_MUTED;
         clrs[6] = COL_TEXT_MUTED;
         clrs[7] = PnLColor(m_positions[r].pnl);
         DrawRow("p", r, y, rh, colX, cells, clrs, cols);

         // Center buttons vertically in row
         int by = y + (rh - btnH) / 2;

         // 🔴 Close button
         DrawPosBtn("cl", r,
                    btnAreaX, by,
                    btnW, btnH,
                    C'80,20,20', C'255,110,110', "Close");

         // 🟢 Copy button
         DrawPosBtn("cp", r,
                    btnAreaX + btnW + btnGap, by,
                    btnW, btnH,
                    C'15,60,30', C'80,220,120', "Copy");

         y += rh;
         if(y + rh > m_cy + m_ch) break;
        }
      DrawScrollbar(0, m_posCount, rh, hh + 2);
     }


   //--- Close position by ticket
   void           ExecuteClose(int row)
     {
      ulong ticket = m_positions[row].ticket;
      if(ticket == 0)
        {
         // Demo mode: no real ticket — just log
         AddLog(TimeToString(TimeCurrent(),TIME_SECONDS),
                "warn", "Close: demo mode, no ticket for row " + IntegerToString(row));
         return;
        }
      if(m_trade.PositionClose(ticket))
         AddLog(TimeToString(TimeCurrent(),TIME_SECONDS),
                "ok", "Closed position #" + IntegerToString((int)ticket) +
                " " + m_positions[row].symbol);
      else
         AddLog(TimeToString(TimeCurrent(),TIME_SECONDS),
                "err", "Close failed #" + IntegerToString((int)ticket) +
                " err:" + IntegerToString(m_trade.ResultRetcode()));
     }

   //--- Copy position: open same symbol/lots/sl/tp in same direction
   void           ExecuteCopy(int row)
     {
      string sym  = m_positions[row].symbol;
      double lots = m_positions[row].lots;
      double sl   = m_positions[row].sl;
      double tp   = m_positions[row].tp;
      string type = m_positions[row].type;

      m_trade.SetExpertMagicNumber(m_magicNumber);

      bool ok = false;
      if(type == "BUY")
         ok = m_trade.Buy(lots, sym, 0, sl, tp, "GUI Copy");
      else
         ok = m_trade.Sell(lots, sym, 0, sl, tp, "GUI Copy");

      if(ok)
         AddLog(TimeToString(TimeCurrent(),TIME_SECONDS),
                "ok", "Copied " + type + " " + sym + " " +
                DoubleToString(lots,2) + " lots");
      else
         AddLog(TimeToString(TimeCurrent(),TIME_SECONDS),
                "err", "Copy failed: " + sym +
                " err:" + IntegerToString(m_trade.ResultRetcode()));
     }

   //--- Orders tab
   void           DrawOrders()
     {
      if(m_orderCount == 0)
        {
         L("noord", m_cx + m_cw / 2, m_cy + 60, "No pending orders",
           COL_TEXT_MUTED, 10, "Segoe UI", 11, ANCHOR_CENTER);
         return;
        }
      int cols = 7;
      int rh   = 22;
      int hh   = 20;
      string hdrs[] = {"Symbol","Type","Lots","At Price","S/L","T/P","Status"};
      int pct[]     = {14,14,8,12,10,10,12};
      int colX[7], colW[7];
      int acc = m_cx;
      for(int c = 0; c < cols; c++)
        { colW[c] = m_cw * pct[c] / 100; colX[c] = acc; acc += colW[c]; }

      ClampScroll(1, m_orderCount, rh, hh + 2);
      DrawHeader("o", m_cy + 2, hh, colX, colW, hdrs, cols);

      int sc_o = m_scrollPosArr[1];
      int y = m_cy + 2 + hh;
      for(int r = sc_o; r < m_orderCount; r++)
        {
         string cells[7];
         color  clrs[7];
         cells[0] = m_orders[r].symbol;
         cells[1] = m_orders[r].type;
         cells[2] = DoubleToString(m_orders[r].lots, 2);
         cells[3] = DoubleToString(m_orders[r].atPrice, 5);
         cells[4] = DoubleToString(m_orders[r].sl, 5);
         cells[5] = DoubleToString(m_orders[r].tp, 5);
         cells[6] = "Pending";
         clrs[0] = COL_TEXT_VALUE;
         clrs[1] = BadgeColor(m_orders[r].type);
         clrs[2] = COL_TEXT_VALUE;
         clrs[3] = COL_TEXT_VALUE;
         clrs[4] = COL_TEXT_MUTED;
         clrs[5] = COL_TEXT_MUTED;
         clrs[6] = COL_YELLOW;
         DrawRow("o", r, y, rh, colX, cells, clrs, cols);
         y += rh;
         if(y + rh > m_cy + m_ch) break;
        }
      DrawScrollbar(1, m_orderCount, rh, hh + 2);
     }

   //--- Estimate pixel width of a string in Courier New 9pt (approx 7px per char)
   int            TextPx(string s) { return StringLen(s) * 7 + 10; }

   //--- Sort history by column
   void           SortHistory(int col)
     {
      // Bubble sort (small dataset, fine for <=100 trades)
      for(int i = 0; i < m_histCount - 1; i++)
         for(int j = 0; j < m_histCount - 1 - i; j++)
           {
            bool swap = false;
            SHistoryTrade a = m_history[j];
            SHistoryTrade b = m_history[j+1];
            switch(col)
              {
               case 0: swap = m_histSortAsc ? (a.date   > b.date)   : (a.date   < b.date);   break;
               case 1: swap = m_histSortAsc ? (a.symbol > b.symbol) : (a.symbol < b.symbol); break;
               case 2: swap = m_histSortAsc ? (a.type   > b.type)   : (a.type   < b.type);   break;
               case 3: swap = m_histSortAsc ? (a.lots   > b.lots)   : (a.lots   < b.lots);   break;
               case 4: swap = m_histSortAsc ? (a.openPrice  > b.openPrice)  : (a.openPrice  < b.openPrice);  break;
               case 5: swap = m_histSortAsc ? (a.closePrice > b.closePrice) : (a.closePrice < b.closePrice); break;
               case 6: swap = m_histSortAsc ? (a.pnl > b.pnl) : (a.pnl < b.pnl); break;
              }
            if(swap) { m_history[j] = b; m_history[j+1] = a; }
           }
     }

   //--- History tab — auto-width columns + clickable sort headers
   void           DrawHistory()
     {
      if(m_histCount == 0)
        {
         L("nohist", m_cx + m_cw / 2, m_cy + 60, "No trade history",
           COL_TEXT_MUTED, 10, "Segoe UI", 11, ANCHOR_CENTER);
         return;
        }

      int cols = 7;
      int rh   = 20;
      int hh   = 22;   // taller header — fits sort arrow
      string hdrs[] = {"Date","Symbol","Type","Lots","Open","Close","P&L"};

      //--- Auto-width: measure widest content per column
      int colW[7];
      for(int c = 0; c < cols; c++)
         colW[c] = TextPx(hdrs[c]) + 14;  // header as minimum

      int maxRows = MathMin(m_histCount, 50);
      for(int r = 0; r < maxRows; r++)
        {
         string cells[7];
         cells[0] = m_history[r].date;
         cells[1] = m_history[r].symbol;
         cells[2] = m_history[r].type;
         cells[3] = DoubleToString(m_history[r].lots, 2);
         cells[4] = DoubleToString(m_history[r].openPrice, 5);
         cells[5] = DoubleToString(m_history[r].closePrice, 5);
         cells[6] = SignedStr(m_history[r].pnl, 2);
         for(int c = 0; c < cols; c++)
            colW[c] = MathMax(colW[c], TextPx(cells[c]));
        }

      //--- Scale columns to fit total width
      int totalW = 0;
      for(int c = 0; c < cols; c++) totalW += colW[c];
      double scale = (double)(m_cw - 2) / MathMax(totalW, 1);
      int colX[7];
      int acc = m_cx + 1;
      for(int c = 0; c < cols; c++)
        {
         colW[c] = (int)(colW[c] * scale);
         colX[c] = acc;
         acc    += colW[c];
        }

      //--- Draw clickable sort headers
      m_histSortClickY = m_cy + 2;
      R("th_h", m_cx, m_cy + 2, m_cw, hh, COL_BG_CARD, COL_BORDER_CARD, 1, 10);
      for(int c = 0; c < cols; c++)
        {
         bool   active = (m_histSortCol == c);
         color  hc     = active ? COL_TEXT_ACTIVE : COL_TEXT_LABEL;
         string arrow  = active ? (m_histSortAsc ? " ^" : " v") : "";
         // Clickable header background
         string hbg = "hhdr" + IntegerToString(c);
         R(hbg, colX[c], m_cy + 2, colW[c] - 1, hh,
           active ? C'26,42,72' : COL_BG_CARD, COL_BORDER_CARD, 0, 11);
         L("th_h" + IntegerToString(c),
           colX[c] + 5, m_cy + 2 + (hh - 8) / 2,
           hdrs[c] + arrow, hc, 8, "Segoe UI Bold", 12);
        }
      R("thl_h", m_cx, m_cy + 2 + hh - 1, m_cw, 1, COL_BORDER_TABLINE, COL_BORDER_TABLINE, 0, 12);

      //--- Draw rows with scroll
      ClampScroll(2, maxRows, rh, hh + 2);
      int sc = m_scrollPosArr[2];
      int y = m_cy + 2 + hh;
      for(int r = sc; r < maxRows; r++)
        {
         if(y + rh > m_cy + m_ch) break;
         string cells[7];
         color  clrs[7];
         cells[0] = m_history[r].date;
         cells[1] = m_history[r].symbol;
         cells[2] = m_history[r].type;
         cells[3] = DoubleToString(m_history[r].lots, 2);
         cells[4] = DoubleToString(m_history[r].openPrice, 5);
         cells[5] = DoubleToString(m_history[r].closePrice, 5);
         cells[6] = SignedStr(m_history[r].pnl, 2);
         clrs[0] = COL_TEXT_MUTED;
         clrs[1] = COL_TEXT_VALUE;
         clrs[2] = BadgeColor(m_history[r].type);
         clrs[3] = COL_TEXT_VALUE;
         clrs[4] = COL_TEXT_VALUE;
         clrs[5] = COL_TEXT_VALUE;
         clrs[6] = PnLColor(m_history[r].pnl);
         // Zebra striping
         color rowBg = (r % 2 == 0) ? COL_BG_CONTENT : C'20,28,44';
         R("tr_h" + IntegerToString(r), m_cx, y, m_cw, rh, rowBg, COL_BORDER_CARD, 0, 10);
         for(int c = 0; c < cols; c++)
            L("td_h" + IntegerToString(r) + "_" + IntegerToString(c),
              colX[c] + 4, y + (rh - 8) / 2, cells[c], clrs[c], 9, "Courier New", 11);
         R("trl_h" + IntegerToString(r), m_cx, y + rh - 1, m_cw, 1, C'30,45,70', C'30,45,70', 0, 10);
         y += rh;
        }
      DrawScrollbar(2, maxRows, rh, hh + 2);
     }

   //--- Handle header click for history sort
   //    Returns true if a header was clicked
   bool           OnHistoryHeaderClick(int mx, int my, int hh = 22)
     {
      if(m_activeTab != 3) return false;
      if(my < m_histSortClickY || my > m_histSortClickY + hh) return false;
      if(mx < m_cx || mx > m_cx + m_cw) return false;

      // Rebuild same colX array to find which column was clicked
      int cols = 7;
      string hdrs[] = {"Date","Symbol","Type","Lots","Open","Close","P&L"};
      int colW[7];
      for(int c = 0; c < cols; c++) colW[c] = TextPx(hdrs[c]) + 14;
      int maxRows = MathMin(m_histCount, 50);
      for(int r = 0; r < maxRows; r++)
        {
         string cells[7];
         cells[0] = m_history[r].date;    cells[1] = m_history[r].symbol;
         cells[2] = m_history[r].type;    cells[3] = DoubleToString(m_history[r].lots,2);
         cells[4] = DoubleToString(m_history[r].openPrice,5);
         cells[5] = DoubleToString(m_history[r].closePrice,5);
         cells[6] = SignedStr(m_history[r].pnl,2);
         for(int c = 0; c < cols; c++) colW[c] = MathMax(colW[c], TextPx(cells[c]));
        }
      int totalW = 0;
      for(int c = 0; c < cols; c++) totalW += colW[c];
      double scale = (double)(m_cw - 2) / MathMax(totalW,1);
      int colX[7], acc = m_cx + 1;
      for(int c = 0; c < cols; c++) { colW[c]=(int)(colW[c]*scale); colX[c]=acc; acc+=colW[c]; }

      // Find clicked column
      for(int c = 0; c < cols; c++)
        {
         if(mx >= colX[c] && mx < colX[c] + colW[c])
           {
            if(m_histSortCol == c)
               m_histSortAsc = !m_histSortAsc;  // toggle direction
            else
              { m_histSortCol = c; m_histSortAsc = true; }
            SortHistory(c);
            return true;
           }
        }
      return false;
     }

   //--- Risk tab
   void           DrawRisk()
     {
      int cw3   = (m_cw - 20) / 3;
      int cardH = 58;
      int gap   = 6;
      int r1y   = m_cy + 4;
      int r2y   = r1y + cardH + gap;

      DrawCard("rpt",  m_cx + 2,            r1y, cw3, cardH,
               "RISK / TRADE", DoubleToString(m_riskPerTrade, 2) + "%", COL_TEXT_VALUE);
      DrawCard("rdd",  m_cx + 4 + cw3,      r1y, cw3, cardH,
               "MAX DRAWDOWN",
               DoubleToString(m_maxDrawdown, 2) + "%",
               m_maxDrawdown > 5.0 ? COL_RED : COL_YELLOW);
      DrawCard("rdll", m_cx + 6 + cw3 * 2,  r1y, cw3, cardH,
               "DAILY LOSS LIM.", "$" + DoubleToString(m_dailyLossLimit, 0), COL_TEXT_VALUE);
      DrawCard("rlot", m_cx + 2,             r2y, cw3, cardH,
               "LOT SIZE CALC",  DoubleToString(m_lotSizeCalc, 2),  COL_GREEN);
      DrawCard("rshp", m_cx + 4 + cw3,       r2y, cw3, cardH,
               "SHARPE RATIO",   DoubleToString(m_sharpeRatio, 2),  COL_BLUE);
      DrawCard("rexp", m_cx + 6 + cw3 * 2,   r2y, cw3, cardH,
               "EXPOSURE",       DoubleToString(m_exposure, 1) + "%", COL_TEXT_VALUE);
     }

   //--- Signals tab
   void           DrawSignals()
     {
      if(m_sigCount == 0)
        {
         L("nosig", m_cx + m_cw / 2, m_cy + 60, "No signals available",
           COL_TEXT_MUTED, 10, "Segoe UI", 11, ANCHOR_CENTER);
         return;
        }
      int cols = 5;
      int rh   = 22;
      int hh   = 20;
      string hdrs[] = {"Time","Symbol","Signal","Strength","Source"};
      int pct[]     = {12,14,12,22,16};
      int colX[5], colW[5];
      int acc = m_cx;
      for(int c = 0; c < cols; c++)
        { colW[c] = m_cw * pct[c] / 100; colX[c] = acc; acc += colW[c]; }

      DrawHeader("s", m_cy + 2, hh, colX, colW, hdrs, cols);

      int y = m_cy + 2 + hh;
      for(int r = 0; r < m_sigCount; r++)
        {
         string cells[5];
         color  clrs[5];
         cells[0] = m_signals[r].time;
         cells[1] = m_signals[r].symbol;
         cells[2] = m_signals[r].direction;
         cells[3] = Stars(m_signals[r].stars);
         cells[4] = m_signals[r].source;
         color sc = m_signals[r].stars >= 4 ? COL_GREEN :
                    m_signals[r].stars >= 3 ? COL_YELLOW : COL_RED;
         clrs[0] = COL_TEXT_MUTED;
         clrs[1] = COL_TEXT_VALUE;
         clrs[2] = BadgeColor(m_signals[r].direction);
         clrs[3] = sc;
         clrs[4] = COL_TEXT_MUTED;
         DrawRow("s", r, y, rh, colX, cells, clrs, cols);
         y += rh;
        }
     }

   //--- News tab
   void           DrawNews()
     {
      if(m_newsCount == 0)
        {
         L("nonews", m_cx + m_cw / 2, m_cy + 60, "No news events",
           COL_TEXT_MUTED, 10, "Segoe UI", 11, ANCHOR_CENTER);
         return;
        }
      int itemH = 52;
      int gap   = 8;
      int y     = m_cy + 4;
      for(int i = 0; i < m_newsCount && i < 8; i++)
        {
         string t = "nw" + IntegerToString(i);
         R(t + "bg", m_cx + 2, y, m_cw - 4, itemH, COL_BG_CARD, COL_BORDER_CARD, 1, 10);
         color ic = COL_GREEN;
         if(m_news[i].impact == "HIGH") ic = COL_RED;
         if(m_news[i].impact == "MED")  ic = COL_YELLOW;
         L(t + "tm", m_cx + 10, y + 8,  m_news[i].time,     COL_YELLOW,      8, "Courier New", 11);
         L(t + "im", m_cx + 72, y + 8,  m_news[i].impact,   ic,              8, "Segoe UI Bold", 11);
         L(t + "cu", m_cx + 106,y + 8,  m_news[i].currency, COL_TEXT_MUTED,  8, "Segoe UI",     11);
         L(t + "tt", m_cx + 10, y + 22, m_news[i].title,    COL_TEXT_VALUE,  10, "Segoe UI Bold", 11);
         L(t + "dt", m_cx + 10, y + 38, m_news[i].detail,   COL_TEXT_LABEL,  8, "Segoe UI",     11);
         y += itemH + gap;
        }
     }

   //--- Settings tab
   void           DrawSettings()
     {
      int rh     = 30;
      int y      = m_cy + 6;
      int labelW = (int)(m_cw * 0.55);
      int valX   = m_cx + labelW + 8;
      int valW   = m_cw - labelW - 14;

      string lbls[5], vals[5];
      color  vc[5];
      lbls[0] = "Magic Number";         vals[0] = IntegerToString(m_magicNumber);
      lbls[1] = "Risk per Trade (%)";   vals[1] = DoubleToString(m_settingsRisk, 2);
      lbls[2] = "Max Open Positions";   vals[2] = IntegerToString(m_maxPositions);
      lbls[3] = "Enable Auto-Trading";  vals[3] = m_autoTrading    ? "ON" : "OFF";
      lbls[4] = "Enable Notifications"; vals[4] = m_notifications  ? "ON" : "OFF";
      vc[0] = COL_TEXT_VALUE;
      vc[1] = COL_TEXT_VALUE;
      vc[2] = COL_TEXT_VALUE;
      vc[3] = m_autoTrading   ? COL_GREEN : COL_TEXT_MUTED;
      vc[4] = m_notifications ? COL_GREEN : COL_TEXT_MUTED;

      for(int i = 0; i < 5; i++)
        {
         R("ssep" + IntegerToString(i), m_cx, y - 1, m_cw, 1, C'30,45,70', C'30,45,70', 0, 10);
         L("slbl" + IntegerToString(i), m_cx + 6, y + (rh - 9) / 2,
           lbls[i], C'112,144,176', 10, "Segoe UI", 11);
         R("svbg" + IntegerToString(i), valX - 4, y + 4, valW, rh - 8,
           COL_BG_INPUT, COL_BORDER_CARD, 1, 10);
         L("sval" + IntegerToString(i), valX + 4, y + (rh - 9) / 2,
           vals[i], vc[i], 10, "Courier New", 11);
         y += rh;
        }
      L("shint", m_cx + 6, y + 10,
        "* Edit values via EA input parameters (F7)",
        COL_TEXT_LABEL, 8, "Segoe UI", 11);
     }

   //--- Logs tab
   void           DrawLogs()
     {
      int sbW2 = 10;
      R("logbg", m_cx + 2, m_cy + 4, m_cw - 4 - sbW2, m_ch - 8,
        COL_BG_LOG, COL_BORDER_CARD, 1, 10);

      int lineH    = 16;
      int maxLines = (m_ch - 16) / lineH;

      ClampScroll(3, m_logCount, lineH, 4);
      int start = m_scrollPosArr[3];

      for(int i = start; i < m_logCount && i < start + maxLines; i++)
        {
         int row = i - start;
         int ly  = m_cy + 8 + row * lineH;
         string t = "lg" + IntegerToString(row);
         L(t + "ts", m_cx + 8,  ly, m_logs[i].timestamp, C'42,64,96', 8, "Courier New", 11);
         color mc = COL_TEXT_MUTED;
         if(m_logs[i].level == "ok")   mc = COL_GREEN;
         if(m_logs[i].level == "warn") mc = COL_YELLOW;
         if(m_logs[i].level == "err")  mc = COL_RED;
         if(m_logs[i].level == "info") mc = COL_BLUE;
         L(t + "ms", m_cx + 72, ly, m_logs[i].message, mc, 8, "Courier New", 11);
        }
      DrawScrollbar(3, m_logCount, lineH, 4);
     }

   //--- About tab
   void           DrawAbout()
     {
      int y = m_cy + 16;
      R("aico", m_cx + 10, y, 36, 36, COL_BORDER_TABLINE, COL_CYAN, 1, 10);
      L("aicl", m_cx + 28, y + 18, "M", clrWhite, 14, "Segoe UI Bold", 11, ANCHOR_CENTER);
      L("anm",  m_cx + 56, y + 2,  "MyAPI Dashboard", COL_TEXT_TITLE, 13, "Segoe UI Bold", 11);
      L("aver", m_cx + 56, y + 20, "version " + m_version + "  |  MQL5",
        COL_TEXT_LABEL, 9, "Courier New", 11);
      y += 52;
      R("abox", m_cx + 10, y, m_cw - 20, 82, COL_BG_CARD, COL_BORDER_CARD, 1, 10);
      string alines[5] = {
         "Herbruikbare GUI API voor MetaTrader 5.",
         "Modules: GUIBase  GUITabBar  GUIPanel",
         "         GUIContent  GUIManager",
         "Drag & Drop  |  Resizable  |  10 Tabs",
         "Build: " + m_buildDate
      };
      color alc[5] = { COL_TEXT_VALUE, COL_TEXT_MUTED, COL_TEXT_MUTED, COL_TEXT_MUTED, COL_TEXT_LABEL };
      for(int i = 0; i < 5; i++)
         L("aln" + IntegerToString(i), m_cx + 18, y + 8 + i * 14, alines[i], alc[i], 9, "Segoe UI", 11);
     }

public:
   //--- Route mouse click to history sort header (call from GUIPanel OnMouseDown)
   bool           OnHistoryClick(int mx, int my)
     { return OnHistoryHeaderClick(mx, my, 22); }

   //--- Mouse wheel scroll — call from OnChartEvent CHARTEVENT_MOUSE_WHEEL
   //    delta: positive = scroll up, negative = scroll down
   bool           OnMouseWheel(int mx, int my, int delta)
     {
      // Only scroll if mouse is over the content area
      if(mx < m_cx || mx > m_cx + m_cw) return false;
      if(my < m_cy || my > m_cy + m_ch) return false;
      int tabIdx = -1;
      int rowH   = 22;
      int hdrH   = 22;
      switch(m_activeTab)
        {
         case 1: tabIdx=0; rowH=28; hdrH=22; break;  // Positions
         case 2: tabIdx=1; rowH=22; hdrH=22; break;  // Orders
         case 3: tabIdx=2; rowH=20; hdrH=44; break;  // History
         case 8: tabIdx=3; rowH=16; hdrH=4;  break;  // Logs
        }
      if(tabIdx < 0) return false;
      int steps = (delta > 0) ? -3 : 3;  // wheel up = scroll up = lower offset
      int total = 0;
      switch(tabIdx)
        {
         case 0: total = m_posCount;   break;
         case 1: total = m_orderCount; break;
         case 2: total = m_histCount;  break;
         case 3: total = m_logCount;   break;
        }
      return OnScroll(tabIdx, mx, my, steps, total, rowH, hdrH);
     }

   //--- Scrollbar arrow click — detected by object name from CHARTEVENT_OBJECT_CLICK
   //    Object names: prefix+"c_sb0up", "c_sb0dn", "c_sb1up" etc.
   bool           OnScrollbarClick(string objName)
     {
      // Total rows lookup per tabIdx
      int totals[4];
      totals[0] = m_posCount;
      totals[1] = m_orderCount;
      totals[2] = m_histCount;
      totals[3] = m_logCount;

      int rowHs[4];  rowHs[0]=28; rowHs[1]=22; rowHs[2]=20; rowHs[3]=16;
      int hdrHs[4];  hdrHs[0]=22; hdrHs[1]=22; hdrHs[2]=44; hdrHs[3]=4;

      for(int t = 0; t < 4; t++)
        {
         string pfx = m_prefix + "c_sb" + IntegerToString(t);
         if(objName == pfx + "up" || objName == pfx + "ula")
           {
            int visR  = (m_ch - hdrHs[t]) / MathMax(rowHs[t], 1);
            int maxSc = MathMax(0, totals[t] - visR);
            m_scrollPosArr[t] = MathMax(0, m_scrollPosArr[t] - 1);
            return true;
           }
         if(objName == pfx + "dn" || objName == pfx + "dla")
           {
            int visR  = (m_ch - hdrHs[t]) / MathMax(rowHs[t], 1);
            int maxSc = MathMax(0, totals[t] - visR);
            m_scrollPosArr[t] = MathMin(maxSc, m_scrollPosArr[t] + 1);
            return true;
           }
        }
      return false;
     }

   //--- Thumb drag: call from GUIPanel OnMouseDown when click is on thumb area
   bool           OnThumbMouseDown(int mx, int my)
     {
      int rowHs[4];  rowHs[0]=28; rowHs[1]=22; rowHs[2]=20; rowHs[3]=16;
      int hdrHs[4];  hdrHs[0]=22; hdrHs[1]=22; hdrHs[2]=44; hdrHs[3]=4;
      int totals[4];
      totals[0]=m_posCount; totals[1]=m_orderCount;
      totals[2]=m_histCount; totals[3]=m_logCount;

      // Map activeTab to array index
      int t = -1;
      switch(m_activeTab)
        { case 1:t=0;break; case 2:t=1;break; case 3:t=2;break; case 8:t=3;break; }
      if(t < 0) return false;

      int sbW   = 14;
      int sbX   = m_cx + m_cw - sbW;
      int sbY   = m_cy + hdrHs[t];
      int sbH   = m_ch - hdrHs[t];
      int arrowH= 16;

      // Must click inside scrollbar track (excluding arrows)
      if(mx < sbX || mx > sbX + sbW) return false;
      if(my < sbY + arrowH || my > sbY + sbH - arrowH) return false;
      // Only when scrollbar is needed
      int visR = sbH / MathMax(rowHs[t], 1);
      if(totals[t] <= visR) return false;

      m_thumbDragging    = true;
      m_thumbDragTab     = t;
      m_thumbDragStartY  = my;
      m_thumbDragStartSc = m_scrollPosArr[t];
      return true;
     }

   //--- Thumb drag move: call from GUIPanel OnMouseMove
   bool           OnThumbMouseMove(int my)
     {
      if(!m_thumbDragging || m_thumbDragTab < 0) return false;

      int t = m_thumbDragTab;
      int rowHs[4];  rowHs[0]=28; rowHs[1]=22; rowHs[2]=20; rowHs[3]=16;
      int hdrHs[4];  hdrHs[0]=22; hdrHs[1]=22; hdrHs[2]=44; hdrHs[3]=4;
      int totals[4];
      totals[0]=m_posCount; totals[1]=m_orderCount;
      totals[2]=m_histCount; totals[3]=m_logCount;

      int sbH    = m_ch - hdrHs[t];
      int arrowH = 16;
      int trackH = sbH - arrowH * 2;
      int visR   = trackH / MathMax(rowHs[t], 1);
      int maxSc  = MathMax(1, totals[t] - visR);

      // Map pixel delta to row delta
      int dyPixels = my - m_thumbDragStartY;
      int thumbH   = MathMax(20, (int)((double)visR / totals[t] * trackH));
      double ratio = (double)dyPixels / MathMax(1, trackH - thumbH);
      int newSc    = m_thumbDragStartSc + (int)(ratio * maxSc);
      m_scrollPosArr[t] = (int)MathMax(0, MathMin(maxSc, newSc));
      return true;
     }

   //--- Thumb drag release
   void           OnThumbMouseUp()
     { m_thumbDragging = false; m_thumbDragTab = -1; }

   bool           IsThumbDragging() const { return m_thumbDragging; }

   //--- Execute close or copy action triggered by button click
   //    Called from GUIManager when CHARTEVENT_OBJECT_CLICK fires
   bool           OnButtonClick(string objName)
     {
      // Object names: prefix + "c_pb_cl0_bg", "c_pb_cp2_bg" etc.
      // Extract action and row from the name
      string search_cl = m_prefix + "c_pb_cl";
      string search_cp = m_prefix + "c_pb_cp";

      if(StringFind(objName, search_cl) == 0)
        {
         // Parse row index — character after prefix+action
         int rowIdx = (int)StringToInteger(
                       StringSubstr(objName, StringLen(search_cl), 1));
         if(rowIdx < 0 || rowIdx >= m_posCount) return false;
         ExecuteClose(rowIdx);
         return true;
        }

      if(StringFind(objName, search_cp) == 0)
        {
         int rowIdx = (int)StringToInteger(
                       StringSubstr(objName, StringLen(search_cp), 1));
         if(rowIdx < 0 || rowIdx >= m_posCount) return false;
         ExecuteCopy(rowIdx);
         return true;
        }

      return false;
     }

   //+----------------------------------------------------------------+
   //|  Constructor                                                    |
   //+----------------------------------------------------------------+
                  CGUIContent(long chartID, string prefix)
     : m_chartID(chartID), m_prefix(prefix),
       m_cx(0), m_cy(0), m_cw(0), m_ch(0), m_activeTab(0),
       m_balance(10420.0), m_equity(10218.0), m_openPnL(-202.40),
       m_marginUsed(310.0), m_marginFree(9908.0), m_winRate(68.4),
       m_posCount(0), m_orderCount(0), m_histCount(0),
       m_histSortCol(-1), m_histSortAsc(true), m_histSortClickY(0),
       m_scrollPos(0),
       m_riskPerTrade(1.0), m_maxDrawdown(4.2), m_dailyLossLimit(200.0),
       m_lotSizeCalc(0.12), m_sharpeRatio(1.84), m_exposure(3.0),
       m_sigCount(0), m_newsCount(0), m_logCount(0),
       m_magicNumber(12345), m_settingsRisk(1.0), m_maxPositions(5),
       m_autoTrading(true), m_notifications(false),
       m_version("2.0.0"), m_buildDate("2025.01.01")
     {
      double curve[14] = {48,52,49,55,53,60,57,63,61,66,64,70,68,74};
      for(int i = 0; i < 14; i++) m_equityCurve[i] = curve[i];
      for(int i = 0; i < 4; i++) m_scrollPosArr[i] = 0;
      m_thumbDragging   = false;
      m_thumbDragTab    = -1;
      m_thumbDragStartY = 0;
      m_thumbDragStartSc= 0;
     }

                 ~CGUIContent() { ClearContent(); }

   //--- Set geometry from GUIPanel
   void           SetGeometry(int cx, int cy, int cw, int ch)
     { m_cx = cx; m_cy = cy; m_cw = cw; m_ch = ch; }

   void           SetActiveTab(int t) { m_activeTab = t; }

   void           Redraw()
     {
      ClearContent();
      switch(m_activeTab)
        {
         case 0: DrawOverview();  break;
         case 1: DrawPositions(); break;
         case 2: DrawOrders();    break;
         case 3: DrawHistory();   break;
         case 4: DrawRisk();      break;
         case 5: DrawSignals();   break;
         case 6: DrawNews();      break;
         case 7: DrawSettings();  break;
         case 8: DrawLogs();      break;
         case 9: DrawAbout();     break;
        }
     }

   //+----------------------------------------------------------------+
   //|  Data setters — call from EA                                   |
   //+----------------------------------------------------------------+
   void SetAccountData(double bal, double eq, double pnl,
                       double mu, double fm, double wr)
     { m_balance=bal; m_equity=eq; m_openPnL=pnl;
       m_marginUsed=mu; m_marginFree=fm; m_winRate=wr; }

   void SetEquityCurve(double &data[], int cnt)
     { for(int i=0;i<MathMin(cnt,14);i++) m_equityCurve[i]=data[i]; }

   void ClearPositions() { m_posCount = 0; }
   void AddPosition(string sym, string type, double lots,
                    double op, double cp, double sl, double tp, double pnl, ulong tk=0)
     {
      if(m_posCount >= 10) return;
      m_positions[m_posCount].symbol       = sym;
      m_positions[m_posCount].type         = type;
      m_positions[m_posCount].lots         = lots;
      m_positions[m_posCount].openPrice    = op;
      m_positions[m_posCount].currentPrice = cp;
      m_positions[m_posCount].sl           = sl;
      m_positions[m_posCount].tp           = tp;
      m_positions[m_posCount].pnl          = pnl;
      m_positions[m_posCount].ticket       = tk;
      m_posCount++;
     }

   void ClearOrders() { m_orderCount = 0; }
   void AddOrder(string sym, string type, double lots, double at, double sl, double tp)
     {
      if(m_orderCount >= 10) return;
      m_orders[m_orderCount].symbol  = sym;  m_orders[m_orderCount].type    = type;
      m_orders[m_orderCount].lots    = lots; m_orders[m_orderCount].atPrice = at;
      m_orders[m_orderCount].sl      = sl;   m_orders[m_orderCount].tp      = tp;
      m_orderCount++;
     }

   void ClearHistory() { m_histCount = 0; }
   void AddHistory(string date, string sym, string type, double lots,
                   double op, double cp, double pnl)
     {
      if(m_histCount >= 20) return;
      m_history[m_histCount].date       = date; m_history[m_histCount].symbol     = sym;
      m_history[m_histCount].type       = type; m_history[m_histCount].lots       = lots;
      m_history[m_histCount].openPrice  = op;   m_history[m_histCount].closePrice = cp;
      m_history[m_histCount].pnl        = pnl;
      m_histCount++;
     }

   void SetRiskData(double rpt, double dd, double dll, double lot, double sharpe, double exp)
     { m_riskPerTrade=rpt; m_maxDrawdown=dd; m_dailyLossLimit=dll;
       m_lotSizeCalc=lot; m_sharpeRatio=sharpe; m_exposure=exp; }

   void ClearSignals() { m_sigCount = 0; }
   void AddSignal(string time, string sym, string dir, int stars, string src)
     {
      if(m_sigCount >= 10) return;
      m_signals[m_sigCount].time      = time; m_signals[m_sigCount].symbol    = sym;
      m_signals[m_sigCount].direction = dir;  m_signals[m_sigCount].stars     = stars;
      m_signals[m_sigCount].source    = src;
      m_sigCount++;
     }

   void ClearNews() { m_newsCount = 0; }
   void AddNews(string time, string impact, string cur, string title, string detail)
     {
      if(m_newsCount >= 10) return;
      m_news[m_newsCount].time     = time;   m_news[m_newsCount].impact   = impact;
      m_news[m_newsCount].currency = cur;    m_news[m_newsCount].title    = title;
      m_news[m_newsCount].detail   = detail;
      m_newsCount++;
     }

   void AddLog(string ts, string lvl, string msg)
     {
      if(m_logCount >= 50)
        {
         for(int i = 0; i < 49; i++) m_logs[i] = m_logs[i+1];
         m_logCount = 49;
        }
      m_logs[m_logCount].timestamp = ts;
      m_logs[m_logCount].level     = lvl;
      m_logs[m_logCount].message   = msg;
      m_logCount++;
     }

   void SetSettings(int magic, double risk, int maxP, bool autoT, bool notif)
     { m_magicNumber=magic; m_settingsRisk=risk; m_maxPositions=maxP;
       m_autoTrading=autoT; m_notifications=notif; }

   void SetVersionInfo(string ver, string bd)
     { m_version=ver; m_buildDate=bd; }

   int  GetPosCount()  const { return m_posCount; }
   int  GetHistCount() const { return m_histCount; }
  };

#endif
//+------------------------------------------------------------------+