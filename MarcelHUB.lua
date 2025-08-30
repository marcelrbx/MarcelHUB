-- Hapus GUI lama jika ada
pcall(function()
	game.CoreGui:FindFirstChild("StealHelper"):Destroy()
end)

-- Ambil service
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Net events/tools
local RFCoinsShopServiceRequestBuy = ReplicatedStorage.Packages.Net["RF/CoinsShopService/RequestBuy"]
local REUseItem = ReplicatedStorage.Packages.Net["RE/UseItem"]
local toolName = "Taser Gun"

-- Estado
local running = false
local activePrompts = {}
local holdDetected = {}

-- GUI Utama
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "StealHelper"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 220)
frame.Position = UDim2.new(0.5, -120, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 20)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.new(0, 10, 0, 4)
title.Text = "Steal Helper | Taser"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left

-- Funciones del Taser
local function buyAndEquip()
    local success, result = pcall(function()
        return RFCoinsShopServiceRequestBuy:InvokeServer(toolName)
    end)
    if not success then warn("Error al comprar:", result) end

    task.wait(0.5)
    local tool = player.Backpack:FindFirstChild(toolName)
    if tool then player.Character.Humanoid:EquipTool(tool) end
end

local function useTaserAndTeleport()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        REUseItem:FireServer(hrp)
        hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 20
    end
end

local function addPrompt(prompt)
    if prompt:IsA("ProximityPrompt") and prompt.ActionText == "Steal" and not activePrompts[prompt] then
        activePrompts[prompt] = prompt
        holdDetected[prompt] = false
        prompt.Triggered:Connect(function(plr)
            if plr == player then holdDetected[prompt] = true end
        end)
    end
end

local function scanForPrompts(parent)
    for _, obj in pairs(parent:GetDescendants()) do
        addPrompt(obj)
    end
end

local function scanSpecificZones()
    if workspace:FindFirstChild("Plots") then
        for _, model in pairs(workspace.Plots:GetChildren()) do
            scanForPrompts(model)
        end
    end
    if workspace:FindFirstChild("AnimalPodiums") then
        for _, model in pairs(workspace.AnimalPodiums:GetChildren()) do
            scanForPrompts(model)
        end
    end
    if workspace:FindFirstChild("Base") then scanForPrompts(workspace.Base) end
    if workspace:FindFirstChild("Spawn") then scanForPrompts(workspace.Spawn) end
end

RunService.Heartbeat:Connect(function()
    if running then
        scanSpecificZones()
        for _, prompt in pairs(activePrompts) do
            if prompt and prompt.Parent then
                if prompt:IsHeld() and not holdDetected[prompt] then
                    local progress = prompt:GetHoldProgress()
                    if progress >= 1 - (0.3 / prompt.HoldDuration) then
                        holdDetected[prompt] = true
                        useTaserAndTeleport()
                    end
                elseif not prompt:IsHeld() then
                    holdDetected[prompt] = false
                end
            end
        end
    end
end)

local function startTaser()
    running = true
    activePrompts = {}
    holdDetected = {}
    buyAndEquip()
end

local function stopTaser()
    running = false
    activePrompts = {}
    holdDetected = {}
end

-- Crear botones estilo menú
local function createButton(name, yPos, callback)
    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(0.9, 0, 0, 36)
    button.Position = UDim2.new(0.05, 0, 0, yPos)
    button.Text = name
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    button.TextColor3 = Color3.fromRGB(230, 230, 230)
    button.Font = Enum.Font.Gotham
    button.TextSize = 18
    button.BorderSizePixel = 0
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 12)
    button.MouseButton1Click:Connect(callback)
end

-- Botón de toggle principal
createButton("▶ Start Taser", 60, function()
    if running then stopTaser() else startTaser() end
end)
