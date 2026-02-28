--[[ 
    Universal Aimbot - Exunys base + Controller support (soft aim assist)
    Original © Exunys (CC0) - Fixed for gamepad 2026
]]

-- Cache & services (your original)
local game, workspace = game, workspace
local getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick = getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick
local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV, Drawingnew, TweenInfonew = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV, Drawing.new, TweenInfo.new
local mathclamp, mathacos, mathdeg = math.clamp, math.acos, math.deg

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Environment (your original + controller fields)
if ExunysDeveloperAimbot and ExunysDeveloperAimbot.Exit then ExunysDeveloperAimbot:Exit() end

getgenv().ExunysDeveloperAimbot = {
    DeveloperSettings = {
        UpdateMode = "RenderStepped",
        TeamCheckOption = "TeamColor",
        RainbowSpeed = 1.6,
    },

    Settings = {
        Enabled = false,
        TeamCheck = false,
        AliveCheck = true,
        WallCheck = false,
        OffsetToMoveDirection = false,
        OffsetIncrement = 12,

        -- Controller settings (these make it work on gamepad)
        AimAssistStrength = 0.14,    -- lower = more legit (0.06–0.22 best)
        AimAssistDeadzone = 15,      -- only assist if off-target by more than this angle
        SmoothingFactor   = 0.32,    -- higher = faster response

        LockPart = "Head",
        TriggerKey = Enum.UserInputType.MouseButton2,
        Toggle = false,
    },

    FOVSettings = {
        Enabled = true,
        Visible = true,
        Radius = 140,
        NumSides = 60,
        Thickness = 1.4,
        Transparency = 0.92,
        Filled = false,
        RainbowColor = false,
        Color = Color3.fromRGB(220, 220, 255),
        OutlineColor = Color3.fromRGB(30, 30, 50),
        LockedColor = Color3.fromRGB(255, 120, 140),
    },

    Blacklisted = {},
    Locked = nil,
    FOVCircle = Drawing.new("Circle"),
    FOVCircleOutline = Drawing.new("Circle"),
    Connections = {},
}

local Environment = getgenv().ExunysDeveloperAimbot

Environment.FOVCircle.Visible = false
Environment.FOVCircleOutline.Visible = false

-- Controller helpers
local function IsController() return UserInputService.GamepadEnabled end

local function GetCursorPos()
    if not IsController() then
        local ok, pos = pcall(function() return UserInputService:GetMouseLocation() end)
        if ok then return pos end
    end
    -- Fallback for controller: screen center
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function IsTriggerInput(input)
    local key = Environment.Settings.TriggerKey
    return (input.UserInputType == key) or (input.KeyCode == key) or
           (IsController() and input.UserInputType.Name:find("Gamepad") and
            (input.KeyCode == Enum.KeyCode.ButtonR2 or input.KeyCode == Enum.KeyCode.ButtonR1))
end

-- Core functions (mostly original, but GetClosestPlayer uses controller-safe cursor)
local function CancelLock()
    Environment.Locked = nil
    Environment.FOVCircle.Color = Environment.FOVSettings.Color
end

local function GetClosestPlayer()
    local Settings = Environment.Settings
    local LockPart = Settings.LockPart

    if not Environment.Locked then
        local required = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2000
        local cursor = GetCursorPos()

        for _, player in Players:GetPlayers() do
            if player == LocalPlayer then continue end
            if table.find(Environment.Blacklisted, player.Name) then continue end

            local char = player.Character
            if not char then continue end

            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or (Settings.AliveCheck and hum.Health <= 0) then continue end

            local part = char:FindFirstChild(LockPart)
            if not part then continue end

            if Settings.TeamCheck and player.TeamColor == LocalPlayer.TeamColor then continue end

            if Settings.WallCheck then
                local ignore = {LocalPlayer.Character, char}
                local obstructing = Camera:GetPartsObscuringTarget({part.Position}, ignore)
                if #obstructing > 0 then continue end
            end

            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if not onScreen then continue end

            local dist = (cursor - Vector2.new(pos.X, pos.Y)).Magnitude
            if dist < required then
                required = dist
                Environment.Locked = player
            end
        end
    else
        -- Check if lock still valid
        local char = Environment.Locked.Character
        if char and char:FindFirstChild(LockPart) then
            local pos = Camera:WorldToViewportPoint(char[LockPart].Position)
            local dist = (GetCursorPos() - Vector2.new(pos.X, pos.Y)).Magnitude
            if dist > Environment.FOVSettings.Radius * 1.4 then
                CancelLock()
            end
        else
            CancelLock()
        end
    end
end

-- Main loop (soft assist instead of hard snap)
local Load = function()
    Environment.Connections.Render = RunService.RenderStepped:Connect(function()
        local s = Environment.Settings
        local f = Environment.FOVSettings

        -- FOV circle
        if f.Enabled and s.Enabled then
            Environment.FOVCircle.Position = GetCursorPos()
            Environment.FOVCircle.Radius = f.Radius
            Environment.FOVCircle.NumSides = f.NumSides
            Environment.FOVCircle.Thickness = f.Thickness
            Environment.FOVCircle.Transparency = f.Transparency
            Environment.FOVCircle.Filled = f.Filled
            Environment.FOVCircle.Visible = f.Visible
            Environment.FOVCircle.Color = Environment.Locked and f.LockedColor or f.RainbowColor and Color3.fromHSV(tick() % 3 / 3, 1, 1) or f.Color
        else
            Environment.FOVCircle.Visible = false
        end

        if not Environment.Running or not s.Enabled then return end

        GetClosestPlayer()

        if Environment.Locked then
            local char = Environment.Locked.Character
            if not char then CancelLock() return end

            local part = char:FindFirstChild(s.LockPart)
            if not part then CancelLock() return end

            local targetPos = part.Position

            local currentLook = Camera.CFrame.LookVector
            local toTarget = (targetPos - Camera.CFrame.Position).Unit

            local angle = mathdeg(mathacos(currentLook:Dot(toTarget)))

            if angle > s.AimAssistDeadzone then
                local strength = mathclamp(s.AimAssistStrength, 0.01, 0.6)
                local assisted = currentLook:Lerp(toTarget, strength)

                local goal = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + assisted * 120)
                Camera.CFrame = Camera.CFrame:Lerp(goal, s.SmoothingFactor)
            end
        end
    end)

    -- Input (PC mouse + controller gamepad)
    Environment.Connections.InputBegan = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if IsTriggerInput(input) then
            if Environment.Settings.Toggle then
                Environment.Running = not Environment.Running
                if not Environment.Running then CancelLock() end
            else
                Environment.Running = true
            end
        end
    end)

    Environment.Connections.InputEnded = UserInputService.InputEnded:Connect(function(input)
        if IsTriggerInput(input) and not Environment.Settings.Toggle then
            Environment.Running = false
            CancelLock()
        end
    end)

    -- Typing
    Environment.Connections.TypingStart = UserInputService.TextBoxFocused:Connect(function() Typing = true end)
    Environment.Connections.TypingEnd = UserInputService.TextBoxFocusReleased:Connect(function() Typing = false end)
end

-- Public methods (your original)
function Environment.Exit(self)
    for _, conn in next, Environment.Connections do
        pcall(function() conn:Disconnect() end)
    end
    Environment.FOVCircle:Remove()
    getgenv().ExunysDeveloperAimbot = nil
end

function Environment.Restart()
    for _, conn in next, Environment.Connections do
        pcall(function() conn:Disconnect() end)
    end
    Load()
end

Environment.Load = Load
Load()

print("[Exunys Aimbot] Loaded - Controller support added (soft aim assist)")
