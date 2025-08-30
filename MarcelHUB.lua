-- 🔹 Servicios
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RFCoinsShopServiceRequestBuy = ReplicatedStorage.Packages.Net["RF/CoinsShopService/RequestBuy"]
local REUseItem = ReplicatedStorage.Packages.Net["RE/UseItem"]

-- 🔹 Variables
local running = false
local toolName = "Taser Gun"
local activePrompts = {}
local holdDetected = {}

-- 🔹 Funciones principales
local function buyAndEquip()
    local success, result = pcall(function()
        return RFCoinsShopServiceRequestBuy:InvokeServer(toolName)
    end)
    if not success then
        warn("Error al comprar:", result)
    end
    task.wait(0.5)
    local tool = player.Backpack:FindFirstChild(toolName)
    if tool then
        player.Character.Humanoid:EquipTool(tool)
    end
end

local function useTaserAndTeleport()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        REUseItem:FireServer(hrp)
        hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 20
    end
end

-- 🔹 ProximityPrompts
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
    if workspace:FindFirstChild("Base") then
        scanForPrompts(workspace.Base)
    end
    if workspace:FindFirstChild("Spawn") then
        scanForPrompts(workspace.Spawn)
    end
end

-- 🔹 Loop principal
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

-- 🔹 Start / Stop
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

-- 🔹 GUI
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "TaserToggleGUI"
screenGui.ResetOnSpawn = false

-- 🔹 Burbuja flotante
local bubble = Instance.new("TextButton", screenGui)
bubble.Size = UDim2.new(0, 50, 0, 50)
bubble.Position = UDim2.new(0.05, 0, 0.5, 0)
bubble.Text = "⚡"
bubble.Font = Enum.Font.GothamBold
bubble.TextSize = 24
bubble.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
bubble.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", bubble).CornerRadius = UDim.new(1, 0)

-- Hacer burbuja arrastrable
local dragging = false
local dragInput, dragStart, startPos
bubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = bubble.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
bubble.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        bubble.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- 🔹 Menú flotante
local menu = Instance.new("Frame", screenGui)
menu.Size = UDim2.new(0, 200, 0, 100)
menu.Position = UDim2.new(0.2, 0, 0.3, 0)
menu.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
menu.BorderSizePixel = 0
menu.Visible = false
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 12)

-- Barra gris para arrastrar
local dragBar = Instance.new("Frame", menu)
dragBar.Size = UDim2.new(1, 0, 0, 20)
dragBar.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
dragBar.BorderSizePixel = 0
Instance.new("UICorner", dragBar).CornerRadius = UDim.new(0, 12)

-- Botón activar/desactivar
local toggleButton = Instance.new("TextButton", menu)
toggleButton.Size = UDim2.new(0.8, 0, 0.5, 0)
toggleButton.Position = UDim2.new(0.1, 0, 0.4, 0)
toggleButton.Text = "🔴 OFF"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 22
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 10)

-- Toggle
toggleButton.MouseButton1Click:Connect(function()
    if running then
        stopTaser()
        toggleButton.Text = "🔴 OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
    else
        startTaser()
        toggleButton.Text = "🟢 ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    end
end)

-- Abrir/Cerrar menú con burbuja
bubble.MouseButton1Click:Connect(function()
    menu.Visible = not menu.Visible
end)

-- Hacer menú arrastrable desde barra gris
local draggingMenu = false
local dragInputMenu, dragStartMenu, startPosMenu
dragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingMenu = true
        dragStartMenu = input.Position
        startPosMenu = menu.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingMenu = false
            end
        end)
    end
end)
dragBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInputMenu = input
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInputMenu and draggingMenu then
        local delta = input.Position - dragStartMenu
        menu.Position = UDim2.new(startPosMenu.X.Scale, startPosMenu.X.Offset + delta.X, startPosMenu.Y.Scale, startPosMenu.Y.Offset + delta.Y)
    end
end)
