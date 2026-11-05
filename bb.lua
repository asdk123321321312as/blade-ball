--[[ Blade Ball — Venice Hub v5 | protected GUI + cloneref ]]

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

local function capFps(v)
    if setfpscap then pcall(setfpscap, v) end
end
capFps(9999)

local CONFIG = {
    autoParry = false,
    reaction  = 10,
    maxRange  = 170,
    jitter    = true,
    headless  = false,
    korblox   = false,
    fps60     = false,
    killChecks= false,
    aggressive= false,
    hooks     = false,
}

local ACCENT = Color3.fromRGB(152, 132, 255)
local BG     = Color3.fromRGB(9, 9, 11)
local ROW    = Color3.fromRGB(24, 24, 29)
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

task.wait(1.5)
local Balls = workspace:WaitForChild("Balls", 30)

-- ============================== защищённый контейнер ==============================

local function hiddenParent(guiObj)
    local protect = protectgui or protect_gui or (syn and syn.protect_gui)
    if protect then pcall(protect, guiObj) end

    local target
    if gethui then
        local ok, h = pcall(gethui)
        if ok and typeof(h) == "Instance" then target = h end
    end
    target = target or game:GetService("CoreGui")

    if pcall(function() guiObj.Parent = target end) then return true end
    guiObj.Parent = LP:WaitForChild("PlayerGui")
    return false
end

-- ============================== UI ==============================

local gui = Instance.new("ScreenGui")
gui.Name = "VeniceBB"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hiddenParent(gui)
getgenv().VeniceBB = gui

local isCG = pcall(function() local c = Instance.new("CanvasGroup"); c:Destroy() end)
local main = isCG and Instance.new("CanvasGroup") or Instance.new("Frame")
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.5)
main.Size = UDim2.fromOffset(386, 500)
main.BackgroundColor3 = BG
main.BackgroundTransparency = 0.02
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
local mStroke = Instance.new("UIStroke", main)
mStroke.Color = STROKE
mStroke.Transparency = 0.25

local scaleObj = Instance.new("UIScale", main)
scaleObj.Scale = 0.86

local function fade(o, to, t, s, d)
    if isCG then tw(o, t, { GroupTransparency = to }, s, d)
    else tw(o, t, { BackgroundTransparency = math.clamp(to + 0.05, 0, 1) }, s, d) end
end

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 58)
header.BackgroundTransparency = 1
header.Parent = main

local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(8, 8)
dot.Position = UDim2.fromOffset(18, 24)
dot.BackgroundColor3 = ACCENT
dot.BorderSizePixel = 0
dot.Parent = header
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 0, 20)
title.Position = UDim2.fromOffset(34, 16)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = TEXT
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "VENICE  ·  BLADE BALL"
title.Parent = header

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -80, 0, 16)
status.Position = UDim2.fromOffset(34, 33)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextColor3 = OKC
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "gui скрыт · fps 9999"
status.Parent = header

local line = Instance.new("Frame")
line.Size = UDim2.new(1, -36, 0, 1)
line.Position = UDim2.fromOffset(18, 57)
line.BackgroundColor3 = STROKE
line.BorderSizePixel = 0
line.Parent = header

local grad = Instance.new("Frame")
grad.Size = UDim2.fromOffset(110, 1)
grad.BackgroundColor3 = ACCENT
grad.BorderSizePixel = 0
grad.Position = UDim2.fromOffset(18, 57)
grad.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -40, 0, 14)
closeBtn.BackgroundColor3 = ROW
closeBtn.BackgroundTransparency = 0.3
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = SUB
closeBtn.Text = "×"
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local body = Instance.new("ScrollingFrame")
body.Size = UDim2.new(1, -20, 1, -126)
body.Position = UDim2.fromOffset(10, 68)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 3
body.ScrollBarImageColor3 = ACCENT
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.Parent = main

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = body

local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, -20, 0, 30)
footer.Position = UDim2.new(0, 10, 1, -34)
footer.BackgroundTransparency = 1
footer.Font = Enum.Font.Gotham
footer.TextSize = 11
footer.TextColor3 = Color3.fromRGB(88, 88, 100)
footer.Text = "Z  —  свернуть меню"
footer.Parent = main

local toastBox = Instance.new("Frame")
toastBox.Size = UDim2.new(1, -20, 0, 26)
toastBox.Position = UDim2.new(0, 10, 1, -66)
toastBox.BackgroundColor3 = ROW
toastBox.BackgroundTransparency = 1
toastBox.BorderSizePixel = 0
toastBox.Parent = main
Instance.new("UICorner", toastBox).CornerRadius = UDim.new(0, 8)
local toastLbl = Instance.new("TextLabel")
toastLbl.Size = UDim2.fromScale(1, 1)
toastLbl.BackgroundTransparency = 1
toastLbl.Font = Enum.Font.GothamMedium
toastLbl.TextSize = 11
toastLbl.TextColor3 = TEXT
toastLbl.TextTransparency = 1
toastLbl.Parent = toastBox

local toastToken = 0
local function toast(msg, color)
    toastToken = toastToken + 1
    local my = toastToken
    toastLbl.Text = msg
    toastLbl.TextColor3 = color or TEXT
    tw(toastBox, 0.15, { BackgroundTransparency = 0.25 })
    tw(toastLbl, 0.15, { TextTransparency = 0 })
    task.delay(1.9, function()
        if my ~= toastToken then return end
        tw(toastBox, 0.25, { BackgroundTransparency = 1 })
        tw(toastLbl, 0.25, { TextTransparency = 1 })
    end)
end

local order = 0
local function row(tx, dx)
    order = order + 1
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, -4, 0, 50)
    r.BackgroundColor3 = ROW
    r.BackgroundTransparency = 0.2
    r.BorderSizePixel = 0
    r.LayoutOrder = order
    r.Parent = body
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke", r)
    s.Color = STROKE
    s.Transparency = 0.55

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -70, 0, 16)
    t.Position = UDim2.fromOffset(12, 9)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamSemibold
    t.TextSize = 13
    t.TextColor3 = TEXT
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = tx
    t.Parent = r

    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(1, -70, 0, 14)
    d.Position = UDim2.fromOffset(12, 27)
    d.BackgroundTransparency = 1
    d.Font = Enum.Font.Gotham
    d.TextSize = 10
    d.TextColor3 = SUB
    d.TextXAlignment = Enum.TextXAlignment.Left
    d.Text = dx
    d.Parent = r

    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(36, 18)
    track.Position = UDim2.new(1, -48, 0.5, -9)
    track.BackgroundColor3 = Color3.fromRGB(45, 45, 54)
    track.BorderSizePixel = 0
    track.Parent = r
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(12, 12)
    knob.Position = UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    return r, track, knob
end

local function toggleRow(tx, dx, default, cb)
    local r, track, knob = row(tx, dx)
    local state = default or false
    local function paint(on, anim)
        if anim then
            tw(track, 0.18, { BackgroundColor3 = on and ACCENT or Color3.fromRGB(45, 45, 54) })
            tw(knob, 0.18, {
                Position = on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3),
                BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160),
            })
        else
            track.BackgroundColor3 = on and ACCENT or Color3.fromRGB(45, 45, 54)
            knob.Position = on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
            knob.BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
        end
    end
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = r
    btn.MouseButton1Click:Connect(function()
        state = not state
        paint(state, true)
        task.spawn(function() pcall(cb, state) end)
    end)
    paint(state, false)
    return r
end

local function sliderRow(tx, min, max, default, cb)
    order = order + 1
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, -4, 0, 58)
    r.BackgroundColor3 = ROW
    r.BackgroundTransparency = 0.2
    r.BorderSizePixel = 0
    r.LayoutOrder = order
    r.Parent = body
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke", r)
    s.Color = STROKE
    s.Transparency = 0.55

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -70, 0, 16)
    t.Position = UDim2.fromOffset(12, 9)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamSemibold
    t.TextSize = 13
    t.TextColor3 = TEXT
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = tx
    t.Parent = r

    local val = Instance.new("TextLabel")
    val.Size = UDim2.fromOffset(46, 16)
    val.Position = UDim2.new(1, -58, 0, 9)
    val.BackgroundTransparency = 1
    val.Font = Enum.Font.GothamBold
    val.TextSize = 12
    val.TextColor3 = ACCENT
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Text = tostring(default)
    val.Parent = r

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -24, 0, 4)
    bar.Position = UDim2.new(0, 12, 0, 38)
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
    knob.Size = UDim2.fromOffset(10, 10)
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

local open, busy = true, false
local bubble = Instance.new("TextButton")
bubble.Size = UDim2.fromOffset(46, 46)
bubble.AnchorPoint = Vector2.new(0.5, 1)
bubble.Position = UDim2.new(0.5, 0, 1, -70)
bubble.BackgroundColor3 = BG
bubble.BackgroundTransparency = 1
bubble.BorderSizePixel = 0
bubble.AutoButtonColor = false
bubble.Font = Enum.Font.GothamBold
bubble.TextSize = 17
bubble.TextColor3 = ACCENT
bubble.Text = "V"
bubble.Visible = false
bubble.Parent = gui
Instance.new("UICorner", bubble).CornerRadius = UDim.new(1, 0)
local bStroke = Instance.new("UIStroke", bubble)
bStroke.Color = STROKE
bStroke.Transparency = 0.2

local function setOpen(state)
    if busy or state == open then return end
    busy = true
    open = state
    if state then
        main.Visible = true
        tw(scaleObj, 0.34, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        fade(main, 0, 0.24)
        tw(bubble, 0.18, { BackgroundTransparency = 1 })
        task.delay(0.18, function() bubble.Visible = false end)
    else
        tw(scaleObj, 0.22, { Scale = 0.85 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        fade(main, 1, 0.2)
        task.delay(0.22, function() main.Visible = false end)
        bubble.Visible = true
        tw(bubble, 0.22, { BackgroundTransparency = 0 })
    end
    task.delay(0.38, function() busy = false end)
end

bubble.MouseButton1Click:Connect(function() setOpen(true) end)
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

-- ============================== auto parry ==============================

local function verifyBall(b)
    return typeof(b) == "Instance" and b:IsA("BasePart")
        and b:IsDescendantOf(Balls) and b:GetAttribute("realBall") == true
end

local function isTarget()
    return LP.Character ~= nil and LP.Character:FindFirstChild("Highlight") ~= nil
end

local lastParry = 0
local function Parry()
    local now = os.clock()
    if now - lastParry < 0.055 then return end
    lastParry = now
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local tracked, prevPos = {}, {}
local function watchBall(b)
    if tracked[b] or not verifyBall(b) then return end
    tracked[b] = true
    prevPos[b] = b.Position
end

if Balls then
    for _, b in ipairs(Balls:GetChildren()) do watchBall(b) end
    Balls.ChildAdded:Connect(watchBall)
end

RunService.RenderStepped:Connect(function()
    if not CONFIG.autoParry or not isTarget() then return end
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
                if CONFIG.jitter then thr = thr * (0.9 + math.random() * 0.2) end
                if (dist / vel) <= thr then Parry() end
            end
        end
    end
end)

-- ============================== headless / korblox ==============================

local korbloxMesh, korbloxParts = nil, {}

local function setHeadless(on)
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = on and 1 or 0
        for _, v in ipairs(head:GetChildren()) do
            if v:IsA("Decal") then v.Transparency = on and 1 or 0 end
        end
    end
end

local function setKorblox(on)
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if on then
        if hum.RigType == Enum.HumanoidRigType.R6 then
            if korbloxMesh then korbloxMesh:Destroy() end
            local m = Instance.new("CharacterMesh")
            m.Name = "VeniceKorblox"
            m.BodyPart = Enum.BodyPart.RightLeg
            m.MeshId = 101851696
            m.OverlayTextureId = 101851254
            m.Parent = char
            korbloxMesh = m
        else
            for _, name in ipairs({ "RightUpperLeg", "RightLowerLeg", "RightFoot" }) do
                local part = char:FindFirstChild(name)
                if part then
                    local old = part:FindFirstChildOfClass("SpecialMesh")
                    if old then old:Destroy() end
                    local m = Instance.new("SpecialMesh")
                    m.MeshType = Enum.MeshType.FileMesh
                    m.MeshId = name == "RightFoot" and "rbxassetid://902942089"
                        or name == "RightLowerLeg" and "rbxassetid://902942093"
                        or "rbxassetid://902942096"
                    m.TextureId = "rbxassetid://902843398"
                    m.Parent = part
                    table.insert(korbloxParts, { part = part, mesh = m })
                end
            end
        end
    else
        if korbloxMesh then korbloxMesh:Destroy() korbloxMesh = nil end
        for _, e in ipairs(korbloxParts) do
            if e.mesh then e.mesh:Destroy() end
        end
        korbloxParts = {}
    end
end

LP.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid", 10)
    task.wait(0.6)
    if CONFIG.headless then setHeadless(true) end
    if CONFIG.korblox  then setKorblox(true) end
end)

-- ============================== BAC ==============================

local bac = { hooked = false }
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

local function installHooks()
    if bac.hooked or not hookmetamethod then return end
    bac.hooked = true
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "Kick" and self == LP then
            warn("[Venice] KICK: " .. tostring(select(1, ...)))
        end
        return oldNamecall(self, ...)
    end)
end

local function disableChecks()
    local killed = 0
    local function kill(c)
        if not c then return end
        for _, v in ipairs(c:GetChildren()) do
            if v:IsA("BaseScript") and not v.Name:match("[Dd]evice")
                and (v.Name:match("[Aa]nti") or v.Name:match("BAC") or v.Name:match("[Cc]heck")) then
                pcall(function() v.Disabled = true end)
                killed = killed + 1
            end
        end
    end
    kill(LP.PlayerScripts)
    kill(LP.PlayerScripts:FindFirstChild("Client"))
    return killed
end

local function applyBac()
    if CONFIG.hooks then installHooks() end
    task.wait(0.4)
    installEcho()
    task.wait(0.3)

    local killed = 0
    if CONFIG.killChecks or CONFIG.aggressive then killed = disableChecks() end

    if CONFIG.aggressive then
        local dc = LP.PlayerScripts:FindFirstChild("Client")
        local dev = dc and dc:FindFirstChild("DeviceChecker")
        if dev then pcall(function() dev:Destroy() end) end
        status.Text = string.format("aggressive · снято %d", killed)
        status.TextColor3 = WARNC
    elseif CONFIG.killChecks then
        status.Text = string.format("проверялок снято: %d", killed)
        status.TextColor3 = OKC
    else
        status.Text = "gui скрыт · bypass выкл"
        status.TextColor3 = SUB
    end
end

-- ============================== rows ==============================

toggleRow("Auto Parry", "реакция по velocity + jitter", CONFIG.autoParry, function(v)
    CONFIG.autoParry = v
    toast(v and "Auto Parry вкл" or "Auto Parry выкл", v and OKC or SUB)
end)

sliderRow("Reaction (frames)", 2, 22, CONFIG.reaction, function(v)
    CONFIG.reaction = v
end)

toggleRow("Parry Jitter", "случайный разброс тайминга", CONFIG.jitter, function(v)
    CONFIG.jitter = v
end)

toggleRow("Headless", "клиентская голова-невидимка", CONFIG.headless, function(v)
    CONFIG.headless = v
    if LP.Character then setHeadless(v) end
end)

toggleRow("Korblox", "CharacterMesh · правая нога", CONFIG.korblox, function(v)
    CONFIG.korblox = v
    if LP.Character then setKorblox(v) end
end)

toggleRow("FPS Cap 60", "выкл = 9999 (как в хабах)", CONFIG.fps60, function(v)
    capFps(v and 60 or 9999)
    toast(v and "кап 60" or "анкап 9999", v and OKC or WARNC)
end)

toggleRow("Снять проверялки", "Disabled на античит-скриптах", CONFIG.killChecks, function(v)
    CONFIG.killChecks = v
    applyBac()
end)

toggleRow("Aggressive", "DeviceChecker + все проверки", CONFIG.aggressive, function(v)
    CONFIG.aggressive = v
    applyBac()
end)

toggleRow("Hooks", "перехват namecall (логи)", CONFIG.hooks, function(v)
    CONFIG.hooks = v
    if v then installHooks() end
end)

task.spawn(function()
    tw(scaleObj, 0.42, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    fade(main, 0, 0.3)
    task.wait(0.8)
    installEcho()
end)

print("[Venice] v5 loaded · protected gui · fps 9999")
