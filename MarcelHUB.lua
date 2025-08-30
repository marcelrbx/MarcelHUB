-- Servicios
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- RemoteEvents / Functions
local RFCoinsShopServiceRequestBuy = ReplicatedStorage.Packages.Net["RF/CoinsShopService/RequestBuy"]
local REUseItem = ReplicatedStorage.Packages.Net["RE/UseItem"]

-- Config
local toolName = "Taser Gun"
local running = false
local activePrompts = {}
local holdDetected = {}

-- Función para comprar y equipar Taser Gun
local function buyAndEquip()
    local success, result = pcall(function()
        return RFCoinsShopServiceRequestBuy:InvokeServer(toolName)
    end)
    if success then
        task.wait(0.5)
        local tool = player.Backpack:FindFirstChild(toolName)
        if tool then
            player.Character.Humanoid:EquipTool(tool)
            StarterGui:SetCore("SendNotification", {Title="Taser", Text="Taser Gun equipada", Duration=3})
        end
    else
        StarterGui:SetCore("SendNotification", {Title="Error", Text="No se pudo comprar Taser Gun", Duration=3})
    end
end

-- Función para usar Taser Gun sobre nosotros mismos
local function useTaserAndBoost()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        REUseItem:FireServer(hrp)
        -- Movimiento hacia adelante usando LookVector
        hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 20
        StarterGui:SetCore("SendNotification", {Title="Taser", Text="Taser activada para boost", Duration=2})
    end
end

-- Agregar prompt de Steal
local function addPrompt(prompt)
    if prompt:IsA("ProximityPrompt") and prompt.ActionText == "Steal" and not activePrompts[prompt] then
        activePrompts[prompt] = prompt
        holdDetected[prompt] = false
        StarterGui:SetCore("SendNotification", {Title="Prompt detectado", Text="Se detectó un prompt de Steal", Duration=2})
        prompt.Triggered:Connect(function(plr)
            if plr == player then
                holdDetected[prompt] = true
            end
        end)
    end
end

-- Escanear un padre recursivamente
local function scanForPrompts(parent)
    for _, obj in pairs(parent:GetDescendants()) do
        addPrompt(obj)
    end
end

-- Escanear zonas específicas
local function scanZones()
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

-- Loop principal
RunService.Heartbeat:Connect(function()
    if running then
        scanZones()
        for prompt,_ in pairs(activePrompts) do
            if prompt and prompt.Parent then
                -- Si está siendo sostenido lo usamos
                if prompt:IsHeld() and not holdDetected[prompt] then
                    local progress = prompt:GetHoldProgress()
                    if progress >= 1 - (0.3 / prompt.HoldDuration) then
                        holdDetected[prompt] = true
                        useTaserAndBoost()
                        StarterGui:SetCore("SendNotification", {Title="Prompt robado", Text="Se ejecutó Taser Gun para este prompt", Duration=2})
                    end
                elseif not prompt:IsHeld() then
                    holdDetected[prompt] = false
                end
            end
        end
    end
end)

-- Iniciar / detener
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
    StarterGui:SetCore("SendNotification", {Title="Taser", Text="Detenido", Duration=2})
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
