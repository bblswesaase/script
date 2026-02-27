-- Tracers Only - Minimal & Clean (2025-2026)
-- No ESP text / boxes / head dots / chams — just lines to players

getgenv().TracersOnly = {
    Enabled       = false,
    TeamCheck     = true,           -- true = hide teammates
    AliveCheck    = true,           -- true = hide dead players
    
    TracerType    = "Bottom",       -- "Bottom", "Center", "Mouse"
    Color         = Color3.fromRGB(255, 80, 80),
    Thickness     = 1.5,
    Transparency  = 0.65,
    
    -- Advanced (optional)
    MaxDistance   = 2000,           -- hide very far players (studs)
}

-- Services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local lp         = Players.LocalPlayer
local cam        = workspace.CurrentCamera

local tracers    = {}      -- player → Drawing Line
local connections = {}     -- cleanup table

-- Cleanup everything
local function Cleanup()
    for _, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, line in pairs(tracers) do
        pcall(function() line:Remove() end)
    end
    tracers = {}
    connections = {}
end

-- Create / update single tracer
local function CreateTracer(player)
    if player == lp then return end
    
    local line = Drawing.new("Line")
    line.Visible       = false
    line.Color         = TracersOnly.Color
    line.Thickness     = TracersOnly.Thickness
    line.Transparency  = TracersOnly.Transparency
    
    tracers[player] = line
    
    local conn = RunService.RenderStepped:Connect(function()
        if not TracersOnly.Enabled or not player.Character then
            line.Visible = false
            return
        end
        
        local char = player.Character
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        
        if not root or not hum then
            line.Visible = false
            return
        end
        
        if TracersOnly.AliveCheck and hum.Health <= 0 then
            line.Visible = false
            return
        end
        
        if TracersOnly.TeamCheck and player.TeamColor == lp.TeamColor then
            line.Visible = false
            return
        end
        
        local rootPos, onScreen = cam:WorldToViewportPoint(root.Position)
        if not onScreen then
            line.Visible = false
            return
        end
        
        local dist = (lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")) and 
                     (root.Position - lp.Character.HumanoidRootPart.Position).Magnitude or 9999
        
        if dist > TracersOnly.MaxDistance then
            line.Visible = false
            return
        end
        
        -- From point
        local from
        if TracersOnly.TracerType == "Bottom" then
            from = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
        elseif TracersOnly.TracerType == "Center" then
            from = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        else -- Mouse
            from = UIS:GetMouseLocation()
        end
        
        line.From     = from
        line.To       = Vector2.new(rootPos.X, rootPos.Y)
        line.Visible  = true
    end)
    
    table.insert(connections, conn)
end

-- Watch players
local function OnPlayerAdded(p)
    if p == lp then return end
    
    p.CharacterAdded:Connect(function()
        if TracersOnly.Enabled then
            task.delay(0.4, function()
                CreateTracer(p)
            end)
        end
    end)
    
    if p.Character then
        task.delay(0.4, function()
            CreateTracer(p)
        end)
    end
end

-- Main toggle logic
getgenv().ToggleTracers = function(state)
    TracersOnly.Enabled = state
    
    if state then
        Cleanup() -- clear old
        
        -- Create for existing players
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                task.spawn(function()
                    task.wait(0.1)
                    CreateTracer(p)
                end)
            end
        end
        
        -- Watch new players
        table.insert(connections, Players.PlayerAdded:Connect(OnPlayerAdded))
        
        print("[Tracers] Enabled")
    else
        Cleanup()
        print("[Tracers] Disabled")
    end
end

-- Optional: keybind (press T to toggle)
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.T then
        getgenv().ToggleTracers(not TracersOnly.Enabled)
    end
end)

-- Initial message
print("[Tracers Only] Loaded")
print("→ Use:  getgenv().ToggleTracers(true/false)")
print("→ Or press T to toggle")
print("→ Settings: getgenv().TracersOnly = {...}")

-- Uncomment to auto-enable on script run
-- getgenv().ToggleTracers(true)
