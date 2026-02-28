//+------------------------------------------------------------------+
//|  CleanGUI_Content.mqh  —  Lege tab-inhoud, klaar voor gebruik    |
//|  MyAPI v2.0.0  —  CleanGUI versie                                  |
//+------------------------------------------------------------------+
#ifndef CLEANGUI_CONTENT_MQH
#define CLEANGUI_CONTENT_MQH

#include "CleanGUI_Base.mqh"

//+------------------------------------------------------------------+
//| CCleanGUI_Content — lege renderer, 10 tabs, scrollbar support    |
//+------------------------------------------------------------------+
class CCleanGUI_Content
  {
private:
   long           m_chartID;
   string         m_prefix;

   //--- Content area geometry
   int            m_cx, m_cy, m_cw, m_ch;
   int            m_activeTab;

   //--- Scroll state (per tab, max 10 tabs)
   int            m_scrollPosArr[10];

   //--- Thumb drag state
   bool           m_thumbDragging;
   int            m_thumbDragTab;
   int            m_thumbDragStartY;
   int            m_thumbDragStartSc;

   //+----------------------------------------------------------------+
   //|  Draw primitives                                               |
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

   //+----------------------------------------------------------------+
   //|  Scrollbar helpers                                             |
   //+----------------------------------------------------------------+
   void           SBRect(string n, int x, int y, int w, int h,
                         color bg, color brd, int bw, bool clickable = false)
     {
      if(ObjectFind(m_chartID, n) >= 0) ObjectDelete(m_chartID, n);
      ObjectCreate(m_chartID, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartID, n, OBJPROP_SELECTABLE,   clickable);
      ObjectSetInteger(m_chartID, n, OBJPROP_HIDDEN,       true);
      ObjectSetInteger(m_chartID, n, OBJPROP_CORNER,       CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartID, n, OBJPROP_XDISTANCE,    x);
      ObjectSetInteger(m_chartID, n, OBJPROP_YDISTANCE,    y);
      ObjectSetInteger(m_chartID, n, OBJPROP_XSIZE,        MathMax(1, w));
      ObjectSetInteger(m_chartID, n, OBJPROP_YSIZE,        MathMax(1, h));
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

   //--- Draw scrollbar — always call AFTER drawing your rows
   //    tabIdx  : index 0-9 matching your tab
   //    total   : total number of items/rows
   //    rowH    : pixel height of one row
   //    headerH : pixel height of header above rows (0 if none)
   void           DrawScrollbar(int tabIdx, int total, int rowH, int headerH)
     {
      int sbW    = 14;
      int sbX    = m_cx + m_cw - sbW;
      int sbY    = m_cy + headerH;
      int sbH    = m_ch - headerH;
      int arrowH = 16;
      if(sbH < 30) return;

      int visRows = sbH / MathMax(rowH, 1);
      if(total <= visRows) return;

      string pfx = m_prefix + "c_sb" + IntegerToString(tabIdx);

      SBRect(pfx + "trk", sbX, sbY, sbW, sbH, C'18,25,45', C'70,110,190', 1);
      SBRect(pfx + "up",  sbX, sbY, sbW, arrowH, C'45,80,150', C'100,150,240', 1, true);
      SBLabel(pfx + "ula", sbX + sbW/2, sbY + arrowH/2, "^", C'220,240,255');
      SBRect(pfx + "dn",  sbX, sbY + sbH - arrowH, sbW, arrowH, C'45,80,150', C'100,150,240', 1, true);
      SBLabel(pfx + "dla", sbX + sbW/2, sbY + sbH - arrowH/2, "v", C'220,240,255');

      int trackH    = sbH - arrowH * 2;
      int thumbH    = MathMax(20, (int)((double)visRows / total * trackH));
      int maxScroll = total - visRows;
      int sc        = m_scrollPosArr[tabIdx];
      int thumbY    = sbY + arrowH +
                      (maxScroll > 0 ? (int)((double)sc / maxScroll * (trackH - thumbH)) : 0);
      SBRect(pfx + "thm", sbX + 1, thumbY,   sbW - 2, thumbH, C'70,130,220', C'130,180,255', 1);
      SBRect(pfx + "thl", sbX + 2, thumbY + 1, sbW - 4, 3,    C'180,220,255', C'180,220,255', 0);
     }

   void           ClampScroll(int tabIdx, int total, int rowH, int headerH)
     {
      int visR  = (m_ch - headerH) / MathMax(rowH, 1);
      int maxSc = MathMax(0, total - visR);
      m_scrollPosArr[tabIdx] = (int)MathMax(0, MathMin(maxSc, m_scrollPosArr[tabIdx]));
     }

   bool           ScrollArrow(int tabIdx, string objName, int total, int rowH, int headerH)
     {
      string pfx = m_prefix + "c_sb" + IntegerToString(tabIdx);
      int visR   = (m_ch - headerH) / MathMax(rowH, 1);
      int maxSc  = MathMax(0, total - visR);
      if(objName == pfx + "up" || objName == pfx + "ula")
        { m_scrollPosArr[tabIdx] = MathMax(0,    m_scrollPosArr[tabIdx] - 1); return true; }
      if(objName == pfx + "dn" || objName == pfx + "dla")
        { m_scrollPosArr[tabIdx] = MathMin(maxSc, m_scrollPosArr[tabIdx] + 1); return true; }
      return false;
     }

   //+----------------------------------------------------------------+
   //|  Tab renderers — vul hier je eigen inhoud in                  |
   //+----------------------------------------------------------------+
   void           DrawTab(int tabIdx)
     {
      // Placeholder: laat zien welke tab actief is
      string name = "Tab " + IntegerToString(tabIdx + 1);
      L("tab_placeholder",
        m_cx + m_cw / 2, m_cy + m_ch / 2,
        name + " — voeg hier je inhoud toe",
        COL_TEXT_MUTED, 10, "Segoe UI", 11, ANCHOR_CENTER);
     }

   // Specifieke tab-methodes — vervang DrawTab() door eigen logica per tab
   void           DrawTab1()  { DrawTab(0); }
   void           DrawTab2()  { DrawTab(1); }
   void           DrawTab3()  { DrawTab(2); }
   void           DrawTab4()  { DrawTab(3); }
   void           DrawTab5()  { DrawTab(4); }
   void           DrawTab6()  { DrawTab(5); }
   void           DrawTab7()  { DrawTab(6); }
   void           DrawTab8()  { DrawTab(7); }
   void           DrawTab9()  { DrawTab(8); }
   void           DrawTab10() { DrawTab(9); }

public:
                  CCleanGUI_Content(long chartID, string prefix)
     : m_chartID(chartID), m_prefix(prefix),
       m_cx(0), m_cy(0), m_cw(0), m_ch(0), m_activeTab(0),
       m_thumbDragging(false), m_thumbDragTab(-1),
       m_thumbDragStartY(0), m_thumbDragStartSc(0)
     {
      for(int i = 0; i < 10; i++) m_scrollPosArr[i] = 0;
     }

                 ~CCleanGUI_Content() { ClearContent(); }

   void           SetGeometry(int cx, int cy, int cw, int ch)
     { m_cx = cx; m_cy = cy; m_cw = cw; m_ch = ch; }

   void           SetActiveTab(int t) { m_activeTab = t; }

   void           Redraw()
     {
      ClearContent();
      switch(m_activeTab)
        {
         case 0: DrawTab1();  break;
         case 1: DrawTab2();  break;
         case 2: DrawTab3();  break;
         case 3: DrawTab4();  break;
         case 4: DrawTab5();  break;
         case 5: DrawTab6();  break;
         case 6: DrawTab7();  break;
         case 7: DrawTab8();  break;
         case 8: DrawTab9();  break;
         case 9: DrawTab10(); break;
        }
     }

   //--- Scrollbar arrow click via object name (call from GUIManager)
   bool           OnScrollbarClick(string objName)
     {
      // Voeg hier je tab-specifieke row counts en row heights in
      // Voorbeeld: tabIdx=0 heeft 20 rijen van 22px met 20px header
      // ScrollArrow(0, objName, m_myRowCount, 22, 20);
      return false;
     }

   //--- Mouse wheel (call from GUIManager CHARTEVENT_MOUSE_WHEEL)
   bool           OnMouseWheel(int mx, int my, int delta)
     {
      if(mx < m_cx || mx > m_cx + m_cw) return false;
      if(my < m_cy || my > m_cy + m_ch) return false;
      // Voeg hier je tab-specifieke scroll logica in
      // Voorbeeld: if(m_activeTab == 0) return OnScroll(0, delta, m_myRowCount, 22, 20);
      return false;
     }

   //--- Thumb drag
   bool           OnThumbMouseDown(int mx, int my)
     {
      int sbW   = 14;
      int sbX   = m_cx + m_cw - sbW;
      if(mx < sbX || mx > sbX + sbW) return false;
      if(my < m_cy || my > m_cy + m_ch) return false;

      // Detecteer welke tab scrollbaar is en wat de headerH/rowH zijn
      // Pas aan per tab die je scrollbaar maakt
      int headerH = 20;
      int rowH    = 22;
      int arrowH  = 16;
      int sbY     = m_cy + headerH;
      int sbH     = m_ch - headerH;
      if(my < sbY + arrowH || my > sbY + sbH - arrowH) return false;

      m_thumbDragging    = true;
      m_thumbDragTab     = m_activeTab;
      m_thumbDragStartY  = my;
      m_thumbDragStartSc = m_scrollPosArr[m_activeTab];
      return true;
     }

   bool           OnThumbMouseMove(int my)
     {
      if(!m_thumbDragging) return false;
      int t      = m_thumbDragTab;
      int rowH   = 22;
      int headerH= 20;
      int sbH    = m_ch - headerH;
      int arrowH = 16;
      int trackH = sbH - arrowH * 2;
      // Pas total aan per tab
      int total  = 100;
      int visR   = trackH / MathMax(rowH, 1);
      int maxSc  = MathMax(1, total - visR);
      int thumbH = MathMax(20, (int)((double)visR / total * trackH));
      double ratio = (double)(my - m_thumbDragStartY) / MathMax(1, trackH - thumbH);
      m_scrollPosArr[t] = (int)MathMax(0, MathMin(maxSc,
                           m_thumbDragStartSc + (int)(ratio * maxSc)));
      return true;
     }

   void           OnThumbMouseUp()   { m_thumbDragging = false; m_thumbDragTab = -1; }
   bool           IsThumbDragging()  const { return m_thumbDragging; }
   int            GetScrollPos(int t) const { return m_scrollPosArr[t]; }
  };

#endif
//+------------------------------------------------------------------+