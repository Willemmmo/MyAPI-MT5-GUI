#include <Controls/Dialog.mqh>
#include <Controls/Button.mqh>
#include <Controls/Edit.mqh>
#include <Controls/Label.mqh>

CAppDialog App;

CButton BtnBuy;
CButton BtnSell;
CButton BtnCloseLast;

CEdit   EditLots;
CLabel  LabelLots;
CLabel  ResizeGrip;

bool resizing=false;
bool hoverGrip=false;

int  startW,startH;
int  startMouseX,startMouseY;

#define START_WIDTH  320
#define START_HEIGHT 240
#define MIN_WIDTH    260
#define MIN_HEIGHT   180

//+------------------------------------------------------------------+
int OnInit()
{
   App.Create(0,"Trade",0,50,50,START_WIDTH,START_HEIGHT);

   CreateControls();

   App.Run();
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void CreateControls()
{
   int margin = 20;
   int rowY   = 50;
   int rowGap = 40;

   LabelLots.Create(0,"LabelLots",0,margin,rowY,60,20);
   LabelLots.Text("Lots:");
   App.Add(LabelLots);

   EditLots.Create(0,"EditLots",0,margin+60,rowY,80,22);
   EditLots.Text("0.10");
   App.Add(EditLots);

   rowY += rowGap;

   BtnBuy.Create(0,"BtnBuy",0,margin,rowY,100,30);
   BtnBuy.Text("BUY");
   App.Add(BtnBuy);

   BtnSell.Create(0,"BtnSell",0,margin+110,rowY,100,30);
   BtnSell.Text("SELL");
   App.Add(BtnSell);

   rowY += rowGap;

   BtnCloseLast.Create(0,"BtnCloseLast",0,margin,rowY,200,30);
   BtnCloseLast.Text("Close Last");
   App.Add(BtnCloseLast);

   // Resize grip
   ResizeGrip.Create(0,"ResizeGrip",0,0,0,20,20);
   ResizeGrip.Text("◢");
   ResizeGrip.FontSize(14);
   ResizeGrip.Color(clrGray);
   App.Add(ResizeGrip);

   UpdateLayout();
}
//+------------------------------------------------------------------+
void UpdateLayout()
{
   int w = App.Width();
   int h = App.Height();

   int margin = 20;
   int rowY   = 50;
   int rowGap = 40;

   LabelLots.Move(margin,rowY);
   EditLots.Move(margin+60,rowY);

   rowY += rowGap;

   int buttonWidth = (w - (margin*2) - 10) / 2;

   BtnBuy.Move(margin,rowY);
   BtnBuy.Width(buttonWidth);

   BtnSell.Move(margin + buttonWidth + 10,rowY);
   BtnSell.Width(buttonWidth);

   rowY += rowGap;

   BtnCloseLast.Move(margin,rowY);
   BtnCloseLast.Width(w - margin*2);

   ResizeGrip.Move(w-20,h-20);
}
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   App.ChartEvent(id,lparam,dparam,sparam);

   int mouseX = (int)lparam;
   int mouseY = (int)dparam;

   bool overGrip = (mouseX > App.Width()-20 && mouseY > App.Height()-20);

   // =========================
   // HOVER EFFECT
   // =========================
   if(id==CHARTEVENT_MOUSE_MOVE)
   {
      if(overGrip && !hoverGrip)
      {
         hoverGrip=true;
         ResizeGrip.Color(clrWhite);
         ResizeGrip.Text("◣");
      }
      else if(!overGrip && hoverGrip)
      {
         hoverGrip=false;
         ResizeGrip.Color(clrGray);
         ResizeGrip.Text("◢");
      }

      // RESIZING
      if(resizing)
      {
         int newW = startW + (mouseX - startMouseX);
         int newH = startH + (mouseY - startMouseY);

         if(newW < MIN_WIDTH)  newW = MIN_WIDTH;
         if(newH < MIN_HEIGHT) newH = MIN_HEIGHT;

         App.Width(newW);
         App.Height(newH);

         UpdateLayout();
      }
   }

   // =========================
   // START RESIZE (alleen klik op grip)
   // =========================
   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="ResizeGrip")
   {
      resizing = true;
      startW = App.Width();
      startH = App.Height();
      startMouseX = mouseX;
      startMouseY = mouseY;
   }

   // =========================
   // STOP RESIZE (muis los)
   // =========================
   if(id==CHARTEVENT_CLICK)
   {
      resizing=false;
   }
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   App.Destroy(reason);
}