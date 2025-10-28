//+------------------------------------------------------------------+
//|                               Copyright 2015-2025, EarnForex.com |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015-2025, EarnForex.com"
#property link      "https://www.earnforex.com/metatrader-indicators/Price-Alert/"
#property version   "1.06"
string    Version = "1.06";
#property strict

#property icon      "\\Files\\EF-Icon-64x64px.ico"

#property description "Issues alerts depending on price movement."
#property description "E-mail SMTP Server settings should be configured in your platform."
#property description "MetaQuotes ID for push notifications should also be set via MetaTrader."

#property indicator_chart_window

// Additional checkbox bitmaps:
#resource "\\Images\\CheckBoxOnDark.bmp"
#resource "\\Images\\CheckBoxOffDark.bmp"
#resource "\\Images\\CheckBoxOnDark17.bmp"
#resource "\\Images\\CheckBoxOffDark17.bmp"
#resource "\\Images\\CheckBoxOn17.bmp"
#resource "\\Images\\CheckBoxOff17.bmp"

#include <Controls\Dialog.mqh>
#include <Controls\CheckBox.mqh>
#include <Controls\Label.mqh>
#include <Controls\Button.mqh>

color CONTROLS_BUTTON_COLOR_ENABLE  = CONTROLS_BUTTON_COLOR_BG;
color CONTROLS_BUTTON_COLOR_DISABLE = C'224,224,224';

color DARKMODE_BG_DARK_COLOR = 0x444444;
color DARKMODE_CONTROL_BRODER_COLOR = 0x888888;
color DARKMODE_MAIN_AREA_BORDER_COLOR = 0x333333;
color DARKMODE_MAIN_AREA_BG_COLOR = 0x666666;
color DARKMODE_EDIT_BG_COLOR = 0xAAAAAA;
color DARKMODE_BUTTON_BG_COLOR = 0xA19999;
color DARKMODE_TEXT_COLOR = 0x000000;

enum ENUM_ALERT_ON_PRICE
{
    NormalAskBid, // Normal Ask/Bid
    AskOnly, // Ask only
    BidOnly, // Bid only
    PreviousClose // Previous Close
};

//input group "Main"
input double PriceGoesAbove = 0;
input double PriceGoesBelow = 0;
input double PriceIsExactly = 0;
input bool NativeAlert = false; // NativeAlert: If true, a native alert is issued when price level is triggered.
input bool SendEmail = false; // SendEmail: If true, an e-mail is sent to the e-mail address set in your platform.
input bool SendPush = false; // SendPush: If true, a push notification is sent to via the platform.
input bool SendSound = false; // SendSound: If true, a sound alert is issued when price level is triggered.
input string SoundFile = "alert.wav"; // SoundFile: File name to play on alert.
input ENUM_ALERT_ON_PRICE AlertOnPrice = NormalAskBid; // AlertOnPrice: Which price to use for alerts?
input ENUM_TIMEFRAMES ClosePriceTimeframe = PERIOD_CURRENT; // ClosePriceTimeframe: Timeframe for Close Price when it is used.
input bool DarkMode = false; // DarkMode: Enable dark mode for a less bright panel.
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
input bool HideLines = false; // HideLines: Should lines be hidden by default?
//input group "Position"
input int DefaultPanelPositionX = 0; // PanelPositionX: Panel's X coordinate.
input int DefaultPanelPositionY = 15; // PanelPositionY: Panel's Y coordinate.
input ENUM_BASE_CORNER DefaultPanelPositionCorner = CORNER_LEFT_UPPER; // PanelPositionCorner: Panel's corner.

struct Settings
{
    double PriceAbove;
    double PriceBelow;
    double PriceExactly;
    bool   AboveEnabled;
    bool   BelowEnabled;
    bool   ExactlyEnabled;
    bool   AlertNative;
    bool   AlertEmail;
    bool   AlertPush;
    bool   AlertSound;
    ENUM_ALERT_ON_PRICE AlertOnPrice;
    bool   WasSelectedAbove;
    bool   WasSelectedBelow;
    bool   WasSelectedExactly;
    bool   HideLines;
} sets;

class CPriceAlertPanel : public CAppDialog
{
private:
    CCheckBox         m_ChkEmail, m_ChkPush, m_ChkNative, m_ChkSound, m_ChkUseCandleClose, m_ChkHideLines;
    CEdit             m_EdtAbove, m_EdtBelow, m_EdtExactly;
    CButton           m_BtnAlertOnPrice, m_BtnAbove, m_BtnBelow, m_BtnExactly;
    CLabel            m_LblAlertOnPrice, m_LblURL;
    string            m_FileName;
    double            m_DPIScale;
    bool              NoPanelMaximization; // Crutch variable to prevent panel maximization when Maximize() is called at the indicator's initialization.

public:
                     CPriceAlertPanel(void);
                    ~CPriceAlertPanel(void) {};

    virtual bool     Create(const long chart, const string name, const int subwin, const int x1, const int y1);
    virtual bool     OnEvent(const int id, const long& lparam, const double& dparam, const string& sparam);
    virtual void     RefreshValues(); // Gets values from lines and updates values in the panel.
    virtual bool     SaveSettingsOnDisk();
    virtual bool     LoadSettingsFromDisk();
    virtual bool     DeleteSettingsFile();
    virtual bool     Run()
    {
        SeekAndDestroyDuplicatePanels();
        return(CAppDialog::Run());
    }
    virtual void      IniFileLoad()
    {
        CAppDialog::IniFileLoad();    // Sets panel elements that changed based on changes in input parameters, overwriting the INI settings.
        InitObjects();
    }
    virtual void     HideShowMaximize(bool max);
    string           IniFileName(void) const;
    virtual void     FixatePanelPosition()
    {
        if (!m_minimized) m_norm_rect.SetBound(m_rect);    // Used to fixate panel's position after calling Move(). Otherwise, unless the panel gets dragged by mouse, its position isn't remembered properly in the INI file.
        else m_min_rect.SetBound(m_rect);
    }

    // Remember the panel's location to have the same location for minimized and maximized states.
    int              remember_top, remember_left;
private:
    virtual bool     InitObjects();
    virtual bool     CreateObjects();
    // Arranges panel objects on the panel.
    virtual bool     DisplayValues();
    virtual void     SeekAndDestroyDuplicatePanels();

    virtual bool     ButtonCreate    (CButton&    Btn, int X1, int Y1, int X2, int Y2, string Name, string Text);
    virtual bool     CheckBoxCreate  (CCheckBox&  Chk, int X1, int Y1, int X2, int Y2, string Name, string Text);
    virtual bool     EditCreate      (CEdit&      Edt, int X1, int Y1, int X2, int Y2, string Name, string Text);
    virtual bool     LabelCreate     (CLabel&     Lbl, int X1, int Y1, int X2, int Y2, string Name, string Text);
    virtual void     Maximize();
    virtual void     Minimize();

    // Event handlers
    void             OnClickBtnAlertOnPrice();
    void             OnClickBtnAbove();
    void             OnClickBtnBelow();
    void             OnClickBtnExactly();
    void             OnEndEditEdtAbove();
    void             OnEndEditEdtBelow();
    void             OnEndEditEdtExactly();
    void             OnChangeChkEmail();
    void             OnChangeChkPush();
    void             OnChangeChkNative();
    void             OnChangeChkSound();
    void             OnChangeChkHideLines();
};

CPriceAlertPanel Panel;

// Global variables:
string PanelCaption = "";
bool Dont_Move_the_Panel_to_Default_Corner_X_Y;
bool Uninitialized = true;
string CheckboxOnFile = "", CheckboxOffFile = "";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    if (DarkMode)
    {
        CONTROLS_BUTTON_COLOR_ENABLE = DARKMODE_BUTTON_BG_COLOR;
        CONTROLS_BUTTON_COLOR_DISABLE = 0x919999;
    }
    else
    {
        CONTROLS_BUTTON_COLOR_ENABLE = CONTROLS_BUTTON_COLOR_BG;
        CONTROLS_BUTTON_COLOR_DISABLE = C'224,224,224';
    }

    MathSrand(GetTickCount() + 937029); // Used by CreateInstanceId() in Dialog.mqh (standard library). Keep the second number unique across other panel indicators/EAs.

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
                return INIT_FAILED;
            }
        }
    }

    IndicatorSetString(INDICATOR_SHORTNAME, "Price Alert" + IntegerToString(ChartID()));
    PanelCaption = "Price Alert (ver. " + Version + ")";

    if (!Panel.LoadSettingsFromDisk())
    {
        sets.PriceAbove = PriceGoesAbove;
        if (sets.PriceAbove > 0) sets.AboveEnabled = true;
        else sets.AboveEnabled = false;
        sets.PriceBelow = PriceGoesBelow;
        if (sets.PriceBelow > 0) sets.BelowEnabled = true;
        else sets.BelowEnabled = false;
        sets.PriceExactly = PriceIsExactly;
        if (sets.PriceExactly > 0) sets.ExactlyEnabled = true;
        else sets.ExactlyEnabled = false;
        sets.AlertNative = NativeAlert;
        sets.AlertEmail = SendEmail;
        sets.AlertPush = SendPush;
        sets.AlertSound = SendSound;
        sets.AlertOnPrice = AlertOnPrice;
        sets.HideLines = HideLines;
    }

    if (!Panel.Create(0, PanelCaption, 0, DefaultPanelPositionX, DefaultPanelPositionY)) return -1;

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

    if (DarkMode)
    {
        int total = ObjectsTotal(ChartID());
        for (int i = 0; i < total; i++)
        {
            string obj_name = ObjectName(ChartID(), i);
            if (StringSubstr(obj_name, 0, StringLen(Panel.Name())) != Panel.Name()) continue; // Skip non-panel objects.
            if (obj_name == Panel.Name() + "Back")
            {
                
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, DARKMODE_BG_DARK_COLOR);
            }
            if (obj_name == Panel.Name() + "Caption")
            {
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, DARKMODE_BG_DARK_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, DARKMODE_CONTROL_BRODER_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BORDER_COLOR, DARKMODE_BG_DARK_COLOR);
            }
            else if (obj_name == Panel.Name() + "ClientBack")
            {
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, DARKMODE_MAIN_AREA_BORDER_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, DARKMODE_MAIN_AREA_BG_COLOR);
            }
            else if (StringSubstr(obj_name, 0, StringLen(Panel.Name() + "m_Edt")) == Panel.Name() + "m_Edt")
            {
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, DARKMODE_EDIT_BG_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BORDER_COLOR, DARKMODE_CONTROL_BRODER_COLOR);
            }
            else if (StringSubstr(obj_name, 0, StringLen(Panel.Name() + "m_Btn")) == Panel.Name() + "m_Btn")
            {
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, CONTROLS_BUTTON_COLOR_ENABLE);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BORDER_COLOR, DARKMODE_CONTROL_BRODER_COLOR);
            }
            else if (StringSubstr(obj_name, 0, StringLen(Panel.Name() + "m_Chk")) == Panel.Name() + "m_Chk")
            {
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, DARKMODE_TEXT_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, DARKMODE_MAIN_AREA_BG_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BORDER_COLOR, DARKMODE_MAIN_AREA_BG_COLOR);
            }
            else
            {
                if (obj_name == Panel.Name() + "m_LblURL") ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, 0x224400);
                else ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, DARKMODE_TEXT_COLOR);
            }
        }
    }

    return INIT_SUCCEEDED;
}

void Initialization()
{
    if (Bars == 0) return; // Data not ready yet.

    if (ObjectFind(0, "SoundWhenPriceGoesAbove") == -1) ObjectCreate(0, "SoundWhenPriceGoesAbove", OBJ_HLINE, 0, TimeCurrent(), sets.PriceAbove);
    else ObjectSetDouble(0, "SoundWhenPriceGoesAbove", OBJPROP_PRICE, sets.PriceAbove);
    SetParametersForAboveLine();
    
    if (ObjectFind(0, "SoundWhenPriceGoesBelow") == -1) ObjectCreate(0, "SoundWhenPriceGoesBelow", OBJ_HLINE, 0, TimeCurrent(), sets.PriceBelow);
    else ObjectSetDouble(0, "SoundWhenPriceGoesBelow", OBJPROP_PRICE, sets.PriceBelow);
    SetParametersForBelowLine();

    if (ObjectFind(0, "SoundWhenPriceIsExactly") == -1) ObjectCreate(0, "SoundWhenPriceIsExactly", OBJ_HLINE, 0, TimeCurrent(), sets.PriceExactly);
    else ObjectSetDouble(0, "SoundWhenPriceIsExactly", OBJPROP_PRICE, sets.PriceExactly);
    SetParametersForExactlyLine();

    Uninitialized = false;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function.                      |
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
    return rates_total;
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
    }
}

// Event Map
EVENT_MAP_BEGIN(CPriceAlertPanel)
ON_EVENT(ON_CLICK, m_BtnAlertOnPrice, OnClickBtnAlertOnPrice)
ON_EVENT(ON_CLICK, m_BtnAbove, OnClickBtnAbove)
ON_EVENT(ON_CLICK, m_BtnBelow, OnClickBtnBelow)
ON_EVENT(ON_CLICK, m_BtnExactly, OnClickBtnExactly)
ON_EVENT(ON_END_EDIT, m_EdtAbove, OnEndEditEdtAbove)
ON_EVENT(ON_END_EDIT, m_EdtBelow, OnEndEditEdtBelow)
ON_EVENT(ON_END_EDIT, m_EdtExactly, OnEndEditEdtExactly)
ON_EVENT(ON_CHANGE, m_ChkEmail, OnChangeChkEmail)
ON_EVENT(ON_CHANGE, m_ChkPush, OnChangeChkPush)
ON_EVENT(ON_CHANGE, m_ChkNative, OnChangeChkNative)
ON_EVENT(ON_CHANGE, m_ChkSound, OnChangeChkSound)
ON_EVENT(ON_CHANGE, m_ChkHideLines, OnChangeChkHideLines)
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
    if (!Chk.Create(m_chart_id, m_name + Name, m_subwin, X1, Y1, X2, Y2))       return false;
    if (!Add(Chk))                                                              return false;
    if (!Chk.Text(Text))                                                        return false;

    if (CheckboxOnFile != "")
    {
        bool success = ObjectSetString(ChartID(), m_name + Name + "Button", OBJPROP_BMPFILE, 0, "::Images\\" + CheckboxOnFile);
        if (!success)
        {
            PrintFormat("Failed to load dark checbkox ON state bitmap: %s. Error code: %d.", "::Images\\" + CheckboxOnFile, GetLastError()); 
        }
        success = ObjectSetString(ChartID(), m_name + Name + "Button", OBJPROP_BMPFILE, 1, "::Images\\" + CheckboxOffFile);
        if (!success)
        {
            PrintFormat("Failed to load dark checbkox OFF state bitmap: %s. Error code: %d.", "::Images\\" + CheckboxOffFile, GetLastError()); 
        }
    }

    return true;
}

//+------+
//| Edit |
//+------+
bool CPriceAlertPanel::EditCreate(CEdit &Edt, int X1, int Y1, int X2, int Y2, string Name, string Text)
{
    if (!Edt.Create(m_chart_id, m_name + Name, m_subwin, X1, Y1, X2, Y2))       return false;
    if (!Add(Edt))                                                              return false;
    if (!Edt.Text(Text))                                                        return false;

    return true;
}

//+-------+
//| Label |
//+-------+
bool CPriceAlertPanel::LabelCreate(CLabel &Lbl, int X1, int Y1, int X2, int Y2, string Name, string Text)
{
    if (!Lbl.Create(m_chart_id, m_name + Name, m_subwin, X1, Y1, X2, Y2))       return false;
    if (!Add(Lbl))                                                              return false;
    if (!Lbl.Text(Text))                                                        return false;

    return true;
}

//+--------+
//| Button |
//+--------+
bool CPriceAlertPanel::ButtonCreate(CButton &Btn, int X1, int Y1, int X2, int Y2, string Name, string Text)
{
    if (!Btn.Create(m_chart_id, m_name + Name, m_subwin, X1, Y1, X2, Y2))       return false;
    if (!Add(Btn))                                                              return false;
    if (!Btn.Text(Text))                                                        return false;

    return true;
}

//+-----------------------+
//| Create a panel object |
//+-----------------------+
bool CPriceAlertPanel::Create(const long chart, const string name, const int subwin, const int x1, const int y1)
{
    double screen_dpi = (double)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
    m_DPIScale = screen_dpi / 96.0;

    if (m_DPIScale <= 1)
    {
        if (DarkMode)
        {
            CheckboxOnFile = "CheckBoxOnDark.bmp";
            CheckboxOffFile = "CheckBoxOffDark.bmp";
        }
    }
    else if (m_DPIScale >= 1.5)
    {
        if (DarkMode)
        {
            CheckboxOnFile = "CheckBoxOnDark17.bmp";
            CheckboxOffFile = "CheckBoxOffDark17.bmp";
        }
        else
        {
            CheckboxOnFile = "CheckBoxOn17.bmp";
            CheckboxOffFile = "CheckBoxOff17.bmp";
        }
    }
    
    int x2 = x1 + (int)MathRound(225 * m_DPIScale);
    int y2 = y1 + (int)MathRound(220 * m_DPIScale);
    if (!CAppDialog::Create(chart, name, subwin, x1, y1, x2, y2))               return false;
    if (!CreateObjects())                                                         return false;

    return true;
}

bool CPriceAlertPanel::CreateObjects()
{
    int row_start = (int)MathRound(10 * m_DPIScale);
    int element_height = (int)MathRound(20 * m_DPIScale);
    int v_spacing = (int)MathRound(4 * m_DPIScale);

    int normal_label_width = (int)MathRound(108 * m_DPIScale);
    int normal_edit_width = (int)MathRound(85 * m_DPIScale);
    int narrow_checkbox_width = (int)MathRound(68 * m_DPIScale);

    int first_column_start = (int)MathRound(10 * m_DPIScale);
    int second_column_start = first_column_start + normal_label_width + v_spacing;

    int y = (int)MathRound(8 * m_DPIScale);

    // When the edit field is non-zero - a label is shown, when it is zero - a button is shown.
    // The button fills a zero edit field with a non-zero value.

    if (!CheckBoxCreate(m_ChkHideLines, first_column_start, y, first_column_start + normal_edit_width, y + element_height, "m_ChkHideLines", "Hide lines"))          return false;

    y += element_height + v_spacing;

    if (!LabelCreate(m_LblAlertOnPrice, first_column_start, y, first_column_start + narrow_checkbox_width, y + element_height, "m_LblAlertOnPrice", "Alert on:"))                                         return false;
    if (!ButtonCreate(m_BtnAlertOnPrice, first_column_start + narrow_checkbox_width + v_spacing, y, second_column_start + normal_edit_width, y + element_height, "m_BtnAlertOnPrice", ""))          return false;

    y += element_height + v_spacing;

    if (!ButtonCreate(m_BtnAbove, first_column_start, y, first_column_start + normal_label_width, y + element_height, "m_BtnAbove", "Above price:     "))                                         return false;
    if (!EditCreate(m_EdtAbove, second_column_start, y, second_column_start + normal_edit_width, y + element_height, "m_EdtAbove", ""))                                               return false;

    y += element_height + v_spacing;

    if (!ButtonCreate(m_BtnBelow, first_column_start, y, first_column_start + normal_label_width, y + element_height, "m_BtnBelow", "Below price:     "))                                         return false;
    if (!EditCreate(m_EdtBelow, second_column_start, y, second_column_start + normal_edit_width, y + element_height, "m_EdtBelow", ""))                                               return false;

    y += element_height + v_spacing;

    if (!ButtonCreate(m_BtnExactly, first_column_start, y, first_column_start + normal_label_width, y + element_height, "m_BtnExactly", "Exactly price:    "))                                        return false;
    if (!EditCreate(m_EdtExactly, second_column_start, y, second_column_start + normal_edit_width, y + element_height, "m_EdtExactly", ""))                                               return false;

    y += element_height + v_spacing;

    if (!CheckBoxCreate(m_ChkNative, first_column_start, y, first_column_start + narrow_checkbox_width, y + element_height, "m_ChkNative", "Popup"))          return false;
    if (!CheckBoxCreate(m_ChkEmail, first_column_start + narrow_checkbox_width + 3 * v_spacing, y, first_column_start + narrow_checkbox_width * 2 + 3 * v_spacing, y + element_height, "m_ChkEmail", "Email"))            return false;

    y += element_height + v_spacing;

    if (!CheckBoxCreate(m_ChkPush, first_column_start, y, first_column_start + narrow_checkbox_width, y + element_height, "m_ChkPush", "Push"))           return false;
    if (!CheckBoxCreate(m_ChkSound, first_column_start + narrow_checkbox_width + 3 * v_spacing, y, first_column_start + narrow_checkbox_width * 2 + 3 * v_spacing, y + element_height, "m_ChkSound", "Sound"))           return false;

    y += element_height + v_spacing;

    // EarnForex URL
    if (!LabelCreate(m_LblURL, first_column_start, y, first_column_start + normal_label_width, y + element_height, "m_LblURL", "www.earnforex.com"))                                         return false;
    m_LblURL.FontSize(8);
    m_LblURL.Color(C'0,115,66'); // Green

    return true;
}

bool CPriceAlertPanel::InitObjects()
{
    //+-------------------------------------+
    //| Align text in all objects.          |
    //+-------------------------------------+
    ENUM_ALIGN_MODE align = ALIGN_RIGHT;

    if (sets.AlertOnPrice == NormalAskBid) m_BtnAlertOnPrice.Text("Normal Ask/Bid");
    else if (sets.AlertOnPrice == AskOnly) m_BtnAlertOnPrice.Text("Ask only");
    else if (sets.AlertOnPrice == BidOnly) m_BtnAlertOnPrice.Text("Bid only");
    else if (sets.AlertOnPrice == PreviousClose) m_BtnAlertOnPrice.Text("Previous Close");

    if (!m_EdtAbove.TextAlign(align))                                   return false;
    if (!m_EdtBelow.TextAlign(align))                                   return false;
    if (!m_EdtExactly.TextAlign(align))                                 return false;

    //+-------------+
    //| Init values.|
    //+-------------+

    // Display values
    DisplayValues();

    m_ChkNative.Checked(sets.AlertNative);
    m_ChkEmail.Checked(sets.AlertEmail);
    m_ChkPush.Checked(sets.AlertPush);
    m_ChkSound.Checked(sets.AlertSound);
    m_ChkHideLines.Checked(sets.HideLines);

    return true;
}

bool CPriceAlertPanel::DisplayValues()
{
    //=== Levels
    /* Above price    */ if (!m_EdtAbove.Text(DoubleToString(sets.PriceAbove, _Digits)))                               return false;
    /* Below price    */ if (!m_EdtBelow.Text(DoubleToString(sets.PriceBelow, _Digits)))                               return false;
    /* Exactly price  */ if (!m_EdtExactly.Text(DoubleToString(sets.PriceExactly, _Digits)))                           return false;

    if (sets.AboveEnabled) m_BtnAbove.ColorBackground(CONTROLS_BUTTON_COLOR_DISABLE);
    if (sets.BelowEnabled) m_BtnBelow.ColorBackground(CONTROLS_BUTTON_COLOR_DISABLE);
    if (sets.ExactlyEnabled) m_BtnExactly.ColorBackground(CONTROLS_BUTTON_COLOR_DISABLE);
    
    return true;
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

    // Restore the lines if they are missing for some reason.
    if (ObjectFind(ChartID(), "SoundWhenPriceGoesAbove") < 0)
    {
        ObjectCreate(0, "SoundWhenPriceGoesAbove", OBJ_HLINE, 0, TimeCurrent(), sets.PriceAbove);
        SetParametersForAboveLine();
    }
    if (ObjectFind(ChartID(), "SoundWhenPriceGoesBelow") < 0)
    {
        ObjectCreate(0, "SoundWhenPriceGoesBelow", OBJ_HLINE, 0, TimeCurrent(), sets.PriceBelow);
        SetParametersForBelowLine();
    }
    if (ObjectFind(ChartID(), "SoundWhenPriceIsExactly") < 0)
    {
        ObjectCreate(0, "SoundWhenPriceIsExactly", OBJ_HLINE, 0, TimeCurrent(), sets.PriceExactly);
        SetParametersForExactlyLine();
    }
    
    double new_price_above = NormalizeDouble(ObjectGetDouble(ChartID(), "SoundWhenPriceGoesAbove", OBJPROP_PRICE), _Digits);
    if (MathAbs(sets.PriceAbove - new_price_above) > _Point / 2)
    {
        sets.PriceAbove = new_price_above;
        sets.AboveEnabled = true;
    }
    double new_price_below = NormalizeDouble(ObjectGetDouble(ChartID(), "SoundWhenPriceGoesBelow", OBJPROP_PRICE), _Digits);
    if (MathAbs(sets.PriceBelow - new_price_below) > _Point / 2)
    {
        sets.PriceBelow = new_price_below;
        sets.BelowEnabled = true;
    }
    double new_price_exactly = NormalizeDouble(ObjectGetDouble(ChartID(), "SoundWhenPriceIsExactly", OBJPROP_PRICE), _Digits);
    if (MathAbs(sets.PriceExactly - new_price_exactly) > _Point / 2)
    {
        sets.PriceExactly = new_price_exactly;
        sets.ExactlyEnabled = true;
    }

    if (Bid == 0 || Ask == 0) return; // Protection against connection loss.

    double price = Ask;
    if (sets.AlertOnPrice == BidOnly) price = Bid;
    if (sets.AlertOnPrice == PreviousClose) price = iClose(Symbol(), ClosePriceTimeframe, 1);
    if ((sets.AboveEnabled) && ((price > sets.PriceAbove) && (sets.PriceAbove > 0)))
    {
        if (sets.AlertNative)
        {
            Alert(Symbol(), ", ", EnumToString((ENUM_TIMEFRAMES)Period()), ": Price above the alert level - ", DoubleToString(sets.PriceAbove, _Digits), ".");
        }
        if (sets.AlertEmail)
        {
            SendMail(Symbol() +  " rate above the alert level " + DoubleToString(price, _Digits), Symbol() +  " rate reached " + DoubleToString(price, _Digits) + " level, which is above your alert level of " + DoubleToString(sets.PriceAbove, _Digits) + ".");
        }
        if (sets.AlertPush)
        {
            SendNotification(Symbol() +  " rate reached " + DoubleToString(price, _Digits) + " level, which is above your alert level of " + DoubleToString(sets.PriceAbove, _Digits) + ".");
        }
        if (sets.AlertSound)
        {
            PlaySound(SoundFile);
        }
        sets.AboveEnabled = false;
        m_BtnAbove.ColorBackground(CONTROLS_BUTTON_COLOR_ENABLE);
    }

    price = Bid;
    if (sets.AlertOnPrice == AskOnly) price = Ask;
    if (sets.AlertOnPrice == PreviousClose) price = iClose(Symbol(), ClosePriceTimeframe, 1);
    if ((sets.BelowEnabled) && ((price < sets.PriceBelow) && (sets.PriceBelow > 0)))
    {
        if (sets.AlertNative)
        {
            Alert(Symbol(), ", ", EnumToString((ENUM_TIMEFRAMES)Period()), ": Price below the alert level - ", DoubleToString(sets.PriceBelow, _Digits), ".");
        }
        if (sets.AlertEmail)
        {
            SendMail(Symbol() +  " rate below the alert level " + DoubleToString(price, _Digits), Symbol() +  " rate reached " + DoubleToString(price, _Digits) + " level, which is below your alert level of " + DoubleToString(sets.PriceBelow, _Digits) + ".");
        }
        if (sets.AlertPush)
        {
            SendNotification(Symbol() +  " rate reached " + DoubleToString(price, _Digits) + " level, which is below your alert level of " + DoubleToString(sets.PriceBelow, _Digits) + ".");
        }
        if (sets.AlertSound)
        {
            PlaySound(SoundFile);
        }
        sets.BelowEnabled = false;
        m_BtnBelow.ColorBackground(CONTROLS_BUTTON_COLOR_ENABLE);
    }
    
    if ((sets.ExactlyEnabled) && (((sets.AlertOnPrice == NormalAskBid) && ((Bid == sets.PriceExactly) || (Ask == sets.PriceExactly))) || ((sets.AlertOnPrice == AskOnly) && ((Ask == sets.PriceExactly))) || ((sets.AlertOnPrice == BidOnly) && ((Bid == sets.PriceExactly))) || ((sets.AlertOnPrice == PreviousClose) && ((iClose(Symbol(), ClosePriceTimeframe, 1) == sets.PriceExactly)))))
    {
        if (sets.AlertOnPrice == NormalAskBid)
        {
            price = Bid;
            if (Ask == sets.PriceExactly) price = Ask;
        }
        else if (sets.AlertOnPrice == AskOnly) price = Ask;
        else if (sets.AlertOnPrice == BidOnly) price = Bid;
        else if (sets.AlertOnPrice == PreviousClose) price = iClose(Symbol(), ClosePriceTimeframe, 1);
        if (sets.AlertNative)
        {
            Alert(Symbol(), ", ", EnumToString((ENUM_TIMEFRAMES)Period()), ": Price is exactly at the alert level - ", DoubleToString(sets.PriceExactly, _Digits), ".");
        }
        if (sets.AlertEmail)
        {
            SendMail(Symbol() +  " rate exactly at the alert level " + DoubleToString(price, _Digits), Symbol() +  " rate reached " + DoubleToString(price, _Digits) + " level, which is exactly at your alert level.");
        }
        if (sets.AlertPush)
        {
            SendNotification(Symbol() +  " rate reached " + DoubleToString(price, _Digits) + " level, which is exactly at your alert level.");
        }
        if (sets.AlertSound)
        {
            PlaySound(SoundFile);
        }
        sets.ExactlyEnabled = false;
        m_BtnExactly.ColorBackground(CONTROLS_BUTTON_COLOR_ENABLE);
    }

    DisplayValues();
}

//+------------------------------------------------------------------+
//| Rotate price mode and update the setting parameter accordingly.  |
//+------------------------------------------------------------------+
void CPriceAlertPanel::OnClickBtnAlertOnPrice()
{
    if (sets.AlertOnPrice == NormalAskBid)
    {
        sets.AlertOnPrice = AskOnly;
        m_BtnAlertOnPrice.Text("Ask only");
    }
    else if (sets.AlertOnPrice == AskOnly)
    {
        sets.AlertOnPrice = BidOnly;
        m_BtnAlertOnPrice.Text("Bid only");
    }
    else if (sets.AlertOnPrice == BidOnly)
    {
        sets.AlertOnPrice = PreviousClose;
        m_BtnAlertOnPrice.Text("Previous Close");
    }
    else if (sets.AlertOnPrice == PreviousClose)
    {
        sets.AlertOnPrice = NormalAskBid;
        m_BtnAlertOnPrice.Text("Normal Ask/Bid");
    }
}

void CPriceAlertPanel::OnClickBtnAbove()
{
    if (sets.AboveEnabled)
    {
        sets.AboveEnabled = false;
        m_BtnAbove.ColorBackground(CONTROLS_BUTTON_COLOR_ENABLE);
    }
    else
    {
        sets.AboveEnabled = true;
        if (sets.PriceAbove == 0)
        {
            sets.PriceAbove = iHigh(Symbol(), Period(), 0);
            m_EdtAbove.Text(DoubleToString(sets.PriceAbove, _Digits));
            ObjectSetDouble(ChartID(), "SoundWhenPriceGoesAbove", OBJPROP_PRICE, sets.PriceAbove);
        }
        m_BtnAbove.ColorBackground(CONTROLS_BUTTON_COLOR_DISABLE);
    }
}

void CPriceAlertPanel::OnClickBtnBelow()
{
    if (sets.BelowEnabled)
    {
        sets.BelowEnabled = false;
        m_BtnBelow.ColorBackground(CONTROLS_BUTTON_COLOR_ENABLE);
    }
    else
    {
        sets.BelowEnabled = true;
        if (sets.PriceBelow == 0)
        {
            sets.PriceBelow = iLow(Symbol(), Period(), 0);
            m_EdtBelow.Text(DoubleToString(sets.PriceBelow, _Digits));
            ObjectSetDouble(ChartID(), "SoundWhenPriceGoesBelow", OBJPROP_PRICE, sets.PriceBelow);
        }
        m_BtnBelow.ColorBackground(CONTROLS_BUTTON_COLOR_DISABLE);
    }
}

void CPriceAlertPanel::OnClickBtnExactly()
{
    if (sets.ExactlyEnabled) // Remove the alert.
    {
        sets.ExactlyEnabled = false;
        m_BtnExactly.ColorBackground(CONTROLS_BUTTON_COLOR_ENABLE);
    }
    else // Set the alert.
    {
        sets.ExactlyEnabled = true;
        if (sets.PriceExactly == 0)
        {
            sets.PriceExactly = NormalizeDouble((iHigh(Symbol(), Period(), 0) + iLow(Symbol(), Period(), 0)) / 2, _Digits);
            m_EdtExactly.Text(DoubleToString(sets.PriceExactly, _Digits));
            ObjectSetDouble(ChartID(), "SoundWhenPriceIsExactly", OBJPROP_PRICE, sets.PriceExactly);
        }
        m_BtnExactly.ColorBackground(CONTROLS_BUTTON_COLOR_DISABLE);
    }
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
            sets.AboveEnabled = false;
            m_BtnAbove.ColorBackground(CONTROLS_BUTTON_COLOR_ENABLE);
        }
        else
        {
            sets.AboveEnabled = true;
            m_BtnAbove.ColorBackground(CONTROLS_BUTTON_COLOR_DISABLE);
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
            sets.BelowEnabled = false;
            m_BtnBelow.ColorBackground(CONTROLS_BUTTON_COLOR_ENABLE);
        }
        else
        {
            sets.BelowEnabled = true;
            m_BtnBelow.ColorBackground(CONTROLS_BUTTON_COLOR_DISABLE);
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
            sets.ExactlyEnabled = false;
            m_BtnExactly.ColorBackground(CONTROLS_BUTTON_COLOR_ENABLE);
        }
        else
        {
            sets.ExactlyEnabled = true;
            m_BtnExactly.ColorBackground(CONTROLS_BUTTON_COLOR_DISABLE);
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

void CPriceAlertPanel::OnChangeChkSound()
{
    sets.AlertSound = m_ChkSound.Checked();
}

void CPriceAlertPanel::OnChangeChkHideLines()
{
    sets.HideLines = m_ChkHideLines.Checked();
    if (sets.HideLines)
    {
        sets.WasSelectedAbove = ObjectGetInteger(ChartID(), "SoundWhenPriceGoesAbove", OBJPROP_SELECTED);
        sets.WasSelectedBelow = ObjectGetInteger(ChartID(), "SoundWhenPriceGoesBelow", OBJPROP_SELECTED);
        sets.WasSelectedExactly = ObjectGetInteger(ChartID(), "SoundWhenPriceIsExactly", OBJPROP_SELECTED);
        ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
    }
    else
    {
        ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_SELECTED, sets.WasSelectedAbove);
        ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_SELECTED, sets.WasSelectedBelow);
        ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_SELECTED, sets.WasSelectedExactly);
    }
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
        return false;
    }

    // Order does not matter.
    FileWrite(fh, "PriceAbove");
    FileWrite(fh, DoubleToString(sets.PriceAbove, _Digits));
    FileWrite(fh, "PriceBelow");
    FileWrite(fh, DoubleToString(sets.PriceBelow, _Digits));
    FileWrite(fh, "PriceExactly");
    FileWrite(fh, DoubleToString(sets.PriceExactly, _Digits));
    FileWrite(fh, "AboveEnabled");
    FileWrite(fh, IntegerToString(sets.AboveEnabled));
    FileWrite(fh, "BelowEnabled");
    FileWrite(fh, IntegerToString(sets.BelowEnabled));
    FileWrite(fh, "ExactlyEnabled");
    FileWrite(fh, IntegerToString(sets.ExactlyEnabled));
    FileWrite(fh, "AlertNative");
    FileWrite(fh, IntegerToString(sets.AlertNative));
    FileWrite(fh, "AlertEmail");
    FileWrite(fh, IntegerToString(sets.AlertEmail));
    FileWrite(fh, "AlertPush");
    FileWrite(fh, IntegerToString(sets.AlertPush));
    FileWrite(fh, "AlertSound");
    FileWrite(fh, IntegerToString(sets.AlertSound));
    FileWrite(fh, "AlertOnPrice");
    FileWrite(fh, IntegerToString(sets.AlertOnPrice));
    FileWrite(fh, "HideLines");
    FileWrite(fh, IntegerToString(sets.HideLines));
    FileWrite(fh, "WasSelectedAbove");
    FileWrite(fh, IntegerToString(sets.WasSelectedAbove));
    FileWrite(fh, "WasSelectedBelow");
    FileWrite(fh, IntegerToString(sets.WasSelectedBelow));
    FileWrite(fh, "WasSelectedExactly");
    FileWrite(fh, IntegerToString(sets.WasSelectedExactly));

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
        FileWrite(fh, "Parameter_SendSound");
        FileWrite(fh, IntegerToString(SendSound));
        FileWrite(fh, "Parameter_AlertOnPrice");
        FileWrite(fh, IntegerToString(AlertOnPrice));
        FileWrite(fh, "Parameter_DefaultPanelPositionCorner");
        FileWrite(fh, IntegerToString(DefaultPanelPositionCorner));
        FileWrite(fh, "Parameter_DefaultPanelPositionX");
        FileWrite(fh, IntegerToString(DefaultPanelPositionX));
        FileWrite(fh, "Parameter_DefaultPanelPositionY");
        FileWrite(fh, IntegerToString(DefaultPanelPositionY));
        FileWrite(fh, "Parameter_HideLines");
        FileWrite(fh, IntegerToString(HideLines));
    }

    FileClose(fh);

    Print("Saved settings successfully.");
    return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CPriceAlertPanel::LoadSettingsFromDisk()
{
    Print("Trying to load settings from file.");

    if (!FileIsExist(m_FileName))
    {
        Print("No settings file to load.");
        return false;
    }

    int fh;
    fh = FileOpen(m_FileName, FILE_CSV | FILE_READ);

    if (fh == INVALID_HANDLE)
    {
        Print("Failed to open file for reading: " + m_FileName + ". Error: " + IntegerToString(GetLastError()));
        return false;
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
        else if (var_name == "AboveEnabled")
            sets.AboveEnabled = (bool)StringToInteger(var_content);
        else if (var_name == "BelowEnabled")
            sets.BelowEnabled = (bool)StringToInteger(var_content);
        else if (var_name == "ExactlyEnabled")
            sets.ExactlyEnabled = (bool)StringToInteger(var_content);
        else if (var_name == "AlertNative")
            sets.AlertNative = (bool)StringToInteger(var_content);
        else if (var_name == "AlertEmail")
            sets.AlertEmail = (bool)StringToInteger(var_content);
        else if (var_name == "AlertPush")
            sets.AlertPush = (bool)StringToInteger(var_content);
        else if (var_name == "AlertSound")
            sets.AlertSound = (bool)StringToInteger(var_content);
        else if (var_name == "AlertOnPrice")
            sets.AlertOnPrice = (ENUM_ALERT_ON_PRICE)StringToInteger(var_content);
        else if (var_name == "HideLines")
            sets.HideLines = (bool)StringToInteger(var_content);
        else if (var_name == "WasSelectedAbove")
            sets.WasSelectedAbove = (bool)StringToInteger(var_content);
        else if (var_name == "WasSelectedBelow")
            sets.WasSelectedBelow = (bool)StringToInteger(var_content);
        else if (var_name == "WasSelectedExactly")
            sets.WasSelectedExactly = (bool)StringToInteger(var_content);

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
            else if (var_name == "Parameter_SendSound")
            {
                if ((bool)StringToInteger(var_content) != SendSound) sets.AlertSound = SendSound;
            }
            else if (var_name == "Parameter_AlertOnPrice")
            {
                if ((ENUM_ALERT_ON_PRICE)StringToInteger(var_content) != AlertOnPrice) sets.AlertOnPrice = AlertOnPrice;
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
            else if (var_name == "Parameter_HideLines")
            {
                if ((bool)StringToInteger(var_content) != HideLines) sets.HideLines = HideLines;
            }
        }
    }

    FileClose(fh);
    Print("Loaded settings successfully.");

    // Is indicator reloading due to the input parameters change? Delete the flag variable.
    if (GlobalVariableGet("PA-" + IntegerToString(ChartID()) + "-Parameters") > 0) GlobalVariableDel("PA-" + IntegerToString(ChartID()) + "-Parameters");

    return true;
}

bool CPriceAlertPanel::DeleteSettingsFile()
{
    if (!FileIsExist(m_FileName))
    {
        Print("No settings file to delete.");
        return false;
    }
    Print("Trying to delete settings file.");
    if (!FileDelete(m_FileName))
    {
        Print("Failed to delete file: " + m_FileName + ". Error: " + IntegerToString(GetLastError()));
        return false;
    }
    Print("Deleted settings file successfully.");
    return true;
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
        if (ObjectGetInteger(ChartID(), object_name, OBJPROP_TYPE) != OBJ_BUTTON) continue;
        // Found BtnAbove object.
        if (StringSubstr(object_name, StringLen(object_name) - 10) == "m_BtnAbove")
        {
            string prefix = StringSubstr(object_name, 0, StringLen(Name()));
            // Found BtnAbove object with prefix different than current.
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

void SetParametersForAboveLine()
{
    ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_STYLE, above_line_style);
    ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_COLOR, above_line_color);
    ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_WIDTH, above_line_width);
    ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_SELECTABLE, true);
    ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_SELECTED, true);
    ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_BACK, true);
    if (sets.HideLines) ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
    else ObjectSetInteger(0, "SoundWhenPriceGoesAbove", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
}

void SetParametersForBelowLine()
{
    ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_STYLE, below_line_style);
    ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_COLOR, below_line_color);
    ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_WIDTH, below_line_width);
    ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_SELECTABLE, true);
    ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_SELECTED, true);
    ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_BACK, true);
    if (sets.HideLines) ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
    else ObjectSetInteger(0, "SoundWhenPriceGoesBelow", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
}

void SetParametersForExactlyLine()
{
    ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_STYLE, exactly_line_style);
    ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_COLOR, exactly_line_color);
    ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_WIDTH, exactly_line_width);
    ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_SELECTABLE, true);
    ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_SELECTED, true);
    ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_BACK, true);
    if (sets.HideLines) ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
    else ObjectSetInteger(0, "SoundWhenPriceIsExactly", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
}
//+------------------------------------------------------------------+