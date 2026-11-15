--==================================================================
--  VENICE | Blade Ball
--  BAC bypass + AutoParry + FOV + Sky Customization
--  RightShift — меню | L — автопарри
--==================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local Stats              = game:GetService("Stats")
local UserInputService   = game:GetService("UserInputService")
local VirtualInputManager= game:GetService("VirtualInputManager")
local TweenService       = game:GetService("TweenService")
local Lighting           = game:GetService("Lighting")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Player             = Players.LocalPlayer
local Camera             = workspace.CurrentCamera

--==================================================================
--  BAC BYPASS
--==================================================================
pcall(function()
    local old
    old = hookfunction(getrenv().debug.info, function(f, t)
        if type(f) == "function" then
            return "[C]"
        elseif f == 4 and t == "s" then
            return "ReplicatedStorage.Controllers.SwordsController "
        end
        return old(f, t)
    end)

    local old2
    old2 = hookfunction(getrenv().getfenv, function(l)
        if l ~= nil and type(l) == "number" then
            if l >= 1 and l <= 10 then
                return old2(10)
            end
        end
        return old2(1)
    end)
end)

--==================================================================
--  CONFIG
--==================================================================
local CFG = {
    AutoParry        = true,
    PingBased        = true,
    PingBasedOffset  = 1.95,
    DistanceToParry  = 0.65,
    EmergencyRadius  = 10,
    ClashDistance    = 22,
    ClashSpeed       = 0.01,
    NormalSpeed      = 0.05,
    Visuals          = true,
    CircleColor      = Color3.fromRGB(150, 240, 255),
    RemoteParry      = false,

    FOVEnabled       = false,
    FOV              = 90,

    SkyEnabled       = false,
    ClockTime        = 14,
    Brightness       = 2,
    Ambient          = Color3.fromRGB(70, 70, 80),
    OutdoorAmbient   = Color3.fromRGB(128, 128, 128),
    FogEnd           = 1000,
    FogColor         = Color3.fromRGB(190, 190, 200),
    AtmoDensity      = 0.3,
    AtmoHaze         = 1.5,
    AtmoColor        = Color3.fromRGB(199, 199, 199),
    Sat              = 0,
    Contrast         = 0,
    Tint             = Color3.fromRGB(255, 255, 255),
}
getgenv().Venice = CFG

local ORIG = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor,
    FOV = Camera.FieldOfView,
}

--==================================================================
--  STATE
--==================================================================
local LastClick, LastBallHit, IsParrying, FrameCounter = 0, nil, false, 0
local BallsFolder = workspace:FindFirstChild("Balls") or workspace:WaitForChild("Balls", 5)
local NetStats = Stats:FindFirstChild("Network")
    and Stats.Network:FindFirstChild("ServerStatsItem")
    and Stats.Network.ServerStatsItem:FindFirstChild("Data Ping")

local parryRemote
task.spawn(function()
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and (v.Name == "Parry" or v.Name == "ParryButtonPress") then
            parryRemote = v
            break
        end
    end
end)

--==================================================================
--  UI HELPERS
--==================================================================
local ACCENT = Color3.fromRGB(150, 240, 255)
local BG     = Color3.fromRGB(10, 10, 12)
local PANEL  = Color3.fromRGB(16, 16, 20)
local SIDE   = Color3.fromRGB(13, 13, 16)
local STROKE = Color3.fromRGB(32, 32, 40)
local DIM    = Color3.fromRGB(120, 122, 132)

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(obj, r)
    return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, obj)
end

local function stroke(obj, color, thick)
    return new("UIStroke", {
        Color = color or STROKE, Thickness = thick or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, obj)
end

local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
if game:GetService("CoreGui"):FindFirstChild("VeniceBB") then
    game:GetService("CoreGui").VeniceBB:Destroy()
end
local oldGui = guiParent:FindFirstChild("VeniceBB")
if oldGui then oldGui:Destroy() end

local sg = new("ScreenGui", {
    Name = "VeniceBB", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999
}, guiParent)

--==================================================================
--  WINDOW
--==================================================================
local main = new("Frame", {
    Size = UDim2.fromOffset(600, 410),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = BG, BorderSizePixel = 0, ClipsDescendants = true
}, sg)
corner(main, 14)
stroke(main, Color3.fromRGB(40, 40, 50), 1)

local grad = new("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(18, 18, 24), Color3.fromRGB(8, 8, 10)),
    Rotation = 90
}, main)

-- header
local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = Color3.fromRGB(14, 14, 18), BorderSizePixel = 0
}, main)

new("Frame", {
    Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = Color3.fromRGB(28, 28, 36), BorderSizePixel = 0
}, header)

local logo = new("TextLabel", {
    Size = UDim2.fromOffset(140, 20), Position = UDim2.fromOffset(20, 16),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 17,
    TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left,
    Text = "VENICE"
}, header)

new("TextLabel", {
    Size = UDim2.fromOffset(90, 20), Position = UDim2.fromOffset(112, 17),
    BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 11,
    TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left, Text = "blade ball"
}, header)

local statusLbl = new("TextLabel", {
    Size = UDim2.fromOffset(200, 20), Position = UDim2.new(1, -270, 0, 16),
    BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 11,
    TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Right, Text = "BAC: hooked"
}, header)

local closeBtn = new("TextButton", {
    Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -42, 0, 11),
    BackgroundColor3 = Color3.fromRGB(24, 24, 30), BorderSizePixel = 0,
    Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Color3.fromRGB(255, 110, 110), Text = "×"
}, header)
corner(closeBtn, 8)

-- drag
local dragging, dragStart, startPos
header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = i.Position; startPos = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- sidebar
local sidebar = new("Frame", {
    Size = UDim2.new(0, 150, 1, -52), Position = UDim2.fromOffset(0, 52),
    BackgroundColor3 = SIDE, BorderSizePixel = 0
}, main)

new("Frame", {
    Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0),
    BackgroundColor3 = Color3.fromRGB(26, 26, 32), BorderSizePixel = 0
}, sidebar)

local content = new("Frame", {
    Size = UDim2.new(1, -150, 1, -52), Position = UDim2.fromOffset(150, 52),
    BackgroundTransparency = 1, BorderSizePixel = 0
}, main)

local pages = {}
local tabs = {}

local function switchTab(name)
    for n, p in pairs(pages) do
        p.Visible = (n == name)
    end
    for n, b in pairs(tabs) do
        TweenService:Create(b, TweenInfo.new(0.18), {
            BackgroundColor3 = n == name and Color3.fromRGB(24, 24, 32) or Color3.fromRGB(15, 15, 19),
            TextColor3 = n == name and ACCENT or DIM
        }):Play()
        b.TextXAlignment = Enum.TextXAlignment.Left
    end
end

local function makeTab(name, label, order)
    local page = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(45, 45, 55),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    }, content)
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
        PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14)
    }, page)
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)

    local btn = new("TextButton", {
        Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, 10 + (order - 1) * 40),
        BackgroundColor3 = Color3.fromRGB(15, 15, 19), BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = DIM,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "   " .. label, AutoButtonColor = false
    }, sidebar)
    corner(btn, 8)
    btn.MouseButton1Click:Connect(function() switchTab(name) end)

    pages[name] = page
    tabs[name] = btn
    return page
end

local function section(parent, text)
    local l = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(90, 92, 102),
        TextXAlignment = Enum.TextXAlignment.Left, Text = string.upper(text)
    }, parent)
    return l
end

local function makeToggle(parent, text, default, callback)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = PANEL, BorderSizePixel = 0
    }, parent)
    corner(row, 8)

    new("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = Color3.fromRGB(215, 217, 225), TextXAlignment = Enum.TextXAlignment.Left, Text = text
    }, row)

    local pill = new("TextButton", {
        Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = default and ACCENT or Color3.fromRGB(38, 38, 46),
        BorderSizePixel = 0, Text = "", AutoButtonColor = false
    }, row)
    corner(pill, 10)

    local knob = new("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = default and UDim2.new(1, -18, 0, 2) or UDim2.fromOffset(2, 2),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0
    }, pill)
    corner(knob, 8)

    local state = default
    local function set(v)
        state = v
        TweenService:Create(pill, TweenInfo.new(0.16), {
            BackgroundColor3 = v and ACCENT or Color3.fromRGB(38, 38, 46)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.16), {
            Position = v and UDim2.new(1, -18, 0, 2) or UDim2.fromOffset(2, 2)
        }):Play()
        if callback then callback(v) end
    end
    pill.MouseButton1Click:Connect(function() set(not state) end)
    row.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then set(not state) end
    end)
    return { Set = set }
end

local function makeSlider(parent, text, min, max, default, decimals, callback)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = PANEL, BorderSizePixel = 0
    }, parent)
    corner(row, 8)

    local label = new("TextLabel", {
        Size = UDim2.new(1, -90, 0, 22), Position = UDim2.fromOffset(12, 8),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = Color3.fromRGB(215, 217, 225), TextXAlignment = Enum.TextXAlignment.Left, Text = text
    }, row)

    local valueLbl = new("TextLabel", {
        Size = UDim2.fromOffset(60, 22), Position = UDim2.new(1, -72, 0, 8),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Right,
        Text = string.format("%." .. decimals .. "f", default)
    }, row)

    local track = new("Frame", {
        Size = UDim2.new(1, -24, 0, 4), Position = UDim2.fromOffset(12, 38),
        BackgroundColor3 = Color3.fromRGB(38, 38, 46), BorderSizePixel = 0
    }, row)
    corner(track, 2)

    local fill = new("Frame", {
        Size = UDim2.fromScale((default - min) / (max - min), 1),
        BackgroundColor3 = ACCENT, BorderSizePixel = 0
    }, track)
    corner(fill, 2)

    local knob = new("Frame", {
        Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0
    }, track)
    corner(knob, 6)

    local value = default
    local function apply(v)
        value = math.clamp(v, min, max)
        local a = (value - min) / (max - min)
        fill.Size = UDim2.fromScale(a, 1)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        valueLbl.Text = string.format("%." .. decimals .. "f", value)
        if callback then callback(value) end
    end

    local hold = false
    local function fromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        apply(min + (max - min) * rel)
    end

    row.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            hold = true; fromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if hold and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            fromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            hold = false
        end
    end)

    return { Set = apply, Get = function() return value end }
end

local function makeButton(parent, text, callback)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = PANEL, BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(220, 222, 230),
        Text = text, AutoButtonColor = false
    }, parent)
    corner(b, 8)
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(26, 26, 34) }):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = PANEL }):Play() end)
    b.MouseButton1Click:Connect(callback)
    return b
end

--==================================================================
--  PAGES
--==================================================================
local pCombat = makeTab("combat", "Бой", 1)
local pVisual = makeTab("visual", "Визуал", 2)
local pSky    = makeTab("sky", "Небо", 3)
local pMisc   = makeTab("misc", "Прочее", 4)

-- COMBAT
section(pCombat, "Автопарри")
makeToggle(pCombat, "Включить автопарри", CFG.AutoParry, function(v) CFG.AutoParry = v end)
makeToggle(pCombat, "Учёт пинга", CFG.PingBased, function(v) CFG.PingBased = v end)
makeSlider(pCombat, "Множитель пинга", 0.5, 5, CFG.PingBasedOffset, 2, function(v) CFG.PingBasedOffset = v end)
makeSlider(pCombat, "Дистанция парри", 0.1, 3, CFG.DistanceToParry, 2, function(v) CFG.DistanceToParry = v end)
makeSlider(pCombat, "Аварийный радиус", 2, 40, CFG.EmergencyRadius, 0, function(v) CFG.EmergencyRadius = v end)
section(pCombat, "Клэш")
makeSlider(pCombat, "Дистанция клэша", 5, 60, CFG.ClashDistance, 0, function(v) CFG.ClashDistance = v end)
makeSlider(pCombat, "Задержка клэша", 0.005, 0.2, CFG.ClashSpeed, 3, function(v) CFG.ClashSpeed = v end)
makeSlider(pCombat, "Обычная задержка", 0.01, 0.3, CFG.NormalSpeed, 3, function(v) CFG.NormalSpeed = v end)
makeToggle(pCombat, "Парри через Remote (быстро)", CFG.RemoteParry, function(v) CFG.RemoteParry = v end)

-- VISUAL
section(pVisual, "Индикатор")
makeToggle(pVisual, "Круг-индикатор", CFG.Visuals, function(v)
    CFG.Visuals = v
    if circle then circle.Transparency = v and 0.3 or 1 end
end)
section(pVisual, "Камера")
makeToggle(pVisual, "Кастомный FOV", CFG.FOVEnabled, function(v) CFG.FOVEnabled = v end)
makeSlider(pVisual, "FOV", 40, 120, CFG.FOV, 0, function(v) CFG.FOV = v end)
makeButton(pVisual, "Сбросить FOV", function()
    CFG.FOVEnabled = false
    Camera.FieldOfView = ORIG.FOV
end)

-- SKY
section(pSky, "Освещение")
makeToggle(pSky, "Включить кастомизацию", CFG.SkyEnabled, function(v) CFG.SkyEnabled = v end)
makeSlider(pSky, "Время суток", 0, 24, CFG.ClockTime, 1, function(v) CFG.ClockTime = v end)
makeSlider(pSky, "Яркость", 0, 6, CFG.Brightness, 1, function(v) CFG.Brightness = v end)
makeSlider(pSky, "Туман (дальность)", 50, 5000, CFG.FogEnd, 0, function(v) CFG.FogEnd = v end)
makeSlider(pSky, "Плотность атмосферы", 0, 1, CFG.AtmoDensity, 2, function(v) CFG.AtmoDensity = v end)
makeSlider(pSky, "Дымка", 0, 10, CFG.AtmoHaze, 1, function(v) CFG.AtmoHaze = v end)
section(pSky, "Цветокоррекция")
makeSlider(pSky, "Насыщенность", -1, 1, CFG.Sat, 2, function(v) CFG.Sat = v end)
makeSlider(pSky, "Контраст", -1, 1, CFG.Contrast, 2, function(v) CFG.Contrast = v end)

section(pSky, "Пресеты")
local presetRow = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1 }, pSky)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, presetRow)

local presets = {
    ["Ночь"] = { ct = 0, br = 0.4, amb = Color3.fromRGB(20, 20, 34), fog = 260, dens = 0.45, haze = 3, sat = -0.25, con = 0.1, tint = Color3.fromRGB(180, 195, 255) },
    ["Кровь"] = { ct = 0, br = 0.8, amb = Color3.fromRGB(50, 10, 10), fog = 320, dens = 0.35, haze = 4, sat = 0.35, con = 0.15, tint = Color3.fromRGB(255, 130, 120) },
    ["Пустота"] = { ct = 0, br = 0, amb = Color3.fromRGB(0, 0, 0), fog = 70, dens = 1, haze = 8, sat = -1, con = 0.3, tint = Color3.fromRGB(255, 255, 255) },
    ["Кибер"] = { ct = 17, br = 2.5, amb = Color3.fromRGB(40, 20, 70), fog = 500, dens = 0.25, haze = 2, sat = 1, con = 0.2, tint = Color3.fromRGB(140, 220, 255) },
    ["Закат"] = { ct = 17.6, br = 2.2, amb = Color3.fromRGB(80, 45, 30), fog = 900, dens = 0.2, haze = 1, sat = 0.3, con = 0.05, tint = Color3.fromRGB(255, 200, 150) },
}
for name, p in pairs(presets) do
    local b = new("TextButton", {
        Size = UDim2.new(0, 92, 0, 30), BackgroundColor3 = PANEL, BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = Color3.fromRGB(210, 212, 220),
        Text = name, AutoButtonColor = false
    }, presetRow)
    corner(b, 7)
    b.MouseButton1Click:Connect(function()
        CFG.SkyEnabled = true
        CFG.ClockTime, CFG.Brightness = p.ct, p.br
        CFG.Ambient, CFG.FogEnd, CFG.AtmoDensity, CFG.AtmoHaze = p.amb, p.fog, p.dens, p.haze
        CFG.Sat, CFG.Contrast, CFG.Tint = p.sat, p.con, p.tint
        local cc = Lighting:FindFirstChild("VeniceCC")
        if cc then cc.TintColor = p.tint end
        local at = Lighting:FindFirstChild("VeniceAtmo")
        if at then at.Color = p.tint end
    end)
end

makeButton(pSky, "Сбросить всё", function()
    CFG.SkyEnabled = false
    Lighting.ClockTime = ORIG.ClockTime
    Lighting.Brightness = ORIG.Brightness
    Lighting.Ambient = ORIG.Ambient
    Lighting.OutdoorAmbient = ORIG.OutdoorAmbient
    Lighting.FogEnd = ORIG.FogEnd
    Lighting.FogColor = ORIG.FogColor
    local cc = Lighting:FindFirstChild("VeniceCC")
    if cc then cc:Destroy() end
    local at = Lighting:FindFirstChild("VeniceAtmo")
    if at then at:Destroy() end
end)

-- MISC
section(pMisc, "Скрипт")
makeButton(pMisc, "Перезагрузить меню", function()
    if getgenv().VeniceUnload then getgenv().VeniceUnload() end
end)
new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = DIM,
    TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
    Text = "RightShift — открыть/скрыть меню\nL — быстрое вкл/выкл автопарри\n\nБиндимые клавиши работают только при включённом скрипте."
}, pMisc)

--==================================================================
--  OPEN / CLOSE
--==================================================================
local open = true
local function setOpen(v)
    open = v
    if v then
        main.Visible = true
        main.Size = UDim2.fromOffset(560, 380)
        main.BackgroundTransparency = 1
        TweenService:Create(main, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(600, 410), BackgroundTransparency = 0
        }):Play()
    else
        local t = TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(560, 380), BackgroundTransparency = 1
        })
        t:Play()
        t.Completed:Connect(function() if not open then main.Visible = false end end)
    end
end
closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)

--==================================================================
--  INDICATOR CIRCLE
--==================================================================
local circle, mesh
do
    circle = new("Part", {
        Name = "VeniceCircle", Anchored = true, CanCollide = false,
        Transparency = 1, Material = Enum.Material.Neon, Size = Vector3.new(1, 1, 1)
    }, workspace)
    mesh = new("SpecialMesh", { MeshId = "rbxassetid://3270017" }, circle)
end

--==================================================================
--  PARRY CORE
--==================================================================
local function getBall()
    if not BallsFolder then return nil end
    local ch = BallsFolder:GetChildren()
    for _, v in ipairs(ch) do
        if v:GetAttribute("realBall") == true then return v end
    end
    for _, v in ipairs(ch) do
        if v:IsA("BasePart") and v.AssemblyLinearVelocity.Magnitude > 15 then return v end
    end
    return nil
end

local function isTargeted()
    local ch = Player.Character
    if not ch then return false end
    return ch:GetAttribute("Targeted") == true or ch:FindFirstChild("Highlight") ~= nil
end

local function sendParry(isClash, ball)
    if not CFG.AutoParry or IsParrying then return end
    local now = tick()
    local cd = isClash and CFG.ClashSpeed or CFG.NormalSpeed
    if not isClash and LastBallHit == ball and (now - LastClick) < 0.5 then return end
    if (now - LastClick) < cd then return end

    IsParrying, LastClick, LastBallHit = true, now, ball

    if CFG.RemoteParry and parryRemote then
        pcall(function() parryRemote:FireServer() end)
    else
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end

    task.delay(cd, function() IsParrying = false end)
end

local function updateCircle(root, dist, state)
    if not CFG.Visuals then circle.Transparency = 1 return end
    circle.Transparency = 0.3
    circle.CFrame = root.CFrame * CFrame.new(0, -2.6, 0) * CFrame.Angles(math.rad(90), 0, 0)
    local s = math.clamp(dist * 0.8, 5, 65)
    mesh.Scale = mesh.Scale:Lerp(Vector3.new(s, s, 0.5), 0.5)
    if state == "clash" then
        circle.Color, circle.Transparency = Color3.fromRGB(255, 60, 60), 0.05
    elseif state == "target" then
        circle.Color, circle.Transparency = ACCENT, 0.1
    else
        circle.Color, circle.Transparency = CFG.CircleColor, 0.5
    end
end

RunService.PostSimulation:Connect(function()
    if not CFG.AutoParry then circle.Transparency = 1 return end
    local ch = Player.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    if not root then circle.Transparency = 1 return end

    local ball = getBall()
    if not ball then circle.Transparency = 1 return end

    local bp, pp = ball.Position, root.Position
    local vel = ball.AssemblyLinearVelocity
    local speed = vel.Magnitude
    local dist = (pp - bp).Magnitude
    local dot = ((pp - bp).Unit):Dot(vel.Unit)

    if dot < 0 then LastBallHit = nil end

    local targeted = isTargeted()
    local clash = targeted and dist <= CFG.ClashDistance

    FrameCounter += 1
    if FrameCounter % 2 == 0 then
        updateCircle(root, dist, clash and "clash" or (targeted and "target" or "neutral"))
    end

    if clash then
        sendParry(true, ball)
    elseif targeted and dot > 0 then
        local ping = (CFG.PingBased and NetStats and NetStats.Value / 1000) or 0.04
        local tth = dist / math.max(speed, 1)
        local threshold = CFG.DistanceToParry + (ping * CFG.PingBasedOffset)
        if speed > 150 then threshold *= 1.15 end
        if tth <= threshold or dist <= CFG.EmergencyRadius then
            sendParry(false, ball)
        end
    end
end)

Player.CharacterAdded:Connect(function()
    LastBallHit, IsParrying = nil, false
end)

--==================================================================
--  FOV + SKY LOOPS
--==================================================================
RunService.RenderStepped:Connect(function()
    if CFG.FOVEnabled and Camera then
        Camera.FieldOfView = CFG.FOV
    end
end)

RunService.Heartbeat:Connect(function()
    if not CFG.SkyEnabled then return end

    local cc = Lighting:FindFirstChild("VeniceCC")
    if not cc then
        cc = new("ColorCorrectionEffect", { Name = "VeniceCC" }, Lighting)
    end
    local at = Lighting:FindFirstChild("VeniceAtmo")
    if not at then
        at = new("Atmosphere", { Name = "VeniceAtmo" }, Lighting)
    end

    Lighting.ClockTime = CFG.ClockTime
    Lighting.Brightness = CFG.Brightness
    Lighting.Ambient = CFG.Ambient
    Lighting.OutdoorAmbient = CFG.Ambient
    Lighting.FogEnd = CFG.FogEnd
    Lighting.FogColor = CFG.FogColor
    cc.Saturation = CFG.Sat
    cc.Contrast = CFG.Contrast
    cc.TintColor = CFG.Tint
    at.Density = CFG.AtmoDensity
    at.Haze = CFG.AtmoHaze
    at.Color = CFG.Tint
end)

--==================================================================
--  KEYBINDS
--==================================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setOpen(not open)
    elseif input.KeyCode == Enum.KeyCode.L then
        CFG.AutoParry = not CFG.AutoParry
    end
end)

--==================================================================
--  UNLOAD
--==================================================================
getgenv().VeniceUnload = function()
    pcall(function()
        sg:Destroy()
        if circle then circle:Destroy() end
        if Camera then Camera.FieldOfView = ORIG.FOV end
        Lighting.ClockTime = ORIG.ClockTime
        Lighting.Brightness = ORIG.Brightness
        Lighting.Ambient = ORIG.Ambient
        Lighting.OutdoorAmbient = ORIG.OutdoorAmbient
        Lighting.FogEnd = ORIG.FogEnd
        Lighting.FogColor = ORIG.FogColor
        local cc = Lighting:FindFirstChild("VeniceCC"); if cc then cc:Destroy() end
        local at = Lighting:FindFirstChild("VeniceAtmo"); if at then at:Destroy() end
    end)
end

switchTab("combat")
setOpen(true)
