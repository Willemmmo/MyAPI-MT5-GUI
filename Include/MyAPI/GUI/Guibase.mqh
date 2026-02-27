//+------------------------------------------------------------------+
//|  GUIBase.mqh  —  Drag & Resize foundation                        |
//|  MyAPI v2.0.0                                                    |
//+------------------------------------------------------------------+
#ifndef GUIBASE_MQH
#define GUIBASE_MQH

//--- Minimum dimensions
#define GUI_MIN_WIDTH      380
#define GUI_MIN_HEIGHT     260
#define GUI_RESIZE_ZONE    12

//--- Layout constants
#define GUI_TITLE_H        28
#define GUI_TAB_H          26
#define GUI_STATUSBAR_H    20
#define GUI_TAB_COUNT      10

//--- Color palette matching HTML mockup
#define COL_BG_PANEL       C'20,24,36'
#define COL_BG_CONTENT     C'18,22,31'
#define COL_BG_CARD        C'26,32,53'
#define COL_BG_TITLEBAR    C'26,32,48'
#define COL_BG_TABBAR      C'15,20,32'
#define COL_BG_TAB_ACTIVE  C'26,42,72'
#define COL_BG_TAB_HOVER   C'26,32,53'
#define COL_BG_STATUSBAR   C'12,16,24'
#define COL_BG_LOG         C'12,16,24'
#define COL_BG_INPUT       C'26,32,53'

#define COL_BORDER_PANEL   C'70,100,160'
#define COL_BORDER_CARD    C'50,80,130'
#define COL_BORDER_TAB     C'40,60,110'
#define COL_BORDER_TABLINE C'30,144,255'

#define COL_TEXT_TITLE     C'200,216,240'
#define COL_TEXT_ACTIVE    C'79,168,255'
#define COL_TEXT_INACTIVE  C'106,122,154'
#define COL_TEXT_LABEL     C'74,96,128'
#define COL_TEXT_VALUE     C'200,224,255'
#define COL_TEXT_STATUS    C'58,80,112'
#define COL_TEXT_MUTED     C'80,100,140'

#define COL_GREEN          C'64,208,128'
#define COL_RED            C'224,88,88'
#define COL_BLUE           C'112,176,240'
#define COL_YELLOW         C'192,160,64'
#define COL_CYAN           C'0,198,255'

//+------------------------------------------------------------------+
//| CGUIBase — drag, resize, and object-creation helpers             |
//+------------------------------------------------------------------+
class CGUIBase
  {
protected:
   int            m_x, m_y;
   int            m_width, m_height;
   bool           m_dragging;
   int            m_dragOffsetX, m_dragOffsetY;
   bool           m_resizing;
   int            m_resizeStartX, m_resizeStartY;
   int            m_resizeStartW, m_resizeStartH;
   long           m_chartID;
   string         m_prefix;

   bool           IsInResizeZone(int mx, int my) const
     {
      int rx = m_x + m_width;
      int ry = m_y + m_height;
      return (mx >= rx - GUI_RESIZE_ZONE && mx <= rx + 2 &&
              my >= ry - GUI_RESIZE_ZONE && my <= ry + 2);
     }

   bool           IsInDragZone(int mx, int my) const
     {
      return (mx >= m_x + 1 && mx <= m_x + m_width - 60 &&
              my >= m_y + 1 && my <= m_y + GUI_TITLE_H - 1 &&
              !IsInResizeZone(mx, my));
     }

public:
                  CGUIBase(long chartID, string prefix,
                           int x, int y, int w, int h)
     : m_chartID(chartID), m_prefix(prefix),
       m_x(x), m_y(y), m_width(w), m_height(h),
       m_dragging(false), m_dragOffsetX(0), m_dragOffsetY(0),
       m_resizing(false),
       m_resizeStartX(0), m_resizeStartY(0),
       m_resizeStartW(0), m_resizeStartH(0) {}

   virtual       ~CGUIBase() {}

   int            GetX()      const { return m_x; }
   int            GetY()      const { return m_y; }
   int            GetWidth()  const { return m_width; }
   int            GetHeight() const { return m_height; }

   virtual bool   OnMouseDown(int mx, int my)
     {
      if(IsInResizeZone(mx, my))
        {
         m_resizing     = true;
         m_resizeStartX = mx; m_resizeStartY = my;
         m_resizeStartW = m_width; m_resizeStartH = m_height;
         return true;
        }
      if(IsInDragZone(mx, my))
        {
         m_dragging    = true;
         m_dragOffsetX = mx - m_x;
         m_dragOffsetY = my - m_y;
         return true;
        }
      return false;
     }

   virtual bool   OnMouseMove(int mx, int my)
     {
      if(m_resizing)
        {
         int nw = m_resizeStartW + (mx - m_resizeStartX);
         int nh = m_resizeStartH + (my - m_resizeStartY);
         m_width  = MathMax(GUI_MIN_WIDTH,  nw);
         m_height = MathMax(GUI_MIN_HEIGHT, nh);
         Redraw();
         return true;
        }
      if(m_dragging)
        {
         m_x = mx - m_dragOffsetX;
         m_y = my - m_dragOffsetY;
         int cw = (int)ChartGetInteger(m_chartID, CHART_WIDTH_IN_PIXELS);
         int ch = (int)ChartGetInteger(m_chartID, CHART_HEIGHT_IN_PIXELS);
         m_x = MathMax(0, MathMin(m_x, cw - m_width));
         m_y = MathMax(0, MathMin(m_y, ch - m_height));
         Redraw();
         return true;
        }
      return false;
     }

   virtual bool   OnMouseUp(int mx, int my)
     {
      bool was = m_dragging || m_resizing;
      m_dragging = false;
      m_resizing = false;
      return was;
     }

   virtual void   Redraw() = 0;

   //--- Rect label helper
   void           SetRect(string name, int x, int y, int w, int h,
                          color bg, color border, int bw = 1, int z = 0)
     {
      string n = m_prefix + name;
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
      ObjectSetInteger(m_chartID, n, OBJPROP_BORDER_COLOR, border);
      ObjectSetInteger(m_chartID, n, OBJPROP_BORDER_TYPE,  BORDER_FLAT);
      ObjectSetInteger(m_chartID, n, OBJPROP_WIDTH,        bw);
      ObjectSetInteger(m_chartID, n, OBJPROP_ZORDER,       z);
     }

   //--- Text label helper
   void           SetLabel(string name, int x, int y, string text,
                           color clr, int fs = 9, string font = "Segoe UI",
                           int z = 1, int anchor = ANCHOR_LEFT_UPPER)
     {
      string n = m_prefix + name;
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

   void           DeleteAll()
     {
      int total = ObjectsTotal(m_chartID);
      for(int i = total - 1; i >= 0; i--)
        {
         string name = ObjectName(m_chartID, i);
         if(StringFind(name, m_prefix) == 0)
            ObjectDelete(m_chartID, name);
        }
     }

   void           DeleteGroup(string tag)
     {
      string search = m_prefix + tag;
      int total = ObjectsTotal(m_chartID);
      for(int i = total - 1; i >= 0; i--)
        {
         string name = ObjectName(m_chartID, i);
         if(StringFind(name, search) == 0)
            ObjectDelete(m_chartID, name);
        }
     }
  };

#endif
//+------------------------------------------------------------------+