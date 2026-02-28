
getgenv().Flex = {
    Enabled = false,                -- change here or live
    TeamCheck = false,             -- true = hide teammates
    Color = Color3.fromRGB(255, 50, 50),  -- red
    Thickness = 1.5,
    Transparency = 1,
    Origin = "Bottom"              -- "Bottom", "Center", "Mouse"
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local lplr = Players.LocalPlayer
local camera = workspace.CurrentCamera

local tracers = {}         -- player → Drawing Line
local connections = {}     -- cleanup table

-- Cleanup everything
local function cleanup()
    for _, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, line in pairs(tracers) do
        pcall(function() line:Remove() end)
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
        -- Check if still enabled (global can change live)
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

-- Setup all players (called only when needed)
local function setupTracers()
    cleanup()  -- clear old first
    
    if not getgenv().Tracers.Enabled then return end
    
    print("[Tracers] Enabling...")
    
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

-- Initial run
setupTracers()

-- Watch for global toggle changes (safe way, no infinite loop spam)
task.spawn(function()
    local lastState = getgenv().Tracers.Enabled
    while true do
        task.wait(0.3)
        if getgenv().Tracers.Enabled ~= lastState then
            lastState = getgenv().Tracers.Enabled
            setupTracers()
        end
    end
end)

print("[Tracers] Loaded - toggle with getgenv().Tracers.Enabled = true/false")
print("→ Current state: " .. tostring(getgenv().Tracers.Enabled))
