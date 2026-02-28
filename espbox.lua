getgenv().Flex = {
    Enabled = false,
    TeamCheck = false,
    Color = Color3.fromRGB(255, 50, 50),
    Thickness = 1.5,
    Transparency = 1,
    Origin = "Bottom"
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lplr = Players.LocalPlayer
local camera = workspace.CurrentCamera

local tracers = {}
local connections = {}

local function cleanup()
    for _, conn in pairs(connections) do pcall(conn.Disconnect, conn) end
    for _, line in pairs(tracers) do pcall(line.Remove, line) end
    tracers = {}
    connections = {}
end

local function addTracer(player)
    if player == lplr then return end
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = getgenv().Flex.Color
    line.Thickness = getgenv().Flex.Thickness
    line.Transparency = getgenv().Flex.Transparency
    tracers[player] = line
    local conn = RunService.RenderStepped:Connect(function()
        if not getgenv().Flex.Enabled then
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
        if getgenv().Flex.TeamCheck and player.TeamColor == lplr.TeamColor then
            line.Visible = false
            return
        end
        local vector, onScreen = camera:WorldToViewportPoint(root.Position)
        if onScreen then
            local from
            if getgenv().Flex.Origin == "Bottom" then
                from = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
            elseif getgenv().Flex.Origin == "Center" then
                from = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            else
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

local function setupTracers()
    cleanup()
    if not getgenv().Flex.Enabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lplr then
            task.spawn(function()
                if player.Character then addTracer(player) end
                player.CharacterAdded:Connect(function() addTracer(player) end)
            end)
        end
    end
    table.insert(connections, Players.PlayerAdded:Connect(function(player)
        if player ~= lplr then
            player.CharacterAdded:Connect(function() addTracer(player) end)
        end
    end))
end

setupTracers()

task.spawn(function()
    local last = getgenv().Flex.Enabled
    while true do
        task.wait(0.3)
        if getgenv().Flex.Enabled ~= last then
            last = getgenv().Flex.Enabled
            setupTracers()
        end
    end
end)
