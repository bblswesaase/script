-- Noclip Toggle Script (2025-2026 safe version)
-- Works in most games that use Humanoid / BasePart collision
-- Compatible with most exploits (Synapse, Script-Ware, etc.)

getgenv().noclicp = {
	enabled = false,
	speed_multiplier = 1.0,             -- optional: move faster while noclipping
	ignore_list = {                     -- parts that should NOT be noclipped (rarely needed)
		"HumanoidRootPart",
		"Head"
	}
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- State variables
local noclipConnection = nil
local originalCollisions = {}

-- Function to toggle noclip
local function toggleNoclip()
	getgenv().noclicp.enabled = not getgenv().noclicp.enabled

	if getgenv().noclicp.enabled then
		-- Store original CanCollide states
		originalCollisions = {}
		for _, part in ipairs(Character:GetDescendants()) do
			if part:IsA("BasePart") and not table.find(getgenv().noclicp.ignore_list, part.Name) then
				originalCollisions[part] = part.CanCollide
				part.CanCollide = false
			end
		end

		-- Optional: slightly increase walkspeed while noclipping
		Humanoid.WalkSpeed = Humanoid.WalkSpeed * getgenv().noclicp.speed_multiplier

		-- Main noclip loop (makes sure CanCollide stays false)
		noclipConnection = RunService.Stepped:Connect(function()
			if not getgenv().noclicp.enabled then return end
			if not Character or not Character.Parent then return end

			for _, part in ipairs(Character:GetDescendants()) do
				if part:IsA("BasePart") and not table.find(getgenv().noclicp.ignore_list, part.Name) then
					part.CanCollide = false
				end
			end
		end)

		print("[Noclip] Enabled")
	else
		-- Restore original collision states
		for part, wasCollidable in pairs(originalCollisions) do
			if part and part.Parent then
				part.CanCollide = wasCollidable
			end
		end

		-- Reset walkspeed
		Humanoid.WalkSpeed = 16  -- default Roblox walkspeed (change if needed)

		-- Disconnect loop
		if noclipConnection then
			noclipConnection:Disconnect()
			noclipConnection = nil
		end

		print("[Noclip] Disabled")
	end
end



-- Handle character respawn / reset
LocalPlayer.CharacterAdded:Connect(function(newChar)
	Character = newChar
	Humanoid = newChar:WaitForChild("Humanoid")
	RootPart = newChar:WaitForChild("HumanoidRootPart")

	-- If noclip was enabled, re-apply it
	if getgenv().noclicp.enabled then
		task.wait(0.5) -- small delay for character to fully load
		toggleNoclip()   -- disable first
		task.wait(0.1)
		toggleNoclip()   -- re-enable
	end
end)

-- Optional: command to toggle via executor console
getgenv().toggleNoclip = toggleNoclip

-- Initial status
