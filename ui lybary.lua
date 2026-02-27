-- Elite Hub v2.0 - Advanced Roblox UI Library (Feb 2026)
-- Premium UI library with modern design, smooth animations, and advanced components
-- Features: Window, Tabs, Sections, Buttons, Toggles, Sliders, Keybinds, Dropdowns, Textboxes, Color Pickers
-- Usage: local EliteHub = loadstring(game:HttpGet("your-url-here"))()
-- Then: local Window = EliteHub:CreateWindow({Name = "Elite Hub", Icon = "rbxassetid://0"})

local EliteHub = {}
EliteHub.__index = EliteHub

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Premium Theme Configuration
local Theme = {
    -- Main Colors
    Primary = Color3.fromRGB(20, 20, 25),          -- Dark background
    Secondary = Color3.fromRGB(30, 30, 40),        -- Cards/sections
    Tertiary = Color3.fromRGB(40, 40, 55),         -- Hover states
    Accent = Color3.fromRGB(100, 180, 255),        -- Highlights/buttons
    AccentDark = Color3.fromRGB(70, 140, 220),     -- Darker accent
    
    -- Text Colors
    Text = Color3.fromRGB(240, 240, 250),
    TextDim = Color3.fromRGB(180, 180, 200),
    TextMuted = Color3.fromRGB(120, 120, 140),
    
    -- Status Colors
    Success = Color3.fromRGB(76, 175, 80),
    Warning = Color3.fromRGB(255, 152, 0),
    Error = Color3.fromRGB(244, 67, 54),
    Info = Color3.fromRGB(33, 150, 243),
    
    -- Borders & Effects
    Border = Color3.fromRGB(60, 60, 80),
    Glow = Color3.fromRGB(100, 180, 255),
}

-- Helper Functions
local function CreateInstance(class, props)
    local inst = Instance.new(class)
    for prop, value in pairs(props or {}) do
        pcall(function() inst[prop] = value end)
    end
    return inst
end

local function Tween(obj, props, time, style, direction)
    if not obj or not obj.Parent then return end
    local tweenInfo = TweenInfo.new(
        time or 0.3,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    TweenService:Create(obj, tweenInfo, props):Play()
end

local function AddGradient(frame, color1, color2)
    local gradient = CreateInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color1),
            ColorSequenceKeypoint.new(1, color2)
        }),
        Rotation = 90,
        Parent = frame
    })
    return gradient
end

-- Main Window Creation
function EliteHub:CreateWindow(config)
    local self = setmetatable({}, EliteHub)
    
    self.Config = config or {}
    self.Name = config.Name or "Elite Hub"
    self.Icon = config.Icon or "rbxassetid://0"
    self.Size = config.Size or UDim2.new(0, 850, 0, 600)
    
    -- Main ScreenGui
    self.ScreenGui = CreateInstance("ScreenGui", {
        Name = "EliteHubUI",
        Parent = (LocalPlayer:FindFirstChild("PlayerGui") or game.CoreGui),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        ResetOnSpawn = false
    })
    
    -- Main Window Frame
    self.Window = CreateInstance("Frame", {
        Name = "MainWindow",
        Size = self.Size,
        Position = UDim2.new(0.5, -425, 0.5, -300),
        BackgroundColor3 = Theme.Primary,
        BorderSizePixel = 0,
        Parent = self.ScreenGui,
        Active = true,
        Draggable = true
    })
    
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.Window})
    CreateInstance("UIStroke", {
        Color = Theme.Border,
        Thickness = 2,
        Parent = self.Window
    })
    
    -- Title Bar with Gradient
    self.TitleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Parent = self.Window
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.TitleBar})
    AddGradient(self.TitleBar, Theme.Secondary, Theme.Tertiary)
    
    -- Title Icon
    local TitleIcon = CreateInstance("ImageLabel", {
        Image = self.Icon,
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(0, 12, 0.5, -16),
        BackgroundTransparency = 1,
        Parent = self.TitleBar
    })
    
    -- Title Text
    self.TitleLabel = CreateInstance("TextLabel", {
        Text = self.Name,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 50, 0, 0),
        Parent = self.TitleBar,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Close Button
    local CloseBtn = CreateInstance("TextButton", {
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(0, 35, 0, 35),
        Position = UDim2.new(1, -45, 0.5, -17),
        Parent = self.TitleBar,
        BorderSizePixel = 0
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = CloseBtn})
    
    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}, 0.2)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, {BackgroundColor3 = Theme.Accent}, 0.2)
    end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    
    -- Tab Buttons Container
    self.TabButtonsContainer = CreateInstance("Frame", {
        Name = "TabButtons",
        Size = UDim2.new(1, 0, 0, 45),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundColor3 = Theme.Primary,
        BorderSizePixel = 0,
        Parent = self.Window
    })
    CreateInstance("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Parent = self.TabButtonsContainer
    })
    
    self.TabButtonsLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3),
        Parent = self.TabButtonsContainer
    })
    CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        Parent = self.TabButtonsContainer
    })
    
    -- Content Area
    self.ContentArea = CreateInstance("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -95),
        Position = UDim2.new(0, 0, 0, 95),
        BackgroundColor3 = Theme.Primary,
        BorderSizePixel = 0,
        Parent = self.Window
    })
    
    self.Tabs = {}
    self.CurrentTab = nil
    self.TabIndex = 0
    
    return self
end

-- Create Tab
function EliteHub:CreateTab(config)
    local tabName = config.Name or "Tab"
    local tabIcon = config.Icon or "○"
    self.TabIndex = self.TabIndex + 1
    
    -- Tab Button
    local TabBtn = CreateInstance("TextButton", {
        Name = tabName,
        Text = tabIcon .. " " .. tabName,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextColor3 = Theme.TextDim,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Size = UDim2.new(0, 130, 1, -10),
        Parent = self.TabButtonsContainer,
        BorderSizePixel = 0,
        AutoButtonColor = false
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = TabBtn})
    CreateInstance("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = TabBtn
    })
    
    -- Tab Frame (Content)
    local TabFrame = CreateInstance("Frame", {
        Name = tabName .. "Frame",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.ContentArea
    })
    
    local ScrollFrame = CreateInstance("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 6,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = TabFrame
    })
    
    local Layout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 12),
        Parent = ScrollFrame
    })
    CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        Parent = ScrollFrame
    })
    
    -- Auto-size canvas
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 24)
    end)
    
    local tab = {
        Name = tabName,
        Button = TabBtn,
        Frame = TabFrame,
        ScrollFrame = ScrollFrame,
        Layout = Layout,
        Sections = {},
        Index = self.TabIndex
    }
    
    table.insert(self.Tabs, tab)
    
    -- Tab Switch Logic
    TabBtn.MouseButton1Click:Connect(function()
        self:SwitchTab(tab)
    end)
    TabBtn.MouseEnter:Connect(function()
        if self.CurrentTab ~= tab then
            Tween(TabBtn, {BackgroundTransparency = 0.3}, 0.2)
        end
    end)
    TabBtn.MouseLeave:Connect(function()
        if self.CurrentTab ~= tab then
            Tween(TabBtn, {BackgroundTransparency = 0.5}, 0.2)
        end
    end)
    
    if #self.Tabs == 1 then
        self:SwitchTab(tab)
    end
    
    return tab
end

-- Switch Tab
function EliteHub:SwitchTab(tab)
    if self.CurrentTab then
        self.CurrentTab.Frame.Visible = false
        Tween(self.CurrentTab.Button, {BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.5, TextColor3 = Theme.TextDim}, 0.2)
    end
    
    self.CurrentTab = tab
    tab.Frame.Visible = true
    Tween(tab.Button, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0, TextColor3 = Theme.Primary}, 0.2)
end

-- Create Section
function EliteHub:CreateSection(tab, config)
    local sectionName = config.Name or "Section"
    
    local SectionFrame = CreateInstance("Frame", {
        Name = sectionName,
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Parent = tab.ScrollFrame
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = SectionFrame})
    CreateInstance("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Parent = SectionFrame
    })
    
    -- Section Header
    local HeaderFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Parent = SectionFrame
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = HeaderFrame})
    
    CreateInstance("TextLabel", {
        Text = "▸ " .. sectionName,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        Parent = HeaderFrame,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Content Container
    local ContentFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 1, -35),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundTransparency = 1,
        Parent = SectionFrame
    })
    
    local ContentLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = ContentFrame
    })
    CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        Parent = ContentFrame
    })
    
    -- Auto-size section
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SectionFrame.Size = UDim2.new(1, 0, 0, ContentLayout.AbsoluteContentSize.Y + 45)
    end)
    
    local section = {
        Frame = SectionFrame,
        ContentFrame = ContentFrame,
        ContentLayout = ContentLayout,
        AddElement = function(self, element)
            element.Parent = ContentFrame
        end
    }
    
    table.insert(tab.Sections, section)
    return section
end

-- Button Element
function EliteHub:CreateButton(section, config)
    local btnName = config.Name or "Button"
    local callback = config.Callback or function() end
    
    local Button = CreateInstance("TextButton", {
        Text = btnName,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = Theme.Primary,
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(1, 0, 0, 35),
        Parent = section.ContentFrame,
        BorderSizePixel = 0,
        AutoButtonColor = false
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = Button})
    CreateInstance("UIStroke", {
        Color = Theme.AccentDark,
        Thickness = 1,
        Parent = Button
    })
    
    local debounce = false
    
    Button.MouseEnter:Connect(function()
        Tween(Button, {BackgroundColor3 = Theme.AccentDark}, 0.2)
    end)
    Button.MouseLeave:Connect(function()
        Tween(Button, {BackgroundColor3 = Theme.Accent}, 0.2)
    end)
    
    Button.MouseButton1Click:Connect(function()
        if debounce then return end
        debounce = true
        callback()
        Tween(Button, {BackgroundColor3 = Color3.fromRGB(80, 160, 240)}, 0.1)
        wait(0.1)
        Tween(Button, {BackgroundColor3 = Theme.Accent}, 0.1)
        debounce = false
    end)
    
    return Button
end

-- Toggle Element
function EliteHub:CreateToggle(section, config)
    local togName = config.Name or "Toggle"
    local default = config.Default or false
    local callback = config.Callback or function(state) end
    
    local ToggleFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = section.ContentFrame
    })
    
    CreateInstance("TextLabel", {
        Text = togName,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 1, 0),
        Parent = ToggleFrame,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local ToggleBtn = CreateInstance("Frame", {
        Size = UDim2.new(0, 45, 0, 24),
        Position = UDim2.new(1, -45, 0.5, -12),
        BackgroundColor3 = default and Theme.Success or Theme.Tertiary,
        Parent = ToggleFrame,
        BorderSizePixel = 0
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 12), Parent = ToggleBtn})
    
    local ToggleCircle = CreateInstance("Frame", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(default and 0.5 or 0, default and 2 or 2, 0.5, -10),
        BackgroundColor3 = Theme.Text,
        Parent = ToggleBtn,
        BorderSizePixel = 0
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = ToggleCircle})
    
    local state = default
    
    local function UpdateToggle()
        Tween(ToggleCircle, {Position = UDim2.new(state and 0.5 or 0, state and 2 or 2, 0.5, -10)}, 0.2)
        Tween(ToggleBtn, {BackgroundColor3 = state and Theme.Success or Theme.Tertiary}, 0.2)
        callback(state)
    end
    
    ToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            UpdateToggle()
        end
    end)
    
    return {Frame = ToggleFrame, Set = function(newState) state = newState; UpdateToggle() end, Get = function() return state end}
end

-- Slider Element
function EliteHub:CreateSlider(section, config)
    local sliderName = config.Name or "Slider"
    local min = config.Min or 0
    local max = config.Max or 100
    local default = config.Default or min
    local increment = config.Increment or 1
    local callback = config.Callback or function(value) end
    
    local SliderFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Parent = section.ContentFrame
    })
    
    CreateInstance("TextLabel", {
        Text = sliderName .. ": " .. tostring(default),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Parent = SliderFrame,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local ValueLabel = SliderFrame:FindFirstChild("TextLabel")
    
    local SliderBar = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundColor3 = Theme.Tertiary,
        Parent = SliderFrame,
        BorderSizePixel = 0
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3), Parent = SliderBar})
    
    local SliderFill = CreateInstance("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        Parent = SliderBar,
        BorderSizePixel = 0
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3), Parent = SliderFill})
    
    local value = default
    local dragging = false
    
    local function UpdateSlider(pos)
        local percent = math.clamp((pos - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        value = math.round((min + (max - min) * percent) / increment) * increment
        Tween(SliderFill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.05)
        ValueLabel.Text = sliderName .. ": " .. tostring(value)
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
    
    return {Frame = SliderFrame, Set = function(newVal) UpdateSlider(SliderBar.AbsolutePosition.X + (newVal - min) / (max - min) * SliderBar.AbsoluteSize.X) end, Get = function() return value end}
end

-- Keybind Element
function EliteHub:CreateKeybind(section, config)
    local keyName = config.Name or "Keybind"
    local default = config.Default or Enum.KeyCode.F
    local callback = config.Callback or function() end
    
    local KeyFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = section.ContentFrame
    })
    
    CreateInstance("TextLabel", {
        Text = keyName,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 1, 0),
        Parent = KeyFrame,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local KeyBtn = CreateInstance("TextButton", {
        Text = default.Name,
        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        TextColor3 = Theme.Primary,
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(0, 50, 1, 0),
        Position = UDim2.new(1, -50, 0, 0),
        Parent = KeyFrame,
        BorderSizePixel = 0
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = KeyBtn})
    
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
    
    return {Frame = KeyFrame, Set = function(newKey) key = newKey; KeyBtn.Text = newKey.Name end, Get = function() return key end}
end

-- Dropdown Element
function EliteHub:CreateDropdown(section, config)
    local dropName = config.Name or "Dropdown"
    local options = config.Options or {"Option 1", "Option 2"}
    local default = config.Default or options[1]
    local callback = config.Callback or function(selected) end
    
    local DropFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Parent = section.ContentFrame
    })
    
    local DropBtn = CreateInstance("TextButton", {
        Text = default,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = Theme.Primary,
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 0, 36),
        Parent = DropFrame,
        BorderSizePixel = 0,
        AutoButtonColor = false
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = DropBtn})
    CreateInstance("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Parent = DropBtn
    })
    
    -- Label for dropdown
    local Label = CreateInstance("TextLabel", {
        Text = dropName .. ":",
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = Theme.TextDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 80, 0, 36),
        Parent = DropFrame,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    DropBtn.Position = UDim2.new(0, 85, 0, 0)
    DropBtn.Size = UDim2.new(1, -85, 0, 36)
    
    local DropList = CreateInstance("ScrollingFrame", {
        Size = UDim2.new(1, -85, 0, math.min(#options * 28, 150)),
        Position = UDim2.new(0, 85, 0, 40),
        BackgroundColor3 = Theme.Secondary,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
        Parent = DropFrame,
        BorderSizePixel = 0,
        ZIndex = 1000
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = DropList})
    CreateInstance("UIStroke", {Color = Theme.Border, Thickness = 1, Parent = DropList})
    
    local DropLayout = CreateInstance("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = DropList})
    CreateInstance("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = DropList})
    
    local selected = default
    local open = false
    
    local function ToggleDrop()
        open = not open
        DropList.Visible = open
        if open then
            Tween(DropBtn, {BackgroundColor3 = Theme.Tertiary}, 0.2)
        else
            Tween(DropBtn, {BackgroundColor3 = Theme.Secondary}, 0.2)
        end
    end
    
    DropBtn.MouseButton1Click:Connect(ToggleDrop)
    
    for _, opt in ipairs(options) do
        local OptBtn = CreateInstance("TextButton", {
            Text = opt,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = Theme.Text,
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.7,
            Size = UDim2.new(1, 0, 0, 26),
            BorderSizePixel = 0,
            Parent = DropList,
            AutoButtonColor = false
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = OptBtn})
        
        OptBtn.MouseEnter:Connect(function()
            Tween(OptBtn, {BackgroundTransparency = 0.3, BackgroundColor3 = Theme.Accent}, 0.15)
        end)
        OptBtn.MouseLeave:Connect(function()
            Tween(OptBtn, {BackgroundTransparency = 0.7, BackgroundColor3 = Color3.fromRGB(0, 0, 0)}, 0.15)
        end)
        
        OptBtn.MouseButton1Click:Connect(function()
            selected = opt
            DropBtn.Text = opt
            callback(opt)
            ToggleDrop()
        end)
    end
    
    DropLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        DropList.CanvasSize = UDim2.new(0, 0, 0, DropLayout.AbsoluteContentSize.Y + 8)
    end)
    
    DropFrame.Size = UDim2.new(1, 0, 0, open and (36 + DropList.Size.Y.Offset + 4) or 36)
    
    return {Frame = DropFrame, Set = function(newOpt) selected = newOpt; DropBtn.Text = newOpt end, Get = function() return selected end}
end

-- Textbox Element
function EliteHub:CreateTextbox(section, config)
    local textName = config.Name or "Textbox"
    local placeholder = config.Placeholder or "Enter text..."
    local callback = config.Callback or function(text) end
    
    local TextFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Parent = section.ContentFrame
    })
    
    CreateInstance("TextLabel", {
        Text = textName .. ":",
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = Theme.TextDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 80, 0, 36),
        Parent = TextFrame,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local TextBox = CreateInstance("TextBox", {
        PlaceholderText = placeholder,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.TextMuted,
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, -85, 0, 36),
        Position = UDim2.new(0, 85, 0, 0),
        Parent = TextFrame,
        BorderSizePixel = 0
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = TextBox})
    CreateInstance("UIStroke", {Color = Theme.Border, Thickness = 1, Parent = TextBox})
    CreateInstance("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = TextBox})
    
    TextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            callback(TextBox.Text)
        end
    end)
    
    return {Frame = TextFrame, Set = function(newText) TextBox.Text = newText end, Get = function() return TextBox.Text end}
end

-- Color Picker Element
function EliteHub:CreateColorPicker(section, config)
    local colorName = config.Name or "Color"
    local default = config.Default or Color3.fromRGB(100, 180, 255)
    local callback = config.Callback or function(color) end
    
    local ColorFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = section.ContentFrame
    })
    
    CreateInstance("TextLabel", {
        Text = colorName,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 1, 0),
        Parent = ColorFrame,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local ColorBtn = CreateInstance("Frame", {
        Size = UDim2.new(0, 45, 0, 24),
        Position = UDim2.new(1, -45, 0.5, -12),
        BackgroundColor3 = default,
        Parent = ColorFrame,
        BorderSizePixel = 0
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = ColorBtn})
    CreateInstance("UIStroke", {Color = Theme.Border, Thickness = 1, Parent = ColorBtn})
    
    ColorBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local randomColor = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
            Tween(ColorBtn, {BackgroundColor3 = randomColor}, 0.2)
            callback(randomColor)
        end
    end)
    
    return {Frame = ColorFrame, Set = function(newColor) Tween(ColorBtn, {BackgroundColor3 = newColor}, 0.2) end, Get = function() return ColorBtn.BackgroundColor3 end}
end

-- Destroy UI
function EliteHub:Destroy()
    if self.ScreenGui then
        Tween(self.Window, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        wait(0.3)
        self.ScreenGui:Destroy()
    end
end

return EliteHub
