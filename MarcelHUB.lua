-- Services
local CoreGui = game:GetService("CoreGui")

-- Hapus GUI lama
pcall(function()
    if CoreGui:FindFirstChild("FaDhenGui") then
        CoreGui.FaDhenGui:Destroy()
    end
end)

-- ScreenGui utama
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FaDhenGui"
ScreenGui.Parent = CoreGui

-- Tombol Open di kiri atas
local openButton = Instance.new("TextButton")
openButton.Size = UDim2.new(0, 70, 0, 35)
openButton.Position = UDim2.new(0, 35, 0, 20)
openButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.Text = "Open"
openButton.Font = Enum.Font.SourceSansBold
openButton.TextSize = 16
openButton.Parent = ScreenGui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0,8)
openCorner.Parent = openButton

-- Frame GUI utama
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 300)
mainFrame.Position = UDim2.new(0.5, -100, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = ScreenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0,12)
frameCorner.Parent = mainFrame

-- Tombol Close di pojok kanan atas frame
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 35, 0, 25)
closeButton.Position = UDim2.new(1, -40, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(180,50,50)
closeButton.TextColor3 = Color3.fromRGB(255,255,255)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0,6)
closeCorner.Parent = closeButton

-- ScrollingFrame untuk toggle buttons
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -50)
scrollFrame.Position = UDim2.new(0, 10, 0, 40)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0,0,0,0)
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Parent = scrollFrame
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0,6)

-- Auto update tinggi CanvasSize biar full scroll
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

-- Tabel global toggle buttons
_G.FaDhenToggles = {}

-- Fungsi AddToggle
function _G.FaDhenAddToggle(name, props)
    local callback = props.Callback

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,35)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Text = name.." [OFF]"
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Parent = scrollFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,8)
    corner.Parent = btn

    local toggled = false
    btn.MouseButton1Click:Connect(function()
        toggled = not toggled
        btn.Text = name.." ["..(toggled and "ON" or "OFF").."]"
        if callback then
            callback(toggled)
        end
    end)

    _G.FaDhenToggles[name] = btn
end

-- Tombol Open
openButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
end)

-- Tombol Close
closeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)


_G.FaDhenAddToggle("Chilli Hub", {
    Name = "Chilli Hub",
    Callback = function(on)
        if on then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/NabaruBrainrot/Tempat-Penyimpanan-Roblox-Brainrot-/refs/heads/main/Delfi%20"))()
        end
    end
})






local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Net = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))

-- flag toggle
getgenv().FaDhenAutoAim = getgenv().FaDhenAutoAim or false

-- cari player terdekat
local function getNearestPlayer()
    local nearestPlayer = nil
    local shortestDistance = math.huge
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end

    local myPos = myChar.HumanoidRootPart.Position
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
            if dist < shortestDistance then
                shortestDistance = dist
                nearestPlayer = player
            end
        end
    end
    return nearestPlayer
end

-- fungsi pasang auto aim ke tool
local function hookTool(tool)
    if tool:IsA("Tool") and not tool:FindFirstChild("FaDhenHooked") then
        local marker = Instance.new("BoolValue")
        marker.Name = "FaDhenHooked"
        marker.Parent = tool

        tool.Activated:Connect(function()
            if getgenv().FaDhenAutoAim then
                local nearest = getNearestPlayer()
                if nearest and nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = nearest.Character.HumanoidRootPart
                    Net:RemoteEvent("UseItem"):FireServer(hrp.Position, hrp)
                    return
                end
            end

            -- fallback: pakai mouse
            local PlayerMouse = require(ReplicatedStorage.Packages.PlayerMouse)
            Net:RemoteEvent("UseItem"):FireServer(PlayerMouse.Hit.Position, PlayerMouse.Target)
        end)
    end
end

-- pasang hook ke semua tool di backpack
local function hookBackpack()
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        hookTool(tool)
    end
    LocalPlayer.Backpack.ChildAdded:Connect(hookTool)
end

-- saat karakter respawn, pasang ulang
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1) -- beri delay kecil supaya Backpack terisi
    hookBackpack()
end)

-- pertama kali load
hookBackpack()

-- Toggle UI
_G.FaDhenAddToggle("AimBot", {
    Callback = function(on)
        getgenv().FaDhenAutoAim = on
    end
})







--=== ESP PLAYER (FaDhen Toggle) ===--
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- reuse global table supaya aman kalau script di-execute ulang
local FaESP = getgenv().FaDhenESP or {}
getgenv().FaDhenESP = FaESP

FaESP.Enabled = FaESP.Enabled or false
FaESP.Connections = FaESP.Connections or {}

local function destroyESPFromCharacter(character)
	if character:FindFirstChild("ESP_Highlight") then
		character.ESP_Highlight:Destroy()
	end
	local head = character:FindFirstChild("Head")
	if head and head:FindFirstChild("ESP_Name") then
		head.ESP_Name:Destroy()
	end
end

local function applyESPToCharacter(player, character)
	if player == localPlayer then return end
	if not character then return end

	local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 5)
	if not head then return end

	destroyESPFromCharacter(character)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESP_Name"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 100, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 1.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = player.DisplayName -- pakai nama cadangan (DisplayName)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Font = Enum.Font.SourceSansBold
	label.TextScaled = true
	label.Parent = billboard

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.Adornee = character
	highlight.FillColor = Color3.new(1, 0, 0)
	highlight.FillTransparency = 0.5
	highlight.OutlineColor = Color3.new(0, 0, 0)
	highlight.OutlineTransparency = 0.2
	highlight.Parent = character
end

local function trackPlayer(player)
	if player == localPlayer then return end
	if player.Character then
		applyESPToCharacter(player, player.Character)
	end
	FaESP.Connections[player] = player.CharacterAdded:Connect(function(character)
		applyESPToCharacter(player, character)
	end)
end

local function untrackPlayer(player)
	if FaESP.Connections[player] then
		FaESP.Connections[player]:Disconnect()
		FaESP.Connections[player] = nil
	end
	if player ~= localPlayer and player.Character then
		destroyESPFromCharacter(player.Character)
	end
end

function FaESP:Enable()
	if self.Enabled then return end
	self.Enabled = true
	for _, plr in ipairs(Players:GetPlayers()) do
		trackPlayer(plr)
	end
	self.Connections._PlayerAdded = Players.PlayerAdded:Connect(function(plr)
		trackPlayer(plr)
	end)
	self.Connections._PlayerRemoving = Players.PlayerRemoving:Connect(function(plr)
		untrackPlayer(plr)
	end)
end

function FaESP:Disable()
	if not self.Enabled then return end
	self.Enabled = false
	for key, conn in pairs(self.Connections) do
		if conn and conn.Disconnect then
			conn:Disconnect()
		end
		self.Connections[key] = nil
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= localPlayer and plr.Character then
			destroyESPFromCharacter(plr.Character)
		end
	end
end

--=== Toggle baru pakai FaDhen ===--
_G.FaDhenAddToggle("ESP Player", {
    Callback = function(on)
        if on then
            FaESP:Enable()
        else
            FaESP:Disable()
        end
    end
})








_G.FaDhenAddToggle("Lock Base", {
    Name = "Lock Base",
    Callback = function(on)
        if on then
            
            loadstring(game:HttpGet("https://pastebin.com/raw/makzCS0N"))()
        end
    end
})



-- Services
local CoreGui = game:GetService("CoreGui")
local protect = syn and syn.protect_gui or fluxus and fluxus.protect_gui or function() end

-- Buat GUI (default disembunyikan)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SentryTeleportGUI"
ScreenGui.ResetOnSpawn = false
protect(ScreenGui)
ScreenGui.Parent = (gethui and gethui()) or CoreGui
ScreenGui.Enabled = false  -- awalnya tidak tampil

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(0, 100, 0, 30)  
Button.Position = UDim2.new(0, 10, 0, 60) 
Button.AnchorPoint = Vector2.new(0,0)
Button.Text = "Tp Sentry"
Button.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
Button.TextColor3 = Color3.new(0, 0, 0)
Button.BorderSizePixel = 2
Button.Parent = ScreenGui

-- Fungsi teleport
local function teleportParts()
    local player = game.Players.LocalPlayer
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

    local hrp = player.Character.HumanoidRootPart

    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("BasePart") and obj.Name:match("^Sentry_") then
            local targetCFrame = hrp.CFrame + hrp.CFrame.LookVector * 2
            obj.Anchored = false
            obj.CFrame = targetCFrame
        end
    end
end

Button.MouseButton1Click:Connect(teleportParts)

-- 🔥 Hubungkan ke toggle
_G.FaDhenAddToggle("Tp Sentry", {
    Callback = function(on)
        if on then
            ScreenGui.Enabled = true   -- munculkan GUI
        else
            ScreenGui.Enabled = false  -- sembunyikan GUI
        end
    end
})




-- Load Anti Steal
loadstring(game:HttpGet("https://raw.githubusercontent.com/NabaruBrainrot/Tempat-Penyimpanan-Roblox-Brainrot-/refs/heads/main/Anti%20Steal"))()

-- Tambahkan toggle di GUI
_G.FaDhenAddToggle("Anti Steal", {
    Name = "Anti Steal",
    Callback = function(on)
        if getgenv().AntiSteal_SetEnabled then
            getgenv().AntiSteal_SetEnabled(on)
        else
            warn("Anti Steal belum siap!")
        end
    end
})










local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local screenGui
local function createMainGui()
    if screenGui then return screenGui end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UtilityGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = gui

    -- FRAME UTAMA UNTUK BUTTON
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 200, 0, 32)
    frame.Position = UDim2.new(0.5, 0, 0.02, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = screenGui

    -- RESET BUTTON
    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0, 90, 1, 0)
    resetBtn.Position = UDim2.new(0, 0, 0, 0)
    resetBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    resetBtn.TextColor3 = Color3.new(1, 1, 1)
    resetBtn.Text = "Reset"
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 14
    resetBtn.Parent = frame
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 6)

    resetBtn.MouseButton1Click:Connect(function()
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.Health = 0 end
    end)

    -- LEAVE BUTTON
    local leaveBtn = Instance.new("TextButton")
    leaveBtn.Size = UDim2.new(0, 90, 1, 0)
    leaveBtn.Position = UDim2.new(0, 100, 0, 0)
    leaveBtn.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
    leaveBtn.TextColor3 = Color3.new(1, 1, 1)
    leaveBtn.Text = "Leave"
    leaveBtn.Font = Enum.Font.GothamBold
    leaveBtn.TextSize = 14
    leaveBtn.Parent = frame
    Instance.new("UICorner", leaveBtn).CornerRadius = UDim.new(0, 6)

    leaveBtn.MouseButton1Click:Connect(function()
        game:Shutdown()
    end)

    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        if not gui:FindFirstChild("UtilityGui") then
            screenGui.Parent = gui
        end
    end)

    return screenGui
end

--=== Toggle baru pakai FaDhen ===--
_G.FaDhenAddToggle("Exit Button", {
    Callback = function(on)
        if on then
            createMainGui().Enabled = true
        else
            if screenGui then
                screenGui.Enabled = false
            end
        end
    end
})









--Script lain


local DEBUG = false
local BATCH_SIZE = 250
local SEARCH_TRAPS_IN_GAME = false

local function dprint(...) if DEBUG then print(...) end end

local function processBillboardIfNeeded(obj)
	if not (obj:IsA("BasePart") and obj.Name == "Main") then return end
	if obj:GetAttribute("BillboardProcessed") then return end
	local parent = obj.Parent
	local ok = false
	while parent do
		if parent:IsA("Folder") and parent.Name == "Purchases" then ok = true break end
		parent = parent.Parent
	end
	if not ok then return end
	for _, child in ipairs(obj:GetChildren()) do
		if child:IsA("BillboardGui") then
			child.Size = UDim2.new(0, 180, 0, 150)
			child.MaxDistance = 90
			child.StudsOffset = Vector3.new(0, 5, 0)
			dprint("✅ BillboardGui diubah:", obj:GetFullName())
		end
	end
	obj:SetAttribute("BillboardProcessed", true)
end

task.defer(function()
	local all = workspace:GetDescendants()
	for i = 1, #all do
		processBillboardIfNeeded(all[i])
		if i % BATCH_SIZE == 0 then task.wait() end
	end
end)

workspace.DescendantAdded:Connect(processBillboardIfNeeded)
