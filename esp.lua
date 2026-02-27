-- Modern ESP (name/health/distance + tracers + boxes + head dot)
-- Inspired by Exunys AirHub WallHack but simplified & optimized 2026
-- Usage: paste into executor → toggle with getgenv().ESP.Enabled = true

getgenv().ESP = {
    Enabled      = false,
    TeamCheck    = true,
    AliveCheck   = true,
    
    -- Visual toggles
    ShowName     = true,
    ShowHealth   = true,
    ShowDistance = true,
    
    Tracers      = true,
    TracerType   = "Bottom", -- "Bottom", "Center", "Mouse"
    TracerColor  = Color3.fromRGB(255, 100, 100),
    TracerThick  = 1.5,
    TracerTrans  = 0.7,
    
    Box2D        = true,          -- simple 2D box
    BoxColor     = Color3.fromRGB(255, 255, 100),
    BoxThick     = 1.5,
    BoxFilled    = false,
    
    HeadDot      = true,
    HeadDotColor = Color3.fromRGB(255, 50, 50),
    HeadDotSize  = 6,
    
    TextSize     = 13,
    TextColor    = Color3.fromRGB(255, 255, 255),
    TextOutline  = true,
    TextOutlineColor = Color3.fromRGB(0,0,0),
}

-- Services & shortcuts
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInput     = game:GetService("UserInputService")
local LocalPlayer   = Players.LocalPlayer
local Camera        = workspace.CurrentCamera

local drawings = {}
local connections = {}

-- Cleanup function
local function cleanup()
    for _, conn in pairs(connections) do
        pcall(conn.Disconnect, conn)
    end
    for _, obj in pairs(drawings) do
        pcall(obj.Remove, obj)
    end
    drawings = {}
    connections = {}
end

-- Create drawing objects for a player
local function createESP(player)
    if player == LocalPlayer then return end
    
    local esp = {
        Name     = Drawing.new("Text"),
        Tracer   = Drawing.new("Line"),
        Box      = Drawing.new("Square"),
        HeadDot  = Drawing.new("Circle"),
    }
    
    esp.Name.Visible      = false
    esp.Name.Center       = true
    esp.Name.Outline      = ESP.TextOutline
    esp.Name.OutlineColor = ESP.TextOutlineColor
    esp.Name.Color        = ESP.TextColor
    esp.Name.Size         = ESP.TextSize
    esp.Name.Font         = Drawing.Fonts.UI
    
    esp.Tracer.Visible    = false
    esp.Tracer.Color      = ESP.TracerColor
    esp.Tracer.Thickness  = ESP.TracerThick
    esp.Tracer.Transparency = ESP.TracerTrans
    
    esp.Box.Visible       = false
    esp.Box.Color         = ESP.BoxColor
    esp.Box.Thickness     = ESP.BoxThick
    esp.Box.Filled        = ESP.BoxFilled
    
    esp.HeadDot.Visible   = false
    esp.HeadDot.Color     = ESP.HeadDotColor
    esp.HeadDot.Radius    = ESP.HeadDotSize
    esp.HeadDot.NumSides  = 32
    esp.HeadDot.Filled    = true
    
    table.insert(drawings, esp.Name)
    table.insert(drawings, esp.Tracer)
    table.insert(drawings, esp.Box)
    table.insert(drawings, esp.HeadDot)
    
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not ESP.Enabled or not player.Character then
            esp.Name.Visible = false
            esp.Tracer.Visible = false
            esp.Box.Visible = false
            esp.HeadDot.Visible = false
            return
        end
        
        local char = player.Character
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local hum   = char:FindFirstChildOfClass("Humanoid")
        
        if not root or not head or not hum then
            esp.Name.Visible = false
            esp.Tracer.Visible = false
            esp.Box.Visible = false
            esp.HeadDot.Visible = false
            return
        end
        
        if ESP.AliveCheck and hum.Health <= 0 then
            esp.Name.Visible = false
            esp.Tracer.Visible = false
            esp.Box.Visible = false
            esp.HeadDot.Visible = false
            return
        end
        
        if ESP.TeamCheck and player.TeamColor == LocalPlayer.TeamColor then
            esp.Name.Visible = false
            esp.Tracer.Visible = false
            esp.Box.Visible = false
            esp.HeadDot.Visible = false
            return
        end
        
        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            esp.Name.Visible = false
            esp.Tracer.Visible = false
            esp.Box.Visible = false
            esp.HeadDot.Visible = false
            return
        end
        
        -- Name + Health + Distance
        local text = ""
        if ESP.ShowName then
            text = player.DisplayName .. " (" .. player.Name .. ")"
        end
        if ESP.ShowHealth then
            text = text .. " [" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. "]"
        end
        if ESP.ShowDistance then
            local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) and 
                         (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude or 0
            text = text .. " [" .. math.floor(dist) .. " studs]"
        end
        
        esp.Name.Text = text
        esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - 40)
        esp.Name.Visible = true
        
        -- Head dot
        if ESP.HeadDot then
            local headPos = Camera:WorldToViewportPoint(head.Position)
            esp.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
            esp.HeadDot.Visible = headPos.Z > 0
        end
        
        -- Tracer
        if ESP.Tracers then
            local from
            if ESP.TracerType == "Bottom" then
                from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            elseif ESP.TracerType == "Center" then
                from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            else -- Mouse
                from = UserInputService:GetMouseLocation()
            end
            
            esp.Tracer.From = from
            esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            esp.Tracer.Visible = true
        else
            esp.Tracer.Visible = false
        end
        
        -- 2D Box
        if ESP.Box2D then
            local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 3, 0))
            local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            
            local width = math.abs(top.X - bottom.X) * 2.5
            local height = math.abs(top.Y - bottom.Y) * 1.2
            
            esp.Box.Size = Vector2.new(width, height)
            esp.Box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
            esp.Box.Visible = true
        else
            esp.Box.Visible = false
        end
    end)
    
    table.insert(connections, conn)
end

-- Watch players
local function onPlayerAdded(player)
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            if ESP.Enabled then
                task.spawn(function()
                    task.wait(0.3)
                    createESP(player)
                end)
            end
        end)
        
        if player.Character then
            task.spawn(function()
                task.wait(0.3)
                createESP(player)
            end)
        end
    end
end

-- Main loop
local function mainLoop()
    cleanup() -- clear old stuff
    
    if not ESP.Enabled then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            task.spawn(function()
                task.wait(0.1)
                createESP(player)
            end)
        end
    end
    
    -- Watch new players
    table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))
    
    -- Periodic refresh (in case characters respawn weirdly)
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if not ESP.Enabled then return end
        -- Optional: you can add extra logic here if needed
    end))
end

-- Toggle function (call this to enable/disable)
getgenv().ToggleESP = function(state)
    ESP.Enabled = state
    if state then
        mainLoop()
        print("[ESP] Enabled")
    else
        cleanup()
        print("[ESP] Disabled")
    end
end

-- Initial setup
Players.PlayerRemoving:Connect(function(player)
    -- cleanup drawings for leaving player (optional)
end)

print("[ESP] Loaded | Use getgenv().ToggleESP(true/false) to toggle")

-- Optional: auto enable on load (comment out if unwanted)
-- getgenv().ToggleESP(true)
