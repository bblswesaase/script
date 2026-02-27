getgenv().Tracers = {
    Enabled = true,          -- set to false to disable
    TeamCheck = false,       -- true = hide teammates
    Color = Color3.fromRGB(255, 50, 50),   -- red
    Thickness = 1.5,
    Transparency = 1,
    Origin = "Bottom"        -- "Bottom", "Center", "Mouse"
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local lplr = Players.LocalPlayer
local camera = workspace.CurrentCamera

local tracers = {}         -- player → Drawing Line
local connections = {}     -- cleanup

-- Cleanup function
local function cleanup()
    for _, conn in pairs(connections) do
        pcall(conn.Disconnect, conn)
    end
    for _, line in pairs(tracers) do
        pcall(line.Remove, line)
    end
    tracers = {}
    connections = {}
end

-- Add tracer for one player
local function addTracer(player)
    if player == lplr then return end
    
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = getgenv().Tracers.Color
    line.Thickness = getgenv().Tracers.Thickness
    line.Transparency = getgenv().Tracers.Transparency
    
    tracers[player] = line
    
    local conn = RunService.RenderStepped:Connect(function()
        if not getgenv().Tracers.Enabled then
            line.Visible = false
            return
        end
        
        if not player.Character then
            line.Visible = false
            return
        end
        
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        
        if not root or not hum or hum.Health <= 0 then
            line.Visible = false
            return
        end
        
        if getgenv().Tracers.TeamCheck and player.TeamColor == lplr.TeamColor then
            line.Visible = false
            return
        end
        
        local vector, onScreen = camera:WorldToViewportPoint(root.Position)
        
        if onScreen then
            local from
            if getgenv().Tracers.Origin == "Bottom" then
                from = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
            elseif getgenv().Tracers.Origin == "Center" then
                from = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            else -- Mouse
                from = UIS:GetMouseLocation()
            end
            
            line.From = from
            line.To = Vector2.new(vector.X, vector.Y)
            line.Visible = true
        else
            line.Visible = false
        end
    end)
    
    table.insert(connections, conn)
end

-- Watch all players
local function setup()
    cleanup() -- clear old
    
    if not getgenv().Tracers.Enabled then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lplr then
            task.spawn(function()
                if player.Character then
                    addTracer(player)
                end
                player.CharacterAdded:Connect(function()
                    addTracer(player)
                end)
            end)
        end
    end
    
    -- New players
    table.insert(connections, Players.PlayerAdded:Connect(function(player)
        if player ~= lplr then
            player.CharacterAdded:Connect(function()
                addTracer(player)
            end)
        end
    end))
end

-- Auto-run when script loads
setup()

-- Watch for setting changes (so you can toggle via executor)
task.spawn(function()
    while true do
        task.wait(0.5)
        setup() -- re-run setup if Enabled changes
    end
end)

print("[Tracers] Loaded")
print("→ Toggle:   getgenv().Tracers.Enabled = true/false")
print("→ TeamCheck: getgenv().Tracers.TeamCheck = true/false")
print("→ Origin:    getgenv().Tracers.Origin = 'Bottom' / 'Center' / 'Mouse'")
