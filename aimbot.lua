--[[ 
    Universal Aimbot Module - Controller-Friendly Version
    Original by Exunys (CC0) - Soft Aim Assist Edition for Gamepad
    Modified for better controller compatibility (2026 style)
]]

--// Cache
local game, workspace = game, workspace
local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV
local Drawingnew, TweenInfonew = Drawing.new, TweenInfo.new
local mathclamp, mathacos, mathdeg, tick = math.clamp, math.acos, math.deg, tick

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

--// Environment
getgenv().ExunysDeveloperAimbot = getgenv().ExunysDeveloperAimbot or {}
local Environment = getgenv().ExunysDeveloperAimbot

if Environment.Exit then Environment:Exit() end

Environment = {
	DeveloperSettings = {
		UpdateMode     = "RenderStepped",
		TeamCheckOption = "TeamColor",
		RainbowSpeed   = 1.8,
	},

	Settings = {
		Enabled              = true,
		TeamCheck            = false,
		AliveCheck           = true,
		WallCheck            = false,
		OffsetToMoveDirection = false,
		OffsetIncrement      = 12,

		-- Controller-friendly settings
		AimAssistStrength    = 0.16,     -- 0.05 = very subtle, 0.35 = aggressive (tune per game)
		AimAssistDeadzone    = 14,       -- degrees - assist only if target is within this cone
		SmoothingFactor      = 0.38,     -- higher = faster response (0.2–0.6 range usually feels good)
		LockPart             = "Head",
		TriggerKey           = Enum.UserInputType.MouseButton2,
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
		RainbowOutlineColor = false,
		Color            = Color3fromRGB(220, 220, 255),
		OutlineColor     = Color3fromRGB(20, 20, 40),
		LockedColor      = Color3fromRGB(255, 120, 140)
	},

	Blacklisted      = {},
	Locked           = nil,
	FOVCircle        = Drawingnew("Circle"),
	FOVCircleOutline = Drawingnew("Circle")
}

setmetatable(Environment, { __index = Environment })

-- Hide circles initially
Environment.FOVCircle.Visible       = false
Environment.FOVCircleOutline.Visible = false

--// Helpers
local function GetRainbowColor()
	local t = tick() % Environment.DeveloperSettings.RainbowSpeed / Environment.DeveloperSettings.RainbowSpeed
	return Color3fromHSV(t, 1, 1)
end

local function ConvertVector(v3)
	return Vector2new(v3.X, v3.Y)
end

local function CancelLock()
	Environment.Locked = nil
	Environment.FOVCircle.Color = Environment.FOVSettings.Color
	if Environment.Animation then
		Environment.Animation:Cancel()
		Environment.Animation = nil
	end
end

local function GetClosestPlayer()
	if not Environment.Locked then
		local requiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2500
		local mousePos = UserInputService:GetMouseLocation()

		for _, player in Players:GetPlayers() do
			if player == LocalPlayer then continue end
			if table.find(Environment.Blacklisted, player.Name) then continue end

			local char = player.Character
			if not char then continue end

			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if not humanoid or (Environment.Settings.AliveCheck and humanoid.Health <= 0) then continue end

			local part = char:FindFirstChild(Environment.Settings.LockPart)
			if not part then continue end

			if Environment.Settings.TeamCheck and player[Environment.DeveloperSettings.TeamCheckOption] == LocalPlayer[Environment.DeveloperSettings.TeamCheckOption] then
				continue
			end

			local pos = part.Position
			local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
			if not onScreen then continue end

			local distance = (mousePos - ConvertVector(screenPos)).Magnitude
			if distance >= requiredDistance then continue end

			if Environment.Settings.WallCheck then
				local parts = Camera:GetPartsObscuringTarget({pos}, {LocalPlayer.Character, char})
				if #parts > 0 then continue end
			end

			requiredDistance = distance
			Environment.Locked = player
		end
	else
		-- Check if still in range
		local char = Environment.Locked.Character
		if char then
			local part = char:FindFirstChild(Environment.Settings.LockPart)
			if part then
				local screenPos = Camera:WorldToViewportPoint(part.Position)
				local dist = (UserInputService:GetMouseLocation() - ConvertVector(screenPos)).Magnitude
				if dist > (Environment.FOVSettings.Radius * 1.3) then
					CancelLock()
				end
			else
				CancelLock()
			end
		else
			CancelLock()
		end
	end
end

--// Main Loop
local function Load()
	local conn
	conn = RunService[Environment.DeveloperSettings.UpdateMode]:Connect(function()
		local Settings = Environment.Settings
		local FOV = Environment.FOVSettings

		-- Update FOV circle
		if FOV.Enabled and Settings.Enabled then
			Environment.FOVCircle.Position         = UserInputService:GetMouseLocation()
			Environment.FOVCircle.Radius           = FOV.Radius
			Environment.FOVCircle.NumSides         = FOV.NumSides
			Environment.FOVCircle.Thickness        = FOV.Thickness
			Environment.FOVCircle.Transparency     = FOV.Transparency
			Environment.FOVCircle.Filled           = FOV.Filled
			Environment.FOVCircle.Visible          = FOV.Visible

			Environment.FOVCircleOutline.Position      = Environment.FOVCircle.Position
			Environment.FOVCircleOutline.Radius        = FOV.Radius + FOV.Thickness + 1
			Environment.FOVCircleOutline.Thickness     = FOV.Thickness + 1.5
			Environment.FOVCircleOutline.Transparency  = FOV.Transparency * 0.7
			Environment.FOVCircleOutline.Visible       = FOV.Visible

			if Environment.Locked then
				Environment.FOVCircle.Color = FOV.LockedColor
			else
				Environment.FOVCircle.Color = FOV.RainbowColor and GetRainbowColor() or FOV.Color
			end
			Environment.FOVCircleOutline.Color = FOV.RainbowOutlineColor and GetRainbowColor() or FOV.OutlineColor
		else
			Environment.FOVCircle.Visible       = false
			Environment.FOVCircleOutline.Visible = false
		end

		if not Settings.Enabled then return end

		GetClosestPlayer()

		if Environment.Locked then
			local char = Environment.Locked.Character
			if not char then CancelLock() return end

			local part = char:FindFirstChild(Settings.LockPart)
			if not part then CancelLock() return end

			local offset = Settings.OffsetToMoveDirection and (char.Humanoid.MoveDirection * (Settings.OffsetIncrement / 10)) or Vector3zero
			local targetPos = part.Position + offset

			local currentLook = Camera.CFrame.LookVector
			local toTarget    = (targetPos - Camera.CFrame.Position).Unit

			local angleDiff = mathdeg(mathacos(currentLook:Dot(toTarget)))

			if angleDiff <= Settings.AimAssistDeadzone then
				-- Already aimed well → minimal/no assist
			else
				-- Soft assist nudge
				local strength = mathclamp(Settings.AimAssistStrength, 0.01, 0.6)
				local assistedDir = currentLook:Lerp(toTarget, strength)

				local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + assistedDir * 150)

				-- Apply smoothed rotation
				local smooth = mathclamp(Settings.SmoothingFactor, 0.1, 0.8)
				Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smooth)
			end
		end
	end)

	-- Trigger handling
	local typing = false

	UserInputService.TextBoxFocused:Connect(function() typing = true end)
	UserInputService.TextBoxFocusReleased:Connect(function() typing = false end)

	local inputConnBegan = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or typing then return end

		local key = Settings.TriggerKey
		if (input.UserInputType == key) or (input.KeyCode == key) then
			if Settings.Toggle then
				Environment.Running = not Environment.Running
				if not Environment.Running then CancelLock() end
			else
				Environment.Running = true
			end
		end
	end)

	local inputConnEnded = UserInputService.InputEnded:Connect(function(input)
		local key = Settings.TriggerKey
		if Settings.Toggle then return end
		if (input.UserInputType == key) or (input.KeyCode == key) then
			Environment.Running = false
			CancelLock()
		end
	end)

	Environment.Connections = {
		Render = conn,
		InputBegan = inputConnBegan,
		InputEnded = inputConnEnded
	}
end

--// Public Methods
function Environment:Exit()
	for _, conn in pairs(self.Connections or {}) do
		pcall(function() conn:Disconnect() end)
	end
	self.FOVCircle:Remove()
	self.FOVCircleOutline:Remove()
	getgenv().ExunysDeveloperAimbot = nil
end

function Environment:Load()
	Load()
end

function Environment:GetClosestPlayer()
	GetClosestPlayer()
	local target = self.Locked
	CancelLock()
	return target
end

-- Auto-load on script execution
Environment:Load()

print("[Exunys Aimbot - Controller Edition] Loaded | Strength: " .. Environment.Settings.AimAssistStrength .. " | Deadzone: " .. Environment.Settings.AimAssistDeadzone)
