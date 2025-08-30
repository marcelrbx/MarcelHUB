-- LocalScript (pegar en StarterPlayerScripts o ejecutor como LocalScript)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local DEBUG = true -- ponlo true para ver prints en Output

local function Dprint(...)
    if DEBUG then print("[TASER DEBUG]", ...) end
end

-- Ajusta estos nombres si en tu juego son diferentes
local RFCoinsShopServiceRequestBuy = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Net") and ReplicatedStorage.Packages.Net:FindFirstChild("RF/CoinsShopService/RequestBuy")
local REUseItem = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Net") and ReplicatedStorage.Packages.Net:FindFirstChild("RE/UseItem")

local running = false
local toolName = "Taser Gun"

-- trackedPrompts[prompt] = { handled = false }
local trackedPrompts = {}

-- Compra y equipa (verifica si ya existe)
local function buyAndEquip()
    -- Si no existe el RemoteFunction, solo intentamos equipar si ya lo tienes
    local tool = player.Backpack:FindFirstChild(toolName) or (player.Character and player.Character:FindFirstChild(toolName))
    if not tool and RFCoinsShopServiceRequestBuy then
        local ok, res = pcall(function()
            return RFCoinsShopServiceRequestBuy:InvokeServer(toolName)
        end)
        if not ok then warn("Error al comprar:", res) end
        task.wait(0.5)
        tool = player.Backpack:FindFirstChild(toolName) or (player.Character and player.Character:FindFirstChild(toolName))
    end

    if tool and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:EquipTool(tool)
        Dprint("Taser equipado")
    else
        Dprint("No se encontró Taser para equipar")
    end
end

-- Usa el taser y teletransporta (cuidado con anticheats)
local function useTaserAndTeleport()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        Dprint("Usando taser y teletransportando...")
        pcall(function()
            if REUseItem then
                -- Algunos juegos esperan distintos argumentos; este es el que usabas
                REUseItem:FireServer(hrp)
            end
        end)
        -- Teletransporte directo (si quieres más "suave" usar TweenService / Humanoid:MoveTo)
        hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 20
    end
end

-- Registra un prompt para seguimiento (solo los que coincidan con "steal")
local function addPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    if trackedPrompts[prompt] then return end

    -- Filtro por ActionText: hazlo más laxo si necesitas detectar todo
    local action = tostring(prompt.ActionText or "")
    if not string.find(action:lower(), "steal") then
        -- Si quieres detectar todos, comenta la siguiente línea
        return
    end

    trackedPrompts[prompt] = { handled = false }
    Dprint("Prompt añadido:", prompt, "ActionText=", action, "HoldDuration=", prompt.HoldDuration, "Parent=", prompt.Parent and prompt.Parent:GetFullName())

    -- Si el prompt es instantáneo (HoldDuration == 0) → usar Triggered
    prompt.Triggered:Connect(function(plr)
        if plr == player then
            local state = trackedPrompts[prompt]
            if state and not state.handled then
                state.handled = true
                useTaserAndTeleport()
                task.delay(0.5, function()
                    if trackedPrompts[prompt] then trackedPrompts[prompt].handled = false end
                end)
            end
        end
    end)
end

local function removePrompt(prompt)
    if trackedPrompts[prompt] then
        Dprint("Prompt removido:", prompt)
        trackedPrompts[prompt] = nil
    end
end

-- Escaneo inicial (ligero)
for _, obj in pairs(workspace:GetDescendants()) do
    pcall(function() addPrompt(obj) end)
end

-- Mantener la lista actualizada
workspace.DescendantAdded:Connect(function(obj)
    pcall(function()
        if obj:IsA("ProximityPrompt") then
            addPrompt(obj)
        end
    end)
end)
workspace.DescendantRemoving:Connect(function(obj)
    pcall(function()
        if obj:IsA("ProximityPrompt") then
            removePrompt(obj)
        end
    end)
end)

-- Loop que revisa progreso en prompts con HoldDuration > 0
RunService.Heartbeat:Connect(function()
    if not running then return end
    for prompt, state in pairs(trackedPrompts) do
        if prompt and prompt.Parent then
            local hd = tonumber(prompt.HoldDuration) or 0
            if hd > 0 then
                -- solo si alguien lo mantiene
                if prompt:IsHeld() and not state.handled then
                    local ok, progress = pcall(function() return prompt:GetHoldProgress() end)
                    if ok and type(progress) == "number" then
                        -- Umbral: 0.3s antes de terminar, protegido contra división por cero
                        local threshold = 1 - (0.3 / math.max(hd, 0.001))
                        threshold = math.clamp(threshold, 0, 1)
                        if progress >= threshold then
                            state.handled = true
                            useTaserAndTeleport()
                            task.delay(0.5, function()
                                if trackedPrompts[prompt] then trackedPrompts[prompt].handled = false end
                            end)
                        end
                    end
                end
            end
        else
            -- prompt inválido -> limpiar
            trackedPrompts[prompt] = nil
        end
    end
end)

-- Start / Stop
local function startTaser()
    running = true
    buyAndEquip()
    Dprint("Sistema TASER activado")
end
local function stopTaser()
    running = false
    Dprint("Sistema TASER desactivado")
end

-- GUI (igual que la tuya, pero con debug)
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
