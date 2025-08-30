-- Hapus GUI lama jika ada
pcall(function() game.CoreGui:FindFirstChild("PremiumDeliveryGUI"):Destroy() end)

-- Ambil service dan data pemain
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local plots = workspace:WaitForChild("Plots")

-- GUI Baru Setup
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "PremiumDeliveryGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 176, 0, 104)
frame.Position = UDim2.new(0.1, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- Judul
local title = Instance.new("TextLabel", frame)
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 25)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Steal Helper"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16

-- Garis bawah judul
local garis = Instance.new("Frame", frame)
garis.Size = UDim2.new(1, -20, 0, 1)
garis.Position = UDim2.new(0, 10, 0, 25)
garis.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
garis.BorderSizePixel = 0

-- Tombol Toggle
local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Name = "ToggleButton"
toggleBtn.Size = UDim2.new(0.90, 0, 0, 34) -- Dibesar 20% dari ukuran awal
toggleBtn.Position = UDim2.new(0.05, 0, 0, 42) -- Disesuaikan agar tetap di tengah
toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamSemibold
toggleBtn.TextSize = 14
toggleBtn.Text = "▶ Start"
toggleBtn.AutoButtonColor = false
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
--
-- Hover Effect
toggleBtn.MouseEnter:Connect(function()
	toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
end)
toggleBtn.MouseLeave:Connect(function()
	if active then
		toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
	else
		toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	end
end)

-- Logic
local speed = 35
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

	local closestHitbox = getClosestHitbox(myHitbox, 200)
	if not closestHitbox then warn("Tidak ada DeliveryHitbox lain dalam jarak 200 studs.") return end

	local currentGoal = closestHitbox.Position + Vector3.new(0, 3, 0)
	local phase = "ToClosest"
	arrived = false

	jumpLoop = task.spawn(function()
		while active and not arrived do
			if humanoid.FloorMaterial ~= Enum.Material.Air then
				humanoid.JumpPower = phase == "ToClosest" and 50 or 100
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
			task.wait(0.3)
		end
	end)

	moveConn = RunService.Heartbeat:Connect(function()
		if not active or arrived then return end
		if (humanoidRootPart.Position - currentGoal).Magnitude < 5 then
			if phase == "ToClosest" then
				phase = "ToMyBase"
				currentGoal = myHitbox.Position + Vector3.new(0, 3, 0)
			else
				arrived = true
				cleanup()
				active = false
				toggleBtn.Text = "▶ Start"
				toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
			end
			return
		end
		local dir = (currentGoal - humanoidRootPart.Position).Unit
		humanoidRootPart.Velocity = Vector3.new(dir.X * speed, humanoidRootPart.Velocity.Y, dir.Z * speed)
	end)
end

toggleBtn.MouseButton1Click:Connect(function()
	if active then
		active = false
		toggleBtn.Text = "▶ Start"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
		cleanup()
	else
		if not humanoidRootPart or not humanoid then return warn("Karakter belum siap.") end
		active = true
		arrived = false
		toggleBtn.Text = "■ Stop"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
		runDelivery()
	end
end)

Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")
	cleanup()
	if active then task.wait(1) runDelivery() end
end)



        task.wait(1) -- beri jeda biar GUI keburu siap
game:GetService("StarterGui"):SetCore("SendNotification", {
	Title = "Equip Invisibility Cloak!",
	Text = "The script only works if you equip Invisibility Cloak",
	Duration = 4
})
