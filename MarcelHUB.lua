-- Limpia GUI vieja
pcall(function() game.CoreGui:FindFirstChild("StealHelper"):Destroy() end)

-- Servicios
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- Eventos de Taser y Compra
local RFCoinsShopServiceRequestBuy = ReplicatedStorage.Packages.Net["RF/CoinsShopService/RequestBuy"]
local REUseItem = ReplicatedStorage.Packages.Net["RE/UseItem"]

-- Variables
local running = false
local activePrompts = {}
local holdDetected = {}
local toolName = "Taser Gun"

-- ======================
-- Funciones
-- ======================

-- Comprar y equipar Taser Gun
local function buyAndEquip()
    local success, result = pcall(function()
        return RFCoinsShopServiceRequestBuy:InvokeServer(toolName)
    end)
    if not success then warn("Error al comprar:", result) end

    task.wait(0.5)
    local tool = player.Backpack:FindFirstChild(toolName)
    if tool then player.Character.Humanoid:EquipTool(tool) end
end

-- Notificaciones
local function notify(msg)
    StarterGui:SetCore("SendNotification", {
        Title = "Steal Helper",
        Text = msg,
        Duration = 2
    })
end

-- Detecta prompts de Steal
local function addPrompt(prompt)
    if prompt:IsA("ProximityPrompt") and prompt.ActionText == "Steal" and not activePrompts[prompt] then
        activePrompts[prompt] = prompt
        holdDetected[prompt] = false
        prompt.Triggered:Connect(function(plr)
            if plr == player then
                holdDetected[prompt] = true
                notify("Prompt de Steal activado!")
            end
        end)
    end
end

-- Buscar prompts en descendientes
local function scanForPrompts(parent)
    for _, obj in pairs(parent:GetDescendants()) do
        addPrompt(obj)
    end
end

-- Escanear zonas relevantes
local function scanZones()
    if workspace:FindFirstChild("Plots") then
        for _, model in pairs(workspace.Plots:GetChildren()) do
            scanForPrompts(model)
        end
    end
end

-- Encontrar hitbox propia (Base)
local function findMyHitbox()
    for _, base in pairs(workspace.Plots:GetChildren()) do
        if base:IsA("Model") then
            for _, desc in pairs(base:GetDescendants()) do
                if desc:IsA("TextLabel") and (string.find(desc.Text, player.Name) or string.find(desc.Text, player.DisplayName)) then
                    return base:FindFirstChild("DeliveryHitbox", true)
                end
            end
        end
    end
end

-- Boost con Taser hacia la base
local function taserBoostToGoal(goalCFrame)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    if not hrp then return end

    notify("Iniciando recorrido hacia la base...")

    local reached = false
    local heartbeatConn
    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not hrp or reached then
            if heartbeatConn then heartbeatConn:Disconnect() end
            notify("Recorrido finalizado")
            return
        end

        local vectorToGoal = goalCFrame.Position - hrp.Position
        local distance = vectorToGoal.Magnitude

        if distance < 5 then
            reached = true
            notify("¡Llegaste a la base!")
            if heartbeatConn then heartbeatConn:Disconnect() end
            return
        end

        local direction = vectorToGoal.Unit
        local moveVector = direction * math.min(distance, 25)
        hrp.CFrame = CFrame.new(hrp.Position + moveVector, goalCFrame.Position)

        -- Activar Taser cada tick
        REUseItem:FireServer(hrp)
    end)
end

-- ======================
-- Loop Principal
-- ======================
RunService.Heartbeat:Connect(function()
    if running then
        scanZones()
        for _, prompt in pairs(activePrompts) do
            if prompt and prompt.Parent then
                if prompt:IsHeld() and not holdDetected[prompt] then
                    local progress = prompt:GetHoldProgress()
                    if progress >= 1 - (0.3 / prompt.HoldDuration) then
                        holdDetected[prompt] = true
                        notify("Steal iniciado! Activando Taser...")
                        local myBase = findMyHitbox()
                        if myBase then
                            taserBoostToGoal(myBase.CFrame + Vector3.new(0,3,0))
                        else
                            notify("No se encontró la base!")
                        end
                    end
                elseif not prompt:IsHeld() then
                    holdDetected[prompt] = false
                end
            end
        end
    end
end)

-- ======================
-- Funciones para iniciar/detener
-- ======================
local function startTaser()
    running = true
    activePrompts = {}
    holdDetected = {}
    buyAndEquip()
    notify("Taser Helper ON")
end

local function stopTaser()
    running = false
    activePrompts = {}
    holdDetected = {}
    notify("Taser Helper OFF")
end

-- ======================
-- GUI
-- ======================
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "StealHelper"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 50)
frame.Position = UDim2.new(0.05,0,0.3,0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,40)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

local button = Instance.new("TextButton", frame)
button.Size = UDim2.new(1, -10, 1, -10)
button.Position = UDim2.new(0,5,0,5)
button.Text = "🔴 OFF"
button.Font = Enum.Font.GothamBold
button.TextSize = 18
button.TextColor3 = Color3.fromRGB(255,255,255)
button.BackgroundColor3 = Color3.fromRGB(120,0,0)
Instance.new("UICorner", button).CornerRadius = UDim.new(0,10)

button.MouseButton1Click:Connect(function()
    if running then
        stopTaser()
        button.Text = "🔴 OFF"
        button.BackgroundColor3 = Color3.fromRGB(120,0,0)
    else
        startTaser()
        button.Text = "🟢 ON"
        button.BackgroundColor3 = Color3.fromRGB(0,150,0)
    end
end)
