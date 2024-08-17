#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_MyDocuments%

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
iniFile := A_MyDocuments "\AutoClicker\settings.ini"
IsAlwaysOnTop := true
isDarkMode := true
isAcrylic := true
bgrColor := "000000"
textColor := "FFFFFF"

; Change icon
hIcon := DllCall("LoadImage", uint, 0, str, A_ScriptDir "\icon.ico", uint, 1, int, 0, int, 0, uint, 0x10)
Gui +LastFound
SendMessage, 0x80, 0, hIcon

; Load settings from INI file
LoadSettings()

; Create GUI
Gui, -DPIScale +Owner +hwndgHwnd
Gui, Font, s10, Arial

; GUI layout
Gui, Add, Text, x10 y10 vActionText, Action
if (clickMode == "Left Click") {
    Gui, Add, DropDownList, x170 y7 w95 vClickMode gSetMode, Left Click||Right Click|Key|
} else if (clickMode = "Right Click") {
    Gui, Add, DropDownList, x170 y7 w95 vClickMode gSetMode, Left Click|Right Click||Key|
} else {
    Gui, Add, DropDownList, x170 y7 w95 vClickMode gSetMode, Left Click|Right Click|Key||
}

Gui, Add, Text, x10 y40 vKeyText, Key to Spam/Hold
Gui, Add, Edit, x170 y37 w30 vKeyInput gValidateKey, %spamKey%
if (clickMode != "Key") {
    GuiControl, Disable, KeyInput
}

Gui, Add, Text, x10 y70 vDelayText, Delay (ms)
Gui, Add, Edit, x170 y67 w50 vDelayInput gSetDelay Number, %spamDelay%

Gui, Add, Text, x10 y100 vRandomText, Random Delay (ms)
Gui, Add, CheckBox, x132 y100 vRandomDelay gSetRandomDelay
if (useRandomDelay) {
    GuiControl,, RandomDelay, 1
}
Gui, Add, Edit, x170 y100 w50 vMaxRandomDelay gSetMaxRandomDelay Number, %maxRandomDelay%

Gui, Add, Text, x10 y130 vSpamText, Spam
Gui, Add, Text, x84 y130 vHoldText, Hold
Gui, Add, Radio, x52 y130 vSpamMode gSetMode
if (isSpamMode) {
    GuiControl,, SpamMode, 1
}
Gui, Add, Radio, x119 y130 vHoldMode gSetMode
if (!isSpamMode) {
    GuiControl,, HoldMode, 1
}

Gui, Add, Button, x10 y160 w250 h30 vToggleButton gToggleAction, Start (F6)

UpdateTheme()
Gui, Show, w270 h200, Auto Clicker

GuiControlGet, hEdit, Hwnd, KeyInput
DllCall("HideCaret", "Int", hEdit)

; Create a custom tray menu
Menu, Tray, NoStandard
Menu, Tray, Add, Show GUI, ShowGUI
Menu, Tray, Add, Always on Top, ToggleAlwaysOnTop
Menu, Tray, Add, Dark Mode, ToggleDarkMode
Menu, Tray, Add, Acrylic Effect, ToggleAcrylicEffect
Menu, Tray, Add, Exit, GuiClose
Menu, Tray, Default, Show GUI

; Set initial tray checks
if (IsAlwaysOnTop) {
    Menu, Tray, ToggleCheck, Always on Top
    Gui, +AlwaysOnTop
}
if (isDarkMode) {
    Menu, Tray, ToggleCheck, Dark Mode
}
if (isAcrylic) {
    Menu, Tray, ToggleCheck, Acrylic Effect
    EnableBlur(gHwnd)
}

return

ToggleAlwaysOnTop:
    IsAlwaysOnTop := !IsAlwaysOnTop
    if (IsAlwaysOnTop) {
        Gui, +AlwaysOnTop
    } else {
        Gui, -AlwaysOnTop
    }
    Menu, Tray, ToggleCheck, Always on Top
    SaveSettings()
return

ToggleDarkMode:
    isDarkMode := !isDarkMode
    UpdateTheme()
    Menu, Tray, ToggleCheck, Dark Mode
    SaveSettings()
return

ToggleAcrylicEffect:
    isAcrylic := !isAcrylic
    UpdateTheme()
    Menu, Tray, ToggleCheck, Acrylic Effect
    SaveSettings()
return

ValidateKey:
    DllCall("HideCaret", "Int", hEdit)
    GuiControlGet, KeyInput
    if (StrLen(KeyInput) != 1 || !RegExMatch(KeyInput, "^[a-zA-Z]$")) {
        KeyInput := SubStr(KeyInput, 1, 1)
    }
    GuiControl,, KeyInput, %KeyInput%
    spamKey := KeyInput
return

SetDelay:
    Gui, Submit, NoHide
    spamDelay := DelayInput
    SaveSettings()
return

SetMaxRandomDelay:
    Gui, Submit, NoHide
    maxRandomDelay := MaxRandomDelay
    SaveSettings()
return

SetRandomDelay:
    Gui, Submit, NoHide
    useRandomDelay := RandomDelay
    SaveSettings()
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
        Gosub, ToggleAction
    }

    SaveSettings()
return

ToggleAction:
    isActive := !isActive
    if (isActive) {
        if (isSpamMode) {
            SetTimer, SpamKey, %spamDelay%
        } else {
            SendAction("down")
        }
        GuiControl,, ToggleButton, Stop (F6)
    } else {
        if (isSpamMode) {
            SetTimer, SpamKey, Off
        } else {
            SendAction("up")
        }
        GuiControl,, ToggleButton, Start (F6)
    }
return

SendAction(action) {
    global clickMode, spamKey
    if (clickMode = "Left Click") {
        if (action = "down") {
            Click Down
        } else if (action = "up") {
            Click Up
        }
    } else if (clickMode = "Right Click") {
        if (action = "down") {
            Click Down Right
        } else if (action = "up") {
            Click Up Right
        }
    } else {
        if (action = "down") {
            Send, {%spamKey% Down}
        } else if (action = "up") {
            Send, {%spamKey% Up}
        }
    }
}

SpamKey:
    SendAction("down")
    SleepDelay()
    SendAction("up")
return

SleepDelay() {
    global spamDelay, useRandomDelay, maxRandomDelay
    if (useRandomDelay) {
        Random, randomDelay, 0, maxRandomDelay
        Sleep, spamDelay + randomDelay
    } else {
        Sleep, spamDelay
    }
}

F6::Gosub, ToggleAction
return

ShowGUI:
    Gui, Show
return

GuiClose:
    SaveSettings()
    ExitApp

OnExit("ExitFunc")
ExitFunc(ExitReason, ExitCode) {
    global
    if (!isSpamMode && isActive) {
        SendAction("up")
    }
}

SaveSettings() {
    global
    IniWrite, %spamKey%, %iniFile%, Settings, SpamKey
    IniWrite, %spamDelay%, %iniFile%, Settings, SpamDelay
    IniWrite, %maxRandomDelay%, %iniFile%, Settings, MaxRandomDelay
    IniWrite, %useRandomDelay%, %iniFile%, Settings, UseRandomDelay
    IniWrite, %clickMode%, %iniFile%, Settings, ClickMode
    IniWrite, %isSpamMode%, %iniFile%, Settings, IsSpamMode
    IniWrite, %IsAlwaysOnTop%, %iniFile%, Settings, IsAlwaysOnTop
    IniWrite, %isDarkMode%, %iniFile%, Settings, isDarkMode
    IniWrite, %isAcrylic%, %iniFile%, Settings, isAcrylic
}

LoadSettings() {
    global
    IniRead, spamKey, %iniFile%, Settings, SpamKey, w
    IniRead, spamDelay, %iniFile%, Settings, SpamDelay, 50
    IniRead, maxRandomDelay, %iniFile%, Settings, MaxRandomDelay, 0
    IniRead, useRandomDelay, %iniFile%, Settings, UseRandomDelay, 0
    IniRead, clickMode, %iniFile%, Settings, ClickMode, Left Click
    IniRead, isSpamMode, %iniFile%, Settings, IsSpamMode, 1
    IniRead, IsAlwaysOnTop, %iniFile%, Settings, IsAlwaysOnTop, true
    IniRead, isDarkMode, %iniFile%, Settings, isDarkMode, true
    IniRead, isAcrylic, %iniFile%, Settings, isAcrylic, true
}

; qwerty12 on AHK forums
EnableBlur(gHwnd, enable := true)
{
    ; WindowCompositionAttribute
    WCA_ACCENT_POLICY := 19
    
    ; AccentState
    ACCENT_DISABLED := 0,
    ACCENT_ENABLE_GRADIENT := 1,
    ACCENT_ENABLE_TRANSPARENTGRADIENT := 2
    ACCENT_ENABLE_BLURBEHIND := 3
    ACCENT_INVALID_STATE := 4

    accentStructSize := VarSetCapacity(AccentPolicy, 4*4, 0)
    NumPut(ACCENT_ENABLE_BLURBEHIND * enable, AccentPolicy, 0, "UInt")

    padding := A_PtrSize == 8 ? 4 : 0
    VarSetCapacity(WindowCompositionAttributeData, 4 + padding + A_PtrSize + 4 + padding)
    NumPut(WCA_ACCENT_POLICY, WindowCompositionAttributeData, 0, "UInt")
    NumPut(&AccentPolicy, WindowCompositionAttributeData, 4 + padding, "Ptr")
    NumPut(accentStructSize, WindowCompositionAttributeData, 4 + padding + A_PtrSize, "UInt")
    
    DllCall("SetWindowCompositionAttribute", "Ptr", gHwnd, "Ptr", &WindowCompositionAttributeData)
}

UpdateTheme() {
    global
    if (isDarkMode) {
        if (isAcrylic) {
            bgrColor := "000000"
        } else {
            bgrColor := "222222"
        }
        textColor := "FFFFFF"
    } else {
        if (isAcrylic) {
            bgrColor := "AAAAAA"
        } else {
            bgrColor := "EEEEEE"
        }
        textColor := "000000"
    }
    Gui, Color, c%bgrColor%
    GuiControl, +c%textColor%, ActionText
    GuiControl, +c%textColor%, KeyText
    GuiControl, +c%textColor%, DelayText
    GuiControl, +c%textColor%, RandomText
    GuiControl, +c%textColor%, SpamText
    GuiControl, +c%textColor%, HoldText
    EnableBlur(gHwnd, isAcrylic)
}
