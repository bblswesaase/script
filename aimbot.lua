-- Universal Aimbot Module by Exunys © CC0 1.0 Universal (2023 - 2024)
-- https://github.com/Exunys
-- Modified for better controller support (2025/2026)

-- Cache
local game, workspace = game, workspace
local getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick = getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick
local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV, Drawingnew, TweenInfonew = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV, Drawing.new, TweenInfo.new
local getupvalue, mousemoverel, tablefind, tableremove, stringlower, stringsub, mathclamp = debug.getupvalue, mousemoverel or (Input and Input.MouseMove), table.find, table.remove, string.lower, string.sub, math.clamp

local GameMetatable = getrawmetatable and getrawmetatable(game) or {
	__index = function(self, Index) return self[Index] end,
	__newindex = function(self, Index, Value) self[Index] = Value end
}

local __index = GameMetatable.__index
local __newindex = GameMetatable.__newindex
local getrenderproperty, setrenderproperty = getrenderproperty or __index, setrenderproperty or __newindex
local GetService = __index(game, "GetService")

-- Services
local RunService        = GetService(game, "RunService")
local UserInputService  = GetService(game, "UserInputService")
local TweenService      = GetService(game, "TweenService")
local Players           = GetService(game, "Players")

-- Service Methods
local LocalPlayer       = __index(Players, "LocalPlayer")
local Camera            = __index(workspace, "CurrentCamera")
local FindFirstChild    = __index(game, "FindFirstChild")
local FindFirstChildOfClass = __index(game, "FindFirstChildOfClass")
local GetDescendants    = __index(game, "GetDescendants")
local WorldToViewportPoint = __index(Camera, "WorldToViewportPoint")
local GetPartsObscuringTarget = __index(Camera, "GetPartsObscuringTarget")
local GetMouseLocation  = __index(UserInputService, "GetMouseLocation")
local GetPlayers        = __index(Players, "GetPlayers")

-- Variables
local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity = 2000, false, false, {}
local Connect, Disconnect = __index(game, "DescendantAdded").Connect

-- Checking for multiple processes
if ExunysDeveloperAimbot and ExunysDeveloperAimbot.Exit then
	ExunysDeveloperAimbot:Exit()
end

-- Environment
getgenv().ExunysDeveloperAimbot = {
	DeveloperSettings = {
		UpdateMode = "RenderStepped",
		TeamCheckOption = "TeamColor",
		RainbowSpeed = 1    -- Bigger = Slower
	},

	Settings = {
		Enabled = true,
		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,
		OffsetToMoveDirection = false,
		OffsetIncrement = 15,
		Sensitivity = 0,       -- CFrame mode animation time (0 = instant)
		Sensitivity2 = 1.2,    -- mousemoverel divisor (lower = faster)
		LockMode = 2,          -- 1 = CFrame   |   2 = mousemoverel (better for controller)
		LockPart = "Head",
		TriggerKey = Enum.KeyCode.ButtonL2,   -- Right trigger (controller default)
		--TriggerKey = Enum.KeyCode.ButtonL2, -- Left trigger alternative
		--TriggerKey = Enum.UserInputType.MouseButton2, -- Mouse fallback
		Toggle = false         -- false = hold to aim (recommended for controller)
	},

	FOVSettings = {
		Enabled = true,
		Visible = true,
		Radius = 90,
		NumSides = 60,
		Thickness = 1,
		Transparency = 1,
		Filled = false,
		RainbowColor = false,
		RainbowOutlineColor = false,
		Color = Color3fromRGB(255, 255, 255),
		OutlineColor = Color3fromRGB(0, 0, 0),
		LockedColor = Color3fromRGB(255, 150, 150)
	},

	Blacklisted = {},

	FOVCircleOutline = Drawingnew("Circle"),
	FOVCircle = Drawingnew("Circle")
}

local Environment = getgenv().ExunysDeveloperAimbot

setrenderproperty(Environment.FOVCircle, "Visible", false)
setrenderproperty(Environment.FOVCircleOutline, "Visible", false)

-- Core Functions
local FixUsername = function(String)
	local Result
	for _, Value in next, GetPlayers(Players) do
		local Name = __index(Value, "Name")
		if stringsub(stringlower(Name), 1, #String) == stringlower(String) then
			Result = Name
		end
	end
	return Result
end

local GetRainbowColor = function()
	local RainbowSpeed = Environment.DeveloperSettings.RainbowSpeed
	return Color3fromHSV(tick() % RainbowSpeed / RainbowSpeed, 1, 1)
end

local ConvertVector = function(Vector)
	return Vector2new(Vector.X, Vector.Y)
end

local CancelLock = function()
	Environment.Locked = nil
	local FOVCircle = Environment.FOVCircle
	setrenderproperty(FOVCircle, "Color", Environment.FOVSettings.Color)
	__newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)
	if Animation then Animation:Cancel() end
end

local GetClosestPlayer = function()
	local Settings = Environment.Settings
	local LockPart = Settings.LockPart

	if not Environment.Locked then
		RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2000

		for _, Value in next, GetPlayers(Players) do
			local Character = __index(Value, "Character")
			local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")

			if Value ~= LocalPlayer
				and not tablefind(Environment.Blacklisted, __index(Value, "Name"))
				and Character
				and FindFirstChild(Character, LockPart)
				and Humanoid then

				local PartPosition = __index(Character[LockPart], "Position")
				local TeamCheckOption = Environment.DeveloperSettings.TeamCheckOption

				if Settings.TeamCheck and __index(Value, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then continue end
				if Settings.AliveCheck and __index(Humanoid, "Health") <= 0 then continue end

				if Settings.WallCheck then
					local BlacklistTable = GetDescendants(__index(LocalPlayer, "Character"))
					for _, Value in next, GetDescendants(Character) do
						BlacklistTable[#BlacklistTable + 1] = Value
					end
					if #GetPartsObscuringTarget(Camera, {PartPosition}, BlacklistTable) > 0 then continue end
				end

				local Vector, OnScreen = WorldToViewportPoint(Camera, PartPosition)
				Vector = ConvertVector(Vector)
				local Distance = (GetMouseLocation(UserInputService) - Vector).Magnitude

				if Distance < RequiredDistance and OnScreen then
					RequiredDistance, Environment.Locked = Distance, Value
				end
			end
		end
	elseif (GetMouseLocation(UserInputService) - ConvertVector(WorldToViewportPoint(Camera, __index(__index(__index(Environment.Locked, "Character"), LockPart), "Position")))).Magnitude > RequiredDistance then
		CancelLock()
	end
end

local Load = function()
	OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")

	local Settings = Environment.Settings
	local FOVCircle = Environment.FOVCircle
	local FOVCircleOutline = Environment.FOVCircleOutline
	local FOVSettings = Environment.FOVSettings

	ServiceConnections.RenderSteppedConnection = Connect(RunService[Environment.DeveloperSettings.UpdateMode], function()
		local OffsetToMoveDirection = Settings.OffsetToMoveDirection
		local LockPart = Settings.LockPart

		if FOVSettings.Enabled and Settings.Enabled then
			for Index, Value in next, FOVSettings do
				if Index == "Color" then continue end
				if pcall(getrenderproperty, FOVCircle, Index) then
					setrenderproperty(FOVCircle, Index, Value)
					setrenderproperty(FOVCircleOutline, Index, Value)
				end
			end

			setrenderproperty(FOVCircle, "Color", (Environment.Locked and FOVSettings.LockedColor) or FOVSettings.RainbowColor and GetRainbowColor() or FOVSettings.Color)
			setrenderproperty(FOVCircleOutline, "Color", FOVSettings.RainbowOutlineColor and GetRainbowColor() or FOVSettings.OutlineColor)
			setrenderproperty(FOVCircleOutline, "Thickness", FOVSettings.Thickness + 1)
			setrenderproperty(FOVCircle, "Position", GetMouseLocation(UserInputService))
			setrenderproperty(FOVCircleOutline, "Position", GetMouseLocation(UserInputService))
		else
			setrenderproperty(FOVCircle, "Visible", false)
			setrenderproperty(FOVCircleOutline, "Visible", false)
		end

		if Running and Settings.Enabled then
			GetClosestPlayer()

			local Offset = OffsetToMoveDirection and __index(FindFirstChildOfClass(__index(Environment.Locked, "Character"), "Humanoid"), "MoveDirection") * (mathclamp(Settings.OffsetIncrement, 1, 30) / 10) or Vector3zero

			if Environment.Locked then
				local LockedPosition_Vector3 = __index(__index(Environment.Locked, "Character")[LockPart], "Position") + Offset
				local LockedPosition = WorldToViewportPoint(Camera, LockedPosition_Vector3)

				if Settings.LockMode == 2 then
					-- mousemoverel (smoother on controller)
					local deltaX = (LockedPosition.X - GetMouseLocation(UserInputService).X) / Settings.Sensitivity2
					local deltaY = (LockedPosition.Y - GetMouseLocation(UserInputService).Y) / Settings.Sensitivity2
					mousemoverel(deltaX, deltaY)
				else
					-- CFrame mode
					if Settings.Sensitivity > 0 then
						Animation = TweenService:Create(Camera, TweenInfonew(Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
							CFrame = CFramenew(Camera.CFrame.Position, LockedPosition_Vector3)
						})
						Animation:Play()
					else
						__newindex(Camera, "CFrame", CFramenew(Camera.CFrame.Position, LockedPosition_Vector3))
					end
					__newindex(UserInputService, "MouseDeltaSensitivity", 0)
				end

				setrenderproperty(FOVCircle, "Color", FOVSettings.LockedColor)
			end
		end
	end)

	-- Improved input handling (controller + kbm)
	ServiceConnections.InputBeganConnection = Connect(UserInputService.InputBegan, function(input, gameProcessed)
		if gameProcessed then return end
		if Typing then return end

		local trig = Settings.TriggerKey

		local isTriggerDown = 
			(input.UserInputType == trig) or
			(input.KeyCode == trig) or
			(input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == trig)

		if isTriggerDown then
			if Settings.Toggle then
				Running = not Running
				if not Running then
					CancelLock()
				end
			else
				Running = true
			end
		end
	end)

	ServiceConnections.InputEndedConnection = Connect(UserInputService.InputEnded, function(input, gameProcessed)
		if gameProcessed then return end

		local trig = Settings.TriggerKey

		local isTriggerUp = 
			(input.UserInputType == trig) or
			(input.KeyCode == trig) or
			(input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == trig)

		if isTriggerUp and not Settings.Toggle then
			Running = false
			CancelLock()
		end
	end)
end

-- Typing Check
ServiceConnections.TypingStartedConnection = Connect(UserInputService.TextBoxFocused, function()
	Typing = true
end)

ServiceConnections.TypingEndedConnection = Connect(UserInputService.TextBoxFocusReleased, function()
	Typing = false
end)

-- Public Methods
function Environment.Exit(self)
	assert(self, "EXUNYS_AIMBOT-V3.Exit: Missing parameter #1 \"self\" <table>.")
	for Index, _ in next, ServiceConnections do
		if ServiceConnections[Index] then
			Disconnect(ServiceConnections[Index])
		end
	end
	Load = nil; ConvertVector = nil; CancelLock = nil; GetClosestPlayer = nil; GetRainbowColor = nil; FixUsername = nil
	self.FOVCircle:Remove()
	self.FOVCircleOutline:Remove()
	getgenv().ExunysDeveloperAimbot = nil
end

function Environment.Restart()
	for Index, _ in next, ServiceConnections do
		if ServiceConnections[Index] then
			Disconnect(ServiceConnections[Index])
		end
	end
	Load()
end

function Environment.Blacklist(self, Username)
	assert(self, "EXUNYS_AIMBOT-V3.Blacklist: Missing parameter #1 \"self\" <table>.")
	assert(Username, "EXUNYS_AIMBOT-V3.Blacklist: Missing parameter #2 \"Username\" <string>.")
	Username = FixUsername(Username)
	assert(Username, "EXUNYS_AIMBOT-V3.Blacklist: User not found.")
	self.Blacklisted[#self.Blacklisted + 1] = Username
end

function Environment.Whitelist(self, Username)
	assert(self, "EXUNYS_AIMBOT-V3.Whitelist: Missing parameter #1 \"self\" <table>.")
	assert(Username, "EXUNYS_AIMBOT-V3.Whitelist: Missing parameter #2 \"Username\" <string>.")
	Username = FixUsername(Username)
	local Index = tablefind(self.Blacklisted, Username)
	assert(Index, "EXUNYS_AIMBOT-V3.Whitelist: User not blacklisted.")
	tableremove(self.Blacklisted, Index)
end

function Environment.GetClosestPlayer()
	GetClosestPlayer()
	local Value = Environment.Locked
	CancelLock()
	return Value
end

Environment.Load = Load
setmetatable(Environment, {__call = Load})

return Environment
