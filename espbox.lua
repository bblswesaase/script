-- ESP Boxes Only (2D Square) - getgenv style
-- Toggle: getgenv().ESPBoxes.Enabled = true/false

getgenv().ESPBoxes = {
    Enabled = false,                -- change here or live
    TeamCheck = false,             -- true = hide teammates
    AliveCheck = true,             -- true = hide dead players
    Color = Color3.fromRGB(255, 200, 60),  -- yellow/orange
    Thickness = 1.8,
    Transparency = 0.9,
    Filled = false,                -- true = solid fill (looks weird on players)
    SizeMultiplier = 2.2           -- bigger/smaller box (adjust if too small/big)
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lplr = Players.LocalPlayer
local camera = workspace.CurrentCamera

local boxes = {}           -- player → Drawing Square
local connections = {}     -- cleanup

-- Cleanup everything
local function cleanup()
    for _, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, box in pairs(boxes) do
        pcall(function() box:Remove() end)
    end
    boxes = {}
    connections = {}
end

-- Add box for one player
local function addBox(player)
    if player == lplr then return end
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = getgenv().ESPBoxes.Color
    box.Thickness = getgenv().ESPBoxes.Thickness
    box.Transparency = getgenv().ESPBoxes.Transparency
    box.Filled = getgenv().ESPBoxes.Filled
    
    boxes[player] = box
    
    local conn = RunService.RenderStepped:Connect(function()
        if not getgenv().ESPBoxes.Enabled then
            box.Visible = false
            return
        end
        
        if not player.Character then
            box.Visible = false
            return
        end
        
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        local head = player.Character:FindFirstChild("Head")
        local hum  = player.Character:FindFirstChildOfClass("Humanoid")
        
        if not root or not head or not hum then
            box.Visible = false
            return
        end
        
        if getgenv().ESPBoxes.AliveCheck and hum.Health <= 0 then
            box.Visible = false
            return
        end
        
        if getgenv().ESPBoxes.TeamCheck and player.TeamColor == lplr.TeamColor then
            box.Visible = false
            return
        end
        
        local rootPos, onScreen = camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            box.Visible = false
            return
        end
        
        -- Calculate box from head to legs
        local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.2, 0))
        local legPos  = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
        
        local width = math.abs(headPos.X - legPos.X) * getgenv().ESPBoxes.SizeMultiplier
        local height = math.abs(headPos.Y - legPos.Y) * 1.3  -- slightly taller than wide
        
        box.Size = Vector2.new(width, height)
        box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
        box.Visible = true
    end)
    
    table.insert(connections, conn)
end

-- Setup all players
local function setupBoxes()
    cleanup()  -- clear old
    
    if not getgenv().ESPBoxes.Enabled then return end
    
    print("[ESP Boxes] Enabling...")
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lplr then
            task.spawn(function()
                if player.Character then
                    addBox(player)
                end
                player.CharacterAdded:Connect(function()
                    addBox(player)
                end)
            end)
        end
    end
    
    -- New players
    table.insert(connections, Players.PlayerAdded:Connect(function(player)
        if player ~= lplr then
            player.CharacterAdded:Connect(function()
                addBox(player)
            end)
        end
    end))
end

-- Initial run
setupBoxes()

-- Watch for toggle changes (no spam loop)
task.spawn(function()
    local lastState = getgenv().ESPBoxes.Enabled
    while true do
        task.wait(0.3)
        if getgenv().ESPBoxes.Enabled ~= lastState then
            lastState = getgenv().ESPBoxes.Enabled
            setupBoxes()
        end
    end
end)

print("[ESP Boxes] Loaded")
print("→ Toggle: getgenv().ESPBoxes.Enabled = true/false")
print("→ TeamCheck: getgenv().ESPBoxes.TeamCheck = true/false")
print("→ Color: getgenv().ESPBoxes.Color = Color3.fromRGB(r,g,b)")
