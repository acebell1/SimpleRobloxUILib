# SimpleRobloxUILib
Simple Roblox UI Lib for executors, use for creating your cheats

## Features

- Clean, modern dark theme with customizable accent color
- Tabs and sub-tabs for organizing your menu
- Ready-made elements: Section, Label, Button, Toggle, Slider, Dropdown, Textbox, Keybind
- Built-in config save/load (via executor file API)
- Toast notifications
- Draggable window
- Accent color presets + custom
- Safe callbacks (pcall-wrapped, won't crash the menu)
- Scale setting (70% - 130%)

---

## Installation

### Option A - Load from GitHub (recommended)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/acebell1/SimpleRobloxUILib/main/SimpleRobloxUILib.lua"))()

Replace USERNAME/REPO with your own GitHub path.

### Option B - Local file

Paste the entire RealUI.lua source at the top of your script, remove the demo section at the bottom (keep "return Library"), then write your code below it.

WARNING: Requires an executor. RealUI uses gethui, writefile, readfile, isfolder, makefolder, and isfile. It will not run in Roblox Studio without modification.

---

## Quick Start

-- 1. Load the library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/REPO/main/RealUI.lua"))()

-- 2. Create the window
local Win = Library:CreateWindow({
    Title = "My Cheats",
    Size = Vector2.new(580, 380),            -- optional
    Accent = Color3.fromRGB(110, 120, 255),  -- optional
    ToggleKey = Enum.KeyCode.RightShift,     -- optional (default: RightShift)
})

-- 3. Create tabs
local Main = Win:CreateTab("Main")
local Visual = Win:CreateTab("Visuals", "rbxassetid://123456") -- icon optional

-- 4. Add elements
Main:AddSection("Movement")
Main:AddSlider({
    Name = "WalkSpeed",
    Min = 16, Max = 200,
    Default = 16,
    Suffix = " studs",
    Flag = "speed",
    Callback = function(value)
        local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = value end
    end,
})

Main:AddButton({
    Name = "Say hi",
    Callback = function() Win:Notify({ Title = "Hi!", Content = "Hello, world." }) end,
})

-- 5. Settings tab (always last)
Win:CreateSettingsTab()

-- 6. Welcome message
Win:Notify({ Title = "Loaded", Content = "Press RightShift to open." })

---

## API Reference

### Window

local Win = Library:CreateWindow(config)

Fields:

Title       - string         - Title shown in the topbar
Size        - Vector2        - Window size (default 580, 380)
Accent      - Color3         - Accent color
ToggleKey   - Enum.KeyCode   - Key that hides/shows the menu

Methods:

Win:CreateTab(name, icon?)              - Creates a new tab in the sidebar
Win:CreateSettingsTab(name?)            - Creates the prebuilt Settings tab
Win:Notify({Title, Content, Duration})  - Shows a toast notification
Win:SetAccent(Color3)                   - Changes accent color at runtime
Win:SetToggleKey(Enum.KeyCode)          - Changes the hide/show key
Win:Toggle(state?)                      - Hides/shows the menu (toggles if nil)
Win:SaveConfig(name)                    - Saves all flags to RealUI/<name>.json
Win:LoadConfig(name)                    - Loads flags from a config file
Win:Destroy()                           - Removes the menu completely
Win.Flags.<Flag>                        - Reads the current value of a flagged element

---

### Tab / SubTab

Both share the same element API. If a tab contains sub-tabs, elements added directly to the tab are hidden - use one or the other.

local Tab = Win:CreateTab("Main")
local Sub = Tab:CreateSubTab("ESP")

Methods:

:AddSection(text)                                              - Header label for grouping elements
:AddLabel(text)                                                - Plain text label
:AddButton({Name, Callback})                                   - Clickable button
:AddToggle({Name, Default, Flag, Callback, CallOnLoad})        - On/off switch
:AddSlider({Name, Min, Max, Default, Increment, Suffix, Flag, Callback}) - Numeric slider
:AddDropdown({Name, Options, Default, Multi, Flag, Callback})  - Dropdown list
:AddTextbox({Name, Default, Placeholder, Flag, Callback})      - Text input
:AddKeybind({Name, Default, Flag, Callback, OnChanged})        - Key binding

---

### Elements in Detail

Button:

Tab:AddButton({
    Name = "Click me",
    Callback = function() print("clicked") end,
})

Toggle:

local toggle = Tab:AddToggle({
    Name = "Enable ESP",
    Default = false,
    Flag = "esp_on",
    Callback = function(state) print(state) end,
})
toggle:Set(true) -- programmatic change

Slider:

Tab:AddSlider({
    Name = "Speed",
    Min = 16, Max = 200,
    Default = 50,
    Increment = 1,
    Suffix = " studs",
    Flag = "speed",
    Callback = function(v) print(v) end,
})

Dropdown (single):

local dd = Tab:AddDropdown({
    Name = "Mode",
    Options = {"Box", "Corner", "3D"},
    Default = "Box",
    Flag = "esp_mode",
    Callback = function(v) print(v) end,
})
dd:Refresh({"NewA", "NewB"}) -- replace options at runtime

Dropdown (multi-select):

Tab:AddDropdown({
    Name = "Targets",
    Options = {"Players", "NPCs", "Items"},
    Multi = true,
    Default = {"Players"},
    Callback = function(list) print(table.concat(list, ", ")) end,
})

Textbox:

Tab:AddTextbox({
    Name = "Name",
    Default = "",
    Placeholder = "type here...",
    Flag = "name",
    Callback = function(text) print(text) end,
})

Callback fires when the input loses focus or Enter is pressed.

Keybind:

Tab:AddKeybind({
    Name = "Activate",
    Default = Enum.KeyCode.E,
    Flag = "activate",
    Callback = function() print("pressed") end,
    OnChanged = function(name, keyCode) print(name) end,
})

Click the button, then press a key. Escape cancels, Backspace resets to None.

---

### Flags

Any element with a Flag field stores its value in Win.Flags:

if Win.Flags.esp_on then
    print("ESP is on")
end
print(Win.Flags.speed)  -- current slider value

---

### Configs

Win:SaveConfig("mysettings")  -- writes RealUI/mysettings.json
Win:LoadConfig("mysettings")  -- restores all flagged values

Configs only work when the executor provides writefile / readfile.

---

### Notifications

Win:Notify({
    Title = "Success",
    Content = "Script loaded.",
    Duration = 4,
})

---

## Full Example - Simple Cheat Menu

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/REPO/main/RealUI.lua"))()

local Win = Library:CreateWindow({ Title = "Cheat Menu" })

local Player = Win:CreateTab("Player")
local Visual = Win:CreateTab("Visuals")
local Misc   = Win:CreateTab("Misc")

-- Helpers
local function getHumanoid()
    local char = game.Players.LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- Player
Player:AddSection("Movement")

Player:AddSlider({
    Name = "WalkSpeed", Min = 16, Max = 300, Default = 16,
    Flag = "speed",
    Callback = function(v)
        local h = getHumanoid()
        if h then h.WalkSpeed = v end
    end,
})

Player:AddSlider({
    Name = "JumpPower", Min = 50, Max = 300, Default = 50,
    Flag = "jump",
    Callback = function(v)
        local h = getHumanoid()
        if h then h.UseJumpPower = true; h.JumpPower = v end
    end,
})

-- Visuals
Visual:AddSection("ESP")

local espEnabled = false
Visual:AddToggle({
    Name = "Enable ESP", Flag = "esp", Default = false,
    Callback = function(state) espEnabled = state end,
})

-- Misc
Misc:AddButton({
    Name = "Rejoin",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
    end,
})

Win:CreateSettingsTab()
Win:Notify({ Title = "Ready", Content = "Press RightShift." })

---

## Customization

### Theme

Edit DefaultTheme at the top of RealUI.lua:

local DefaultTheme = {
    Background   = Color3.fromRGB(20, 20, 26),
    Topbar       = Color3.fromRGB(26, 26, 34),
    Sidebar      = Color3.fromRGB(24, 24, 31),
    Element      = Color3.fromRGB(32, 32, 42),
    ElementHover = Color3.fromRGB(42, 42, 54),
    Stroke       = Color3.fromRGB(52, 52, 66),
    Text         = Color3.fromRGB(235, 235, 245),
    SubText      = Color3.fromRGB(150, 150, 172),
    Accent       = Color3.fromRGB(110, 120, 255),
}

### Accent presets

Add your own to AccentPresets:

local AccentPresets = {
    { "Indigo", Color3.fromRGB(110, 120, 255) },
    { "Gold",   Color3.fromRGB(255, 215, 0) },   -- new
}

### Custom element

function Container:AddMyElement(cfg)
    local card = self:_card(34)
    -- draw your element here
    return someObject
end

Because Tab and SubTab inherit from Container, the new method becomes available everywhere.

---

## Known Issues

- Keybind can hang if you click the button and then click elsewhere without pressing a key. W.Listening stays true and blocks other keybinds until you press a key.
- SetToggleKey does not update the keybind element inside the Settings tab automatically.
- Keybinds fire while typing in a Textbox - no GetFocusedTextBox() check.
- Executor-only globals (gethui, writefile, etc.) are called without pcall - the library will error in Roblox Studio.
- Demo section at the bottom of RealUI.lua must be removed when integrating into your own script.

---

## Project Structure

RealUI.lua        -- the library (library + demo)
README.md         -- this file
LICENSE           -- MIT (recommended)

---

## Recommended Companion Tools

- Dex - object tree explorer
- Infinite Yield - universal command console
- Cobalt - RemoteEvent spy
- Hydroxide - advanced Remote spy

These are separate tools, not part of RealUI.

---

## License

MIT License - free to use, modify, and redistribute. Credit is appreciated but not required.

Copyright (c) 2026 <YOUR NAME>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.

---

## Credits

Author:   <YOUR NAME>
Language: Luau (Roblox)
Built for: Roblox script executors (Real, Synapse, KRNL, Xeno, etc.)

---

## Disclaimer

This library is provided for educational and research purposes only. Using it with executors may violate Roblox's Terms of Service and can result in account bans. The author is not responsible for any consequences resulting from its use. Use at your own risk.

---

## Contributing

Pull requests are welcome. If you find a bug, open an issue with:
1. What you did
2. What you expected
3. What actually happened
4. Your executor name and version

---

## Quick Reference Card

Library:CreateWindow({Title, Size, Accent, ToggleKey})
    :CreateTab(name, icon?)
        :CreateSubTab(name)
        :AddSection(text)
        :AddLabel(text)
        :AddButton({Name, Callback})
        :AddToggle({Name, Default, Flag, Callback})
        :AddSlider({Name, Min, Max, Default, Increment, Suffix, Flag, Callback})
        :AddDropdown({Name, Options, Default, Multi, Flag, Callback})
        :AddTextbox({Name, Default, Placeholder, Flag, Callback})
        :AddKeybind({Name, Default, Flag, Callback, OnChanged})
    :CreateSettingsTab()
    :SetAccent(Color3)
    :SetToggleKey(Enum.KeyCode)
    :Notify({Title, Content, Duration})
    :Toggle(state?)
    :SaveConfig(name)
    :LoadConfig(name)
    :Destroy()

---

Made with love for the Roblox scripting community.
