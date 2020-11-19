//+------------------------------------------------------------------+
//|                               Copyright 2015-2020, EarnForex.com |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015-2020, EarnForex.com"
#property link      "https://www.earnforex.com/metatrader-indicators/Price-Alert/"
#property version   "1.03"
string    Version = "1.03";
#property strict
#property indicator_plots 0

#property description "Issues various alerts depending on price movement."
#property description "E-mail SMTP Server settings should be configured in your platform."
#property description "MetaQuotes ID for push notifications should also be set via MetaTrader."

#property indicator_chart_window

#include <Controls\Dialog.mqh>
#include <Controls\CheckBox.mqh>
#include <Controls\Label.mqh>
#include <Controls\Button.mqh>

//input group "Main"
input double PriceGoesAbove = 0;
input double PriceGoesBelow = 0;
input double PriceIsExactly = 0;
input bool NativeAlert = false; // NativeAlert: If true, a native alert is issued when price level is triggered.
input bool SendEmail = false; // SendEmail: If true, an e-mail is sent to the e-mail address set in your platform.
input bool SendPush = false; // SendPush: If true, a push notification is sent to via the platform.
input bool PanelOnTopOfChart = true; // PanelOnTopOfChart: Draw chart as background?
//input group "Lines"
input color above_line_color = clrGreen; // Above Line Color
input color below_line_color = clrRed; // Below Line Color
input color exactly_line_color = clrYellow; // Exactly Line Color
input ENUM_LINE_STYLE above_line_style = STYLE_SOLID; // Above Line Style
input ENUM_LINE_STYLE below_line_style = STYLE_SOLID; // Below Line Style
input ENUM_LINE_STYLE exactly_line_style = STYLE_SOLID; // Exactly Line Style
input uint above_line_width = 1; // Above Line Width
input uint below_line_width = 1; // Below Line Width
input uint exactly_line_width = 1; // Exactly Line Width
//input group "Position"
input int DefaultPanelPositionX = 0; // PanelPositionX: Panel's X coordinate.
input int DefaultPanelPositionY = 15; // PanelPositionY: Panel's Y coordinate.
input ENUM_BASE_CORNER DefaultPanelPositionCorner = CORNER_LEFT_UPPER; // PanelPositionCorner: Panel's corner.

struct Settings
{
   double PriceAbove;
   double PriceBelow;
   double PriceExactly;
   bool AlertNative;
   bool AlertEmail;
   bool AlertPush;
} sets;

class CPriceAlertPanel : public CAppDialog
{
private:
   CCheckBox         m_ChkEmail, m_ChkPush, m_ChkNative;
   CEdit 		      m_EdtAbove, m_EdtBelow, m_EdtExactly;
   CButton 		      m_BtnAbove, m_BtnBelow, m_BtnExactly;
   CLabel            m_LblURL, m_LblAbove, m_LblBelow, m_LblExactly;
   string            m_FileName;
   double				m_DPIScale;
   bool              NoPanelMaximization; // Crutch variable to prevent panel maximization when Maximize() is called at the indicator's initialization.
 
public:
                     CPriceAlertPanel(void);
                    ~CPriceAlertPanel(void) {};
        

   virtual bool      Create(const long chart, const string name, const int subwin, const int x1, const int y1);
   virtual bool      OnEvent(const int id, const long& lparam, const double& dparam, const string& sparam);   
   virtual void      RefreshValues(); // Gets values from lines and updates values in the panel.
   virtual bool      SaveSettingsOnDisk();
   virtual bool      LoadSettingsFromDisk();
   virtual bool      DeleteSettingsFile();
   virtual bool		Run() {SeekAndDestroyDuplicatePanels(); return(CAppDialog::Run());}
   virtual void      IniFileLoad() {CAppDialog::IniFileLoad();InitObjects();} // Sets panel elements that changed based on changes in input parameters, overwriting the INI settings.
   virtual void		HideShowMaximize(bool max);
   string            IniFileName(void) const;
   virtual void      FixatePanelPosition() {if (!m_minimized) m_norm_rect.SetBound(m_rect); else m_min_rect.SetBound(m_rect);} // Used to fixate panel's position after calling Move(). Otherwise, unless the panel gets dragged by mouse, its position isn't remembered properly in the INI file.
   
   // Remember the panel's location to have the same location for minimized and maximized states.
           int       remember_top, remember_left;
private:     
   virtual bool      InitObjects();
   virtual bool      CreateObjects();
   // Arranges panel objects on the panel.
   virtual bool      DisplayValues();
   virtual void		SeekAndDestroyDuplicatePanels();

   virtual bool      ButtonCreate    (CButton&    Btn, int X1, int Y1, int X2, int Y2, string Name, string Text);
   virtual bool      CheckBoxCreate  (CCheckBox&  Chk, int X1, int Y1, int X2, int Y2, string Name, string Text);
   virtual bool      EditCreate      (CEdit&      Edt, int X1, int Y1, int X2, int Y2, string Name, string Text);
   virtual bool      LabelCreate     (CLabel&     Lbl, int X1, int Y1, int X2, int Y2, string Name, string Text);
   virtual void      Maximize();
   virtual void      Minimize();

	// Event handlers
	void OnClickBtnAbove();
	void OnClickBtnBelow();
	void OnClickBtnExactly();
   void OnEndEditEdtAbove();
   void OnEndEditEdtBelow();
   void OnEndEditEdtExactly();
   void OnChangeChkEmail();
   void OnChangeChkPush();
   void OnChangeChkNative();
};
 
CPriceAlertPanel Panel;

// Global variables:
string PanelCaption = "";
bool Dont_Move_the_Panel_to_Default_Corner_X_Y;
bool Uninitialized = true;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
	Dont_Move_the_Panel_to_Default_Corner_X_Y = true;
	
	// Prevent attachment of second panel if it is not a timeframe/parameters change.
	if (GlobalVariableGet("PA-" + IntegerToString(ChartID()) + "-Flag") > 0)
	{
	   GlobalVariableDel("PA-" + IntegerToString(ChartID()) + "-Flag");
	}
	else
	{
		int indicators_total = ChartIndicatorsTotal(0, 0);
		for (int i = 0; i < indicators_total; i++)
		{
         if (ChartIndicatorName(0, 0, i) == "Price Alert" + IntegerToString(ChartID()))
			{
				Print("Price Alert panel is already attached.");
				return(INIT_FAILED);
			}
		}
	}
	
   IndicatorSetString(INDICATOR_SHORTNAME, "Price Alert" + IntegerToString(ChartID()));
   PanelCaption = "Price Alert (ver. " + Version + ")";

   if (!Panel.LoadSettingsFromDisk())
   {
      sets.PriceAbove = PriceGoesAbove;
      sets.PriceBelow = PriceGoesBelow;
      sets.PriceExactly = PriceIsExactly;
      sets.AlertNative = NativeAlert;
      sets.AlertEmail = SendEmail;
      sets.AlertPush = SendPush;
   }

   if (!Panel.Create(0, PanelCaption, 0, DefaultPanelPositionX, DefaultPanelPositionY)) return(-1);

   string filename = Panel.IniFileName() + Panel.IniFileExt();
   // No ini file - move the panel according to the inputs.
   if (!FileIsExist(filename)) Dont_Move_the_Panel_to_Default_Corner_X_Y = false;

   Panel.IniFileLoad();

   Panel.Run();

   Initialization();
   
   // Brings panel on top of other objects without actual maximization of the panel.
   Panel.HideShowMaximize(false);

   if (!Dont_Move_the_Panel_to_Default_Corner_X_Y)
   {
      int new_x = DefaultPanelPositionX, new_y = DefaultPanelPositionY;
      int chart_width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      int chart_height = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
      int panel_width = Panel.Width();
      int panel_height = Panel.Height();
      
      // Invert coordinate if necessary.
      if (DefaultPanelPositionCorner == CORNER_LEFT_LOWER)
      {
         new_y = chart_height - panel_height - new_y;
      }
      else if (DefaultPanelPositionCorner == CORNER_RIGHT_UPPER)
      {
         new_x = chart_width - panel_width - new_x;
      }
      else if (DefaultPanelPositionCorner == CORNER_RIGHT_LOWER)
      {
         new_x = chart_width - panel_width - new_x;
         new_y = chart_height - panel_height - new_y;
      }
      Panel.remember_left = new_x;
      Panel.remember_top = new_y;
      Panel.Move(new_x, new_y);
      Panel.FixatePanelPosition(); // Remember the panel's new position for the INI file.
   }

   return(INIT_SUCCEEDED);
}

void Initialization()
{
   if (Bars == 0) return; // Data not ready yet.

   if (ObjectFind(0, "SoundWhenPriceGoesAbove") == -1) ObjectCreate(0, "SoundWhenPriceGoesAbove", OBJ_HLINE, 0, TimeCurrent(), sets.PriceAbove);
   else ObjectSetDouble(0, "SoundWhenPriceGoesAbove", OBJPROP_PRICE, sets.PriceAbove);
   ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_STYLE, above_line_style);
   ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_COLOR, above_line_color);
   ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_WIDTH, above_line_width);
   ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_SELECTED, true);

   if (ObjectFind(0, "SoundWhenPriceGoesBelow") == -1) ObjectCreate(0, "SoundWhenPriceGoesBelow", OBJ_HLINE, 0, TimeCurrent(), sets.PriceBelow);
   else ObjectSetDouble(0, "SoundWhenPriceGoesBelow", OBJPROP_PRICE, sets.PriceBelow);
   ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_STYLE, below_line_style);
   ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_COLOR, below_line_color);
   ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_WIDTH, below_line_width);
   ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_SELECTED, true);
	  
   if (ObjectFind(0, "SoundWhenPriceIsExactly") == -1) ObjectCreate(0, "SoundWhenPriceIsExactly", OBJ_HLINE, 0, TimeCurrent(), sets.PriceExactly);
   else ObjectSetDouble(0, "SoundWhenPriceIsExactly", OBJPROP_PRICE, sets.PriceExactly);
   ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_STYLE, exactly_line_style);
   ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_COLOR, exactly_line_color);
   ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_WIDTH, exactly_line_width);
   ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_SELECTED, true);

   ChartSetInteger(0, CHART_FOREGROUND, !PanelOnTopOfChart);
   
   Uninitialized = false;
}

//+------------------------------------------------------------------+
//| Custor indicator deinitialization function.                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // If we tried to add a second indicator, do not delete objects.
   if (reason == REASON_INITFAILED) return;
	
   if (reason == REASON_REMOVE)
   {
      Panel.DeleteSettingsFile();
      ObjectDelete(0, "SoundWhenPriceIsExactly");
      ObjectDelete(0, "SoundWhenPriceGoesAbove");
      ObjectDelete(0, "SoundWhenPriceGoesBelow");
      if (!FileDelete(Panel.IniFileName() + Panel.IniFileExt())) Print("Failed to delete PA panel's .ini file: ", GetLastError());
   }  
   else
   {
      // It is deinitialization due to input parameters change - save current parameters values (that are also changed via panel) to global variables.
      if (reason == REASON_PARAMETERS) GlobalVariableSet("PA-" + IntegerToString(ChartID()) + "-Parameters", 1);

   	Panel.SaveSettingsOnDisk();
   	// Set temporary global variable, so that the indicator knows it is reinitializing because of timeframe/parameters change and should not prevent attachment.
   	if ((reason == REASON_CHARTCHANGE) || (reason == REASON_PARAMETERS) || (reason == REASON_RECOMPILE)) GlobalVariableSet("PA-" + IntegerToString(ChartID()) + "-Flag", 1);
   }
   
   Panel.Destroy(reason);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   Panel.RefreshValues();
	return(rates_total);
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   // Remember the panel's location to have the same location for minimized and maximized states.
   if ((id == CHARTEVENT_CUSTOM + ON_DRAG_END) && (lparam == -1))
   {
      Panel.remember_top = Panel.Top();
      Panel.remember_left = Panel.Left();
   }

	// Call Panel's event handler only if it is not a CHARTEVENT_CHART_CHANGE - workaround for minimization bug on chart switch.
   if (id != CHARTEVENT_CHART_CHANGE) Panel.OnEvent(id, lparam, dparam, sparam);

   // Recalculate on chart changes, clicks, and certain object dragging.
   if ((id == CHARTEVENT_CLICK) || (id == CHARTEVENT_CHART_CHANGE) ||
   ((id == CHARTEVENT_OBJECT_DRAG) && ((sparam == "SoundWhenPriceGoesAbove") || (sparam == "SoundWhenPriceGoesBelow") || (sparam == "SoundWhenPriceIsExactly"))))
   {
      if (id != CHARTEVENT_CHART_CHANGE) Panel.RefreshValues();

      // If this is an active chart, make sure the panel is visible (not behind the chart's borders). For inactive chart, this will work poorly, because inactive charts get minimized by MetaTrader.
      if (ChartGetInteger(ChartID(), CHART_BRING_TO_TOP))
      {
         if (Panel.Top() < 0) Panel.Move(Panel.Left(), 0);
         int chart_height = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
         if (Panel.Top() > chart_height) Panel.Move(Panel.Left(), chart_height - Panel.Height());
         int chart_width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
         if (Panel.Left() > chart_width) Panel.Move(chart_width - Panel.Width(), Panel.Top());
      }
      ChartRedraw();
   }
}

// Event Map
EVENT_MAP_BEGIN(CPriceAlertPanel)
   ON_EVENT(ON_CLICK, m_BtnAbove, OnClickBtnAbove)
   ON_EVENT(ON_CLICK, m_BtnBelow, OnClickBtnBelow)
   ON_EVENT(ON_CLICK, m_BtnExactly, OnClickBtnExactly)
   ON_EVENT(ON_END_EDIT, m_EdtAbove, OnEndEditEdtAbove)
   ON_EVENT(ON_END_EDIT, m_EdtBelow, OnEndEditEdtBelow)
   ON_EVENT(ON_END_EDIT, m_EdtExactly, OnEndEditEdtExactly)
   ON_EVENT(ON_CHANGE, m_ChkEmail, OnChangeChkEmail)
   ON_EVENT(ON_CHANGE, m_ChkPush, OnChangeChkPush)
   ON_EVENT(ON_CHANGE, m_ChkNative, OnChangeChkNative)
EVENT_MAP_END(CAppDialog)  

//+------------------
/// Class constructor 
//+------------------
CPriceAlertPanel::CPriceAlertPanel(void)
{
   m_FileName = "PA_" + Symbol() + IntegerToString(ChartID()) + ".txt";
   NoPanelMaximization = false;
   remember_left = -1;
   remember_top = -1;
}

//+----------+
//| Checkbox |
//+----------+
bool CPriceAlertPanel::CheckBoxCreate(CCheckBox &Chk, int X1, int Y1, int X2, int Y2, string Name, string Text)
{
   if (!Chk.Create(m_chart_id, m_name + Name, m_subwin, X1, Y1, X2, Y2))       return(false);
   if (!Add(Chk))                                                              return(false);
   if (!Chk.Text(Text))                                                        return(false);

   return(true);
} 

//+------+
//| Edit |
//+------+
bool CPriceAlertPanel::EditCreate(CEdit &Edt, int X1, int Y1, int X2, int Y2, string Name, string Text)
{
   if (!Edt.Create(m_chart_id, m_name + Name, m_subwin, X1, Y1, X2, Y2))       return(false);
   if (!Add(Edt))                                                              return(false);
   if (!Edt.Text(Text))                                                        return(false);

   return(true);
} 

//+-------+
//| Label |
//+-------+
bool CPriceAlertPanel::LabelCreate(CLabel &Lbl, int X1, int Y1, int X2, int Y2, string Name, string Text)
{
   if (!Lbl.Create(m_chart_id, m_name + Name, m_subwin, X1, Y1, X2, Y2))       return(false);
   if (!Add(Lbl))                                                              return(false);
   if (!Lbl.Text(Text))                                                        return(false);

   return(true);
}
 
//+--------+
//| Button |
//+--------+
bool CPriceAlertPanel::ButtonCreate(CButton &Btn, int X1, int Y1, int X2, int Y2, string Name, string Text)
{
   if (!Btn.Create(m_chart_id, m_name + Name, m_subwin, X1, Y1, X2, Y2))       return(false);
   if (!Add(Btn))                                                              return(false);
   if (!Btn.Text(Text))                                                        return(false);

   return(true);
}

//+-----------------------+
//| Create a panel object |
//+-----------------------+
bool CPriceAlertPanel::Create(const long chart, const string name, const int subwin, const int x1, const int y1)
{
	double screen_dpi = (double)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
	m_DPIScale = screen_dpi / 96.0;

   int x2 = x1 + (int)MathRound(225 * m_DPIScale);
   int y2 = y1 + (int)MathRound(150 * m_DPIScale);
   if (!CAppDialog::Create(chart, name, subwin, x1, y1, x2, y2))               return(false);
   if (!CreateObjects())                                                  		 return(false);

   return(true);
} 

bool CPriceAlertPanel::CreateObjects()
{
	int row_start = (int)MathRound(10 * m_DPIScale);
	int element_height = (int)MathRound(20 * m_DPIScale);
	int v_spacing = (int)MathRound(4 * m_DPIScale);
	
	int normal_label_width = (int)MathRound(108 * m_DPIScale);
	int normal_edit_width = (int)MathRound(85 * m_DPIScale);
	int narrow_checkbox_width = (int)MathRound(65 * m_DPIScale);
	
	int first_column_start = (int)MathRound(10 * m_DPIScale);
	int second_column_start = first_column_start + (int)MathRound((normal_label_width + v_spacing) * m_DPIScale);

	int y = (int)MathRound(8 * m_DPIScale);

// When the edit field is non-zero - a label is shown, when it is zero - a button is shown.
// The button fills a zero edit field with a non-zero value.

   if (!ButtonCreate(m_BtnAbove, first_column_start, y, first_column_start + normal_label_width, y + element_height, "m_BtnAbove", "Above price:     "))             						 	 return(false);
   if (!LabelCreate(m_LblAbove, first_column_start, y, first_column_start + normal_label_width, y + element_height, "m_LblAbove", "Above price:"))             						 	 return(false);
   if (!EditCreate(m_EdtAbove, second_column_start, y, second_column_start + normal_edit_width, y + element_height, "m_EdtAbove", ""))                    					 		 return(false);

y += element_height + v_spacing;

   if (!ButtonCreate(m_BtnBelow, first_column_start, y, first_column_start + normal_label_width, y + element_height, "m_BtnBelow", "Below price:     "))             						 	 return(false);
   if (!LabelCreate(m_LblBelow, first_column_start, y, first_column_start + normal_label_width, y + element_height, "m_LblBelow", "Below price:"))             						 	 return(false);
   if (!EditCreate(m_EdtBelow, second_column_start, y, second_column_start + normal_edit_width, y + element_height, "m_EdtBelow", ""))                    					 		 return(false);

y += element_height + v_spacing;

   if (!ButtonCreate(m_BtnExactly, first_column_start, y, first_column_start + normal_label_width, y + element_height, "m_BtnExactly", "Exactly price:    "))             						 	 return(false);
   if (!LabelCreate(m_LblExactly, first_column_start, y, first_column_start + normal_label_width, y + element_height, "m_LblExactly", "Exactly price:"))             						 	 return(false);
   if (!EditCreate(m_EdtExactly, second_column_start, y, second_column_start + normal_edit_width, y + element_height, "m_EdtExactly", ""))                    					 		 return(false);

y += element_height + v_spacing;

   if (!CheckBoxCreate(m_ChkNative, first_column_start, y, first_column_start + narrow_checkbox_width, y + element_height, "m_ChkNative", "Popup"))    		 return(false);
   if (!CheckBoxCreate(m_ChkEmail, first_column_start + narrow_checkbox_width + v_spacing, y, first_column_start + narrow_checkbox_width * 2 + v_spacing, y + element_height, "m_ChkEmail", "Email"))    		 return(false);
   if (!CheckBoxCreate(m_ChkPush, first_column_start + narrow_checkbox_width * 2 + v_spacing * 2, y, first_column_start + narrow_checkbox_width * 3 + v_spacing * 2, y + element_height, "m_ChkPush", "Push"))    		 return(false);

y += element_height + v_spacing;

	// EarnForex URL
	if (!LabelCreate(m_LblURL, first_column_start, y, first_column_start + normal_label_width, y + element_height, "m_LblURL", "www.earnforex.com"))             						 	 return(false);
	m_LblURL.FontSize(8);
	m_LblURL.Color(C'0,115,66'); // Green

   //InitObjects();

   return(true);
} 

bool CPriceAlertPanel::InitObjects()
{
   //+-------------------------------------+
   //| Align text in all objects.          |
   //+-------------------------------------+ 
   ENUM_ALIGN_MODE align = ALIGN_RIGHT;
   if (!m_EdtAbove.TextAlign(align))                                   return(false);
   if (!m_EdtBelow.TextAlign(align))                                   return(false);
   if (!m_EdtExactly.TextAlign(align))                                 return(false);

   //+-------------+
   //| Init values.|
   //+-------------+

   // Display values
   DisplayValues();
   
   m_ChkNative.Checked(sets.AlertNative);
   m_ChkEmail.Checked(sets.AlertEmail);
   m_ChkPush.Checked(sets.AlertPush);

   return(true);
}

bool CPriceAlertPanel::DisplayValues()
{
   //=== Levels
   /* Above price    */ if (!m_EdtAbove.Text(DoubleToString(sets.PriceAbove, _Digits)))                        		  return(false);
   /* Below price    */ if (!m_EdtBelow.Text(DoubleToString(sets.PriceBelow, _Digits)))                        		  return(false);
   /* Exactly price  */ if (!m_EdtExactly.Text(DoubleToString(sets.PriceExactly, _Digits)))                     		  return(false);

	if (!m_minimized)
	{
      if (sets.PriceAbove > 0)
      {
         m_BtnAbove.Hide();
         m_LblAbove.Show();
      }
      else
      {
         m_BtnAbove.Show();
         m_LblAbove.Hide();
      }
      
      if (sets.PriceBelow > 0)
      {
         m_BtnBelow.Hide();
         m_LblBelow.Show();
      }
      else
      {
         m_BtnBelow.Show();
         m_LblBelow.Hide();
      }
      
      if (sets.PriceExactly > 0)
      {
         m_BtnExactly.Hide();
         m_LblExactly.Show();
      }
      else
      {
         m_BtnExactly.Show();
         m_LblExactly.Hide();
      }
   }   
   return(true);
} 

void CPriceAlertPanel::Minimize()
{
   CAppDialog::Minimize();
   if (remember_left != -1)
   {
      Move(remember_left, remember_top);
      m_min_rect.Move(remember_left, remember_top);
   }
   IniFileSave();
}

void CPriceAlertPanel::Maximize()
{
   if (!NoPanelMaximization)
   {
      CAppDialog::Maximize();
   }
   else if (m_minimized) CAppDialog::Minimize();
   
   if (remember_left != -1) Move(remember_left, remember_top);
   
   DisplayValues();
   
   NoPanelMaximization = false;
}

void CPriceAlertPanel::RefreshValues()
{
   if (Uninitialized) Initialization(); // Helps with 'Waiting for data'. MT4 only solution. MT5 handles this differently.
   
   sets.PriceAbove = NormalizeDouble(ObjectGetDouble(ChartID(), "SoundWhenPriceGoesAbove", OBJPROP_PRICE), _Digits);
   sets.PriceBelow = NormalizeDouble(ObjectGetDouble(ChartID(), "SoundWhenPriceGoesBelow", OBJPROP_PRICE), _Digits);
   sets.PriceExactly = NormalizeDouble(ObjectGetDouble(ChartID(), "SoundWhenPriceIsExactly", OBJPROP_PRICE), _Digits);

   if ((Ask > sets.PriceAbove) && (sets.PriceAbove > 0))
   {
      if (sets.AlertNative) Alert(Symbol(), ", ", EnumToString((ENUM_TIMEFRAMES)Period()), ": Price above the alert level - ", DoubleToString(sets.PriceAbove, _Digits), ".");
      if (sets.AlertEmail) SendMail(Symbol() +  " rate above the alert level " + DoubleToString(Ask, _Digits), Symbol() +  " rate reached " + DoubleToString(Ask, _Digits) + " level, which is above your alert level of " + DoubleToString(sets.PriceAbove, _Digits) + ".");
      if (sets.AlertPush) SendNotification(Symbol() +  " rate reached " + DoubleToString(Ask, _Digits) + " level, which is above your alert level of " + DoubleToString(sets.PriceAbove, _Digits) + ".");
      sets.AlertNative = false;
      sets.AlertEmail = false;
      sets.AlertPush = false;
      m_ChkNative.Checked(sets.AlertNative);
      m_ChkEmail.Checked(sets.AlertEmail);
      m_ChkPush.Checked(sets.AlertPush);
   }
   if ((Bid < sets.PriceBelow) && (sets.PriceBelow > 0))
   {
      if (sets.AlertNative) Alert(Symbol(), ", ", EnumToString((ENUM_TIMEFRAMES)Period()), ": Price below the alert level - ", DoubleToString(sets.PriceBelow, _Digits), ".");
      if (sets.AlertEmail) SendMail(Symbol() +  " rate below the alert level " + DoubleToString(Bid, _Digits), Symbol() +  " rate reached " + DoubleToString(Bid, _Digits) + " level, which is below your alert level of " + DoubleToString(sets.PriceBelow, _Digits) + ".");
      if (sets.AlertPush) SendNotification(Symbol() +  " rate reached " + DoubleToString(Bid, _Digits) + " level, which is below your alert level of " + DoubleToString(sets.PriceBelow, _Digits) + ".");
      sets.AlertNative = false;
      sets.AlertEmail = false;
      sets.AlertPush = false;
      m_ChkNative.Checked(sets.AlertNative);
      m_ChkEmail.Checked(sets.AlertEmail);
      m_ChkPush.Checked(sets.AlertPush);
   }
   if ((Bid == sets.PriceExactly) || (Ask == sets.PriceExactly))
   {
      double price = Bid;
      if (Ask == sets.PriceExactly) price = Ask;
      if (sets.AlertNative) Alert(Symbol(), ", ", EnumToString((ENUM_TIMEFRAMES)Period()), ": Price is exactly at the alert level - ", DoubleToString(sets.PriceExactly, _Digits), ".");
      if (sets.AlertEmail) SendMail(Symbol() +  " rate exactly at the alert level " + DoubleToString(price, _Digits), Symbol() +  " rate reached " + DoubleToString(price, _Digits) + " level, which is exactly at your alert level.");
      if (sets.AlertPush) SendNotification(Symbol() +  " rate reached " + DoubleToString(price, _Digits) + " level, which is exactly at your alert level.");
      sets.AlertNative = false;
      sets.AlertEmail = false;
      sets.AlertPush = false;
      m_ChkNative.Checked(sets.AlertNative);
      m_ChkEmail.Checked(sets.AlertEmail);
      m_ChkPush.Checked(sets.AlertPush);
   }

   DisplayValues();
}

void CPriceAlertPanel::OnClickBtnAbove()
{
   if (sets.PriceAbove != 0) return; // Only set PriceAbove if it is zero.
   sets.PriceAbove = High[0];
   m_EdtAbove.Text(DoubleToString(sets.PriceAbove, _Digits));
   ObjectSetDouble(ChartID(), "SoundWhenPriceGoesAbove", OBJPROP_PRICE, sets.PriceAbove);
   m_BtnAbove.Hide();
   m_LblAbove.Show();
}

void CPriceAlertPanel::OnClickBtnBelow()
{
   if (sets.PriceBelow != 0) return; // Only set PriceBelow if it is zero.
   sets.PriceBelow = Low[0];
   m_EdtBelow.Text(DoubleToString(sets.PriceBelow, _Digits));
   ObjectSetDouble(ChartID(), "SoundWhenPriceGoesBelow", OBJPROP_PRICE, sets.PriceBelow);
   m_BtnBelow.Hide();
   m_LblBelow.Show();
}

void CPriceAlertPanel::OnClickBtnExactly()
{
   if (sets.PriceExactly != 0) return; // Only set PriceExactly if it is zero.
   sets.PriceExactly = NormalizeDouble((High[0] + Low[0]) / 2, _Digits);
   m_EdtExactly.Text(DoubleToString(sets.PriceAbove, _Digits));
   ObjectSetDouble(ChartID(), "SoundWhenPriceIsExactly", OBJPROP_PRICE, sets.PriceExactly);
   m_BtnExactly.Hide();
   m_LblExactly.Show();
}

void CPriceAlertPanel::OnEndEditEdtAbove()
{
   if (sets.PriceAbove != StringToDouble(m_EdtAbove.Text()))
   {
      sets.PriceAbove = StringToDouble(m_EdtAbove.Text());
   	ObjectSetDouble(ChartID(), "SoundWhenPriceGoesAbove", OBJPROP_PRICE, sets.PriceAbove);
   	RefreshValues();
      if (sets.PriceAbove == 0)
      {
         m_BtnAbove.Show();
         m_LblAbove.Hide();
      }
      else
      {
         m_BtnAbove.Hide();
         m_LblAbove.Show();
      }
   }
}

void CPriceAlertPanel::OnEndEditEdtBelow()
{
   if (sets.PriceBelow != StringToDouble(m_EdtBelow.Text()))
   {
      sets.PriceBelow = StringToDouble(m_EdtBelow.Text());
   	ObjectSetDouble(ChartID(), "SoundWhenPriceGoesBelow", OBJPROP_PRICE, sets.PriceBelow);
   	RefreshValues();
      if (sets.PriceBelow == 0)
      {
         m_BtnBelow.Show();
         m_LblBelow.Hide();
      }
      else
      {
         m_BtnBelow.Hide();
         m_LblBelow.Show();
      }
   }
}

void CPriceAlertPanel::OnEndEditEdtExactly()
{
   if (sets.PriceExactly != StringToDouble(m_EdtExactly.Text()))
   {
      sets.PriceExactly = StringToDouble(m_EdtExactly.Text());
   	ObjectSetDouble(ChartID(), "SoundWhenPriceIsExactly", OBJPROP_PRICE, sets.PriceExactly);
   	RefreshValues();
      if (sets.PriceExactly == 0)
      {
         m_BtnExactly.Show();
         m_LblExactly.Hide();
      }
      else
      {
         m_BtnExactly.Hide();
         m_LblExactly.Show();
      }   
   }
}

void CPriceAlertPanel::OnChangeChkNative()
{
   sets.AlertNative = m_ChkNative.Checked();
}

void CPriceAlertPanel::OnChangeChkEmail()
{
   sets.AlertEmail = m_ChkEmail.Checked();
}

void CPriceAlertPanel::OnChangeChkPush()
{
   sets.AlertPush = m_ChkPush.Checked();
}

//+-----------------------+
//| Working with settings |
//|+----------------------+
bool CPriceAlertPanel::SaveSettingsOnDisk()
{
	Print("Trying to save settings to file: " + m_FileName + ".");
   
	int fh;
	fh = FileOpen(m_FileName, FILE_CSV | FILE_WRITE);
	if (fh == INVALID_HANDLE)
	{
		Print("Failed to open file for writing: " + m_FileName + ". Error: " + IntegerToString(GetLastError()));
		return(false);
	}

	// Order does not matter.
	FileWrite(fh, "PriceAbove");
	FileWrite(fh, DoubleToString(sets.PriceAbove, _Digits));
	FileWrite(fh, "PriceBelow");
	FileWrite(fh, DoubleToString(sets.PriceBelow, _Digits));
	FileWrite(fh, "PriceExactly");
	FileWrite(fh, DoubleToString(sets.PriceExactly, _Digits));
	FileWrite(fh, "AlertNative");
	FileWrite(fh, IntegerToString(sets.AlertNative));
	FileWrite(fh, "AlertEmail");
	FileWrite(fh, IntegerToString(sets.AlertEmail));
	FileWrite(fh, "AlertPush");
	FileWrite(fh, IntegerToString(sets.AlertPush));

   // These are not part of settings but are panel-related input parameters.
   // When indicator is reloaded due to its input parameters change, these should be compared to the new values.
   // If the value is changed, it should be updated in the panel too.
   // Is indicator reloading due to the input parameters change?
   if (GlobalVariableGet("PA-" + IntegerToString(ChartID()) + "-Parameters") > 0)
   {
      FileWrite(fh, "Parameter_PriceAbove");
      FileWrite(fh, DoubleToString(PriceGoesAbove, _Digits));
      FileWrite(fh, "Parameter_PriceBelow");
      FileWrite(fh, DoubleToString(PriceGoesBelow, _Digits));
      FileWrite(fh, "Parameter_PriceExactly");
      FileWrite(fh, DoubleToString(PriceIsExactly, _Digits));
   	FileWrite(fh, "Parameter_NativeAlert");
   	FileWrite(fh, IntegerToString(NativeAlert));
   	FileWrite(fh, "Parameter_SendEmail");
   	FileWrite(fh, IntegerToString(SendEmail));
   	FileWrite(fh, "Parameter_SendPush");
   	FileWrite(fh, IntegerToString(SendPush));
   	FileWrite(fh, "Parameter_DefaultPanelPositionCorner");
   	FileWrite(fh, IntegerToString(DefaultPanelPositionCorner));
   	FileWrite(fh, "Parameter_DefaultPanelPositionX");
   	FileWrite(fh, IntegerToString(DefaultPanelPositionX));
   	FileWrite(fh, "Parameter_DefaultPanelPositionY");
   	FileWrite(fh, IntegerToString(DefaultPanelPositionY));
   }

	FileClose(fh);

	Print("Saved settings successfully.");
	return(true);
}

bool CPriceAlertPanel::LoadSettingsFromDisk()
{
   Print("Trying to load settings from file.");
   
   if (!FileIsExist(m_FileName))
   {
   	Print("No settings file to load.");
   	return(false);
   }
   
   int fh;
   fh = FileOpen(m_FileName, FILE_CSV | FILE_READ);
   
	if (fh == INVALID_HANDLE)
	{
		Print("Failed to open file for reading: " + m_FileName + ". Error: " + IntegerToString(GetLastError()));
		return(false);
	}

	while (!FileIsEnding(fh))
	{
	   string var_name = FileReadString(fh);
	   string var_content = FileReadString(fh);
	   if (var_name == "PriceAbove")
	   	sets.PriceAbove = StringToDouble(var_content);
	   else if (var_name == "PriceBelow")
	   	sets.PriceBelow = StringToDouble(var_content);
	   else if (var_name == "PriceExactly")
	   	sets.PriceExactly = StringToDouble(var_content);
	   else if (var_name == "AlertNative")
	   	sets.AlertNative = (bool)StringToInteger(var_content);
	   else if (var_name == "AlertEmail")
	   	sets.AlertEmail = (bool)StringToInteger(var_content);
	   else if (var_name == "AlertPush")
	   	sets.AlertPush = (bool)StringToInteger(var_content);

      // Is indicator reloading due to the input parameters change?
      if (GlobalVariableGet("PA-" + IntegerToString(ChartID()) + "-Parameters") > 0)
      {
         // These are not part of settings but are panel-related input parameters.
         // When indicator is reloaded due to its input parameters change, these should be compared to the new values.
         // If the value is changed, it should be updated in the panel too.
   	   if (var_name == "Parameter_PriceAbove")
   	   {
   	   	if (StringToDouble(var_content) != PriceGoesAbove) sets.PriceAbove = PriceGoesAbove;
   	   }
   	   else if (var_name == "Parameter_PriceBelow")
   	   {
   	   	if (StringToDouble(var_content) != PriceGoesBelow) sets.PriceBelow = PriceGoesBelow;
   	   }
   	   else if (var_name == "Parameter_PriceExactly")
   	   {
   	   	if (StringToDouble(var_content) != PriceIsExactly) sets.PriceExactly = PriceIsExactly;
   	   }
   	   else if (var_name == "Parameter_NativeAlert")
   	   {
   	   	Print(var_content, " ", NativeAlert);
   	   	if ((bool)StringToInteger(var_content) != NativeAlert) sets.AlertNative = NativeAlert;
   	   }
   	   else if (var_name == "Parameter_SendEmail")
   	   {
   	   	if ((bool)StringToInteger(var_content) != SendEmail) sets.AlertEmail = SendEmail;
   	   }
   	   else if (var_name == "Parameter_SendPush")
   	   {
   	   	if ((bool)StringToInteger(var_content) != SendPush) sets.AlertPush = SendPush;
   	   }
         // These three only trigger panel repositioning (default position changed via the input parameters deliberately).
         else if (var_name == "Parameter_DefaultPanelPositionCorner")
   	   {
   	   	if ((ENUM_BASE_CORNER)StringToInteger(var_content) != DefaultPanelPositionCorner) Dont_Move_the_Panel_to_Default_Corner_X_Y = false;
   	   }
         else if (var_name == "Parameter_DefaultPanelPositionX")
   	   {
   	   	if (StringToInteger(var_content) != DefaultPanelPositionX) Dont_Move_the_Panel_to_Default_Corner_X_Y = false;
   	   }
         else if (var_name == "Parameter_DefaultPanelPositionY")
   	   {
   	   	if (StringToInteger(var_content) != DefaultPanelPositionY) Dont_Move_the_Panel_to_Default_Corner_X_Y = false;
   	   }
      }
	}

   FileClose(fh);
   Print("Loaded settings successfully.");

   // Is indicator reloading due to the input parameters change? Delete the flag variable.
   if (GlobalVariableGet("PA-" + IntegerToString(ChartID()) + "-Parameters") > 0) GlobalVariableDel("PA-" + IntegerToString(ChartID()) + "-Parameters");

   return(true); 
} 

bool CPriceAlertPanel::DeleteSettingsFile()
{
   if (!FileIsExist(m_FileName))
   {
	   Print("No settings file to delete.");
   	return(false);
   }
   Print("Trying to delete settings file.");
   if (!FileDelete(m_FileName))
   {
   	Print("Failed to delete file: " + m_FileName + ". Error: " + IntegerToString(GetLastError()));
   	return(false);
   }
   Print("Deleted settings file successfully.");
   return(true);
} 
 
void CPriceAlertPanel::HideShowMaximize(bool max = true)
{
   // Remember the panel's location.
   remember_left = Left();
   remember_top = Top();

	Hide();
	Show();
	if (!max) NoPanelMaximization = true;
	else NoPanelMaximization = false;
	Maximize();
}
 
//+------------------------------------------------------------------+
//| Extends CAppDialog::IniFileName() to prevent problems with       |
//| trading instruments containing more than one dot in their name.  |
//+------------------------------------------------------------------+
string CPriceAlertPanel::IniFileName(void) const
{
   string name = CAppDialog::IniFileName();
   StringReplace(name, ".", "_dot_");
   return(name);
}

void CPriceAlertPanel::SeekAndDestroyDuplicatePanels()
{
	int ot = ObjectsTotal(ChartID());
	for (int i = ot - 1; i >= 0; i--)
	{
		string object_name = ObjectName(ChartID(), i);
		if (ObjectGetInteger(ChartID(), object_name, OBJPROP_TYPE) != OBJ_LABEL) continue;
		// Found LblAbove object.
		if (StringSubstr(object_name, StringLen(object_name) - 10) == "m_LblAbove")
		{
			string prefix = StringSubstr(object_name, 0, StringLen(Name()));
			// Found LblAbove object with prefix different than current.
			if (prefix != Name())
			{
				ObjectsDeleteAll(ChartID(), prefix);
				// Reset object counter.
				ot = ObjectsTotal(ChartID());
				i = ot;
				Print("Deleted duplicate panel objects with prefix = ", prefix, ".");
				continue;
			}
		}
	}
}
//+------------------------------------------------------------------+