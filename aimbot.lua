--[[ 
    Universal Aimbot - PC + Controller Compatible (Updated Trigger Support)
    Original by Exunys (CC0) - Enhanced with gamepad trigger keys (2026)
]]

-- Cache
local game, workspace = game, workspace
local pcall, getgenv, next, tick = pcall, getgenv, next, tick
local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV
local Drawingnew = Drawing.new

-- Services
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- Environment
if getgenv().ExunysDeveloperAimbot and getgenv().ExunysDeveloperAimbot.Exit then
	getgenv().ExunysDeveloperAimbot:Exit()
end

getgenv().ExunysDeveloperAimbot = {
	DeveloperSettings = {
		UpdateMode      = "RenderStepped",
		TeamCheckOption = "TeamColor",
		RainbowSpeed    = 1.8,
	},

	Settings = {
		Enabled              = false,
		TeamCheck            = false,
		AliveCheck           = true,
		WallCheck            = false,
		OffsetToMoveDirection = false,
		OffsetIncrement      = 12,

		-- Controller / Gamepad settings
		AimAssistStrength    = 0.16,     -- 0.05–0.35 recommended
		AimAssistDeadzone    = 14,       -- degrees
		SmoothingFactor      = 0.38,     -- 0.2–0.6 best range
		LockPart             = "Head",

		-- Trigger key (works on PC and controller)
		TriggerKey           = Enum.UserInputType.MouseButton2,   -- default right click
		GamepadTriggerKeys   = {Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonR1},  -- right trigger / right bumper
		Toggle               = false,
	},

	FOVSettings = {
		Enabled          = true,
		Visible          = true,
		Radius           = 140,
		NumSides         = 60,
		Thickness        = 1.4,
		Transparency     = 0.95,
		Filled           = false,
		RainbowColor     = false,
		Color            = Color3fromRGB(220, 220, 255),
		OutlineColor     = Color3fromRGB(20, 20, 40),
		LockedColor      = Color3fromRGB(255, 120, 140),
	},

	Blacklisted = {},
	Locked      = nil,
	FOVCircle   = Drawingnew("Circle"),
	Connections = {},
}

local Environment = getgenv().ExunysDeveloperAimbot

Environment.FOVCircle.Visible = false

-- Helpers
local function IsController()
	return UserInputService.GamepadEnabled
end

local function GetCursorPos()
	if not IsController() then
		local ok, pos = pcall(UserInputService.GetMouseLocation, UserInputService)
		if ok then return pos end
	end
	return Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function IsTriggerInput(input)
	local s = Environment.Settings

	-- Mouse or keyboard
	if input.UserInputType == s.TriggerKey or input.KeyCode == s.TriggerKey then
		return true
	end

	-- Gamepad buttons
	if IsController() and input.UserInputType.Name:find("Gamepad") then
		for _, key in ipairs(s.GamepadTriggerKeys) do
			if input.KeyCode == key then
				return true
			end
		end
	end

	return false
end

local function GetRainbowColor()
	local t = tick() % Environment.DeveloperSettings.RainbowSpeed / Environment.DeveloperSettings.RainbowSpeed
	return Color3fromHSV(t, 1, 1)
end

local function CancelLock()
	Environment.Locked = nil
	Environment.FOVCircle.Color = Environment.FOVSettings.Color
end

local function GetClosestPlayer()
	if Environment.Locked then
		-- Check if still valid
		local char = Environment.Locked.Character
		if char then
			local part = char:FindFirstChild(Environment.Settings.LockPart)
			if part then
				local screen = Camera:WorldToViewportPoint(part.Position)
				local dist = (GetCursorPos() - Vector2new(screen.X, screen.Y)).Magnitude
				if dist > Environment.FOVSettings.Radius * 1.4 then
					CancelLock()
				end
			else
				CancelLock()
			end
		else
			CancelLock()
		end
		return
	end

	local reqDist = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2500
	local mousePos = GetCursorPos()

	for _, player in Players:GetPlayers() do
		if player == LocalPlayer then continue end
		if table.find(Environment.Blacklisted, player.Name) then continue end

		local char = player.Character
		if not char then continue end

		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or (Environment.Settings.AliveCheck and hum.Health <= 0) then continue end

		local part = char:FindFirstChild(Environment.Settings.LockPart)
		if not part then continue end

		if Environment.Settings.TeamCheck and player.TeamColor == LocalPlayer.TeamColor then
			continue
		end

		if Environment.Settings.WallCheck then
			local parts = Camera:GetPartsObscuringTarget({part.Position}, {LocalPlayer.Character, char})
			if #parts > 0 then continue end
		end

		local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
		if not onScreen then continue end

		local dist = (mousePos - Vector2new(screen.X, screen.Y)).Magnitude
		if dist < reqDist then
			reqDist = dist
			Environment.Locked = player
		end
	end
end

-- Main loop
local function Load()
	Environment.Connections.Render = RunService[Environment.DeveloperSettings.UpdateMode]:Connect(function()
		local s = Environment.Settings
		local f = Environment.FOVSettings

		-- FOV circle
		if f.Enabled and s.Enabled then
			Environment.FOVCircle.Position         = GetCursorPos()
			Environment.FOVCircle.Radius           = f.Radius
			Environment.FOVCircle.NumSides         = f.NumSides
			Environment.FOVCircle.Thickness        = f.Thickness
			Environment.FOVCircle.Transparency     = f.Transparency
			Environment.FOVCircle.Filled           = f.Filled
			Environment.FOVCircle.Visible          = f.Visible

			Environment.FOVCircle.Color = Environment.Locked and f.LockedColor or f.RainbowColor and GetRainbowColor() or f.Color
		else
			Environment.FOVCircle.Visible = false
		end

		if not s.Enabled then return end

		GetClosestPlayer()

		if Environment.Locked then
			local char = Environment.Locked.Character
			if not char then CancelLock() return end

			local part = char:FindFirstChild(s.LockPart)
			if not part then CancelLock() return end

			local offset = s.OffsetToMoveDirection and (char.Humanoid.MoveDirection * (s.OffsetIncrement / 10)) or Vector3zero
			local targetPos = part.Position + offset

			local currentLook = Camera.CFrame.LookVector
			local direction   = (targetPos - Camera.CFrame.Position).Unit

			local angle = mathdeg(mathacos(currentLook:Dot(direction)))

			if angle > s.AimAssistDeadzone then
				local strength = mathclamp(s.AimAssistStrength, 0.01, 0.6)
				local assisted = currentLook:Lerp(direction, strength)

				local newCF = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + assisted * 150)
				Camera.CFrame = Camera.CFrame:Lerp(newCF, s.SmoothingFactor)
			end
		end
	end)

	-- Input handling (mouse + keyboard + gamepad)
	Environment.Connections.InputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

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
end

-- Public methods
function Environment.Exit()
	for _, conn in pairs(Environment.Connections) do
		pcall(function() conn:Disconnect() end)
	end
	Environment.FOVCircle:Remove()
	getgenv().ExunysDeveloperAimbot = nil
end

function Environment.Load()
	Load()
end

Environment.Load()

print("[Exunys Aimbot] Loaded | Controller trigger support added (R2 / RMB)")
