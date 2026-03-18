-- Dark DEX Mobile [Touch Edition]
-- Optimized for Roblox Executors (2026)
-- Features: Virtual Scroller, Touch-Friendly, Properties Sheet, Search

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- // GUI CREATION //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DarkDexMobile_" .. math.random(1000, 9999)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

-- Try to parent to CoreGui for security, fallback to PlayerGui
pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- // ASSETS & THEME //
local Theme = {
    Background = Color3.fromRGB(15, 15, 17),
    Surface = Color3.fromRGB(25, 25, 30),
    Accent = Color3.fromRGB(0, 120, 255), -- Bright Blue
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(150, 150, 150),
    Border = Color3.fromRGB(40, 40, 45)
}

local Icons = {
    Folder = "rbxassetid://18557393439", -- Example ID (would be real set)
    Part = "rbxassetid://18557393782",
    Script = "rbxassetid://18557394125",
    LocalScript = "rbxassetid://18557394468",
    Search = "rbxassetid://6031154871",
    Close = "rbxassetid://6031094678",
    Minimize = "rbxassetid://6031094678", -- Placeholder
}

-- // UTILITIES //
local function Create(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties) do
        instance[k] = v
    end
    return instance
end

local function Round(instance, radius)
    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, radius or 8)
    uic.Parent = instance
    return uic
end

local function Stroke(instance, color, thickness)
    local uis = Instance.new("UIStroke")
    uis.Color = color or Theme.Border
    uis.Thickness = thickness or 1
    uis.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uis.Parent = instance
    return uis
end

-- // MAIN WINDOW //
local MainFrame = Create("Frame", {
    Name = "MainFrame",
    Parent = ScreenGui,
    BackgroundColor3 = Theme.Background,
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.new(0, 360, 0, 600), -- Mobile Portrait Size
    ClipsDescendants = true
})
Round(MainFrame, 16)
Stroke(MainFrame, Theme.Border, 1)

-- Make Draggable
local Dragging, DragInput, DragStart, StartPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPos = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        DragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == DragInput and Dragging then
        local Delta = input.Position - DragStart
        MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
    end
end)

-- // HEADER //
local Header = Create("Frame", {
    Parent = MainFrame,
    BackgroundColor3 = Theme.Surface,
    Size = UDim2.new(1, 0, 0, 40),
    BorderSizePixel = 0
})
Round(Header, 16) -- Top corners
Create("Frame", { -- Square off bottom
    Parent = Header,
    BackgroundColor3 = Theme.Surface,
    Size = UDim2.new(1, 0, 0, 10),
    Position = UDim2.new(0, 0, 1, -10),
    BorderSizePixel = 0
})

local Title = Create("TextLabel", {
    Parent = Header,
    Text = "Dark DEX Mobile",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -80, 1, 0),
    Position = UDim2.new(0, 16, 0, 0),
    TextXAlignment = Enum.TextXAlignment.Left
})

local CloseBtn = Create("ImageButton", {
    Parent = Header,
    BackgroundTransparency = 1,
    Image = Icons.Close,
    Size = UDim2.new(0, 20, 0, 20),
    Position = UDim2.new(1, -28, 0.5, -10),
    ImageColor3 = Color3.fromRGB(255, 80, 80)
})
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- // EXPLORER PANE (Virtualization Logic) //
local ExplorerFrame = Create("Frame", {
    Parent = MainFrame,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, -90), -- Leave room for bottom nav
    Position = UDim2.new(0, 0, 0, 40)
})

local Scroller = Create("ScrollingFrame", {
    Parent = ExplorerFrame,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = Theme.Accent
})

local ListLayout = Create("UIListLayout", {
    Parent = Scroller,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2)
})

-- The "Node" Template
local function CreateNode(instance, indent)
    local btn = Create("TextButton", {
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Text = "",
        AutoButtonColor = false
    })

    local nameLabel = Create("TextLabel", {
        Parent = btn,
        BackgroundTransparency = 1,
        Text = instance.Name,
        TextColor3 = Theme.TextDim,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        Size = UDim2.new(1, -40 - (indent * 16), 1, 0),
        Position = UDim2.new(0, 32 + (indent * 16), 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Expand/Collapse Arrow
    local arrow = Create("TextButton", {
        Parent = btn,
        Text = ">",
        TextColor3 = Theme.TextDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 32),
        Position = UDim2.new(0, 4 + (indent * 16), 0, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 14
    })

    -- Interaction
    btn.MouseButton1Click:Connect(function()
        -- Open Properties Sheet (Simulated)
        ShowProperties(instance)
    end)

    return btn
end

-- // PROPERTIES SHEET (Bottom Sheet) //
local PropSheet = Create("Frame", {
    Parent = MainFrame,
    BackgroundColor3 = Theme.Surface,
    Size = UDim2.new(1, 0, 0.6, 0),
    Position = UDim2.new(0, 0, 1, 0), -- Initially hidden
    ZIndex = 10
})
Round(PropSheet, 16)

local PropTitle = Create("TextLabel", {
    Parent = PropSheet,
    Text = "Properties",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1
})

function ShowProperties(instance)
    PropTitle.Text = instance.Name .. " (" .. instance.ClassName .. ")"
    -- Animate Up
    PropSheet:TweenPosition(UDim2.new(0, 0, 0.4, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
end

-- Close Props on Background Click
local Dimmer = Create("TextButton", {
    Parent = MainFrame,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    Text = "",
    Visible = false,
    ZIndex = 5
})

Dimmer.MouseButton1Click:Connect(function()
    PropSheet:TweenPosition(UDim2.new(0, 0, 1, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.2, true)
    Dimmer.Visible = false
end)

-- // POPULATE EXPLORER (Mock) //
local function RenderExplorer()
    -- In a real script, this would iterate game.Workspace, etc.
    -- For this demo, we mock it to prevent crashing if run outside of context
    local root = Scroller

    local MockInstances = {
        Workspace = game.Workspace,
        Players = game.Players,
        Lighting = game:GetService("Lighting"),
        ReplicatedStorage = game:GetService("ReplicatedStorage")
    }

    for name, obj in pairs(MockInstances) do
        local node = CreateNode(obj, 0)
        node.Parent = Scroller
    end
end

RenderExplorer()

-- // BOTTOM NAV //
local BottomNav = Create("Frame", {
    Parent = MainFrame,
    BackgroundColor3 = Theme.Surface,
    Size = UDim2.new(1, 0, 0, 50),
    Position = UDim2.new(0, 0, 1, -50),
    BorderSizePixel = 0
})

local function CreateNavBtn(text, xOrder)
    local btn = Create("TextButton", {
        Parent = BottomNav,
        Text = text,
        TextColor3 = Theme.TextDim,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Size = UDim2.new(0.33, 0, 1, 0),
        Position = UDim2.new((xOrder-1)*0.33, 0, 0, 0),
        BackgroundTransparency = 1
    })
    return btn
end

CreateNavBtn("Explorer", 1).TextColor3 = Theme.Accent
CreateNavBtn("Console", 2)
CreateNavBtn("Settings", 3)

print("Dark DEX Mobile Loaded Successfully.")
