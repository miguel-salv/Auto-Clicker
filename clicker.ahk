#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_MyDocuments%  ; Ensures a consistent starting directory.

; Create directory if it doesn't exist
if !FileExist(A_MyDocuments "\AutoClicker") {
    FileCreateDir, %A_MyDocuments%\AutoClicker
}

; Global variables
spamKey := "w"  ; Default key to spam/hold
isActive := false
spamDelay := 50  ; Delay between key presses in milliseconds
maxRandomDelay := 0  ; Maximum additional random delay in milliseconds
isSpamMode := true  ; True for spam mode, False for hold mode
clickMode := "Left Click"  ; Default mode is to spam/hold a key
useRandomDelay := false  ; Whether to use random delay
hEdit := 0  ; Handle for the Edit control
iniFile := A_MyDocuments "\AutoClicker\settings.ini"  ; Path to INI file in Documents folder

; Change icon
hIcon := DllCall("LoadImage", uint, 0, str, A_ScriptDir "\icon.ico"
    , uint, 1, int, 0, int, 0, uint, 0x10)  ; Type, Width, Height, Flags
Gui +LastFound  ; Set the "last found window" for use in the next lines.
SendMessage, 0x80, 0, hIcon  ; Set the window's small icon (0x80 is WM_SETICON).

; Load settings from INI file
LoadSettings()

; Create GUI

; Acyrlic blur
Gui, -DPIScale +Owner +hwndhGui
bgrColor := "222222"
Gui, Color, c%bgrColor%

dhw := A_DetectHiddenWindows
DetectHiddenWindows On  ; </Lexikos>
WinSet, AlwaysOnTop, On, ahk_id %hGui%
SetAcrylicGlassEffect(bgrColor, 200, hGui)
DetectHiddenWindows % dhw  ; Lexikos

; Set font and text color for labels and text
Gui, Font, s10, Arial

; Action mode
Gui, Add, Text, x10 y10 cWhite, Action
if (clickMode = "Left Click") {
    Gui, Add, DropDownList, x170 y7 w95 vClickMode gSetMode, Left Click||Right Click|Key|
} else if (clickMode = "Right Click") {
    Gui, Add, DropDownList, x170 y7 w95 vClickMode gSetMode, Left Click|Right Click||Key|
} else {
    Gui, Add, DropDownList, x170 y7 w95 vClickMode gSetMode, Left Click|Right Click|Key||
}

; Key
Gui, Add, Text, x10 y40 cWhite, Key to Spam/Hold
if (clickMode = "Key") {
    Gui, Add, Edit, x170 y37 w30 vKeyInput gValidateKey, %spamKey%
} else {
    Gui, Add, Edit, x170 y37 w30 vKeyInput gValidateKey Disabled, %spamKey%
}

; Delay
Gui, Add, Text, x10 y70 cWhite, Delay (ms)
Gui, Add, Edit, x170 y67 w50 vDelayInput gSetDelay Number, %spamDelay%

; Random Delay
Gui, Add, Text, x10 y100 cWhite, Random Delay (ms)
Gui, Add, CheckBox, x132 y100 vRandomDelay gSetRandomDelay, 
if (useRandomDelay) {
    GuiControl,, RandomDelay, Checked
}
Gui, Add, Edit, x170 y100 w50 vMaxRandomDelay gSetMaxRandomDelay Number, %maxRandomDelay%

; Spam Mode
if (isSpamMode) {
    Gui, Add, Text, x10 y130 cWhite, Spam
    Gui, Add, Text, x84 y130 cWhite, Hold
    Gui, Add, Radio, x52 y130 vSpamMode gSetMode Checked,
    Gui, Add, Radio, x119 y130 vHoldMode gSetMode,
} else {
    Gui, Add, Text, x10 y130 cWhite, Spam
    Gui, Add, Text, x84 y130 cWhite, Hold
    Gui, Add, Radio, x52 y130 vSpamMode gSetMode,
    Gui, Add, Radio, x119 y130 vHoldMode gSetMode Checked,
}

; Start Button
Gui, Add, Button, x10 y160 w250 h30 vToggleButton gToggleAction, Start (F6)

; Start GUI
Gui, Show, w270 h200, Auto Clicker

; Get the handle for the Edit control
GuiControlGet, hEdit, Hwnd, KeyInput

; Hide the caret permanently
DllCall("HideCaret", "Int", hEdit)

; Create a custom tray menu
Menu, Tray, NoStandard
Menu, Tray, Add, Show GUI, ShowGUI
Menu, Tray, Add, Exit, GuiClose
Menu, Tray, Default, Show GUI

return

ValidateKey:
    ; Hide the caret (redundant, but ensures it's always hidden)
    DllCall("HideCaret", "Int", hEdit)

    GuiControlGet, KeyInput
    if (StrLen(KeyInput) != 1 || !RegExMatch(KeyInput, "^[a-zA-Z]$")) {
        KeyInput := SubStr(KeyInput, 1, 1)  ; Truncate input to the first character if invalid
        GuiControl,, KeyInput, %KeyInput%
        spamKey := KeyInput
    } else {
        spamKey := KeyInput
    }
return

SetDelay:
    Gui, Submit, NoHide
    spamDelay := DelayInput
    SaveSettings()  ; Save settings when changed
return

SetMaxRandomDelay:
    Gui, Submit, NoHide
    maxRandomDelay := MaxRandomDelay
    SaveSettings()  ; Save settings when changed
return

SetRandomDelay:
    Gui, Submit, NoHide
    useRandomDelay := RandomDelay
    SaveSettings()  ; Save settings when changed
return

SetMode:
    Gui, Submit, NoHide
    clickMode := ClickMode
    isSpamMode := SpamMode
    if (clickMode = "Key") {
        GuiControl, Enable, KeyInput
    } else {
        GuiControl, Disable, KeyInput
    }
    if (isActive) {
        Gosub, ToggleAction ; Reset the current action if it's active
    }
    SaveSettings()  ; Save settings when changed
return

ToggleAction:
    isActive := !isActive
    if (isActive) {
        if (isSpamMode) {
            SetTimer, SpamKey, %spamDelay%
        } else {
            if (clickMode = "Left Click") {
                Click, down
            } else if (clickMode = "Right Click") {
                Click, right down
            } else {
                Send, {%spamKey% down}
            }
        }
        GuiControl,, ToggleButton, Stop (F6)
    } else {
        if (isSpamMode) {
            SetTimer, SpamKey, Off
        } else {
            if (clickMode = "Left Click") {
                Click, up
            } else if (clickMode = "Right Click") {
                Click, right up
            } else {
                Send, {%spamKey% up}
            }
        }
        GuiControl,, ToggleButton, Start (F6)
    }
return

SpamKey:
    if (clickMode = "Left Click") {
        Click
    } else if (clickMode = "Right Click") {
        Click, right
    } else {
        Send, {%spamKey%}
    }
    if (useRandomDelay) {
        Random, randomDelay, 0, maxRandomDelay
        Sleep, spamDelay + randomDelay
    } else {
        Sleep, spamDelay
    }
return

F6::
    Gosub, ToggleAction
return

ShowGUI:
    Gui, Show
return

GuiClose:
    SaveSettings()  ; Save settings when the GUI is closed
    ExitApp

; Ensure the key or mouse button is released when the script exits
OnExit("ExitFunc")
ExitFunc(ExitReason, ExitCode)
{
    global
    if (!isSpamMode && isActive) {
        if (clickMode = "Left Click") {
            Click, up
        } else if (clickMode = "Right Click") {
            Click, right up
        } else {
            Send, {%spamKey% up}
        }
    }
}

; Function to save settings to INI file
SaveSettings() {
    global
    IniWrite, %spamKey%, %iniFile%, Settings, SpamKey
    IniWrite, %spamDelay%, %iniFile%, Settings, SpamDelay
    IniWrite, %maxRandomDelay%, %iniFile%, Settings, MaxRandomDelay
    IniWrite, %useRandomDelay%, %iniFile%, Settings, UseRandomDelay
    IniWrite, %clickMode%, %iniFile%, Settings, ClickMode
    IniWrite, %isSpamMode%, %iniFile%, Settings, IsSpamMode
}

; Function to load settings from INI file
LoadSettings() {
    global
    IniRead, spamKey, %iniFile%, Settings, SpamKey, w
    IniRead, spamDelay, %iniFile%, Settings, SpamDelay, 50
    IniRead, maxRandomDelay, %iniFile%, Settings, MaxRandomDelay, 0
    IniRead, useRandomDelay, %iniFile%, Settings, UseRandomDelay, 0
    IniRead, clickMode, %iniFile%, Settings, ClickMode, Left Click
    IniRead, isSpamMode, %iniFile%, Settings, IsSpamMode, 1
}

ConvertToBGRfromRGB(RGB) { ; Get numeric BGR value from numeric RGB value or HTML color name
  ; HEX values
  BGR := SubStr(RGB, -1, 2) SubStr(RGB, 1, 4) 
  Return BGR 
}

SetAcrylicGlassEffect(thisColor, thisAlpha, hWindow) {
  ; based on https://github.com/jNizM/AHK_TaskBar_SetAttr/blob/master/scr/TaskBar_SetAttr.ahk
  ; by jNizM
    initialAlpha := thisAlpha
    If (thisAlpha<16)
       thisAlpha := 16
    Else If (thisAlpha>245)
       thisAlpha := 245


    ; Lexikos: Keep original value of thisAlpha for use below.
    gradient_color := Format("{1:#x}{}", thisAlpha, ConvertToBGRfromRGB(thisColor))

    Static init, accent_state := 4, ver := DllCall("GetVersion") & 0xff < 10
    Static pad := A_PtrSize = 8 ? 4 : 0, WCA_ACCENT_POLICY := 19
    accent_size := VarSetCapacity(ACCENT_POLICY, 16, 0)
    NumPut(accent_state, ACCENT_POLICY, 0, "int")

    If (RegExMatch(gradient_color, "0x[[:xdigit:]]{8}"))
       NumPut(gradient_color, ACCENT_POLICY, 8, "int")

    VarSetCapacity(WINCOMPATTRDATA, 4 + pad + A_PtrSize + 4 + pad, 0)
    && NumPut(WCA_ACCENT_POLICY, WINCOMPATTRDATA, 0, "int")
    && NumPut(&ACCENT_POLICY, WINCOMPATTRDATA, 4 + pad, "ptr")
    && NumPut(accent_size, WINCOMPATTRDATA, 4 + pad + A_PtrSize, "uint")
    If !(DllCall("user32\SetWindowCompositionAttribute", "ptr", hWindow, "ptr", &WINCOMPATTRDATA))
       Return 0 
    thisOpacity := (initialAlpha<16) ? 60 + initialAlpha*9 : 250
    ; Lexikos: Use TransColor instead of Transparent.
    WinSet, TransColor, %thisColor% %thisOpacity%, ahk_id %hWindow%
    Return 1
}