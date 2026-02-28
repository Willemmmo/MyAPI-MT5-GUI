//+------------------------------------------------------------------+
//|  CleanGUI_Manager.mqh  —  Publieke API                          |
//|  CleanGUI v1.0                                                  |
//+------------------------------------------------------------------+
#ifndef CLEANGUI_MANAGER_MQH
#define CLEANGUI_MANAGER_MQH

#include "CleanGUI_Panel.mqh"

class CCleanGUI_Manager
  {
private:
   CCleanGUI_Panel  *m_panel;
   long              m_chartID;
   bool              m_mouseDown;
   bool              m_scrollHandled;

   static int        ToInt(long v) { return (int)v; }

public:
                     CCleanGUI_Manager(string title   = "CleanGUI Dashboard",
                                       int    x       = 20,
                                       int    y       = 30,
                                       int    width   = 540,
                                       int    height  = 380,
                                       string prefix  = "CLEANGUI_",
                                       long   chartID = 0)
     : m_chartID(chartID == 0 ? ChartID() : chartID),
       m_mouseDown(false), m_scrollHandled(false)
     {
      m_panel = new CCleanGUI_Panel(m_chartID, prefix, title, x, y, width, height);
     }

                    ~CCleanGUI_Manager()
     {
      if(m_panel != NULL) { delete m_panel; m_panel = NULL; }
     }

   void SetTabLabel(int i, string lbl)
     { if(m_panel != NULL) m_panel.SetTabLabel(i, lbl); }

   void SetAllTabLabels(string t0,string t1,string t2,string t3,string t4,
                        string t5,string t6,string t7,string t8,string t9)
     {
      if(m_panel==NULL) return;
      m_panel.SetTabLabel(0,t0); m_panel.SetTabLabel(1,t1);
      m_panel.SetTabLabel(2,t2); m_panel.SetTabLabel(3,t3);
      m_panel.SetTabLabel(4,t4); m_panel.SetTabLabel(5,t5);
      m_panel.SetTabLabel(6,t6); m_panel.SetTabLabel(7,t7);
      m_panel.SetTabLabel(8,t8); m_panel.SetTabLabel(9,t9);
     }

   void SetSymbol(string sym, string tf)
     { if(m_panel != NULL) m_panel.SetSymbol(sym, tf); }

   void SetStatusData(bool conn, string price, string spread, string ver)
     { if(m_panel != NULL) m_panel.SetStatusData(conn, price, spread, ver); }

   int  GetActiveTab()     const { return m_panel != NULL ? m_panel.GetActiveTab()     : 0; }
   int  GetContentX()      const { return m_panel != NULL ? m_panel.GetContentX()      : 0; }
   int  GetContentY()      const { return m_panel != NULL ? m_panel.GetContentY()      : 0; }
   int  GetContentWidth()  const { return m_panel != NULL ? m_panel.GetContentWidth()  : 0; }
   int  GetContentHeight() const { return m_panel != NULL ? m_panel.GetContentHeight() : 0; }

   CCleanGUI_Content *Content()
     { return m_panel != NULL ? m_panel.Content() : NULL; }

   void Show()   { if(m_panel != NULL) m_panel.Show(); }
   void Hide()   { if(m_panel != NULL) m_panel.Hide(); }
   void Redraw() { if(m_panel != NULL) m_panel.Redraw(); }

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
               if(m_mouseDown) m_panel.OnMouseUp(mx, my);
               m_mouseDown = false; m_scrollHandled = false;
              }
            else if(btnHeld && m_scrollHandled) { }
            else if(btnHeld && !m_mouseDown)
              { m_mouseDown = true; m_panel.OnMouseDown(mx, my); }
            else if(btnHeld && m_mouseDown)
              { m_panel.OnMouseMove(mx, my); }
           }
           break;

         case CHARTEVENT_CLICK:
           m_mouseDown = true;
           m_panel.OnMouseDown(mx, my);
           break;

         case CHARTEVENT_OBJECT_CLICK:
           if(m_panel != NULL && m_panel.Content() != NULL)
              if(m_panel.Content().OnScrollbarClick(sparam))
                { m_mouseDown=false; m_scrollHandled=true; m_panel.Redraw(); break; }
           m_mouseDown = true;
           m_panel.OnMouseDown(mx, my);
           break;

         case CHARTEVENT_MOUSE_WHEEL:
           if(m_panel != NULL && m_panel.Content() != NULL)
             {
              int wd = (int)StringToInteger(sparam);
              int steps = wd / 120;
              if(steps == 0) steps = (wd > 0) ? 1 : -1;
              if(m_panel.Content().OnMouseWheel(mx, my, steps))
                 m_panel.Redraw();
             }
           break;
        }
     }
  };

#endif
//+------------------------------------------------------------------+