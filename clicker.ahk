#NoEnv
#Warn
#SingleInstance Force
SendMode Input
SetWorkingDir %A_MyDocuments%

; Create directory if it doesn't exist
if !FileExist(A_MyDocuments "\AutoClicker") {
    FileCreateDir, %A_MyDocuments%\AutoClicker
}

; Global variables
spamKey := "w"
isActive := false
spamDelay := 50
maxRandomDelay := 0
isSpamMode := true
clickMode := "Left Click"
useRandomDelay := false
hEdit := 0
iniFile := A_MyDocuments "\AutoClicker\settings.ini"

; Change icon
hIcon := DllCall("LoadImage", uint, 0, str, A_ScriptDir "\icon.ico", uint, 1, int, 0, int, 0, uint, 0x10)
Gui +LastFound
SendMessage, 0x80, 0, hIcon

; Load settings from INI file
LoadSettings()

; Create GUI
Gui, Font, s10, Arial

; Set font and text color for labels and text
Gui, Add, Text, x10 y10, Action
if (clickMode = "Left Click") {
    Gui, Add, DropDownList, x170 y7 w95 vClickMode gSetMode, Left Click||Right Click|Key|
} else if (clickMode = "Right Click") {
    Gui, Add, DropDownList, x170 y7 w95 vClickMode gSetMode, Left Click|Right Click||Key|
} else {
    Gui, Add, DropDownList, x170 y7 w95 vClickMode gSetMode, Left Click|Right Click|Key||
}

Gui, Add, Text, x10 y40, Key to Spam/Hold
if (clickMode = "Key") {
    Gui, Add, Edit, x170 y37 w30 vKeyInput gValidateKey, %spamKey%
} else {
    Gui, Add, Edit, x170 y37 w30 vKeyInput gValidateKey Disabled, %spamKey%
}

Gui, Add, Text, x10 y70, Delay (ms)
Gui, Add, Edit, x170 y67 w50 vDelayInput gSetDelay Number, %spamDelay%

if (useRandomDelay) {
    Gui, Add, CheckBox, x10 y100 vRandomDelay gSetRandomDelay Checked, Random Delay (ms)
} else {
    Gui, Add, CheckBox, x10 y100 vRandomDelay gSetRandomDelay, Random Delay (ms)
}

Gui, Add, Edit, x170 y97 w50 vMaxRandomDelay gSetMaxRandomDelay Number, %maxRandomDelay%

if (isSpamMode) {
    Gui, Add, Radio, x10 y130 vSpamMode gSetMode Checked, Spam
    Gui, Add, Radio, x75 y130 vHoldMode gSetMode, Hold
} else {
    Gui, Add, Radio, x10 y130 vSpamMode gSetMode, Spam
    Gui, Add, Radio, x75 y130 vHoldMode gSetMode Checked, Hold
}

Gui, Add, Button, x10 y160 w250 h30 vToggleButton gToggleAction, Start (F6)

Gui, Show, w270 h200, Auto Clicker

; Get the handle for the Edit control
GuiControlGet, hEdit, Hwnd, KeyInput

; Hide the caret permanently
DllCall("HideCaret", "Int", hEdit)

; Apply acrylic effect
SetAcrylicGlassEffect("000022", 125, WinExist())

; Create a custom tray menu
Menu, Tray, NoStandard
Menu, Tray, Add, Show GUI, ShowGUI
Menu, Tray, Add, Exit, GuiClose
Menu, Tray, Default, Show GUI

return

; Function to set acrylic background
SetAcrylicGlassEffect(thisColor, thisAlpha, hWindow) {
    initialAlpha := thisAlpha
    If (thisAlpha < 16)
        thisAlpha := 16
    Else If (thisAlpha > 245)
        thisAlpha := 245

    thisColor := ConvertToBGRfromRGB(thisColor)
    thisAlpha := Format("{1:#x}", thisAlpha)
    gradient_color := thisAlpha . thisColor

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
    thisOpacity := (initialAlpha < 16) ? 60 + initialAlpha * 9 : 250
    WinSet, Transparent, %thisOpacity%, ahk_id %hWindow%
    Return 1
}

; Function to convert RGB to BGR
ConvertToBGRfromRGB(RGB) {
    BGR := SubStr(RGB, -1, 2) . SubStr(RGB, 1, 4)
    Return BGR
}


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
