--////////////////////////////////////////////////////////////
--  UI arrastrable + compra/equipar tool + dash a base
--  Uso permitido: tu propio juego/lugar de pruebas
--////////////////////////////////////////////////////////////

--===== SERVICIOS =====
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

--===== CONFIG =====
local TOOL_NAME = "Taser Gun"  -- nombre exacto de tu herramienta
-- Rutas de tus remotes en TU juego:
local RF_BUY_PATH = {"Packages","Net","RF/CoinsShopService/RequestBuy"} -- RemoteFunction para comprar
local RE_USE_PATH = {"Packages","Net","RE/UseItem"}                     -- RemoteEvent opcional para “usar” el tool

-- Velocidad del dash (studs/seg). Sube/baja si quieres más rápido/lento.
local DASH_SPEED = 300

--===== UTILS =====
local function findRemote(root, pathArray)
    local obj = root
    for _, name in ipairs(pathArray) do
        if not obj then return nil end
        obj = obj:FindFirstChild(name)
    end
    return obj
end

local RF_Buy = findRemote(ReplicatedStorage, RF_BUY_PATH)
local RE_Use = findRemote(ReplicatedStorage, RE_USE_PATH)

local function makeDraggable(containerGuiObject, dragHandleGuiObject)
    -- Drag totalmente custom (no depende de .Draggable)
    local dragging = false
    local dragStart
    local startPos
    local dragInput

    local function update(input)
        local delta = input.Position - dragStart
        containerGuiObject.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    dragHandleGuiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = containerGuiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandleGuiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            update(input)
        end
    end)
end

-- Busca un CFrame de “base” en TU mapa (ajústalo a tu estructura)
local function getBaseCFrame()
    -- 1) BaseTeleport/Part (ejemplo común)
    local baseTele = workspace:FindFirstChild("BaseTeleport")
    if baseTele then
        local p = baseTele:FindFirstChildWhichIsA("BasePart", true)
        if p then return p.CFrame + Vector3.new(0, 5, 0) end
    end

    -- 2) Plots con dueño (varias heurísticas)
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local isOwner =
                (plot.Name == player.Name) or
                (plot:GetAttribute("Owner") == player.UserId) or
                (plot:FindFirstChild("Owner") and plot.Owner.Value == player.UserId)

            if isOwner then
                local part = plot:FindFirstChild("Base") or plot:FindFirstChild("Spawn")
                part = part or plot:FindFirstChildWhichIsA("BasePart", true)
                if part then return part.CFrame + Vector3.new(0, 5, 0) end
            end
        end
    end

    -- 3) Spawn o Base genéricos
    local spawnFolder = workspace:FindFirstChild("Spawn")
    if spawnFolder then
        local p = spawnFolder:FindFirstChildWhichIsA("BasePart", true)
        if p then return p.CFrame + Vector3.new(0, 5, 0) end
    end

    local basePart = workspace:FindFirstChild("Base") or workspace:FindFirstChild("SafeZone")
    if basePart and basePart:IsA("BasePart") then
        return basePart.CFrame + Vector3.new(0, 5, 0)
    end

    return nil
end

local function dashToBase()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local target = getBaseCFrame()
    if not target then
        warn("[Dash] No se encontró una base. Ajusta getBaseCFrame().")
        return
    end

    local startPos = hrp.Position
    local endPos = target.Position
    local distance = (endPos - startPos).Magnitude
    if distance < 1 then return end

    local duration = math.max(distance / DASH_SPEED, 0.1)
    local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(endPos)})
    tween:Play()
    -- No bloqueamos con :Wait() para no congelar el hilo UI
end

-- Compra (si hace falta) y equipa el tool
local function buyAndEquip()
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local tool = player.Backpack:FindFirstChild(TOOL_NAME) or char:FindFirstChild(TOOL_NAME)
    if not tool and RF_Buy then
        local ok, err = pcall(function()
            return RF_Buy:InvokeServer(TOOL_NAME)
        end)
        if not ok then
            warn("[Buy] Error al comprar:", err)
        end
        task.wait(0.3)
        tool = player.Backpack:FindFirstChild(TOOL_NAME) or char:FindFirstChild(TOOL_NAME)
    end

    if tool and not tool.Parent:IsA("Model") then
        -- Si está en Backpack, equípalo
        hum:EquipTool(tool)
    elseif tool and tool.Parent ~= char then
        hum:EquipTool(tool)
    end
end

-- Opcional: “usar” el tool antes del dash (si tu server lo utiliza)
local function useToolRemote()
    if not RE_Use then return end
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        RE_Use:FireServer(hrp)
    end)
end

-- Cuando el tool se activa (click), hacemos la acción
local enabled = false
local cooldown = false
local function onToolActivated()
    if not enabled or cooldown then return end
    cooldown = true
    -- Lanza tu remoto de “uso”, si aplica, y luego dash
    useToolRemote()
    dashToBase()
    task.delay(0.6, function() cooldown = false end) -- anti-spam
end

-- Hookea herramientas actuales y futuras con el nombre correcto
local function hookTool(tool)
    if tool and tool:IsA("Tool") and tool.Name == TOOL_NAME then
        tool.Activated:Connect(onToolActivated)
    end
end
player.Backpack.ChildAdded:Connect(hookTool)
player.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(hookTool)
    task.defer(function()
        local t = char:FindFirstChild(TOOL_NAME) or player.Backpack:FindFirstChild(TOOL_NAME)
        if t then hookTool(t) end
    end)
end)
-- Si ya está la herramienta cuando corre el script
task.defer(function()
    local char = player.Character or player.CharacterAdded:Wait()
    local t = char:FindFirstChild(TOOL_NAME) or player.Backpack:FindFirstChild(TOOL_NAME)
    if t then hookTool(t) end
end)

--===== UI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WeroUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Burbuja roja (arrastrable)
local bubble = Instance.new("TextButton")
bubble.Name = "Bubble"
bubble.Size = UDim2.new(0, 56, 0, 56)
bubble.Position = UDim2.new(0, 20, 0.5, -28)
bubble.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
bubble.Text = "⚙️"
bubble.TextScaled = true
bubble.TextColor3 = Color3.fromRGB(255,255,255)
bubble.AutoButtonColor = true
bubble.Parent = screenGui

local uiCornerB = Instance.new("UICorner", bubble)
uiCornerB.CornerRadius = UDim.new(0, 28)

-- Menú (arrastrable desde TopBar)
local frame = Instance.new("Frame")
frame.Name = "Menu"
frame.Size = UDim2.new(0, 240, 0, 140)
frame.Position = UDim2.new(0, 90, 0.5, -70)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.Visible = false
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 32)
topBar.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
topBar.Parent = frame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ WeroHub (demo segura)"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = topBar

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "Toggle"
toggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
toggleBtn.Position = UDim2.new(0.1, 0, 0, 60)
toggleBtn.Text = "Activar"
toggleBtn.TextSize = 18
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 170, 20)
toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
toggleBtn.Parent = frame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)

-- Drag: burbuja y menú (desde TopBar)
makeDraggable(bubble, bubble)
makeDraggable(frame, topBar)

-- Mostrar/ocultar menú al pulsar la burbuja
bubble.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- Toggle de activación
local function setEnabled(state)
    enabled = state
    if enabled then
        toggleBtn.Text = "Desactivar"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        -- Compra/equipa al activar
        buyAndEquip()
    else
        toggleBtn.Text = "Activar"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 170, 20)
    end
end
toggleBtn.MouseButton1Click:Connect(function()
    setEnabled(not enabled)
end)

-- Si ya quieres empezar apagado:
setEnabled(false)
