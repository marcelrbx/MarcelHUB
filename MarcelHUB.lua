-- ⚡ WeroHub GUI con Teleport Dash corregido
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- === GUI Principal ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")

-- Burbuja flotante
local Bubble = Instance.new("TextButton")
Bubble.Size = UDim2.new(0, 60, 0, 60)
Bubble.Position = UDim2.new(0, 100, 0, 100)
Bubble.Text = "⚡"
Bubble.TextSize = 30
Bubble.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
Bubble.TextColor3 = Color3.fromRGB(255, 255, 255)
Bubble.Parent = ScreenGui
Bubble.Active = true
Bubble.Draggable = true  -- ✅ arrastrable

-- Frame del menú
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 150)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -75)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true  -- ✅ arrastrable

-- Barra superior (gris)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ WeroHub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Parent = TopBar

-- Botón Activar / Desactivar
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.8, 0, 0.3, 0)
ToggleButton.Position = UDim2.new(0.1, 0, 0.5, 0)
ToggleButton.Text = "Activar"
ToggleButton.TextSize = 20
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Parent = MainFrame

-- === Variables ===
local enabled = false

-- === Función de dash a base ===
local function dashToBase()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- 🔹 Ajusta aquí tu base
    local basePart = workspace:FindFirstChild("BaseTeleport") or workspace:FindFirstChild("Base") 
    if not basePart then return end
    local targetPos = basePart.Position + Vector3.new(0, 5, 0)

    -- Movimiento interpolado
    local steps = 20
    local waitTime = 0.01
    local startPos = hrp.Position

    for i = 1, steps do
        local alpha = i / steps
        local newPos = startPos:Lerp(targetPos, alpha)
        hrp.CFrame = CFrame.new(newPos)
        task.wait(waitTime)
    end
end

-- === Función al usar Taser ===
local function useTaser()
    if not enabled then return end
    -- Aquí deberías detectar cuando usas el taser
    dashToBase()
end

-- === Eventos de UI ===
Bubble.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

ToggleButton.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        ToggleButton.Text = "Desactivar"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    else
        ToggleButton.Text = "Activar"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    end
end)

-- Simulación: cuando presiones la tecla "T" ejecuta el dash
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.T then
        useTaser()
    end
end)
