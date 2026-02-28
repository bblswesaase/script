--[[ 
    Universal Aimbot Module - PC + Controller Compatible
    Original by Exunys (CC0) - Soft Aim Assist Edition for Gamepad (2026)
    https://github.com/Exunys
]]

-- Cache
local game, workspace = game, workspace
local pcall, getgenv, next, tick = pcall, getgenv, next, tick
local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV
local Drawingnew, TweenInfonew = Drawing.new, TweenInfo.new
local mathclamp, mathacos, mathdeg = math.clamp, math.acos, math.deg

-- Services
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- Environment
if getgenv().ExunysDeveloperAimbot and getgenv().ExunysDeveloperAimbot.Exit then
    getgenv().ExunysDeveloperAimbot:Exit()
end

getgenv().ExunysDeveloperAimbot = {
    DeveloperSettings = {
        UpdateMode      = "RenderStepped",
        TeamCheckOption = "TeamColor",
        RainbowSpeed    = 1.8,
    },

    Settings = {
        Enabled              = false,
        TeamCheck            = false,
        AliveCheck           = true,
        WallCheck            = false,
        OffsetToMoveDirection = false,
        OffsetIncrement      = 12,

        -- Controller / Gamepad settings
        AimAssistStrength    = 0.16,    -- 0.05 = very subtle, 0.35 = aggressive
        AimAssistDeadzone    = 14,      -- degrees - only assist if target is outside this cone
        SmoothingFactor      = 0.38,    -- higher = faster camera response (0.2–0.6 best)
        LockPart             = "Head",
        TriggerKey           = Enum.UserInputType.MouseButton2,  -- can be changed to gamepad button
        Toggle               = false,
    },

    FOVSettings = {
        Enabled          = true,
        Visible          = true,
        Radius           = 140,
        NumSides         = 60,
        Thickness        = 1.4,
        Transparency     = 0.95,
        Filled           = false,
        RainbowColor     = false,
        RainbowOutlineColor = false,
        Color            = Color3fromRGB(220, 220, 255),
        OutlineColor     = Color3fromRGB(20, 20, 40),
        LockedColor      = Color3fromRGB(255, 120, 140),
    },

    Blacklisted      = {},
    Locked           = nil,
    FOVCircle        = Drawingnew("Circle"),
    FOVCircleOutline = Drawingnew("Circle"),
    Connections      = {},
}

local Environment = getgenv().ExunysDeveloperAimbot

Environment.FOVCircle.Visible       = false
Environment.FOVCircleOutline.Visible = false

-- Helpers
local function IsController()
    return UserInputService.GamepadEnabled
end

local function GetCursorPos()
    if not IsController() then
        return UserInputService:GetMouseLocation()
    end
    -- Fallback for controller: screen center
    return Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function GetRainbowColor()
    local t = tick() % Environment.DeveloperSettings.RainbowSpeed / Environment.DeveloperSettings.RainbowSpeed
    return Color3fromHSV(t, 1, 1)
end

local function ConvertVector(v)
    return Vector2new(v.X, v.Y)
end

local function CancelLock()
    Environment.Locked = nil
    Environment.FOVCircle.Color = Environment.FOVSettings.Color
end

local function GetClosestPlayer()
    if Environment.Locked then
        local char = Environment.Locked.Character
        if char then
            local part = char:FindFirstChild(Environment.Settings.LockPart)
            if part then
                local screenPos = Camera:WorldToViewportPoint(part.Position)
                local dist = (GetCursorPos() - ConvertVector(screenPos)).Magnitude
                if dist > Environment.FOVSettings.Radius * 1.4 then
                    CancelLock()
                end
            else
                CancelLock()
            end
        else
            CancelLock()
        end
        return
    end

    local required = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2500
    local mousePos = GetCursorPos()

    for _, player in Players:GetPlayers() do
        if player == LocalPlayer then continue end
        if table.find(Environment.Blacklisted, player.Name) then continue end

        local char = player.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or (Environment.Settings.AliveCheck and hum.Health <= 0) then continue end

        local part = char:FindFirstChild(Environment.Settings.LockPart)
        if not part then continue end

        if Environment.Settings.TeamCheck and player[Environment.DeveloperSettings.TeamCheckOption] == LocalPlayer[Environment.DeveloperSettings.TeamCheckOption] then
            continue
        end

        if Environment.Settings.WallCheck then
            local parts = Camera:GetPartsObscuringTarget({part.Position}, {LocalPlayer.Character, char})
            if #parts > 0 then continue end
        end

        local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local dist = (mousePos - ConvertVector(screen)).Magnitude
        if dist < required then
            required = dist
            Environment.Locked = player
        end
    end
end

-- Main logic
local function Load()
    ServiceConnections = Environment.Connections

    ServiceConnections.Render = RunService[Environment.DeveloperSettings.UpdateMode]:Connect(function()
        local s = Environment.Settings
        local f = Environment.FOVSettings

        -- Update FOV circle
        if f.Enabled and s.Enabled then
            local pos = GetCursorPos()
            Environment.FOVCircle.Position         = pos
            Environment.FOVCircle.Radius           = f.Radius
            Environment.FOVCircle.NumSides         = f.NumSides
            Environment.FOVCircle.Thickness        = f.Thickness
            Environment.FOVCircle.Transparency     = f.Transparency
            Environment.FOVCircle.Filled           = f.Filled
            Environment.FOVCircle.Visible          = f.Visible

            Environment.FOVCircleOutline.Position      = pos
            Environment.FOVCircleOutline.Radius        = f.Radius + f.Thickness + 2
            Environment.FOVCircleOutline.Thickness     = f.Thickness + 1.5
            Environment.FOVCircleOutline.Transparency  = f.Transparency * 0.7
            Environment.FOVCircleOutline.Visible       = f.Visible

            Environment.FOVCircle.Color = Environment.Locked and f.LockedColor or f.RainbowColor and GetRainbowColor() or f.Color
            Environment.FOVCircleOutline.Color = f.RainbowOutlineColor and GetRainbowColor() or f.OutlineColor
        else
            Environment.FOVCircle.Visible       = false
            Environment.FOVCircleOutline.Visible = false
        end

        if not s.Enabled then return end

        GetClosestPlayer()

        if Environment.Locked then
            local char = Environment.Locked.Character
            if not char then CancelLock() return end

            local part = char:FindFirstChild(s.LockPart)
            if not part then CancelLock() return end

            local offset = s.OffsetToMoveDirection and (char.Humanoid.MoveDirection * (s.OffsetIncrement / 10)) or Vector3zero
            local targetPos = part.Position + offset

            local currentLook = Camera.CFrame.LookVector
            local toTarget    = (targetPos - Camera.CFrame.Position).Unit

            local angle = mathdeg(mathacos(currentLook:Dot(toTarget)))

            if angle > s.AimAssistDeadzone then
                local strength = mathclamp(s.AimAssistStrength, 0.01, 0.6)
                local assisted = currentLook:Lerp(toTarget, strength)

                local newCF = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + assisted * 200)
                Camera.CFrame = Camera.CFrame:Lerp(newCF, s.SmoothingFactor)
            end
        end
    end)

    -- Input handling (supports mouse + gamepad)
    ServiceConnections.InputBegan = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end

        local key = s.TriggerKey
        local isTrigger = (input.UserInputType == key) or (input.KeyCode == key)

        -- Gamepad support - example: Right Trigger or Right Bumper
        if IsController() and (input.UserInputType == Enum.UserInputType.Gamepad1) then
            if input.KeyCode == Enum.KeyCode.ButtonR2 or input.KeyCode == Enum.KeyCode.ButtonR1 then
                isTrigger = true
            end
        end

        if isTrigger then
            if s.Toggle then
                Running = not Running
                if not Running then CancelLock() end
            else
                Running = true
            end
        end
    end)

    ServiceConnections.InputEnded = UserInputService.InputEnded:Connect(function(input)
        local key = s.TriggerKey
        local isTrigger = (input.UserInputType == key) or (input.KeyCode == key)

        if IsController() and (input.UserInputType == Enum.UserInputType.Gamepad1) then
            if input.KeyCode == Enum.KeyCode.ButtonR2 or input.KeyCode == Enum.KeyCode.ButtonR1 then
                isTrigger = true
            end
        end

        if not s.Toggle and isTrigger then
            Running = false
            CancelLock()
        end
    end)

    -- Typing detection
    ServiceConnections.TypingStart = UserInputService.TextBoxFocused:Connect(function() Typing = true end)
    ServiceConnections.TypingEnd   = UserInputService.TextBoxFocusReleased:Connect(function() Typing = false end)
end

-- Public API
function Environment.Exit()
    for _, conn in pairs(ServiceConnections) do
        pcall(function() conn:Disconnect() end)
    end
    Environment.FOVCircle:Remove()
    Environment.FOVCircleOutline:Remove()
    getgenv().ExunysDeveloperAimbot = nil
end

function Environment.Restart()
    for _, conn in pairs(ServiceConnections) do
        pcall(function() conn:Disconnect() end)
    end
    Load()
end

function Environment.Load()
    Load()
end

Environment.Load()

print("[Exunys Aimbot] Loaded | PC + Controller support | Strength: " .. Environment.Settings.AimAssistStrength)
