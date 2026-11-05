--[[ Blade Ball — Venice Hub v9 | parry через Hotbar.Block, без VIM ]]

if getgenv().VeniceBB then pcall(function() getgenv().VeniceBB:Destroy() end) end

local ref = cloneref or function(s) return s end
local Players             = ref(game:GetService("Players"))
local RunService          = ref(game:GetService("RunService"))
local TweenService        = ref(game:GetService("TweenService"))
local UserInputService    = ref(game:GetService("UserInputService"))
local VirtualInputManager = ref(game:GetService("VirtualInputManager"))
local ReplicatedStorage   = ref(game:GetService("ReplicatedStorage"))

local LP = Players.LocalPlayer
while not LP do task.wait() end

local CONFIG = {
    autoParry = false,
    reaction  = 10,
    maxRange  = 170,
    jitter    = true,
    headless  = false,
    korblox   = false,
    safe      = true,
}

local ACCENT = Color3.fromRGB(152, 132, 255)
local BG     = Color3.fromRGB(9, 9, 11)
local ROW    = Color3.fromRGB(23, 23, 28)
local STROKE = Color3.fromRGB(41, 41, 49)
local TEXT   = Color3.fromRGB(238, 238, 244)
local SUB    = Color3.fromRGB(128, 128, 144)
local OKC    = Color3.fromRGB(120, 220, 160)
local WARNC  = Color3.fromRGB(255, 170, 90)

local function tw(o, t, p, s, d)
    local T = TweenService:Create(o, TweenInfo.new(t, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out), p)
    T:Play()
    return T
end

task.wait(2)

local protectFn = protectgui or protect_gui or (syn and syn.protect_gui)
local container, containerName = nil, "playergui"
if gethui then
    local ok, h = pcall(gethui)
    if ok and typeof(h) == "Instance" then container, containerName = h, "gethui" end
end
if not container then
    container = game:GetService("CoreGui")
    containerName = protectFn and "protect+core" or "core"
end

local gui = Instance.new("ScreenGui")
gui.Name = "VeniceBB"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 500
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if protectFn then pcall(protectFn, gui) end
if not pcall(function() gui.Parent = container end) then
    gui.Parent = LP:WaitForChild("PlayerGui")
    containerName = "playergui!"
end
getgenv().VeniceBB = gui

-- ============================== каркас ==============================

local main = Instance.new("Frame")
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.5)
main.Size = UDim2.fromOffset(340, 452)
main.BackgroundColor3 = BG
main.BackgroundTransparency = 0.03
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Visible = false
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 13)
local mStroke = Instance.new("UIStroke", main)
mStroke.Color = STROKE
mStroke.Transparency = 0.25

task.wait(0.1)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 54)
header.BackgroundTransparency = 1
header.Parent = main

local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(7, 7)
dot.Position = UDim2.fromOffset(16, 22)
dot.BackgroundColor3 = ACCENT
dot.BorderSizePixel = 0
dot.Parent = header
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 0, 18)
title.Position = UDim2.fromOffset(30, 15)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = TEXT
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "VENICE  ·  BLADE BALL"
title.Parent = header

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -70, 0, 15)
status.Position = UDim2.fromOffset(30, 31)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 10
status.TextColor3 = OKC
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "safe · parry: remote"
status.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(26, 26)
closeBtn.Position = UDim2.new(1, -36, 0, 13)
closeBtn.BackgroundColor3 = ROW
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 15
closeBtn.TextColor3 = SUB
closeBtn.Text = "×"
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 7)

task.wait(0.1)

local body = Instance.new("ScrollingFrame")
body.Size = UDim2.new(1, -18, 1, -92)
body.Position = UDim2.fromOffset(9, 62)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 2
body.ScrollBarImageColor3 = ACCENT
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.Parent = main

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 7)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = body

local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, -18, 0, 22)
footer.Position = UDim2.new(0, 9, 1, -26)
footer.BackgroundTransparency = 1
footer.Font = Enum.Font.Gotham
footer.TextSize = 10
footer.TextColor3 = Color3.fromRGB(86, 86, 98)
footer.Text = "Z  —  свернуть меню"
footer.Parent = main

-- ============================== строки ==============================

local order = 0
local function baseRow(tx, dx, h)
    order = order + 1
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, -4, 0, h)
    r.BackgroundColor3 = ROW
    r.BackgroundTransparency = 0.15
    r.BorderSizePixel = 0
    r.LayoutOrder = order
    r.Parent = body
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, 9)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -64, 0, 15)
    t.Position = UDim2.fromOffset(11, 8)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamSemibold
    t.TextSize = 12
    t.TextColor3 = TEXT
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = tx
    t.Parent = r

    if dx then
        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(1, -64, 0, 13)
        d.Position = UDim2.fromOffset(11, 24)
        d.BackgroundTransparency = 1
        d.Font = Enum.Font.Gotham
        d.TextSize = 9
        d.TextColor3 = SUB
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.Text = dx
        d.Parent = r
    end
    return r
end

local function toggleRow(tx, dx, default, cb)
    local r = baseRow(tx, dx, 46)
    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(34, 17)
    track.Position = UDim2.new(1, -45, 0.5, -8)
    track.BackgroundColor3 = default and ACCENT or Color3.fromRGB(45, 45, 54)
    track.BorderSizePixel = 0
    track.Parent = r
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(11, 11)
    knob.Position = default and UDim2.fromOffset(20, 3) or UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = default and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default or false
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = r
    btn.MouseButton1Click:Connect(function()
        state = not state
        tw(track, 0.16, { BackgroundColor3 = state and ACCENT or Color3.fromRGB(45, 45, 54) })
        tw(knob, 0.16, {
            Position = state and UDim2.fromOffset(20, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160),
        })
        task.spawn(function() pcall(cb, state) end)
    end)
    return r
end

local function sliderRow(tx, min, max, default, cb)
    local r = baseRow(tx, nil, 52)
    local val = Instance.new("TextLabel")
    val.Size = UDim2.fromOffset(40, 15)
    val.Position = UDim2.new(1, -52, 0, 8)
    val.BackgroundTransparency = 1
    val.Font = Enum.Font.GothamBold
    val.TextSize = 11
    val.TextColor3 = ACCENT
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Text = tostring(default)
    val.Parent = r

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -22, 0, 4)
    bar.Position = UDim2.new(0, 11, 0, 34)
    bar.BackgroundColor3 = Color3.fromRGB(45, 45, 54)
    bar.BorderSizePixel = 0
    bar.Parent = r
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale((default - min) / (max - min), 1)
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(9, 9)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = bar
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function setX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + (max - min) * rel + 0.5)
        val.Text = tostring(v)
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        pcall(cb, v)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return r
end

local function buttonRow(tx, dx, cb)
    local r = baseRow(tx, dx, 42)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = r
    local lbl = r:FindFirstChildOfClass("TextLabel")
    btn.MouseEnter:Connect(function() tw(lbl, 0.15, { TextColor3 = ACCENT }) end)
    btn.MouseLeave:Connect(function() tw(lbl, 0.15, { TextColor3 = TEXT }) end)
    btn.MouseButton1Click:Connect(function()
        tw(lbl, 0.1, { TextColor3 = OKC })
        task.delay(0.25, function() tw(lbl, 0.2, { TextColor3 = TEXT }) end)
        task.spawn(function() pcall(cb) end)
    end)
    return r
end

-- ============================== окно ==============================

local open = true
local function setOpen(state)
    if state == open then return end
    open = state
    if state then
        main.Visible = true
        main.BackgroundTransparency = 1
        tw(main, 0.22, { BackgroundTransparency = 0.03 })
    else
        tw(main, 0.16, { BackgroundTransparency = 1 })
        task.delay(0.17, function() if not open then main.Visible = false end end)
    end
end

closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Z and not UserInputService:GetFocusedTextBox() then
        setOpen(not open)
    end
end)

local dragging, dragStart, startPos
header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = i.Position
        startPos = main.Position
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

-- ============================== парирование через кнопку игры ==============================

local Balls = workspace:WaitForChild("Balls", 30)
local tracked, prevPos = {}, {}
local loopConn = nil
local blockCache = nil

local function verifyBall(b)
    return typeof(b) == "Instance" and b:IsA("BasePart")
        and b:IsDescendantOf(Balls) and b:GetAttribute("realBall") == true
end

local function isTarget()
    return LP.Character ~= nil and LP.Character:FindFirstChild("Highlight") ~= nil
end

local function getBlock()
    if blockCache and blockCache.Parent then return blockCache end
    blockCache = nil
    local pg = LP:FindFirstChild("PlayerGui")
    local hotbar = pg and pg:FindFirstChild("Hotbar")
    local btn = hotbar and hotbar:FindFirstChild("Block")
    if btn then
        blockCache = btn
        return btn
    end
end

local method = "remote"

local function Parry()
    local block = getBlock()

    if block then
        if firesignal then
            local ok = pcall(firesignal, block.Activated)
            if ok then return end
        end
        if getconnections then
            local ok = pcall(function()
                for _, c in ipairs(getconnections(block.Activated)) do
                    if c.Enabled then c:Fire() end
                end
            end)
            if ok then return end
        end
    end

    method = "vim"
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function step()
    if not isTarget() then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local eye = cam.CFrame.Position
    for b in pairs(tracked) do
        if not b.Parent or not b:IsDescendantOf(Balls) then
            tracked[b] = nil
            prevPos[b] = nil
        else
            local pos  = b.Position
            local prev = prevPos[b] or pos
            prevPos[b] = pos
            local vel  = (prev - pos).Magnitude
            local dist = (pos - eye).Magnitude
            if vel > 0.15 and dist <= CONFIG.maxRange and (prev - eye).Magnitude > dist then
                local thr = CONFIG.reaction
                local spread = CONFIG.safe and 0.22 or 0.1
                if CONFIG.jitter then thr = thr * (1 - spread / 2 + math.random() * spread) end
                if (dist / vel) <= thr then Parry() end
            end
        end
    end
end

local function setParry(on)
    CONFIG.autoParry = on
    if loopConn then loopConn:Disconnect() loopConn = nil end
    if on then
        if Balls then
            for _, b in ipairs(Balls:GetChildren()) do
                if verifyBall(b) then tracked[b] = true prevPos[b] = b.Position end
            end
        end
        loopConn = RunService.RenderStepped:Connect(step)
    end
end

-- ============================== внешность ==============================

local korbloxMesh = nil
local applying = false

local function waitAppearance()
    local char = LP.Character
    if not char then return nil end
    if CONFIG.safe and not LP:HasAppearanceLoaded() then
        local t = 0
        while not LP:HasAppearanceLoaded() and t < 40 do
            task.wait(0.1)
            t = t + 1
        end
    end
    return LP.Character
end

local function applyHeadless(on)
    local char = waitAppearance()
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    head.Transparency = on and 1 or 0
    for _, v in ipairs(head:GetChildren()) do
        if v:IsA("Decal") then v.Transparency = on and 1 or 0 end
    end
end

local function applyKorblox(on)
    local char = waitAppearance()
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.RigType ~= Enum.HumanoidRigType.R6 then return end
    if on then
        if korbloxMesh and korbloxMesh.Parent then korbloxMesh:Destroy() end
        local m = Instance.new("CharacterMesh")
        m.Name = "VeniceKorblox"
        m.BodyPart = Enum.BodyPart.RightLeg
        m.MeshId = 101851696
        m.OverlayTextureId = 101851254
        m.Parent = char
        korbloxMesh = m
    elseif korbloxMesh then
        korbloxMesh:Destroy()
        korbloxMesh = nil
    end
end

local function refreshCosmetics()
    if applying then return end
    applying = true
    task.spawn(function()
        if CONFIG.safe then task.wait(1.2) else task.wait(0.2) end
        if CONFIG.headless then applyHeadless(true) end
        if CONFIG.safe then task.wait(0.4) end
        if CONFIG.korblox then applyKorblox(true) end
        applying = false
    end)
end

LP.CharacterAdded:Connect(function()
    blockCache = nil
    task.wait(1)
    refreshCosmetics()
end)

-- ============================== BAC ==============================

local bac = { removed = false, hooked = false }
local echoed = {}

local function installEcho()
    local sec = ReplicatedStorage:FindFirstChild("Security")
    if not sec then return end
    for _, v in ipairs(sec:GetDescendants()) do
        if v:IsA("RemoteEvent") and not echoed[v] then
            echoed[v] = true
            v.OnClientEvent:Connect(function(...)
                local packed = table.pack(...)
                if packed.n == 0 then return end
                task.delay(0.02, function()
                    pcall(function() v:FireServer(table.unpack(packed, 1, packed.n)) end)
                end)
            end)
        end
    end
end

local function removeBac()
    if bac.removed then
        status.Text = "bac уже удалён"
        return
    end
    bac.removed = true
    status.Text = "удаляю bac..."
    status.TextColor3 = WARNC

    installEcho()
    task.wait(0.6)

    local killed = 0
    local function killScripts(c)
        if not c then return end
        for _, v in ipairs(c:GetChildren()) do
            if v:IsA("BaseScript") and not v.Name:match("[Dd]evice")
                and (v.Name:match("[Aa]nti") or v.Name:match("BAC") or v.Name:match("[Cc]heck")) then
                pcall(function() v.Disabled = true end)
                killed = killed + 1
            end
        end
    end
    killScripts(LP.PlayerScripts)
    killScripts(LP.PlayerScripts:FindFirstChild("Client"))

    local sec = ReplicatedStorage:FindFirstChild("Security")
    if sec then
        for _, v in ipairs(sec:GetDescendants()) do
            if v:IsA("BaseScript") then
                pcall(function() v.Disabled = true end)
                killed = killed + 1
            end
        end
    end

    task.wait(0.4)
    local dc = LP.PlayerScripts:FindFirstChild("Client")
    local dev = dc and dc:FindFirstChild("DeviceChecker")
    if dev then pcall(function() dev:Destroy() end) end

    status.Text = string.format("bac удалён · снято %d", killed)
    status.TextColor3 = OKC
end

-- ============================== наполнение ==============================

local function build()
    toggleRow("Безопасный режим", "медленно, после загрузки вида", CONFIG.safe, function(v)
        CONFIG.safe = v
        status.Text = (v and "safe" or "normal") .. " · parry: " .. method
        status.TextColor3 = v and OKC or SUB
    end)
    task.wait(0.06)
    buttonRow("Удалить BAC", "проверялки + DeviceChecker, эхо остаётся", removeBac)
    task.wait(0.06)
    toggleRow("Auto Parry", "через Hotbar.Block, не VIM", CONFIG.autoParry, setParry)
    task.wait(0.06)
    sliderRow("Reaction (frames)", 2, 22, CONFIG.reaction, function(v) CONFIG.reaction = v end)
    task.wait(0.06)
    toggleRow("Parry Jitter", "случайный разброс тайминга", CONFIG.jitter, function(v) CONFIG.jitter = v end)
    task.wait(0.06)
    toggleRow("Headless", "голова + face прозрачные", CONFIG.headless, function(v)
        CONFIG.headless = v
        task.spawn(function()
            if CONFIG.safe then task.wait(1.2) end
            applyHeadless(v)
        end)
    end)
    task.wait(0.06)
    toggleRow("Korblox", "CharacterMesh на правую ногу", CONFIG.korblox, function(v)
        CONFIG.korblox = v
        task.spawn(function()
            if CONFIG.safe then task.wait(1.2) end
            applyKorblox(v)
        end)
    end)
end

task.spawn(function()
    build()
    task.wait(0.1)
    main.Visible = true
    main.BackgroundTransparency = 1
    tw(main, 0.25, { BackgroundTransparency = 0.03 })
end)

print("[Venice] v9 · parry: Hotbar.Block")
