--[[ 
    Wall Hack / ESP Module [AirHub] - PC + Controller Compatible
    Original by Exunys (CC0) - Enhanced for Gamepad fallback (2026)
    https://github.com/Exunys
]]

-- Cache
local select, next, pcall, getgenv, mathfloor, mathabs, mathcos, mathsin, mathrad = 
    select, next, pcall, getgenv, math.floor, math.abs, math.cos, math.sin, math.rad

local Vector2new, Vector3new, Vector3zero, CFramenew, Drawingnew, Color3fromRGB = 
    Vector2.new, Vector3.new, Vector3.zero, CFrame.new, Drawing.new, Color3.fromRGB

-- Services
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- Early exit if already loaded
if not getgenv().AirHub or getgenv().AirHub.WallHack then return end

getgenv().AirHub.WallHack = {
    Settings = {
        Enabled    = false,
        TeamCheck  = false,
        AliveCheck = true,
    },

    Visuals = {
        ChamsSettings = {
            Enabled      = false,
            Color        = Color3fromRGB(255, 180, 100),
            Transparency = 0.25,
            Thickness    = 1,
            Filled       = true,
            EntireBody   = false,
        },
        ESPSettings = {
            Enabled          = true,
            TextColor        = Color3fromRGB(255, 255, 255),
            TextSize         = 13,
            Outline          = true,
            OutlineColor     = Color3fromRGB(0, 0, 0),
            TextTransparency = 0.65,
            TextFont         = Drawing.Fonts.UI,
            Offset           = 18,
            DisplayDistance  = true,
            DisplayHealth    = true,
            DisplayName      = true,
        },
        TracersSettings = {
            Enabled      = true,
            Type         = 1, -- 1=Bottom, 2=Center, 3=Mouse (fallback to center on controller)
            Transparency = 0.65,
            Thickness    = 1.4,
            Color        = Color3fromRGB(220, 220, 255),
        },
        BoxSettings = {
            Enabled      = true,
            Type         = 1, -- 1=3D corners, 2=2D box
            Color        = Color3fromRGB(255, 255, 255),
            Transparency = 0.7,
            Thickness    = 1.2,
            Filled       = false,
            Increase     = 1.05,
        },
        HeadDotSettings = {
            Enabled      = true,
            Color        = Color3fromRGB(255, 80, 100),
            Transparency = 0.6,
            Thickness    = 1,
            Filled       = true,
            Sides        = 24,
        },
        HealthBarSettings = {
            Enabled      = true,
            Transparency = 0.75,
            Size         = 3,
            Offset       = 6,
            OutlineColor = Color3fromRGB(20, 20, 20),
            Blue         = 60,
            Type         = 3, -- 1=Top, 2=Bottom, 3=Left, 4=Right
        },
    },

    Crosshair = {
        Settings = {
            Enabled              = false,
            Type                 = 2, -- 1=Mouse (fallback center on controller), 2=Screen Center
            Size                 = 14,
            Thickness            = 1.2,
            Color                = Color3fromRGB(0, 255, 120),
            Transparency         = 0.9,
            GapSize              = 6,
            Rotation             = 0,
            CenterDot            = true,
            CenterDotColor       = Color3fromRGB(255, 255, 255),
            CenterDotSize        = 2,
            CenterDotTransparency = 1,
            CenterDotFilled      = true,
        },
        Parts = {
            LeftLine   = Drawingnew("Line"),
            RightLine  = Drawingnew("Line"),
            TopLine    = Drawingnew("Line"),
            BottomLine = Drawingnew("Line"),
            CenterDot  = Drawingnew("Circle"),
        }
    },

    WrappedPlayers = {},
}

local Environment = getgenv().AirHub.WallHack

-- Helper: Controller detection
local function IsControllerMode()
    return UserInputService.GamepadEnabled
end

-- Helper: Safe cursor position (fallback for controller)
local function GetCursorPosition()
    if not IsControllerMode() then
        local success, pos = pcall(UserInputService.GetMouseLocation, UserInputService)
        if success then return pos end
    end
    -- Fallback to screen center on controller / error
    return Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local WorldToViewportPoint = function(...) 
    return Camera:WorldToViewportPoint(...) 
end

-- Get player data table
local function GetPlayerTable(player)
    for _, data in next, Environment.WrappedPlayers do
        if data.Name == player.Name then return data end
    end
end

-- Assign rig type (R6/R15)
local function AssignRigType(player)
    local data = GetPlayerTable(player)
    if not player.Character then return end

    if player.Character:FindFirstChild("Torso") then
        data.RigType = "R6"
    elseif player.Character:FindFirstChild("LowerTorso") then
        data.RigType = "R15"
    end
end

-- Alive / team checks
local function InitChecks(player)
    local data = GetPlayerTable(player)
    data.Connections = data.Connections or {}

    data.Connections.UpdateChecks = RunService.RenderStepped:Connect(function()
        if not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") then
            data.Checks = {Alive = false, Team = false}
            return
        end

        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        data.Checks.Alive = Environment.Settings.AliveCheck and hum.Health > 0 or true
        data.Checks.Team  = Environment.Settings.TeamCheck and player.TeamColor ~= LocalPlayer.TeamColor or true
    end)
end

-- Chams update (quad drawing - simplified a bit)
local function UpdateCham(part, cham)
    if not part or not Environment.Visuals.ChamsSettings.Enabled then
        for i = 1, 6 do cham["Quad"..i].Visible = false end
        return
    end

    local cf, size = part.CFrame, part.Size / 2
    local visible = select(2, WorldToViewportPoint(cf.Position))

    if not visible then
        for i = 1, 6 do cham["Quad"..i].Visible = false end
        return
    end

    local settings = Environment.Visuals.ChamsSettings
    local color, trans, thick, filled = settings.Color, settings.Transparency, settings.Thickness, settings.Filled

    -- Define 8 corner points (for all 6 faces)
    local corners = {
        cf * CFramenew( size.X,  size.Y,  size.Z),
        cf * CFramenew(-size.X,  size.Y,  size.Z),
        cf * CFramenew( size.X, -size.Y,  size.Z),
        cf * CFramenew(-size.X, -size.Y,  size.Z),
        cf * CFramenew( size.X,  size.Y, -size.Z),
        cf * CFramenew(-size.X,  size.Y, -size.Z),
        cf * CFramenew( size.X, -size.Y, -size.Z),
        cf * CFramenew(-size.X, -size.Y, -size.Z),
    }

    local screen = {}
    for i, c in ipairs(corners) do
        local pos, onScreen = WorldToViewportPoint(c.Position)
        screen[i] = onScreen and Vector2new(pos.X, pos.Y) or nil
    end

    -- Simple front/back/top/bottom/right/left approximation (you can expand)
    local function setQuad(q, a,b,c,d)
        if screen[a] and screen[b] and screen[c] and screen[d] then
            q.PointA = screen[a]
            q.PointB = screen[b]
            q.PointC = screen[c]
            q.PointD = screen[d]
            q.Color       = color
            q.Transparency = trans
            q.Thickness   = thick
            q.Filled      = filled
            q.Visible     = true
        else
            q.Visible = false
        end
    end

    setQuad(cham.Quad1, 1,2,4,3) -- front
    setQuad(cham.Quad2, 5,6,8,7) -- back
    setQuad(cham.Quad3, 1,2,6,5) -- top
    setQuad(cham.Quad4, 3,4,8,7) -- bottom
    setQuad(cham.Quad5, 1,3,7,5) -- right
    setQuad(cham.Quad6, 2,4,8,6) -- left
end

-- Visuals table (only showing modified/important parts - addChams, addTracer, addCrosshair updated)
local Visuals = {
    AddChams = function(player)
        local data = GetPlayerTable(player)
        local char = player.Character or player.CharacterAdded:Wait()

        -- Rig detection
        AssignRigType(player)

        -- Create quads per body part
        data.Chams = {}
        local parts = (data.RigType == "R15" and not Environment.Visuals.ChamsSettings.EntireBody) 
            and {"Head", "UpperTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg"}
            or char:GetChildren()

        for _, part in ipairs(parts) do
            if part:IsA("BasePart") or part:IsA("MeshPart") then
                data.Chams[part.Name] = {}
                for i = 1, 6 do
                    data.Chams[part.Name]["Quad"..i] = Drawingnew("Quad")
                end
            end
        end

        data.Connections.Chams = RunService.RenderStepped:Connect(function()
            for name, cham in pairs(data.Chams) do
                local part = char:FindFirstChild(name)
                if part then
                    pcall(UpdateCham, part, cham)
                end
            end
        end)
    end,

    -- Tracer with controller fallback
    AddTracer = function(player)
        local data = GetPlayerTable(player)
        data.Tracer = Drawingnew("Line")

        data.Connections.Tracer = RunService.RenderStepped:Connect(function()
            if not player.Character or not Environment.Settings.Enabled then
                data.Tracer.Visible = false
                return
            end

            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then 
                data.Tracer.Visible = false
                return 
            end

            local pos, onScreen = WorldToViewportPoint(hrp.Position)
            if not onScreen then
                data.Tracer.Visible = false
                return
            end

            local bottom = WorldToViewportPoint(hrp.CFrame * CFramenew(0, -3, 0).Position)
            local fromPos

            local tType = Environment.Visuals.TracersSettings.Type
            if tType == 3 and IsControllerMode() then
                tType = 2 -- fallback
            end

            if tType == 1 then
                fromPos = Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            elseif tType == 2 then
                fromPos = Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            else
                fromPos = GetCursorPosition()
            end

            data.Tracer.Visible = Environment.Visuals.TracersSettings.Enabled and data.Checks.Alive and data.Checks.Team
            if data.Tracer.Visible then
                data.Tracer.From = fromPos
                data.Tracer.To   = Vector2new(bottom.X, bottom.Y)
                data.Tracer.Color = Environment.Visuals.TracersSettings.Color
                data.Tracer.Thickness = Environment.Visuals.TracersSettings.Thickness
                data.Tracer.Transparency = Environment.Visuals.TracersSettings.Transparency
            end
        end)
    end,

    -- Crosshair with controller fallback
    AddCrosshair = function()
        local cursorConn = RunService.RenderStepped:Connect(function()
            if not Environment.Crosshair.Settings.Enabled then return end

            local cType = Environment.Crosshair.Settings.Type
            if cType == 1 and IsControllerMode() then
                cType = 2
            end

            local x, y
            if cType == 1 then
                local pos = GetCursorPosition()
                x, y = pos.X, pos.Y
            else
                x = Camera.ViewportSize.X / 2
                y = Camera.ViewportSize.Y / 2
            end

            local s = Environment.Crosshair.Settings
            local p = Environment.Crosshair.Parts

            p.LeftLine.Visible   = s.Enabled
            p.LeftLine.From      = Vector2new(x - mathcos(mathrad(s.Rotation)) * s.GapSize, y - mathsin(mathrad(s.Rotation)) * s.GapSize)
            p.LeftLine.To        = Vector2new(x - mathcos(mathrad(s.Rotation)) * (s.Size + s.GapSize), y - mathsin(mathrad(s.Rotation)) * (s.Size + s.GapSize))
            p.LeftLine.Color     = s.Color
            p.LeftLine.Thickness = s.Thickness
            p.LeftLine.Transparency = s.Transparency

            -- Repeat pattern for RightLine, TopLine, BottomLine (copy-paste with sign changes)

            p.CenterDot.Visible      = s.Enabled and s.CenterDot
            p.CenterDot.Position     = Vector2new(x, y)
            p.CenterDot.Radius       = s.CenterDotSize
            p.CenterDot.Color        = s.CenterDotColor
            p.CenterDot.Transparency = s.CenterDotTransparency
            p.CenterDot.Filled       = s.CenterDotFilled
            p.CenterDot.Thickness    = s.CenterDotThickness
        end)
    end,

    -- AddESP, AddBox, AddHeadDot, AddHealthBar remain similar — just add pcall around drawing
    -- (you can copy from original and wrap drawing lines in pcall if needed)
}

-- Wrap / Unwrap / Load functions (mostly unchanged, just safer)
local function Wrap(player)
    if player == LocalPlayer or GetPlayerTable(player) then return end

    local data = {
        Name = player.Name,
        Checks = {Alive = true, Team = true},
        Connections = {},
        ESP = nil, Tracer = nil, HeadDot = nil,
        HealthBar = {Main = nil, Outline = nil},
        Box = {Square = nil, Lines = {}},
        Chams = {}
    }

    Environment.WrappedPlayers[#Environment.WrappedPlayers + 1] = data

    AssignRigType(player)
    InitChecks(player)
    Visuals.AddChams(player)
    Visuals.AddESP(player)
    Visuals.AddTracer(player)
    Visuals.AddBox(player)
    Visuals.AddHeadDot(player)
    Visuals.AddHealthBar(player)
end

local function UnWrap(player)
    for i, data in ipairs(Environment.WrappedPlayers) do
        if data.Name == player.Name then
            for _, conn in pairs(data.Connections) do
                pcall(conn.Disconnect, conn)
            end
            pcall(function()
                data.ESP:Remove()
                data.Tracer:Remove()
                data.HeadDot:Remove()
                data.HealthBar.Main:Remove()
                data.HealthBar.Outline:Remove()
            end)
            -- Clean boxes and chams...
            Environment.WrappedPlayers[i] = nil
            break
        end
    end
end

local function Load()
    Visuals.AddCrosshair()

    Players.PlayerAdded:Connect(Wrap)
    Players.PlayerRemoving:Connect(UnWrap)

    -- Periodic re-wrap (safer interval)
    spawn(function()
        while true do
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then Wrap(plr) end
            end
            task.wait(25)
        end
    end)
end

-- Public API
Environment.Functions = {
    Exit = function()
        -- cleanup all connections, drawings, etc.
        for _, conn in pairs(ServiceConnections) do pcall(conn.Disconnect, conn) end
        for _, part in pairs(Environment.Crosshair.Parts) do pcall(part.Remove, part) end
        for _, plr in ipairs(Players:GetPlayers()) do UnWrap(plr) end
        getgenv().AirHub.WallHack = nil
    end,
    Restart = function()
        for _, plr in ipairs(Players:GetPlayers()) do UnWrap(plr) end
        Load()
    end,
}

Load()

print("[AirHub WallHack] Loaded - Controller + PC compatible")
