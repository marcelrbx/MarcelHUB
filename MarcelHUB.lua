-- Hapus GUI lama jika ada
pcall(function() game.CoreGui:FindFirstChild("PremiumDeliveryGUI"):Destroy() end)

-- Ambil service dan data pemain
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local plots = workspace:WaitForChild("Plots")

-- GUI Setup
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "PremiumDeliveryGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 192, 0, 88) -- 20% lebih kecil dari 240x110
frame.Position = UDim2.new(0, 30, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.02
frame.Parent = gui
frame.Active = true
frame.Draggable = true

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(0, 180, 255)
stroke.Thickness = 1.6
stroke.Transparency = 0.1

local title = Instance.new("TextLabel", frame)
title.Name = "TitleLabel"
title.Size = UDim2.new(1, 0, 0, 24)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Instan Steal"
title.Font = Enum.Font.GothamBlack
title.TextColor3 = Color3.fromRGB(230, 230, 230)
title.TextSize = 17
title.TextStrokeTransparency = 0.8

local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Name = "ToggleButton"
toggleBtn.Size = UDim2.new(1, -20, 0, 42)
toggleBtn.Position = UDim2.new(0, 10, 0, 36)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.Text = "Start"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 15
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.BorderSizePixel = 0
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

-- Logic
local speed = 42
local arrived = false
local active = false
local jumpLoop = nil
local moveConn = nil

local function getClosestHitbox(excludeHitbox, maxDistance)
	local closest = nil
	local shortest = maxDistance
	for _, base in pairs(plots:GetChildren()) do
		if base:IsA("Model") then
			local deliveryHitbox = base:FindFirstChild("DeliveryHitbox", true)
			if deliveryHitbox and deliveryHitbox ~= excludeHitbox then
				local dist = (humanoidRootPart.Position - deliveryHitbox.Position).Magnitude
				if dist < shortest then
					shortest = dist
					closest = deliveryHitbox
				end
			end
		end
	end
	return closest
end

local function findMyHitbox()
	for _, base in pairs(plots:GetChildren()) do
		if base:IsA("Model") then
			for _, desc in pairs(base:GetDescendants()) do
				if desc:IsA("TextLabel") and (string.find(desc.Text, player.Name) or string.find(desc.Text, player.DisplayName)) then
					return base:FindFirstChild("DeliveryHitbox", true)
				end
			end
		end
	end
end

local function cleanup()
	arrived = true
	if jumpLoop then task.cancel(jumpLoop) jumpLoop = nil end
	if moveConn then moveConn:Disconnect() moveConn = nil end
	if humanoidRootPart then
		humanoidRootPart.Velocity = Vector3.zero
	end
end

local function runDelivery()
	local myHitbox = findMyHitbox()
	if not myHitbox then warn("Tidak menemukan DeliveryHitbox sendiri.") return end

	local closestHitbox = getClosestHitbox(myHitbox, 50)
	if not closestHitbox then warn("Tidak ada DeliveryHitbox lain dalam 50 studs.") return end

	local currentGoal = closestHitbox.Position + Vector3.new(0, 3, 0)
	local phase = "ToClosest"
	arrived = false

	jumpLoop = task.spawn(function()
		while active and not arrived do
			if phase == "ToClosest" or phase == "ToMyBase" then
				humanoidRootPart.Velocity = Vector3.new(humanoidRootPart.Velocity.X, 120, humanoidRootPart.Velocity.Z)
				task.wait(phase == "ToClosest" and 0.5 or 1.5)
			else
				task.wait(0.5)
			end
		end
	end)

	moveConn = RunService.Heartbeat:Connect(function()
		if not active or arrived then return end

		if (humanoidRootPart.Position - currentGoal).Magnitude < 5 then
			if phase == "ToClosest" then
				phase = "ToMyBase"
				currentGoal = myHitbox.Position + Vector3.new(0, 3, 0)
			elseif phase == "ToMyBase" then
				arrived = true
				cleanup()

				-- Auto Stop
				active = false
				toggleBtn.Text = "Start"
				toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			end
			return
		end

		local direction = (currentGoal - humanoidRootPart.Position).Unit
		humanoidRootPart.Velocity = Vector3.new(direction.X * speed, humanoidRootPart.Velocity.Y, direction.Z * speed)
	end)
end

-- Toggle tombol
toggleBtn.MouseButton1Click:Connect(function()
	if active then
		active = false
		toggleBtn.Text = "Start"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		cleanup()
	else
		if not humanoidRootPart then return warn("Karakter belum siap.") end
		active = true
		arrived = false
		toggleBtn.Text = "Stop"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
		runDelivery()
	end
end)

-- Dengarkan respawn
Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	cleanup()

	if active then
		task.wait(1)
		runDelivery()
	end
end)
