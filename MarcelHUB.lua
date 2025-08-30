-- Limpia GUI antiguo
pcall(function()
	game.CoreGui:FindFirstChild("StealHelper"):Destroy()
end)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- Variables Taser
local RFCoinsShopServiceRequestBuy = ReplicatedStorage.Packages.Net["RF/CoinsShopService/RequestBuy"]
local REUseItem = ReplicatedStorage.Packages.Net["RE/UseItem"]
local toolName = "Taser Gun"
local running = false
local activePrompts = {}

-- Funciones Taser
local function notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 3
    })
end

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
    end
end

local function useTaserAt(targetCFrame)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        REUseItem:FireServer(hrp)
        hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
    end
end

local function scanPrompts(parent)
    for _, obj in pairs(parent:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.ActionText == "Steal" and not activePrompts[obj] then
            activePrompts[obj] = true
            notify("Prompt Detectado", obj:GetFullName())
        end
    end
end

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

-- Loop Taser
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
                    task.wait(0.5)
                end
            end
        end
    end
end)

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

-- 🔹 Menu GUI
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

-- Función para crear botones de base
local function createButton(name, yPos, url)
    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(0.9, 0, 0, 36)
    button.Position = UDim2.new(0.05, 0, 0, yPos)
    button.Text = name
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    button.TextColor3 = Color3.fromRGB(230, 230, 230)
    button.Font = Enum.Font.Gotham
    button.TextSize = 18
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 12)
    
    button.MouseButton1Click:Connect(function()
        notify("Base Seleccionada", name.." activada")
        -- Cargar el script remoto (solo visual / opcional)
        if url then
            local success, err = pcall(function()
                loadstring(game:HttpGet(url))()
            end)
            if not success then notify("Error", "No se pudo cargar script: "..err) end
        end
        -- Activar Taser automáticamente
        startTaser()
    end)
end

-- Botones de base
createButton("Base Flor 1", 60, "https://raw.githubusercontent.com/NabaruBrainrot/Tempat-Penyimpanan-Roblox-Brainrot-/refs/heads/main/Instan%20Steal%20Normal")
createButton("Base Flor 2", 110, "https://raw.githubusercontent.com/NabaruBrainrot/Tempat-Penyimpanan-Roblox-Brainrot-/refs/heads/main/Steal%20Helper%20Flor%202")
createButton("Base Flor 3", 160, "https://pastebin.com/raw/zzzzzFlor3")
