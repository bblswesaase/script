getgenv().chams = {
    Enabled = false,
    TeamCheck = false,
    AliveCheck = true,
    Color = Color3.fromRGB(255, 0, 4), -- red (your color)
    Thickness = 1.8,
    Transparency = 0.9,
    Filled = false,
    SizeMultiplier = 2.2
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lplr = Players.LocalPlayer
local camera = workspace.CurrentCamera

local boxes = {}
local connections = {}

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

local function addBox(player)
    if player == lplr then return end
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = getgenv().chams.Color
    box.Thickness = getgenv().chams.Thickness
    box.Transparency = getgenv().chams.Transparency
    box.Filled = getgenv().chams.Filled
    
    boxes[player] = box
    
    local conn = RunService.RenderStepped:Connect(function()
        if not getgenv().chams.Enabled then
            box.Visible = false
            return
        end
        
        local char = player.Character
        if not char then
            box.Visible = false
            return
        end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if not root or not head or not hum then
            box.Visible = false
            return
        end
        
        if getgenv().chams.AliveCheck and hum.Health <= 0 then
            box.Visible = false
            return
        end
        
        if getgenv().chams.TeamCheck and player.TeamColor == lplr.TeamColor then
            box.Visible = false
            return
        end
        
        local rootPos, onScreen = camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            box.Visible = false
            return
        end
        
        -- IMPROVED BOX CALCULATION
        local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.2, 0))
        local legPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
        
        local height = math.abs(headPos.Y - legPos.Y)
        
        local widthFromProjection = math.abs(headPos.X - legPos.X) * 2.5
        local minWidth = height * 0.55
        local width = math.max(widthFromProjection, minWidth)
        
        width = width * getgenv().chams.SizeMultiplier
        height = height * 1.3
        
        box.Size = Vector2.new(width, height)
        box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
        box.Visible = true
    end)
    
    table.insert(connections, conn)
end

local function setup()
    cleanup()
    if not getgenv().chams.Enabled then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lplr then
            task.spawn(function()
                if player.Character then addBox(player) end
                player.CharacterAdded:Connect(function() addBox(player) end)
            end)
        end
    end
    
    table.insert(connections, Players.PlayerAdded:Connect(function(player)
        if player ~= lplr then
            player.CharacterAdded:Connect(function() addBox(player) end)
        end
    end))
end

-- Initial run
setup()

-- Watch toggle changes
task.spawn(function()
    local last = getgenv().chams.Enabled
    while true do
        task.wait(0.3)
        if getgenv().chams.Enabled ~= last then
            last = getgenv().chams.Enabled
            setup()
        end
    end
end)
