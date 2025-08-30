--// Servicios
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local uis = game:GetService("UserInputService")

--// Configuración
local activated = false -- estado del hack

--// Función para moverse a la base
local function dashToBase()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- 🔹 Cambia esto por el objeto que sea tu base
    local basePart = workspace:WaitForChild("BaseTeleport"):WaitForChild("Part")
    local targetPos = basePart.Position + Vector3.new(0, 5, 0)

    local tweenInfo = TweenInfo.new(
        0.4, -- duración del dash
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
    tween:Play()
end

--// Función principal al robar
local function useTaserAndDash()
    if not activated then return end
    dashToBase()
end

-- Aquí pones tu evento que detecta cuando robas el brainrot
-- Ejemplo (ajusta al evento real del juego):
-- workspace.BrainrotSteal.Event.OnClientEvent:Connect(useTaserAndDash)

--------------------------------------------------------------------
--// INTERFAZ
--------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
local Bubble = Instance.new("TextButton")
local MenuFrame = Instance.new("Frame")
local ToggleButton = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")

-- Burbuja roja
Bubble.Size = UDim2.new(0, 50, 0, 50)
Bubble.Position = UDim2.new(0, 20, 0.5, -25)
Bubble.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
Bubble.Text = "⚙️"
Bubble.TextScaled = true
Bubble.TextColor3 = Color3.new(1,1,1)
Bubble.Parent = ScreenGui
Bubble.ZIndex = 2
Bubble.AutoButtonColor = true
Bubble.Name = "WeroBubble"
Bubble.BackgroundTransparency = 0.2
Bubble.BorderSizePixel = 0
Bubble.Visible = true

-- Frame del menú
MenuFrame.Size = UDim2.new(0, 200, 0, 120)
MenuFrame.Position = UDim2.new(0, 80, 0.5, -60)
MenuFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MenuFrame.BorderSizePixel = 0
MenuFrame.Visible = false
MenuFrame.Parent = ScreenGui

-- Botón de activar/desactivar
ToggleButton.Size = UDim2.new(0.8, 0, 0.3, 0)
ToggleButton.Position = UDim2.new(0.1, 0, 0.35, 0)
ToggleButton.Text = "Activar"
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0) -- verde
ToggleButton.TextColor3 = Color3.new(1,1,1)
ToggleButton.TextScaled = true
ToggleButton.Parent = MenuFrame
ToggleButton.BorderSizePixel = 0

--------------------------------------------------------------------
--// Lógica de UI
--------------------------------------------------------------------
-- Mostrar/ocultar menú al hacer click en la burbuja
Bubble.MouseButton1Click:Connect(function()
    MenuFrame.Visible = not MenuFrame.Visible
end)

-- Cambiar estado al presionar botón
ToggleButton.MouseButton1Click:Connect(function()
    activated = not activated
    if activated then
        ToggleButton.Text = "Desactivar"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0) -- rojo
    else
        ToggleButton.Text = "Activar"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0) -- verde
    end
end)
