-- Servicios
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- Remotes
local RFCoinsShopServiceRequestBuy = ReplicatedStorage.Packages.Net["RF/CoinsShopService/RequestBuy"]
local REUseItem = ReplicatedStorage.Packages.Net["RE/UseItem"]

local toolName = "Taser Gun"
local activePrompts = {}
local holdDetected = {}
local running = false

-- Equipar Taser Gun
local function equipTaser()
    local success, _ = pcall(function()
        RFCoinsShopServiceRequestBuy:InvokeServer(toolName)
    end)
    task.wait(0.5)
    local tool = player.Backpack:FindFirstChild(toolName)
    if tool then
        player.Character.Humanoid:EquipTool(tool)
        StarterGui:SetCore("SendNotification", {Title="Taser", Text="Taser equipada", Duration=3})
    end
end

-- Usar Taser Gun sobre nosotros mismos para boost
local function taserBoost()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        REUseItem:FireServer(hrp)
        -- Movimiento rápido hacia adelante
        hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 20
        StarterGui:SetCore("SendNotification", {Title="Taser", Text="Taser activada para boost", Duration=2})
    end
end

-- Detectar prompts de Steal
local function addPrompt(prompt)
    if prompt:IsA("ProximityPrompt") and prompt.ActionText == "Steal" and not activePrompts[prompt] then
        activePrompts[prompt] = prompt
        holdDetected[prompt] = false
        prompt.Triggered:Connect(function(plr)
            if plr == player then
                holdDetected[prompt] = true
                StarterGui:SetCore("SendNotification", {Title="Steal detectado", Text="Activando Taser para recorrido", Duration=3})
                taserBoost()
            end
        end)
    end
end

-- Escanear zonas del mapa
local function scanZones()
    for _, zone in pairs({"Plots", "AnimalPodiums", "Base", "Spawn"}) do
        if workspace:FindFirstChild(zone) then
            for _, obj in pairs(workspace[zone]:GetDescendants()) do
                addPrompt(obj)
            end
        end
    end
end

-- Loop principal
RunService.Heartbeat:Connect(function()
    if running then
        scanZones()
    end
end)

-- Iniciar / Detener
local function startTaser()
    running = true
    activePrompts = {}
    holdDetected = {}
    equipTaser()
end

local function stopTaser()
    running = false
    activePrompts = {}
    holdDetected = {}
end

-- GUI simple toggle
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "TaserToggleGUI"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 150, 0, 50)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.2
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local toggleButton = Instance.new("TextButton", frame)
toggleButton.Size = UDim2.new(1, -10, 1, -10)
toggleButton.Position = UDim2.new(0, 5, 0, 5)
toggleButton.Text = "🔴 OFF"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 20
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
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
