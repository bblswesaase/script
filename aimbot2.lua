-- Universal Aimbot Module by Exunys © CC0 1.0 Universal (2023 - 2024)
-- https://github.com/Exunys
-- FULL MODIFIED VERSION 2026: KBM (Right Click) + Controller (L2) support
-- Smooth controller aiming (no more crazy screen shake/jitter)
-- FIXED: No more constant mouse drift/jitter on controller – true lock-on with deadzone + prediction
-- + Velocity Prediction (sticky tracking for movers)
-- + Walk to Target (optional auto-walk)
-- Cache
local game, workspace = game, workspace
local getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick = getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick
local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV, Drawingnew, TweenInfonew = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV, Drawing.new, TweenInfo.new
local getupvalue, mousemoverel, tablefind, tableremove, stringlower, stringsub, mathclamp, mathabs = debug.getupvalue, mousemoverel or (Input and Input.MouseMove), table.find, table.remove, string.lower, string.sub, math.clamp, math.abs
local GameMetatable = getrawmetatable and getrawmetatable(game) or {
__index = function(self, Index) return self[Index] end,
__newindex = function(self, Index, Value) self[Index] = Value end
}
local __index = GameMetatable.__index
local __newindex = GameMetatable.__newindex
local getrenderproperty, setrenderproperty = getrenderproperty or __index, setrenderproperty or __newindex
local GetService = __index(game, "GetService")
-- Services
local RunService = GetService(game, "RunService")
local UserInputService = GetService(game, "UserInputService")
local TweenService = GetService(game, "TweenService")
local Players = GetService(game, "Players")
-- Service Methods
local LocalPlayer = __index(Players, "LocalPlayer")
local Camera = __index(workspace, "CurrentCamera")
local FindFirstChild = __index(game, "FindFirstChild")
local FindFirstChildOfClass = __index(game, "FindFirstChildOfClass")
local GetDescendants = __index(game, "GetDescendants")
local WorldToViewportPoint = __index(Camera, "WorldToViewportPoint")
local GetPartsObscuringTarget = __index(Camera, "GetPartsObscuringTarget")
local GetMouseLocation = __index(UserInputService, "GetMouseLocation")
local GetConnectedGamepads = __index(UserInputService, "GetConnectedGamepads")
local GetPlayers = __index(Players, "GetPlayers")
-- Variables
local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity, OriginalWalkSpeed = 2000, false, false, {}, nil, nil, nil
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
RainbowSpeed = 1
},
Settings = {
Enabled = true,
TeamCheck = false,
AliveCheck = true,
WallCheck = false,
OffsetToMoveDirection = false,
OffsetIncrement = 15,
-- Aiming settings
LockMode = 2, -- 2 = mousemoverel (best for both KBM + controller)
Sensitivity = 0, -- CFrame only (ignore if LockMode=2)
Sensitivity2 = 0.65, -- LOWERED: mousemoverel speed (less aggressive for lock)
SmoothingFactor = 0.18, -- LOWERED: ultra-smooth controller lock (0.12-0.25 range)
LockPart = "Head",
PredictionLeadTime = 0.12, -- Global prediction time (ms); auto-adjusts higher for controller
DeadzonePixels = 5, -- NEW: Ignore tiny deltas (prevents drift)
MaxMovePerFrame = 12, -- NEW: Cap movement (no big jumps fighting input)
-- Walk to Target
WalkToTarget = false,
WalkSpeedMultiplier = 1.2,
-- Trigger keys (BOTH work at the same time!)
TriggerKey = Enum.UserInputType.MouseButton2, -- Right click for KBM
TriggerKeyController = Enum.KeyCode.ButtonL2, -- L2 for controller
Toggle = false -- false = hold-to-aim (recommended)
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
-- NEW: Get predicted position (used in selection + aiming for consistent lock)
local GetPredictedPosition = function(Character, LockPart)
local currentPos = __index(Character[LockPart], "Position")
local RootPart = FindFirstChild(Character, "HumanoidRootPart")
if RootPart then
local vel = __index(RootPart, "AssemblyLinearVelocity") or __index(RootPart, "Velocity") or Vector3zero
local connectedPads = GetConnectedGamepads(UserInputService)
local leadTime = (#connectedPads > 0) and (Environment.Settings.PredictionLeadTime * 1.25) or Environment.Settings.PredictionLeadTime -- Controller: +25% lead
return currentPos + (vel * leadTime)
end
return currentPos
end
local CancelLock = function()
Environment.Locked = nil
local FOVCircle = Environment.FOVCircle
setrenderproperty(FOVCircle, "Color", Environment.FOVSettings.Color)
__newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)
if Animation then Animation:Cancel() end
-- Restore walk speed
local char = __index(LocalPlayer, "Character")
if char then
local hum = FindFirstChildOfClass(char, "Humanoid")
if hum and OriginalWalkSpeed then
__newindex(hum, "WalkSpeed", OriginalWalkSpeed)
end
end
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
local predictedPos = GetPredictedPosition(Character, LockPart)
local TeamCheckOption = Environment.DeveloperSettings.TeamCheckOption
if Settings.TeamCheck and __index(Value, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then continue end
if Settings.AliveCheck and __index(Humanoid, "Health") <= 0 then continue end
if Settings.WallCheck then
local currentPos = __index(Character[LockPart], "Position")
local BlacklistTable = GetDescendants(__index(LocalPlayer, "Character"))
for _, v in next, GetDescendants(Character) do
BlacklistTable[#BlacklistTable + 1] = v
end
if #GetPartsObscuringTarget(Camera, {currentPos}, BlacklistTable) > 0 then continue end
end
local Vector, OnScreen = WorldToViewportPoint(Camera, predictedPos)
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
local char = __index(LocalPlayer, "Character")
if char then
local hum = FindFirstChildOfClass(char, "Humanoid")
if hum then
OriginalWalkSpeed = __index(hum, "WalkSpeed")
end
end
local Settings = Environment.Settings
local FOVCircle = Environment.FOVCircle
local FOVCircleOutline = Environment.FOVCircleOutline
local FOVSettings = Environment.FOVSettings
ServiceConnections.RenderSteppedConnection = Connect(RunService[Environment.DeveloperSettings.UpdateMode], function()
local OffsetToMoveDirection = Settings.OffsetToMoveDirection
local LockPart = Settings.LockPart
-- FOV Circle
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
local LockedChar = __index(Environment.Locked, "Character")
local predictedPos = GetPredictedPosition(LockedChar, LockPart) + Offset
local LockedPosition_Vector3 = predictedPos
local LockedPosition = WorldToViewportPoint(Camera, LockedPosition_Vector3)
if Settings.LockMode == 2 then
-- FIXED: Controller-optimized mousemoverel (NO DRIFT + TRUE LOCK)
local mouseLoc = GetMouseLocation(UserInputService)
local deltaX = LockedPosition.X - mouseLoc.X
local deltaY = LockedPosition.Y - mouseLoc.Y
local deadzone = Settings.DeadzonePixels
if mathabs(deltaX) < deadzone and mathabs(deltaY) < deadzone then
-- DEADZONE: On target? NO MOVEMENT (perfect lock, no jitter)
else
local controllerFactor = (#GetConnectedGamepads(UserInputService) > 0) and 0.85 or 1.0
local moveX = deltaX * Settings.Sensitivity2 * Settings.SmoothingFactor * controllerFactor
local moveY = deltaY * Settings.Sensitivity2 * Settings.SmoothingFactor * controllerFactor
-- CLAMP: Prevent big jumps fighting input
local maxMove = Settings.MaxMovePerFrame
moveX = mathclamp(moveX, -maxMove, maxMove)
moveY = mathclamp(moveY, -maxMove, maxMove)
mousemoverel(moveX, moveY)
end
else
-- CFrame mode (unchanged)
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
-- Walk to Target
if Settings.WalkToTarget then
local myChar = __index(LocalPlayer, "Character")
local myHumanoid = myChar and FindFirstChildOfClass(myChar, "Humanoid")
local myRoot = myChar and FindFirstChild(myChar, "HumanoidRootPart")
local targetRoot = FindFirstChild(LockedChar, LockPart)
if myHumanoid and myRoot and targetRoot then
local direction = (targetRoot.Position - myRoot.Position).Unit
local distance = (targetRoot.Position - myRoot.Position).Magnitude
if distance > 5 then
__newindex(myHumanoid, "MoveDirection", direction)
if Settings.WalkSpeedMultiplier ~= 1 then
__newindex(myHumanoid, "WalkSpeed", OriginalWalkSpeed * Settings.WalkSpeedMultiplier)
end
else
__newindex(myHumanoid, "MoveDirection", Vector3zero)
end
end
end
else
-- No lock → reset walk
if Settings.WalkToTarget then
local myChar = __index(LocalPlayer, "Character")
local myHumanoid = myChar and FindFirstChildOfClass(myChar, "Humanoid")
if myHumanoid then
if OriginalWalkSpeed then
__newindex(myHumanoid, "WalkSpeed", OriginalWalkSpeed)
end
__newindex(myHumanoid, "MoveDirection", Vector3zero)
end
end
end
else
-- Not running → reset
if Settings.WalkToTarget then
local myChar = __index(LocalPlayer, "Character")
local myHumanoid = myChar and FindFirstChildOfClass(myChar, "Humanoid")
if myHumanoid and OriginalWalkSpeed then
__newindex(myHumanoid, "WalkSpeed", OriginalWalkSpeed)
__newindex(myHumanoid, "MoveDirection", Vector3zero)
end
end
end
end)
-- Dual input (KBM + Controller)
ServiceConnections.InputBeganConnection = Connect(UserInputService.InputBegan, function(input, gameProcessed)
if gameProcessed or Typing then return end
local trigKBM = Settings.TriggerKey
local trigController = Settings.TriggerKeyController
local activated = false
if input.UserInputType == trigKBM or input.KeyCode == trigKBM then
activated = true
end
if trigController and (input.KeyCode == trigController or (input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == trigController)) then
activated = true
end
if activated then
if Settings.Toggle then
Running = not Running
if not Running then CancelLock() end
else
Running = true
end
end
end)
ServiceConnections.InputEndedConnection = Connect(UserInputService.InputEnded, function(input, gameProcessed)
if gameProcessed or Typing then return end
local trigKBM = Settings.TriggerKey
local trigController = Settings.TriggerKeyController
local deactivated = false
if input.UserInputType == trigKBM or input.KeyCode == trigKBM then
deactivated = true
elseif trigController and (input.KeyCode == trigController or (input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == trigController)) then
deactivated = true
end
if deactivated and not Settings.Toggle then
Running = false
CancelLock()
end
end)
end
-- Typing Check
ServiceConnections.TypingStartedConnection = Connect(UserInputService.TextBoxFocused, function() Typing = true end)
ServiceConnections.TypingEndedConnection = Connect(UserInputService.TextBoxFocusReleased, function() Typing = false end)
-- Public Methods
function Environment.Exit(self)
assert(self, "EXUNYS_AIMBOT-V3.Exit: Missing parameter #1 \"self\" <table>.")
for Index, _ in next, ServiceConnections do
if ServiceConnections[Index] then
Disconnect(ServiceConnections[Index])
end
end
local char = __index(LocalPlayer, "Character")
if char then
local hum = FindFirstChildOfClass(char, "Humanoid")
if hum and OriginalWalkSpeed then
__newindex(hum, "WalkSpeed", OriginalWalkSpeed)
end
end
Load = nil; ConvertVector = nil; CancelLock = nil; GetClosestPlayer = nil; GetPredictedPosition = nil; GetRainbowColor = nil; FixUsername = nil
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
