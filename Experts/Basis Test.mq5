//+------------------------------------------------------------------+
//|                                                Gemini_Expert.mq5 |
//|                                       Copyright 2024, Gemini AI  |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Gemini AI"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- Inclusief de benodigde bibliotheken
#include <Trade/Trade.mqh>      // Voor handelsfuncties
#include <Controls/Dialog.mqh>  // Voor het hoofdvenster van het paneel
#include <Controls/Button.mqh>  // Voor knoppen
#include <Controls/Edit.mqh>    // Voor invoervelden
#include <Controls/Label.mqh>   // Voor tekstlabels

//--- Globale variabelen
CTrade      trade;              // Handelsobject

//--- Input parameters
input int InpMagicNumber = 654321; // Uniek ID voor de orders van deze EA

//+------------------------------------------------------------------+
//| Class CResizePanel                                               |
//+------------------------------------------------------------------+
class CResizePanel : public CAppDialog
  {
public:
   CEdit             m_lot_size;
   CButton           m_tabs[10];      // 10 nieuwe tabbladen
   CButton           m_resize_handle; // Knop om te slepen
   CLabel            m_lbl_lot;
   int               m_current_tab;
   bool              m_resizing;      // Status: zijn we aan het slepen?
   int               m_drag_x;        // Laatste muis X
   int               m_drag_y;        // Laatste muis Y

                     CResizePanel() : m_current_tab(0), m_resizing(false) {}
                    ~CResizePanel() {}

   virtual bool      Create(const long chart, const string name, const int subwin, const int x1, const int y1, const int x2, const int y2);
   virtual bool      OnResize();
   virtual void      ChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void              UpdateUI();
  };

CResizePanel ExtPanel;

//+------------------------------------------------------------------+
//| Create                                                           |
//+------------------------------------------------------------------+
bool CResizePanel::Create(const long chart, const string name, const int subwin, const int x1, const int y1, const int x2, const int y2)
  {
   if(!CAppDialog::Create(chart, name, subwin, x1, y1, x2, y2))
      return(false);

   // Bereken relatieve posities op basis van de startpositie (x1, y1)
   // Originele layout: Panel op 50,50. Tabs op 60,80. Offset X=10, Y=30.
   // De posities worden nu volledig beheerd in OnResize().
   // We creëren de controls hier op (0,0) en verplaatsen ze daarna.
   int tabW = 55; int tabH = 25; int gap = 5;

   //--- Tabs
   for(int i=0; i<10; i++)
     {
      if(!m_tabs[i].Create(chart, name + "Tab" + IntegerToString(i), subwin, 0, 0, tabW, tabH))
         return(false);
      m_tabs[i].Text("Tab " + IntegerToString(i+1));
      Add(m_tabs[i]);
     }

   // Lots Label
   if(!m_lbl_lot.Create(chart, name + "LotLabel", subwin, 0, 0, 50, 20)) return(false);
   m_lbl_lot.Text("Lots:");
   Add(m_lbl_lot);

   // Lot Edit
   if(!m_lot_size.Create(chart, name + "LotEdit", subwin, 0, 0, 100, 20)) return(false);
   m_lot_size.Text("0.01");
   Add(m_lot_size);

   // Resize Handle (Rechtsonder)
   if(!m_resize_handle.Create(chart, name + "Resize", subwin, 0, 0, 15, 15)) return(false);
   m_resize_handle.Text("◢");
   m_resize_handle.ColorBackground(clrNONE);
   m_resize_handle.ColorBorder(clrNONE);
   m_resize_handle.Color(clrGray);
   Add(m_resize_handle);

   UpdateUI();
   OnResize(); // Forceer layout update zodat controls direct de ruimte vullen
   return(true);
  }

//+------------------------------------------------------------------+
//| OnResize handler                                                 |
//+------------------------------------------------------------------+
bool CResizePanel::OnResize()
  {
   if(!CAppDialog::OnResize())
      return(false);

   // Marges en afmetingen definiëren
   int border = 1;
   int caption_height = 22;

   // Totale breedte en hoogte van het paneel
   int total_w = Width();
   int total_h = Height();

   // Positioneer tabs achter elkaar
   int tab_y = caption_height + 1; // Direct onder de titelbalk
   int left = border;              // Start bij de linker rand
   int available_w = total_w - (2 * border);

   for(int i=0; i<10; i++)
     {
      int x1 = left + (i * available_w) / 10;
      int x2 = left + ((i + 1) * available_w) / 10;
      m_tabs[i].Move(x1, tab_y);
      m_tabs[i].Width(x2 - x1);
     }

   // Positioneer Lot controls onder de tabs
   int margin = 10;
   int content_y = tab_y + m_tabs[0].Height() + margin;
   m_lbl_lot.Move(left + margin, content_y + 2);
   m_lot_size.Move(m_lbl_lot.Right() + 5, content_y);
   m_lot_size.Width(60);
   
   // Verplaats de resize handle naar rechtsonder
   // Helemaal in de hoek
   m_resize_handle.Move(total_w - m_resize_handle.Width() - border, total_h - m_resize_handle.Height() - border);
   
   return(true);
  }

//+------------------------------------------------------------------+
//| ChartEvent handler voor custom resizing                          |
//+------------------------------------------------------------------+
void CResizePanel::ChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   // Roep eerst de basis handler aan
   CAppDialog::ChartEvent(id, lparam, dparam, sparam);

   // Custom resize logica bij muisbeweging
   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      int x = (int)lparam;
      int y = (int)dparam;
      int state = (int)sparam;
      int left_btn_mask = 1;

      // Als linkermuisknop is ingedrukt
      if((state & left_btn_mask) == left_btn_mask)
        {
         if(!m_resizing)
           {
            // Check of we op de resize handle klikken
            // Coördinaten omrekenen naar absoluut scherm
            int abs_x = Left() + m_resize_handle.Left();
            int abs_y = Top() + m_resize_handle.Top();
            
            if(x >= abs_x && x <= abs_x + m_resize_handle.Width() &&
               y >= abs_y && y <= abs_y + m_resize_handle.Height())
              {
               m_resizing = true;
               m_drag_x = x;
               m_drag_y = y;
               ChartSetInteger(m_chart_id, CHART_MOUSE_SCROLL, false); // Blokkeer scrollen tijdens resize
              }
           }
         else
           {
            // We zijn aan het slepen -> update grootte
            int dx = x - m_drag_x;
            int dy = y - m_drag_y;

            if(dx != 0 || dy != 0)
              {
               int new_w = Width() + dx;
               int new_h = Height() + dy;

               // Minimum afmetingen bewaken
               if(new_w > 200 && new_h > 150)
                 {
                  // Update de interne afmetingen van de klasse
                  Width(new_w);
                  Height(new_h);
                  
                  // Roep OnResize aan om de controls mee te schalen
                  OnResize();
                  
                  m_drag_x = x;
                  m_drag_y = y;
                  ChartRedraw(); // Forceer direct hertekenen voor soepele beweging
                 }
              }
           }
        }
      else
        {
         // Muisknop losgelaten -> stop resizen
         if(m_resizing)
           {
            m_resizing = false;
            ChartSetInteger(m_chart_id, CHART_MOUSE_SCROLL, true);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| UpdateUI                                                         |
//+------------------------------------------------------------------+
void CResizePanel::UpdateUI()
  {
   // 0 = Eerste tab (Trade)
   bool isTradeTab = (m_current_tab == 0);

   // Toon of verberg de trade controls
   m_lbl_lot.Visible(isTradeTab);
   m_lot_size.Visible(isTradeTab);
   
   // Update kleuren van de tabs (Actief = Wit, Inactief = Grijs)
   for(int i=0; i<10; i++)
      m_tabs[i].ColorBackground(m_current_tab == i ? clrWhite : clrSilver);
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Stel het magic number in voor het handelsobject
   trade.SetExpertMagicNumber(InpMagicNumber);

   // Zet muis events aan voor het slepen
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);

//--- Creëer het paneel
   // Paneel groter gemaakt: 300x250 -> 450x400
   if(!ExtPanel.Create(0, "Expert Panel", 0, 50, 50, 450, 400))
     {
      Print("Fout bij het creëren van het paneel!");
      return(INIT_FAILED);
     }
   ExtPanel.Run();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Vernietig het paneel om geheugen vrij te maken
   ExtPanel.Destroy(reason);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- Hier kan logica komen die per tick moet worden uitgevoerd
  }

//+------------------------------------------------------------------+
//| ChartEvent function (VANGT GEBEURTENISSEN OP DE GRAFIEK OP)      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//--- Geef de gebeurtenis door aan het paneel
   ExtPanel.ChartEvent(id, lparam, dparam, sparam);

//--- Update de UI als er geklikt is (bijv. op een tab)
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      // Check of er op een van de 10 tabs is geklikt
      for(int i=0; i<10; i++)
        {
         if(sparam == ExtPanel.m_tabs[i].Name())
           {
            ExtPanel.m_current_tab = i;
            break;
           }
        }
      
      ExtPanel.UpdateUI();
     }
  }