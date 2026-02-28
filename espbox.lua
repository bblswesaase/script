-- ESP Boxes (fixed - no collapsing to line when facing directly)

getgenv().chams = {
	Enabled = false,
	TeamCheck = false,
	AliveCheck = true,
	Color = Color3.fromRGB(255, 0, 4),  -- yellow/orange
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
	for _, conn in pairs(connections) do pcall(conn.Disconnect, conn) end
	for _, box in pairs(boxes) do pcall(box.Remove, box) end
	boxes = {}
	connections = {}
end

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

		-- IMPROVED BOX CALCULATION
		local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.2, 0))
		local legPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

		local height = math.abs(headPos.Y - legPos.Y)

		-- Width: use real projection + minimum ratio so it never collapses to line
		local widthFromProjection = math.abs(headPos.X - legPos.X) * 2.5
		local minWidth = height * 0.55  -- ~55% of height minimum
		local width = math.max(widthFromProjection, minWidth)

		-- Apply global multiplier
		width = width * getgenv().ESPBoxes.SizeMultiplier
		height = height * 1.3  -- slight vertical stretch

		box.Size = Vector2.new(width, height)
		box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
		box.Visible = true
	end)

	table.insert(connections, conn)
end

local function setup()
	cleanup()
	if not getgenv().ESPBoxes.Enabled then return end

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
	local last = getgenv().ESPBoxes.Enabled
	while true do
		task.wait(0.3)
		if getgenv().ESPBoxes.Enabled ~= last then
			last = getgenv().ESPBoxes.Enabled
			setup()
		end
	end
end)

print("[ESP Boxes] Loaded - toggle with getgenv().ESPBoxes.Enabled")
