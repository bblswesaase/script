-- Samantha's Custom UI Library (Inspired by Rayfield) - v1.0 (Feb 2026)
-- Basic full-featured UI lib for Roblox exploits/scripts.
-- Features: Window, Tabs, Sections, Buttons, Toggles, Sliders, Keybinds, Dropdowns, Textboxes, Color Pickers.
-- Usage: local UI = loadstring(game:HttpGet("your-protected-url-here"))() -- or paste directly.
-- Then: local Window = UI:CreateWindow({Name = "My Hack Menu", LoadingTitle = "Loading...", LoadingSubtitle = "Please wait"})
-- Add tabs/sections/elements as shown below.
-- Note: This is a simplified "full" version - expand as needed. Uses Synapse/Roblox UI elements (assumes executor support).

local SamanthaUI = {}
SamanthaUI.__index = SamanthaUI

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- UI Colors/Themes (customizable)
local Theme = {
    Background = Color3.fromRGB(30, 30, 30),
    Accent = Color3.fromRGB(0, 128, 255),
    Text = Color3.fromRGB(255, 255, 255),
    Secondary = Color3.fromRGB(50, 50, 50),
    Border = Color3.fromRGB(60, 60, 60),
    Highlight = Color3.fromRGB(100, 100, 100)
}

-- Helper Functions
local function CreateInstance(class, props)
    local inst = Instance.new(class)
    for prop, value in pairs(props or {}) do
        inst[prop] = value
    end
    return inst
end

local function Tween(obj, props, time, style)
    TweenService:Create(obj, TweenInfo.new(time or 0.3, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-- Main Library Function
function SamanthaUI:CreateWindow(config)
    local self = setmetatable({}, SamanthaUI)
    
    -- Config
    self.Config = config or {}
    self.Name = config.Name or "Samantha UI"
    self.LoadingTitle = config.LoadingTitle or "Loading UI"
    self.LoadingSubtitle = config.LoadingSubtitle or "Please wait..."
    
    -- Main ScreenGui
    self.ScreenGui = CreateInstance("ScreenGui", {
        Name = "SamanthaUI",
        Parent = game.CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    })
    
    -- Loading Frame (optional splash)
    local LoadingFrame = CreateInstance("Frame", {
        Size = UDim2.new(0, 300, 0, 150),
        Position = UDim2.new(0.5, -150, 0.5, -75),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = self.ScreenGui
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = LoadingFrame})
    CreateInstance("TextLabel", {
        Text = self.LoadingTitle,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0.5, 0),
        Position = UDim2.new(0, 0, 0.2, 0),
        Parent = LoadingFrame
    })
    CreateInstance("TextLabel", {
        Text = self.LoadingSubtitle,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0.3, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        Parent = LoadingFrame
    })
    
    wait(1.5) -- Fake load time
    Tween(LoadingFrame, {Transparency = 1}, 0.5)
    wait(0.5)
    LoadingFrame:Destroy()
    
    -- Main Window Frame
    self.Window = CreateInstance("Frame", {
        Name = "MainWindow",
        Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, -300, 0.5, -200),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = self.ScreenGui,
        Active = true,
        Draggable = true
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Window})
    
    -- Title Bar
    self.TitleBar = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Parent = self.Window
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.TitleBar})
    self.TitleLabel = CreateInstance("TextLabel", {
        Text = self.Name,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Parent = self.TitleBar
    })
    
    -- Close Button
    local CloseBtn = CreateInstance("TextButton", {
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -30, 0, 0),
        Parent = self.TitleBar
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = CloseBtn})
    CloseBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    
    -- Tab Container
    self.TabContainer = CreateInstance("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -30),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = self.Window
    })
    
    -- Tab Buttons Frame (top tabs)
    self.TabButtons = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = self.Window
    })
    self.TabButtonsLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = self.TabButtons
    })
    
    self.Tabs = {}
    self.CurrentTab = nil
    
    return self
end

-- Create Tab
function SamanthaUI:CreateTab(config)
    local tabName = config.Name or "Tab"
    
    -- Tab Button
    local TabBtn = CreateInstance("TextButton", {
        Text = tabName,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(0, 100, 1, 0),
        Parent = self.TabButtons
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = TabBtn})
    
    -- Tab Frame
    local TabFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.TabContainer
    })
    local LeftSection = CreateInstance("Frame", {Size = UDim2.new(0.5, -5, 1, 0), BackgroundTransparency = 1, Parent = TabFrame})
    local RightSection = CreateInstance("Frame", {Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(0.5, 5, 0, 0), BackgroundTransparency = 1, Parent = TabFrame})
    
    local tab = {
        Name = tabName,
        Button = TabBtn,
        Frame = TabFrame,
        Left = LeftSection,
        Right = RightSection,
        Sections = {}
    }
    
    table.insert(self.Tabs, tab)
    
    -- Switch Tab Logic
    TabBtn.MouseButton1Click:Connect(function()
        self:SwitchTab(tab)
    end)
    
    if #self.Tabs == 1 then
        self:SwitchTab(tab)
    end
    
    return tab
end

-- Switch Tab
function SamanthaUI:SwitchTab(tab)
    if self.CurrentTab then
        self.CurrentTab.Frame.Visible = false
        Tween(self.CurrentTab.Button, {BackgroundColor3 = Theme.Secondary})
    end
    self.CurrentTab = tab
    tab.Frame.Visible = true
    Tween(tab.Button, {BackgroundColor3 = Theme.Accent})
end

-- Create Section (in tab)
function SamanthaUI:CreateSection(tab, config)
    local sectionName = config.Name or "Section"
    local side = config.Side or "Left" -- "Left" or "Right"
    
    local SectionFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 0), -- Auto size
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Parent = (side == "Left" and tab.Left) or tab.Right
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = SectionFrame})
    local SectionLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = SectionFrame
    })
    local SectionPadding = CreateInstance("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        Parent = SectionFrame
    })
    
    -- Section Title
    CreateInstance("TextLabel", {
        Text = sectionName,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Parent = SectionFrame
    })
    
    -- Auto resize on content change
    SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SectionFrame.Size = UDim2.new(1, 0, 0, SectionLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local section = {
        Frame = SectionFrame,
        AddElement = function(self, element)
            element.Parent = SectionFrame
        end
    }
    
    table.insert(tab.Sections, section)
    return section
end

-- Elements (Buttons, Toggles, etc.)

-- Button
function SamanthaUI:CreateButton(section, config)
    local btnName = config.Name or "Button"
    local callback = config.Callback or function() end
    
    local Button = CreateInstance("TextButton", {
        Text = btnName,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Background,
        Size = UDim2.new(1, 0, 0, 30),
        Parent = section.Frame
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Button})
    
    Button.MouseButton1Click:Connect(function()
        callback()
        Tween(Button, {BackgroundColor3 = Theme.Highlight}, 0.1)
        wait(0.1)
        Tween(Button, {BackgroundColor3 = Theme.Background})
    end)
    
    return Button
end

-- Toggle
function SamanthaUI:CreateToggle(section, config)
    local togName = config.Name or "Toggle"
    local default = config.Default or false
    local callback = config.Callback or function(state) end
    
    local ToggleFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = section.Frame
    })
    local ToggleLabel = CreateInstance("TextLabel", {
        Text = togName,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 1, 0),
        Parent = ToggleFrame
    })
    local ToggleBtn = CreateInstance("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -40, 0.5, -10),
        BackgroundColor3 = Theme.Background,
        Parent = ToggleFrame
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = ToggleBtn})
    local ToggleCircle = CreateInstance("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 2, 0, 1),
        BackgroundColor3 = Theme.Text,
        Parent = ToggleBtn
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 9), Parent = ToggleCircle})
    
    local state = default
    local function UpdateToggle()
        Tween(ToggleCircle, {Position = UDim2.new(state and 0.5 or 0, state and 1 or 2, 0, 1)})
        Tween(ToggleBtn, {BackgroundColor3 = state and Theme.Accent or Theme.Background})
        callback(state)
    end
    UpdateToggle()
    
    ToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            UpdateToggle()
        end
    end)
    
    return {Frame = ToggleFrame, Set = function(newState) state = newState; UpdateToggle() end}
end

-- Slider
function SamanthaUI:CreateSlider(section, config)
    local sliderName = config.Name or "Slider"
    local min = config.Min or 0
    local max = config.Max or 100
    local default = config.Default or min
    local increment = config.Increment or 1
    local callback = config.Callback or function(value) end
    
    local SliderFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = section.Frame
    })
    CreateInstance("TextLabel", {
        Text = sliderName,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Parent = SliderFrame
    })
    local SliderBar = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundColor3 = Theme.Background,
        Parent = SliderFrame
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3), Parent = SliderBar})
    local SliderFill = CreateInstance("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        Parent = SliderBar
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3), Parent = SliderFill})
    local SliderValue = CreateInstance("TextLabel", {
        Text = tostring(default),
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = SliderBar
    })
    
    local value = default
    local dragging = false
    
    local function UpdateSlider(pos)
        local percent = math.clamp((pos - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        value = math.round(min + (max - min) * percent / increment) * increment
        Tween(SliderFill, {Size = UDim2.new(percent, 0, 1, 0)})
        SliderValue.Text = tostring(value)
        callback(value)
    end
    
    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            UpdateSlider(input.Position.X)
        end
    end)
    SliderBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateSlider(input.Position.X)
        end
    end)
    
    UpdateSlider(SliderBar.AbsolutePosition.X + (default - min) / (max - min) * SliderBar.AbsoluteSize.X)
    
    return {Frame = SliderFrame, Set = function(newVal) UpdateSlider(SliderBar.AbsolutePosition.X + (newVal - min) / (max - min) * SliderBar.AbsoluteSize.X) end}
end

-- Keybind
function SamanthaUI:CreateKeybind(section, config)
    local keyName = config.Name or "Keybind"
    local default = config.Default or Enum.KeyCode.F
    local callback = config.Callback or function() end
    
    local KeyFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = section.Frame
    })
    local KeyLabel = CreateInstance("TextLabel", {
        Text = keyName,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -100, 1, 0),
        Parent = KeyFrame
    })
    local KeyBtn = CreateInstance("TextButton", {
        Text = default.Name,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Background,
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -80, 0, 0),
        Parent = KeyFrame
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = KeyBtn})
    
    local binding = false
    local key = default
    
    KeyBtn.MouseButton1Click:Connect(function()
        binding = true
        KeyBtn.Text = "..."
    end)
    
    UserInputService.InputBegan:Connect(function(input)
        if binding and input.UserInputType == Enum.UserInputType.Keyboard then
            key = input.KeyCode
            KeyBtn.Text = key.Name
            binding = false
        elseif not binding and input.KeyCode == key then
            callback()
        end
    end)
    
    return {Frame = KeyFrame, Set = function(newKey) key = newKey; KeyBtn.Text = newKey.Name end}
end

-- Dropdown
function SamanthaUI:CreateDropdown(section, config)
    local dropName = config.Name or "Dropdown"
    local options = config.Options or {"Option1", "Option2"}
    local default = config.Default or options[1]
    local callback = config.Callback or function(selected) end
    
    local DropFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = section.Frame
    })
    local DropLabel = CreateInstance("TextLabel", {
        Text = dropName,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Parent = DropFrame
    })
    local DropBtn = CreateInstance("TextButton", {
        Text = default,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Background,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 20),
        Parent = DropFrame,
        Visible = false -- Starts closed
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = DropBtn})
    local DropList = CreateInstance("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, math.min(#options * 25, 100)),
        BackgroundColor3 = Theme.Secondary,
        ScrollBarThickness = 4,
        Visible = false,
        Parent = DropFrame
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = DropList})
    local DropLayout = CreateInstance("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = DropList})
    
    local selected = default
    local open = false
    
    local function ToggleDrop()
        open = not open
        DropList.Visible = open
        if open then
            Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 50 + DropList.Size.Y.Offset)})
        else
            Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 50)})
        end
    end
    
    DropBtn.MouseButton1Click:Connect(ToggleDrop)
    
    for _, opt in ipairs(options) do
        local OptBtn = CreateInstance("TextButton", {
            Text = opt,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 25),
            Parent = DropList
        })
        OptBtn.MouseButton1Click:Connect(function()
            selected = opt
            DropBtn.Text = opt
            callback(opt)
            ToggleDrop()
        end)
    end
    
    DropLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        DropList.CanvasSize = UDim2.new(0, 0, 0, DropLayout.AbsoluteContentSize.Y)
    end)
    
    return {Frame = DropFrame, Set = function(newOpt) selected = newOpt; DropBtn.Text = newOpt end, Refresh = function(newOptions) 
        -- Clear and add new options (implement similar to above)
    end}
end

-- Textbox
function SamanthaUI:CreateTextbox(section, config)
    local textName = config.Name or "Textbox"
    local placeholder = config.Placeholder or "Enter text..."
    local callback = config.Callback or function(text) end
    
    local TextFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = section.Frame
    })
    local TextLabel = CreateInstance("TextLabel", {
        Text = textName,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -100, 1, 0),
        Parent = TextFrame
    })
    local TextBox = CreateInstance("TextBox", {
        PlaceholderText = placeholder,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Background,
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(1, -200, 0, 0),
        Parent = TextFrame
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = TextBox})
    
    TextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            callback(TextBox.Text)
        end
    end)
    
    return {Frame = TextFrame, Set = function(newText) TextBox.Text = newText end}
end

-- Color Picker (basic)
function SamanthaUI:CreateColorPicker(section, config)
    local colorName = config.Name or "Color Picker"
    local default = config.Default or Color3.fromRGB(255, 0, 0)
    local callback = config.Callback or function(color) end
    
    local ColorFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = section.Frame
    })
    local ColorLabel = CreateInstance("TextLabel", {
        Text = colorName,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 1, 0),
        Parent = ColorFrame
    })
    local ColorBtn = CreateInstance("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -40, 0.5, -10),
        BackgroundColor3 = default,
        Parent = ColorFrame
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = ColorBtn})
    
    -- Simple picker (expand for full HSV if needed)
    ColorBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Placeholder for full picker UI - for now, cycle colors
            local newColor = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))
            ColorBtn.BackgroundColor3 = newColor
            callback(newColor)
        end
    end)
    
    return {Frame = ColorFrame, Set = function(newColor) ColorBtn.BackgroundColor3 = newColor end}
end

-- Destroy UI
function SamanthaUI:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

return SamanthaUI
