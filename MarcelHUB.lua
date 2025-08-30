local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RFCoinsShopServiceRequestBuy = ReplicatedStorage.Packages.Net["RF/CoinsShopService/RequestBuy"]
local REUseItem = ReplicatedStorage.Packages.Net["RE/UseItem"]

local running = false
local toolName = "Taser Gun"
local activePrompts = {}
local holdDetected = {}

-- 🔹 Funciones
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

-- 🔹 Agregar ProximityPrompt válido
local function addPrompt(prompt)
    if prompt:IsA("ProximityPrompt") and prompt.ActionText == "Steal" and not activePrompts[prompt] then
        activePrompts[prompt] = prompt
        holdDetected[prompt] = false
        prompt.Triggered:Connect(function(plr)
            if plr == player then
                holdDetected[prompt] = true
            end
        end)
    end
end

-- 🔹 Buscar prompts en un modelo o carpeta recursivamente
local function scanForPrompts(parent)
    for _, obj in pairs(parent:GetDescendants()) do
        addPrompt(obj)
    end
end

-- 🔹 Escanear lugares específicos
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

    if workspace:FindFirstChild("Base") then
        scanForPrompts(workspace.Base)
    end

    if workspace:FindFirstChild("Spawn") then
        scanForPrompts(workspace.Spawn)
    end
end

-- 🔹 Loop principal para revisar hold
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

-- 🔹 Iniciar / Detener
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

-- 🔹 GUI Toggle
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "TaserToggleGUI"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 150, 0, 50)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.2
frame.ZIndex = 10
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local toggleButton = Instance.new("TextButton", frame)
toggleButton.Size = UDim2.new(1, -10, 1, -10)
toggleButton.Position = UDim2.new(0, 5, 0, 5)
toggleButton.Text = "🔴 OFF"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 20
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
toggleButton.AutoButtonColor = true
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 10)

toggleButton.MouseButton1Click:Connect(function()
    if running then
        stopTaser()
        toggleButton.Text = "🔴 OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    else
        startTaser()
        toggleButton.Text = "🟢 ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    end
end)
