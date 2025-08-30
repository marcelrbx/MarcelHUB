-- Hapus GUI lama jika ada
pcall(function()
	game.CoreGui:FindFirstChild("StealHelper"):Destroy()
end)

-- Ambil service
local CoreGui = game:GetService("CoreGui")

-- GUI Utama
local gui = Instance.new("ScreenGui")
gui.Name = "StealHelper"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

-- Efek Bayangan Luar
local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(0, 240, 0, 220)
shadow.Position = UDim2.new(0.5, -120, 0.5, -110)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.4
shadow.BorderSizePixel = 0
shadow.ZIndex = 0
shadow.Parent = gui

local shadowCorner = Instance.new("UICorner", shadow)
shadowCorner.CornerRadius = UDim.new(0, 20)

-- Frame Utama
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 220)
frame.Position = UDim2.new(0.5, -120, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
frame.BorderSizePixel = 0
frame.ZIndex = 1
frame.Parent = gui

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 20)

-- Judul
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.new(0, 10, 0, 4)
title.Text = "Steal Helper | choose "
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 2
title.Parent = frame

-- Garis bawah judul
local underline = Instance.new("Frame")
underline.Size = UDim2.new(1, -20, 0, 1)
underline.Position = UDim2.new(0, 10, 0, 44)
underline.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
underline.BorderSizePixel = 0
underline.ZIndex = 1
underline.Parent = frame

-- Fungsi untuk membuat tombol gaya modern
local function createButton(name, yPos, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.9, 0, 0, 36)
	button.Position = UDim2.new(0.05, 0, 0, yPos)
	button.Text = name
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
	button.TextColor3 = Color3.fromRGB(230, 230, 230)
	button.Font = Enum.Font.Gotham
	button.TextSize = 18
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.ZIndex = 2
	button.Parent = frame

	local buttonCorner = Instance.new("UICorner", button)
	buttonCorner.CornerRadius = UDim.new(0, 12)

	local uiStroke = Instance.new("UIStroke", button)
	uiStroke.Thickness = 1
	uiStroke.Color = Color3.fromRGB(80, 80, 100)
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	-- Hover effect
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
	end)

	button.MouseButton1Click:Connect(callback)
end

-- Tambahkan tombol
createButton("Base Flor 1", 60, function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/NabaruBrainrot/Tempat-Penyimpanan-Roblox-Brainrot-/refs/heads/main/Instan%20Steal%20Normal"))()
end)

createButton("Base Flor 2", 110, function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/NabaruBrainrot/Tempat-Penyimpanan-Roblox-Brainrot-/refs/heads/main/Steal%20Helper%20Flor%202"))()
end)

createButton("Base Flor 3", 160, function()
	loadstring(game:HttpGet("https://pastebin.com/raw/zzzzzFlor3"))()
end)
