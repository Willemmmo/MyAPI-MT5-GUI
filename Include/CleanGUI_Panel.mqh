//+------------------------------------------------------------------+
//|  GUIPanel.mqh  —  Main window panel                              |
//|  MyAPI v2.0.0                                                    |
//+------------------------------------------------------------------+
#ifndef CLEANGUI_PANEL_MQH
#define CLEANGUI_PANEL_MQH
#include "CleanGUI_Base.mqh"
#include "CleanGUI_TabBar.mqh"
#include "CleanGUI_Content.mqh"


//+------------------------------------------------------------------+
//| CGUIPanel — panel chrome + tabs + content, extends CGUIBase      |
//+------------------------------------------------------------------+
class CCleanGUI_Panel : public CGUIBase
  {
private:
   CCleanGUI_TabBar    *m_tabBar;
   CCleanGUI_Content   *m_content;

   string         m_title;
   string         m_symbol;
   string         m_timeframe;

   //--- Status bar values
   string         m_statusPrice;
   string         m_statusSpread;
   string         m_statusVersion;
   bool           m_connected;

   //--- Minimize
   bool           m_minimized;
   int            m_fullHeight;

   // Note: static const not supported in MQL5 — use define or enum
   enum { RESIZE_SZ = 16 };

   //--- Draw title bar chrome
   void           DrawTitleBar()
     {
      //--- Drop shadow
      SetRect("shadow", m_x + 3, m_y + 3, m_width, m_height,
              C'8,10,16', C'8,10,16', 0, 0);
      //--- Panel outer
      SetRect("bg", m_x, m_y, m_width, m_height,
              COL_BG_PANEL, COL_BORDER_PANEL, 1, 1);
      //--- Title bar
      SetRect("tb", m_x, m_y, m_width, GUI_TITLE_H,
              COL_BG_TITLEBAR, COL_BORDER_PANEL, 1, 2);
      //--- Icon box
      SetRect("ico_bg", m_x + 6, m_y + 7, 14, 14,
              COL_BORDER_TABLINE, COL_CYAN, 1, 3);
      SetLabel("ico_lbl", m_x + 13, m_y + 14, "M",
               clrWhite, 8, "Segoe UI Bold", 4, ANCHOR_CENTER);
      //--- Title text
      string ttl = m_title + "  |  " + m_symbol + " " + m_timeframe;
      SetLabel("ttl", m_x + 26, m_y + (GUI_TITLE_H - 9) / 2,
               ttl, COL_TEXT_TITLE, 9, "Segoe UI Bold", 3);
      //--- Control buttons
      int bx = m_x + m_width - 12;
      DrawTBBtn("cl", bx,      m_y + 9, C'224,80,80');
      DrawTBBtn("mx", bx - 17, m_y + 9, C'64,192,96');
      DrawTBBtn("mn", bx - 34, m_y + 9, C'240,192,64');
     }

   void           DrawTBBtn(string tag, int x, int y, color bg)
     {
      SetRect("btn_" + tag, x, y, 11, 11, bg, bg, 0, 3);
     }

   //--- Status bar
   void           DrawStatusBar()
     {
      if(m_minimized) return;
      int sy   = m_y + m_height - GUI_STATUSBAR_H;
      int ty   = sy + (GUI_STATUSBAR_H - 8) / 2 + 1;  // vertical center for text
      int doty = sy + GUI_STATUSBAR_H / 2 - 3;         // dot centered, slightly lower

      SetRect("sb",      m_x, sy, m_width, GUI_STATUSBAR_H,
              COL_BG_STATUSBAR, COL_BORDER_PANEL, 1, 2);
      SetRect("sb_line", m_x, sy, m_width, 1, C'50,75,120', C'50,75,120', 0, 3);

      // Status dot — green when connected, red when not
      color dc    = m_connected ? COL_GREEN : COL_RED;
      SetRect("sb_dot", m_x + 9, doty, 6, 6, dc, dc, 0, 3);

      // "Connected" / "Disconnected" — same color as dot so it matches status
      color connCol = m_connected ? COL_GREEN : COL_RED;
      SetLabel("sb_conn",  m_x + 20,  ty,
               m_connected ? "Connected" : "Disconnected",
               connCol, 8, "Courier New", 3);

      // Symbol — bright white/blue so clearly readable
      SetLabel("sb_sym",   m_x + 95,  ty,
               m_symbol, C'180,210,255', 8, "Courier New", 3);

      // Price — bright green
      SetLabel("sb_price", m_x + 148, ty,
               m_statusPrice, COL_GREEN, 8, "Courier New", 3);

      // Spread — soft grey-blue, readable but secondary
      SetLabel("sb_sprd",  m_x + 215, ty,
               "Sprd: " + m_statusSpread, C'140,170,210', 8, "Courier New", 3);
      // Right corner reserved for resize handle
     }

   //--- Delete and recreate resize dots so they are always on top
   //    MT5 visual stacking = creation order, not z-order.
   //    We delete and recreate each redraw so they are always created LAST.
   void           DrawResizeHandle()
     {
      if(m_minimized) return;

      // Delete old dots first so recreation puts them on top
      for(int i = 0; i < 10; i++)
        {
         string dn = m_prefix + "rh" + IntegerToString(i);
         if(ObjectFind(m_chartID, dn) >= 0)
            ObjectDelete(m_chartID, dn);
        }

      color tc = C'120,180,255';  // bright light blue

      // Triangle in bottom-right corner of the panel, INSIDE the statusbar
      // Anchor: absolute pixel coords of panel bottom-right corner
      int ax = m_x + m_width  - 3;   // right edge
      int ay = m_y + m_height - 3;   // bottom edge

      // Draw diagonal stripes from corner outward — each row one step wider
      // Row 0 (closest to corner): 1 dot
      PutDot("rh0", ax,      ay,      4, 4, tc);
      // Row 1: 2 dots
      PutDot("rh1", ax - 7,  ay,      4, 4, tc);
      PutDot("rh2", ax,      ay - 7,  4, 4, tc);
      // Row 2: 3 dots
      PutDot("rh3", ax - 14, ay,      4, 4, tc);
      PutDot("rh4", ax - 7,  ay - 7,  4, 4, tc);
      PutDot("rh5", ax,      ay - 14, 4, 4, tc);
     }

   void           PutDot(string tag, int x, int y, int w, int h, color clr)
     {
      string n = m_prefix + tag;
      ObjectCreate(m_chartID, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartID, n, OBJPROP_SELECTABLE,  false);
      ObjectSetInteger(m_chartID, n, OBJPROP_HIDDEN,      true);
      ObjectSetInteger(m_chartID, n, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartID, n, OBJPROP_XDISTANCE,   x);
      ObjectSetInteger(m_chartID, n, OBJPROP_YDISTANCE,   y);
      ObjectSetInteger(m_chartID, n, OBJPROP_XSIZE,       w);
      ObjectSetInteger(m_chartID, n, OBJPROP_YSIZE,       h);
      ObjectSetInteger(m_chartID, n, OBJPROP_BGCOLOR,     clr);
      ObjectSetInteger(m_chartID, n, OBJPROP_BORDER_COLOR,clr);
      ObjectSetInteger(m_chartID, n, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(m_chartID, n, OBJPROP_WIDTH,       0);
      ObjectSetInteger(m_chartID, n, OBJPROP_ZORDER,      99);
     }

   //--- Push updated geometry into content and redraw it
   void           RefreshContent()
     {
      if(!m_content || m_minimized) return;
      int cx = m_x + 1;
      int cy = m_y + GUI_TITLE_H + GUI_TAB_H + 1;
      int cw = m_width - 2;
      int ch = m_height - GUI_TITLE_H - GUI_TAB_H - GUI_STATUSBAR_H - 2;
      m_content.SetGeometry(cx, cy, cw, ch);
      m_content.SetActiveTab(m_tabBar != NULL ? m_tabBar.GetActiveTab() : 0);
      m_content.Redraw();
     }

public:
                  CCleanGUI_Panel(long chartID, string prefix, string title,
                            int x, int y, int w, int h)
     : CGUIBase(chartID, prefix, x, y, w, h),
       m_title(title), m_symbol("EURUSD"), m_timeframe("H1"),
       m_statusPrice("1.08380"), m_statusSpread("0.8"),
       m_statusVersion("MyAPI v2.0"), m_connected(true),
       m_minimized(false), m_fullHeight(h)
     {
      m_tabBar  = new CCleanGUI_TabBar(chartID, prefix);
      m_content = new CCleanGUI_Content(chartID, prefix);
     }

                 ~CCleanGUI_Panel()
     {
      if(m_tabBar)  { delete m_tabBar;  m_tabBar  = NULL; }
      if(m_content) { delete m_content; m_content = NULL; }
      DeleteAll();
     }

   //--- Accessors
   void           SetTabLabel(int i, string lbl)
     { if(m_tabBar != NULL) m_tabBar.SetTabLabel(i, lbl); }

   int            GetActiveTab() const
     { return m_tabBar != NULL ? m_tabBar.GetActiveTab() : 0; }

   void           SetTitle(string t)   { m_title = t; }
   void           SetSymbol(string s, string tf) { m_symbol = s; m_timeframe = tf; }

   void           SetStatusData(bool conn, string price, string spread, string ver)
     { m_connected=conn; m_statusPrice=price; m_statusSpread=spread; m_statusVersion=ver; }

   CCleanGUI_Content   *Content() { return m_content; }

   //--- Content area coords (for external use)
   int            GetContentX()      const { return m_x + 1; }
   int            GetContentY()      const { return m_y + GUI_TITLE_H + GUI_TAB_H + 1; }
   int            GetContentWidth()  const { return m_width - 2; }
   int            GetContentHeight() const { return m_height - GUI_TITLE_H - GUI_TAB_H - GUI_STATUSBAR_H - 2; }

   //--- Full redraw (implements pure virtual from CGUIBase)
   virtual void   Redraw()
     {
      if(m_minimized)
        {
         DrawTitleBar();
         ChartRedraw(m_chartID);
         return;
        }
      DrawTitleBar();
      if(m_tabBar != NULL)
        {
         m_tabBar.SetGeometry(m_x, m_y + GUI_TITLE_H, m_width);
         m_tabBar.Redraw();
        }
      // Content background
      int cy = m_y + GUI_TITLE_H + GUI_TAB_H;
      int ch = m_height - GUI_TITLE_H - GUI_TAB_H - GUI_STATUSBAR_H;
      SetRect("cbg", m_x + 1, cy, m_width - 2, ch, COL_BG_CONTENT, COL_BORDER_PANEL, 0, 2);
      DrawStatusBar();
      DrawResizeHandle();
      RefreshContent();
      ChartRedraw(m_chartID);
     }

   void           Show() { Redraw(); }

   void           Hide()
     {
      if(m_tabBar  != NULL) m_tabBar.DeleteAll();
      DeleteAll();
      ChartRedraw(m_chartID);
     }

   void           ToggleMinimize()
     {
      if(m_minimized)
        { m_height = m_fullHeight; m_minimized = false; }
      else
        { m_fullHeight = m_height; m_height = GUI_TITLE_H; m_minimized = true; }
      DeleteAll();
      if(m_tabBar != NULL) m_tabBar.DeleteAll();
      Redraw();
     }

   //--- Check if point is inside a title bar button
   //    Buttons drawn at: close=bx, max=bx-17, min=bx-34  (bx = m_x+m_width-12)
   bool           HitBtn(int mx, int my, int bx)
     {
      return (mx >= bx && mx <= bx + 11 && my >= m_y + 9 && my <= m_y + 20);
     }

   //--- Event forwarding
   virtual bool   OnMouseDown(int mx, int my)
     {
      int bx_cl = m_x + m_width - 12;   // close  (red)
      int bx_mx = bx_cl - 17;           // max    (green)
      int bx_mn = bx_mx - 17;           // min    (yellow)

      //--- Close button → shut down the EA
      if(HitBtn(mx, my, bx_cl))
        {
         Hide();
         ExpertRemove();
         return true;
        }

      //--- Max button → restore from minimize (or no-op if already full size)
      if(HitBtn(mx, my, bx_mx))
        {
         if(m_minimized) ToggleMinimize();
         return true;
        }

      //--- Min button → toggle minimize
      if(HitBtn(mx, my, bx_mn))
        {
         ToggleMinimize();
         return true;
        }

      //--- Scrollbar thumb drag start
      if(!m_minimized && m_content != NULL && m_content.OnThumbMouseDown(mx, my))
        return true;  // don't redraw yet — wait for move

      //--- Tab bar clicks
      if(!m_minimized && m_tabBar != NULL && m_tabBar.OnMouseDown(mx, my))
        { RefreshContent(); ChartRedraw(m_chartID); return true; }

      //--- Drag / resize via base class
      return CGUIBase::OnMouseDown(mx, my);
     }

   virtual bool   OnMouseMove(int mx, int my)
     {
      if(m_content != NULL && m_content.IsThumbDragging())
        {
         if(m_content.OnThumbMouseMove(my))
           { RefreshContent(); ChartRedraw(m_chartID); }
         return true;
        }
      if(!m_minimized && m_tabBar != NULL) m_tabBar.OnMouseMove(mx, my);
      return CGUIBase::OnMouseMove(mx, my);
     }

   virtual bool   OnMouseUp(int mx, int my)
     {
      if(m_content != NULL && m_content.IsThumbDragging())
        { m_content.OnThumbMouseUp(); RefreshContent(); ChartRedraw(m_chartID); return true; }
      if(!m_minimized && m_tabBar != NULL) m_tabBar.OnMouseUp(mx, my);
      return CGUIBase::OnMouseUp(mx, my);
     }
  };

#endif
//+------------------------------------------------------------------+
