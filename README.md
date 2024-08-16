# Auto Clicker Script

## Description

This AutoHotkey script provides a customizable auto clicker tool. It allows you to automate mouse clicks or key presses with various configurations, including delays and random delays. The script supports both spam and hold modes, as well as customizable key bindings and click modes.

## Features

- **Click Modes**: Choose between left click, right click, or key press.
- **Spam or Hold Mode**: Toggle between spamming clicks/keys or holding them down.
- **Configurable Delay**: Set a delay between actions, with an option for a random additional delay.
- **Key Binding**: Define a specific key to be spammed or held down.
- **Settings Saving**: Save and load settings from an INI file for persistent configuration.
- **Dynamic Tray Menu**: Access settings and control the script via a system tray menu.

## Requirements

- [AutoHotkey](https://www.autohotkey.com/) (version 1.1 only)

## Usage

1. **Run the Script**: Double-click the script file to launch the GUI.
2. **Configure Settings**:
   - **Action Mode**: Choose between "Left Click," "Right Click," or "Key."
   - **Key to Spam/Hold**: Enter the key you want to spam or hold.
   - **Delay (ms)**: Set the delay between actions.
   - **Random Delay (ms)**: Optionally add a random delay.
   - **Spam Mode**: Select whether to use spam or hold mode.
3. **Control the Script**:
   - **Start/Stop**: Use the "Start (F6)" button to begin or stop the auto-clicking/pressing.
   - **System Tray Menu**: Right-click the system tray icon to show the GUI or exit the script.

## Settings File

Settings are saved to `settings.ini` in the `AutoClicker` directory within your Documents folder. The script will automatically load these settings when it starts.
