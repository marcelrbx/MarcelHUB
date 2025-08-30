-- Limpia GUI anterior
pcall(function()
	game.CoreGui:FindFirstChild("StealHelper"):Destroy()
end)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- RemoteEvents
local REUseItem = ReplicatedStorage.Packages.Net["RE/UseItem"]

-- Variables
local activeSteal = false
local taserActive = false
local activePrompts = {}
local holdDetected = {}
local goalCFrame

-- Notificación
local function notify(msg)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Steal Helper",
        Text = msg,
        Duration = 3
    })
end

-- Función Taser Boost
local function taserBoostToGoal(goalCFrame)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    notify("Iniciando recorrido hacia la base...")

    local reached = false
    local boostConn
    boostConn = RunService.Heartbeat:Connect(function()
        if not hrp or reached then
            if boostConn then boostConn:Disconnect() end
            taserActive = false
            notify("¡Recorrido finalizado!")
            return
        end

        local direction = (goalCFrame.Position - hrp.Position)
        local distance = direction.Magnitude
        if distance < 5 then
            reached = true
            return
        end
        direction = direction.Unit

        -- Dispara Taser y empuja hacia la base
        REUseItem:FireServer(hrp)
        hrp.CFrame = hrp.CFrame + direction * math.min(distance, 20)
    end)
end

-- Agregar ProximityPrompt válido
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

-- Escanear modelos
local function scanForPrompts(parent)
    for _, obj in pairs(parent:GetDescendants()) do
        addPrompt(obj)
    end
end

-- Loop principal para revisar hold
RunService.Heartbeat:Connect(function()
    if activeSteal then
        for _, prompt in pairs(activePrompts) do
            if prompt and prompt.Parent then
                if prompt:IsHeld() and not holdDetected[prompt] and not taserActive then
                    local progress = prompt:GetHoldProgress()
                    if progress >= 1 - (0.3 / prompt.HoldDuration) then
                        holdDetected[prompt] = true
                        notify("Steal detectado, activando Taser...")
                        taserActive = true
                        -- Calcula la base del jugador
                        for _, base in pairs(workspace.Plots:GetChildren()) do
                            if base:IsA("Model") then
                                for _, desc in pairs(base:GetDescendants()) do
                                    if desc:IsA("TextLabel") and (string.find(desc.Text, player.Name) or string.find(desc.Text, player.DisplayName)) then
                                        local deliveryHitbox = base:FindFirstChild("DeliveryHitbox", true)
                                        if deliveryHitbox then
                                            goalCFrame = deliveryHitbox.CFrame + Vector3.new(0,3,0)
                                            taserBoostToGoal(goalCFrame)
                                        end
                                    end
                                end
                            end
                        end
                    end
                elseif not prompt:IsHeld() then
                    holdDetected[prompt] = false
                end
            end
        end
    end
end)

-- Crear GUI
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
title.Text = "Steal Helper | Elegir Base"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left

-- Función para crear botones
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
    local buttonCorner = Instance.new("UICorner", button)
    buttonCorner.CornerRadius = UDim.new(0, 12)

    button.MouseButton1Click:Connect(function()
        notify(name.." seleccionado, cargando script...")
        activeSteal = true
        loadstring(game:HttpGet(url))()
    end)
end

-- Botones Base Flor 1/2/3
createButton("Base Flor 1", 60, "https://raw.githubusercontent.com/NabaruBrainrot/Tempat-Penyimpanan-Roblox-Brainrot-/refs/heads/main/Instan%20Steal%20Normal")
createButton("Base Flor 2", 110, "https://raw.githubusercontent.com/NabaruBrainrot/Tempat-Penyimpanan-Roblox-Brainrot-/refs/heads/main/Steal%20Helper%20Flor%202")
createButton("Base Flor 3", 160, "https://pastebin.com/raw/zzzzzFlor3")

notify("Steal Helper cargado. Selecciona un piso para iniciar.")
