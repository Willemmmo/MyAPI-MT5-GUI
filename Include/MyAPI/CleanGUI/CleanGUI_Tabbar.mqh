//+------------------------------------------------------------------+
//|  GUITabBar.mqh  —  10-tab navigation bar                         |
//|  MyAPI v2.0.0                                                    |
//+------------------------------------------------------------------+
#ifndef CLEANGUI_TABBAR_MQH
#define CLEANGUI_TABBAR_MQH
#include "CleanGUI_Base.mqh"

//+------------------------------------------------------------------+
//| CCleanGUI_TabBar — tab strip with active accent line + hover states    |
//+------------------------------------------------------------------+
class CCleanGUI_TabBar
  {
private:
   long           m_chartID;
   string         m_prefix;
   int            m_x, m_y;
   int            m_totalWidth;
   int            m_activeTab;
   int            m_hoverTab;
   string         m_labels[GUI_TAB_COUNT];

   //--- Object name helpers
   string         RN(int i)  { return m_prefix + "tb_rect_"   + IntegerToString(i); }
   string         TN(int i)  { return m_prefix + "tb_text_"   + IntegerToString(i); }
   string         AN(int i)  { return m_prefix + "tb_accent_" + IntegerToString(i); }
   string         BGN()      { return m_prefix + "tb_bg"; }

   int            TW(int i)  // tab width
     {
      int w = m_totalWidth / GUI_TAB_COUNT;
      return (i == GUI_TAB_COUNT - 1) ? (m_totalWidth - i * w) : w;
     }
   int            TX(int i) { return m_x + i * (m_totalWidth / GUI_TAB_COUNT); }

   void           PutRect(string n, int x, int y, int w, int h,
                          color bg, color brd, int bw, int z)
     {
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

   void           DrawTab(int i)
     {
      int   tx     = TX(i);
      int   tw     = TW(i);
      bool  active = (i == m_activeTab);
      bool  hover  = (i == m_hoverTab && !active);
      color bg     = active ? COL_BG_TAB_ACTIVE : (hover ? COL_BG_TAB_HOVER : COL_BG_TABBAR);
      color tc     = active ? COL_TEXT_ACTIVE    : COL_TEXT_INACTIVE;

      PutRect(RN(i), tx, m_y, tw - 1, GUI_TAB_H, bg, COL_BORDER_TAB, 1, 2);

      //--- Tab text centered
      string tn = TN(i);
      if(ObjectFind(m_chartID, tn) < 0)
        {
         ObjectCreate(m_chartID, tn, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(m_chartID, tn, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(m_chartID, tn, OBJPROP_HIDDEN,     true);
        }
      ObjectSetInteger(m_chartID, tn, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartID, tn, OBJPROP_XDISTANCE, tx + tw / 2);
      ObjectSetInteger(m_chartID, tn, OBJPROP_YDISTANCE, m_y + GUI_TAB_H / 2 - 4);
      ObjectSetString (m_chartID, tn, OBJPROP_TEXT,      m_labels[i]);
      ObjectSetInteger(m_chartID, tn, OBJPROP_COLOR,     tc);
      ObjectSetInteger(m_chartID, tn, OBJPROP_FONTSIZE,  8);
      ObjectSetString (m_chartID, tn, OBJPROP_FONT,      active ? "Segoe UI Bold" : "Segoe UI");
      ObjectSetInteger(m_chartID, tn, OBJPROP_ANCHOR,    ANCHOR_CENTER);
      ObjectSetInteger(m_chartID, tn, OBJPROP_ZORDER,    4);

      //--- Active accent line (bottom 2px, bright blue)
      string an = AN(i);
      if(active)
         PutRect(an, tx, m_y + GUI_TAB_H - 2, tw - 1, 2,
                 COL_BORDER_TABLINE, COL_BORDER_TABLINE, 0, 5);
      else if(ObjectFind(m_chartID, an) >= 0)
         ObjectDelete(m_chartID, an);
     }

public:
                  CCleanGUI_TabBar(long chartID, string prefix)
     : m_chartID(chartID), m_prefix(prefix),
       m_x(0), m_y(0), m_totalWidth(300),
       m_activeTab(0), m_hoverTab(-1)
     {
      string def[GUI_TAB_COUNT] = {
         "Overview","Positions","Orders","History","Risk",
         "Signals","News","Settings","Logs","About"
      };
      for(int i = 0; i < GUI_TAB_COUNT; i++)
         m_labels[i] = def[i];
     }

   void  SetGeometry(int x, int y, int totalWidth)
     { m_x = x; m_y = y; m_totalWidth = totalWidth; }

   void  SetTabLabel(int i, string lbl)
     { if(i >= 0 && i < GUI_TAB_COUNT) m_labels[i] = lbl; }

   int   GetActiveTab() const { return m_activeTab; }
   void  SetActiveTab(int i)  { if(i >= 0 && i < GUI_TAB_COUNT) m_activeTab = i; }

   void  Redraw()
     {
      PutRect(BGN(), m_x, m_y, m_totalWidth, GUI_TAB_H,
              COL_BG_TABBAR, COL_BORDER_TAB, 1, 1);
      for(int i = 0; i < GUI_TAB_COUNT; i++)
         DrawTab(i);
     }

   int   TabAtPoint(int mx, int my) const
     {
      if(my < m_y || my > m_y + GUI_TAB_H)      return -1;
      if(mx < m_x || mx > m_x + m_totalWidth)   return -1;
      int w   = m_totalWidth / GUI_TAB_COUNT;
      int idx = (mx - m_x) / MathMax(1, w);
      return MathMin(idx, GUI_TAB_COUNT - 1);
     }

   bool  OnMouseDown(int mx, int my)
     {
      int idx = TabAtPoint(mx, my);
      if(idx >= 0 && idx != m_activeTab)
        {
         m_activeTab = idx;
         Redraw();
         return true;
        }
      return idx >= 0;
     }

   bool  OnMouseMove(int mx, int my)
     {
      int prev = m_hoverTab;
      m_hoverTab = TabAtPoint(mx, my);
      if(m_hoverTab != prev) { Redraw(); return true; }
      return false;
     }

   void  OnMouseUp(int mx, int my) {}

   void  DeleteAll()
     {
      string bg = BGN();
      if(ObjectFind(m_chartID, bg) >= 0) ObjectDelete(m_chartID, bg);
      for(int i = 0; i < GUI_TAB_COUNT; i++)
        {
         if(ObjectFind(m_chartID, RN(i)) >= 0) ObjectDelete(m_chartID, RN(i));
         if(ObjectFind(m_chartID, TN(i)) >= 0) ObjectDelete(m_chartID, TN(i));
         if(ObjectFind(m_chartID, AN(i)) >= 0) ObjectDelete(m_chartID, AN(i));
        }
     }
  };

#endif
//+------------------------------------------------------------------+