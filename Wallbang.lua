getgenv().Wallbang = {
    Enabled = false,           -- toggle this to turn on/off
    TeamCheck = true,          -- true = don't target teammates
    MaxDistance = 300,         -- max shoot range (studs)
    HitPart = "Head",          -- "Head" or "HumanoidRootPart"
    FOV = 10,                  -- small FOV for "crosshair" wallbang
    Silent = true              -- true = silent aim (no camera move), false = camera aim
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lplr = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = lplr:GetMouse()

-- Hook mouse.Hit for silent aim
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if not checkcaller() and method == "FindPartOnRayWithIgnoreList" and Wallbang.Enabled then
        local closest = getClosestEnemy()
        if closest and closest.Character and closest.Character:FindFirstChild(Wallbang.HitPart) then
            local targetPos = closest.Character[Wallbang.HitPart].Position
            args[1] = Ray.new(camera.CFrame.Position, (targetPos - camera.CFrame.Position).Unit * Wallbang.MaxDistance)
            return oldNamecall(self, unpack(args))
        end
    end
    
    return oldNamecall(self, ...)
end)

-- Find closest enemy in small FOV / crosshair direction
local function getClosestEnemy()
    local closest, dist = nil, Wallbang.FOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == lplr or not player.Character then continue end
        
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 then continue end
        
        if Wallbang.TeamCheck and player.TeamColor == lplr.TeamColor then continue end
        
        local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
        if not onScreen then continue end
        
        local mousePos = UserInputService:GetMouseLocation()
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        
        if distance < dist then
            dist = distance
            closest = player
        end
    end
    
    return closest
end
