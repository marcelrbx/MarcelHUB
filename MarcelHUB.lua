-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Remotes
local RFCoinsShopServiceRequestBuy = ReplicatedStorage.Packages.Net["RF/CoinsShopService/RequestBuy"]
local REUseItem = ReplicatedStorage.Packages.Net["RE/UseItem"]

-- Variables
local running = false
local toolName = "Taser Gun"
local activePrompts = {}

-- 🔹 Notificación
local function notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 3
    })
end

-- 🔹 Comprar y equipar Taser Gun
local function buyAndEquip()
    local success, result = pcall(function()
        return RFCoinsShopServiceRequestBuy:InvokeServer(toolName)
    end)
    if not success then
        warn("Error al comprar:", result)
        notify("Error", "No se pudo comprar la Taser Gun")
        return
    end
    task.wait(0.5)
    local tool = player.Backpack:FindFirstChild(toolName)
    if tool then
        player.Character.Humanoid:EquipTool(tool)
        notify("Taser Gun", "Taser Gun equipada")
    else
        notify("Error", "Taser Gun no encontrada")
    end
end

-- 🔹 Función de usar Taser y teletransportar
local function useTaserAt(targetCFrame)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        -- Disparar Taser
        REUseItem:FireServer(hrp)
        -- Teletransportar cerca del objetivo
        hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
    end
end

-- 🔹 Escanear prompts en un parent
local function scanPrompts(parent)
    for _, obj in pairs(parent:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.ActionText == "Steal" and not activePrompts[obj] then
            activePrompts[obj] = true
            notify("Prompt Detectado", obj:GetFullName())
        end
    end
end

-- 🔹 Escanear zonas típicas
local function scanZones()
    if workspace:FindFirstChild("Plots") then
        for _, model in pairs(workspace.Plots:GetChildren()) do scanPrompts(model) end
    end
    if workspace:FindFirstChild("AnimalPodiums") then
        for _, model in pairs(workspace.AnimalPodiums:GetChildren()) do scanPrompts(model) end
    end
    if workspace:FindFirstChild("Base") then scanPrompts(workspace.Base) end
    if workspace:FindFirstChild("Spawn") then scanPrompts(workspace.Spawn) end
end

-- 🔹 Loop principal
RunService.Heartbeat:Connect(function()
    if running then
        scanZones()
        for prompt, _ in pairs(activePrompts) do
            if prompt and prompt.Parent then
                local targetCFrame = prompt.Parent:IsA("BasePart") and prompt.Parent.CFrame or prompt.Parent.PrimaryPart and prompt.Parent.PrimaryPart.CFrame
                if targetCFrame then
                    useTaserAt(targetCFrame)
                    notify("Steal Activado", "Prompt usado: "..prompt:GetFullName())
                    activePrompts[prompt] = nil
                    task.wait(0.5) -- Pequeña pausa entre cada prompt
                end
            end
        end
    end
end)

-- 🔹 Funciones de inicio/parada
local function startTaser()
    running = true
    activePrompts = {}
    buyAndEquip()
    notify("Taser Helper", "Iniciado")
end

local function stopTaser()
    running = false
    activePrompts = {}
    notify("Taser Helper", "Detenido")
end

-- 🔹 GUI Toggle
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "TaserHelperGUI"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 150, 0, 50)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
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
