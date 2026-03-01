-- Universal Aimbot - Exunys Base + Super Smooth Controller & KBM Lock 2026
-- No jitter/shake on controller (L2/ADS), smooth snap for both inputs
-- https://github.com/Exunys (original base)

getgenv().ExunysDeveloperAimbot = getgenv().ExunysDeveloperAimbot or {}
local A = getgenv().ExunysDeveloperAimbot

-- ──────────────────────────────────────────────────────────────
-- SETTINGS (change these in your hub UI)
-- ──────────────────────────────────────────────────────────────
A.Settings = {
    Enabled = false,                -- Master toggle (set from hub)
    TeamCheck = true,
    AliveCheck = true,
    WallCheck = true,
    OffsetToMoveDirection = false,
    OffsetIncrement = 15,

    -- Aiming smoothness (main fix area)
    LockMode = 2,                   -- 2 = mousemoverel (best & smoothest for both KBM + controller)
    Sensitivity = 0,                -- CFrame only (ignore if LockMode=2)
    Sensitivity2 = 0.88,            -- Base mousemoverel speed (0.7–1.1 feels natural)
    SmoothingFactor = 0.26,         -- Main smoothness (0.20–0.35 = buttery, 0.40+ = faster snap)
    ControllerDeadzone = 0.11,      -- Ignore tiny stick drift (prevents shake/jitter)
    LockPart = "Head",

    -- Triggers (both inputs work at the same time)
    TriggerKey = Enum.UserInputType.MouseButton2,     -- Right click (KBM)
    TriggerKeyController = Enum.KeyCode.ButtonL2,     -- L2 (controller hold)
    Toggle = false                  -- false = hold to aim (recommended), true = toggle
}

A.FOVSettings = {
    Enabled = true,
    Visible = true,
    Radius = 150,
    NumSides = 60,
    Thickness = 1,
    Transparency = 1,
    Filled = false,
    RainbowColor = false,
    RainbowOutlineColor = false,
    Color = Color3.fromRGB(220, 220, 255),
    OutlineColor = Color3.fromRGB(0, 0, 0),
    LockedColor = Color3.fromRGB(255, 80, 80)
}

A.Blacklisted = {}

-- ──────────────────────────────────────────────────────────────
-- CACHE / SERVICES
-- ──────────────────────────────────────────────────────────────
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local mousemoverel = mousemoverel or UserInputService.MouseMove
local lastDelta = Vector2.new(0, 0)
local Running, LockedTarget, OriginalSens = false, nil, UserInputService.MouseDeltaSensitivity

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
local FOVOutline = Drawing.new("Circle")
FOVCircle.Visible = false
FOVOutline.Visible = false

-- ──────────────────────────────────────────────────────────────
-- CORE FUNCTIONS
-- ──────────────────────────────────────────────────────────────
local function CancelLock()
    LockedTarget = nil
    FOVCircle.Color = A.FOVSettings.Color
    UserInputService.MouseDeltaSensitivity = OriginalSens
end

local function GetClosest()
    local s = A.Settings
    local fov = A.FOVSettings.Enabled and A.FOVSettings.Radius or 9999
    local closest, dist = nil, fov

    for _, p in Players:GetPlayers() do
        if p == LocalPlayer then continue end
        local c = p.Character
        if not c then continue end

        local h = c:FindFirstChildOfClass("Humanoid")
        local part = c:FindFirstChild(s.LockPart)
        if not h or not part then continue end

        if s.TeamCheck and p.TeamColor == LocalPlayer.TeamColor then continue end
        if s.AliveCheck and h.Health <= 0 then continue end

        local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local mouse = UserInputService:GetMouseLocation()
        local d = (Vector2.new(screen.X, screen.Y) - mouse).Magnitude
        if d >= dist then continue end

        if s.WallCheck then
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {LocalPlayer.Character or {}, c}
            params.FilterType = Enum.RaycastFilterType.Exclude
            local result = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 5000, params)
            if result and not result.Instance:IsDescendantOf(c) then continue end
        end

        dist = d
        closest = p
    end

    LockedTarget = closest
    return closest
end

-- Main aiming loop
RunService.RenderStepped:Connect(function()
    if not A.Settings.Enabled or not Running then
        FOVCircle.Visible = false
        FOVOutline.Visible = false
        return
    end

    -- Update FOV circle
    local mouse = UserInputService:GetMouseLocation()
    FOVCircle.Position = mouse
    FOVCircle.Radius = A.FOVSettings.Radius
    FOVCircle.Color = A.FOVSettings.Color
    FOVCircle.Thickness = A.FOVSettings.Thickness
    FOVCircle.NumSides = A.FOVSettings.NumSides
    FOVCircle.Transparency = A.FOVSettings.Transparency
    FOVCircle.Filled = A.FOVSettings.Filled
    FOVCircle.Visible = A.FOVSettings.Visible and A.FOVSettings.Enabled

    FOVOutline.Position = mouse
    FOVOutline.Radius = FOVCircle.Radius + 1
    FOVOutline.Color = A.FOVSettings.OutlineColor
    FOVOutline.Thickness = FOVCircle.Thickness + 1
    FOVOutline.Visible = FOVCircle.Visible

    local target = GetClosest()

    if target then
        FOVCircle.Color = A.FOVSettings.LockedColor

        local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local targetPos = root.Position

        if A.Settings.LockMode == 2 then
            -- Super smooth mousemoverel - controller & KBM friendly
            local mousePos = UserInputService:GetMouseLocation()
            local screenPos = Camera:WorldToViewportPoint(targetPos)
            local delta = Vector2.new(screenPos.X - mousePos.X, screenPos.Y - mousePos.Y)

            -- Deadzone + strong exponential smoothing (eliminates shake)
            if delta.Magnitude > A.Settings.ControllerDeadzone * 100 then
                lastDelta = lastDelta:Lerp(delta, A.Settings.SmoothingFactor)
                local moveX = lastDelta.X * A.Settings.Sensitivity2
                local moveY = lastDelta.Y * A.Settings.Sensitivity2
                mousemoverel(moveX, moveY)
            end
        else
            -- CFrame fallback (smooth tween)
            local tweenInfo = TweenInfo.new(A.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            TweenService:Create(Camera, tweenInfo, {CFrame = CFrame.new(Camera.CFrame.Position, targetPos)}):Play()
            UserInputService.MouseDeltaSensitivity = 0
        end
    else
        CancelLock()
    end
end)

-- Input handling (KBM right-click + Controller L2)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    local s = A.Settings
    local trigger = false

    if input.UserInputType == s.TriggerKey or input.KeyCode == s.TriggerKey then
        trigger = true
    end

    if s.TriggerKeyController and (input.KeyCode == s.TriggerKeyController or input.UserInputType.Name:find("Gamepad")) then
        trigger = true
    end

    if trigger then
        if s.Toggle then
            Running = not Running
            if not Running then CancelLock() end
        else
            Running = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if gpe then return end

    local s = A.Settings
    local trigger = false

    if input.UserInputType == s.TriggerKey or input.KeyCode == s.TriggerKey then
        trigger = true
    end

    if s.TriggerKeyController and (input.KeyCode == s.TriggerKeyController or input.UserInputType.Name:find("Gamepad")) then
        trigger = true
    end

    if trigger and not s.Toggle then
        Running = false
        CancelLock()
    end
end)

-- Prevent typing from activating aim
UserInputService.TextBoxFocused:Connect(function() Typing = true end)
UserInputService.TextBoxFocusReleased:Connect(function() Typing = false end)

print("[Aimbot Loaded] Hold RMB or L2 to aim - super smooth lock-on (controller & KBM fixed)")

-- Public API (for hub reload/exit if needed)
function A.Exit()
    for _, conn in pairs(ServiceConnections or {}) do conn:Disconnect() end
    FOVCircle:Remove()
    FOVOutline:Remove()
    getgenv().ExunysDeveloperAimbot = nil
end

function A.Restart()
    A.Exit()
    -- Re-execute if needed
end
