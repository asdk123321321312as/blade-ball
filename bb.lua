--[[ Blade Ball — Venice Hub v16 | bypass 1 ур. + захват пакета + GUI ]]

if getgenv().VeniceBB then pcall(function() getgenv().VeniceBB:Destroy() end) end
if getgenv().VeniceBBConns then
    for _, c in ipairs(getgenv().VeniceBBConns) do pcall(function() c:Disconnect() end) end
end
getgenv().VeniceBBConns = {}

local unpack = unpack or table.unpack

local ref = cloneref or function(s) return s end
local Players             = ref(game:GetService("Players"))
local RunService          = ref(game:GetService("RunService"))
local TweenService        = ref(game:GetService("TweenService"))
local UserInputService    = ref(game:GetService("UserInputService"))
local VirtualInputManager = ref(game:GetService("VirtualInputManager"))
local ReplicatedStorage   = ref(game:GetService("ReplicatedStorage"))

local LP = Players.LocalPlayer
while not LP do task.wait() end

local function track(c) table.insert(getgenv().VeniceBBConns, c) return c end

local CONFIG = {
    bypass    = true,
    method    = "packet",  -- packet | touch | click | signal
    parryDist = 12,
    jitter    = 0.18,
    accuracy  = 85,
    cooldown  = 0.28,
    maxRange  = 170,
    autoParry = false,
    dump      = true,
    safe      = true,
    echo      = false,
    headless  = false,
    korblox   = false,
    mount     = "auto",
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

-- ============================== уровень 1 ==============================

local function applyBypass()
    if not (hookfunction and getrenv) then return false end
    if getgenv().VeniceBBHooked then return true end
    getgenv().VeniceBBHooked = true

    local origInfo = getrenv().debug.info
    local newInfo
    newInfo = hookfunction(origInfo, function(f, t)
        if type(f) == "function" then
            if t == nil or t == "a" then return origInfo(f, t) end
            return "[C]"
        end
        if f == 4 and t == "s" then
            return "ReplicatedStorage.Controllers.SwordsController"
        end
        return origInfo(f, t)
    end)
    getgenv().VeniceBBOrigInfo, getgenv().VeniceBBInfo = origInfo, newInfo

    local origEnv = getrenv().getfenv
    local newEnv
    newEnv = hookfunction(origEnv, function(l)
        if type(l) == "number" and l >= 1 and l <= 10 then return origEnv(10) end
        if type(l) == "function" then return origEnv(l) end
        return origEnv(1)
    end)
    getgenv().VeniceBBOrigEnv, getgenv().VeniceBBEnv = origEnv, newEnv
    return true
end

local function dropBypass()
    if not getgenv().VeniceBBHooked then return end
    pcall(function() hookfunction(getgenv().VeniceBBInfo, getgenv().VeniceBBOrigInfo) end)
    pcall(function() hookfunction(getgenv().VeniceBBEnv, getgenv().VeniceBBOrigEnv) end)
    getgenv().VeniceBBHooked = false
end

if CONFIG.bypass then applyBypass() end

-- ============================== захват пакета ==============================

local cap = { remote = nil, args = nil }
local capturing = true
local attempts = 0
local oldNamecall = nil

local function updateStatus() end

local function installCapture()
    if oldNamecall or not (hookmetamethod and getnamecallmethod) then return end
    pcall(function()
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            if capturing and getnamecallmethod() == "FireServer"
                and typeof(self) == "Instance" and self:IsA("RemoteEvent") then
                local full = self:GetFullName()
                local looks = self.Name:match("[Pp]arry") or self.Name:match("[Bb]lock")
                    or full:match("[Pp]arry") or full:match("[Bb]lock")
                if looks or attempts < 6 then
                    attempts = attempts + 1
                    if looks or not cap.remote then
                        cap.remote = self
                        cap.args = table.pack(...)
                        print(("[Venice] захвачено: %s (%d арг.)%s"):format(
                            full, cap.args.n, looks and "" or " — не похоже на парирование"))
                        if CONFIG.dump then
                            for i = 1, cap.args.n do
                                print("   ", i, typeof(cap.args[i]), tostring(cap.args[i]))
                            end
                        end
                        if looks then capturing = false end
                        task.spawn(updateStatus)
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
end

local function rearm()
    cap.remote, cap.args, attempts = nil, nil, 0
    capturing = true
    print("[Venice] захват перевзведён, нажми Block")
    updateStatus()
end

local function dumpCapture()
    if not cap.remote then print("[Venice] захвата нет") return end
    print("[Venice] ремоут:", cap.remote:GetFullName(), "арг:", cap.args and cap.args.n or 0)
    if cap.args then
        for i = 1, cap.args.n do print("   ", i, typeof(cap.args[i]), tostring(cap.args[i])) end
    end
end

installCapture()

-- ============================== монтирование ==============================

local gui, main, body, status, setGuiOpen, built = nil, nil, nil, nil, nil, false
local order = 0
local mountLabel = "—"

local function candidates()
    local out = {}
    local mode = CONFIG.mount

    if mode == "auto" or mode == "hidden" then
        local ok, h = pcall(function() return gethui and gethui() end)
        if ok and typeof(h) == "Instance" then table.insert(out, { h, "hidden" }) end
    end

    local prot = protectgui or protect_gui or (syn and syn.protect_gui)
    local okc, core = pcall(function() return game:GetService("CoreGui") end)
    if okc and core and (mode == "auto" or mode == "coregui") then
        if prot then table.insert(out, { core, "core+protect", prot }) end
        table.insert(out, { core, "coregui" })
    end

    if mode == "auto" or mode == "playergui" then
        local pg = LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui", 10)
        if pg then table.insert(out, { pg, "playergui" }) end
    end
    return out
end

local function mountGui(g)
    for _, c in ipairs(candidates()) do
        local container, label, prot = c[1], c[2], c[3]
        if prot then pcall(prot, g) end
        if pcall(function() g.Parent = container end) and g.Parent == container then
            mountLabel = label
            return label
        end
    end
    return nil
end

-- ============================== строки ==============================

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
    local trackF = Instance.new("Frame")
    trackF.Size = UDim2.fromOffset(34, 17)
    trackF.Position = UDim2.new(1, -45, 0.5, -8)
    trackF.BackgroundColor3 = default and ACCENT or Color3.fromRGB(45, 45, 54)
    trackF.BorderSizePixel = 0
    trackF.Parent = r
    Instance.new("UICorner", trackF).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(11, 11)
    knob.Position = default and UDim2.fromOffset(20, 3) or UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = default and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
    knob.BorderSizePixel = 0
    knob.Parent = trackF
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default or false
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = r
    btn.MouseButton1Click:Connect(function()
        state = not state
        tw(trackF, 0.16, { BackgroundColor3 = state and ACCENT or Color3.fromRGB(45, 45, 54) })
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
    track(bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setX(i.Position.X)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setX(i.Position.X)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
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

-- ============================== парирование ==============================

local Balls
local tracked, prevPos, lastHit = {}, {}, {}
local loopConn, childConn = nil, nil
local blockCache, lastParry = nil, 0

local function getBalls()
    if Balls and Balls.Parent then return Balls end
    Balls = workspace:FindFirstChild("Balls") or workspace:WaitForChild("Balls", 20)
    return Balls
end

local function verifyBall(b)
    return typeof(b) == "Instance" and b:IsA("BasePart")
        and b:IsDescendantOf(Balls) and b:GetAttribute("realBall") == true
end

local function getHRP()
    local c = LP.Character
    local h = c and c:FindFirstChild("HumanoidRootPart")
    if h and h:IsA("BasePart") then return h end
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
    if btn and btn:IsA("GuiButton") then blockCache = btn return btn end
end

local function sendTouch(x, y)
    return pcall(function()
        VirtualInputManager:SendTouchEvent(x, y, Enum.UserInputState.Begin)
        VirtualInputManager:SendTouchEvent(x, y, Enum.UserInputState.End)
    end)
end

local function sendMouse(x, y)
    return pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
end

local function fireSignal(block)
    if firesignal and pcall(firesignal, block.Activated) then return true end
    if getconnections then
        return pcall(function()
            for _, c in ipairs(getconnections(block.Activated)) do
                if c.Enabled then c:Fire() end
            end
        end)
    end
    return false
end

local function Parry()
    if CONFIG.method == "packet" and cap.remote and cap.args then
        if pcall(function() cap.remote:FireServer(unpack(cap.args, 1, cap.args.n)) end) then
            return true
        end
    end

    local block = getBlock()
    if not block then return false end
    local p, s = block.AbsolutePosition, block.AbsoluteSize
    if s.X <= 0 or s.Y <= 0 then return false end
    local x = p.X + s.X * (0.34 + math.random() * 0.32)
    local y = p.Y + s.Y * (0.34 + math.random() * 0.32)

    if CONFIG.method == "touch" then
        if sendTouch(x, y) then return true end
        return sendMouse(x, y)
    elseif CONFIG.method == "click" then
        if sendMouse(x, y) then return true end
    end
    return fireSignal(block)
end

local function step()
    if not Balls or not isTarget() then return end
    local hrp = getHRP()
    if not hrp then return end
    local me = hrp.Position
    local now = os.clock()

    for b in pairs(tracked) do
        if not b.Parent or not b:IsDescendantOf(Balls) then
            tracked[b] = nil prevPos[b] = nil lastHit[b] = nil
        else
            local pos  = b.Position
            local prev = prevPos[b] or pos
            prevPos[b] = pos

            local dist = (pos - me).Magnitude
            if dist > CONFIG.maxRange then continue end
            if (prev - me).Magnitude <= dist then continue end
            if now - (lastHit[b] or 0) < 0.6 then continue end
            if now - lastParry < CONFIG.cooldown then continue end

            local radius = CONFIG.parryDist * (1 + (math.random() * 2 - 1) * CONFIG.jitter)
            if math.random() * 100 > CONFIG.accuracy then radius = radius * 1.8 end

            if dist <= radius then
                lastHit[b] = now
                lastParry = now
                if Parry() and CONFIG.dump then
                    print(string.format("[Venice] parry @ %.1f (порог %.1f)", dist, radius))
                end
            end
        end
    end
end

local function addBall(b)
    if verifyBall(b) then
        tracked[b] = true
        prevPos[b] = b.Position
    end
end

local function setParry(on)
    CONFIG.autoParry = on
    if loopConn then loopConn:Disconnect() loopConn = nil end
    if childConn then childConn:Disconnect() childConn = nil end
    if on then
        local balls = getBalls()
        if balls then
            for _, b in ipairs(balls:GetChildren()) do addBall(b) end
            childConn = balls.ChildAdded:Connect(addBall)
        end
        loopConn = RunService.RenderStepped:Connect(step)
    end
end

-- ============================== внешность ==============================

local korbloxMesh = nil
local applying = false
local cosmeticConn = nil

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

local function ensureCosmeticConn()
    if cosmeticConn then return end
    cosmeticConn = LP.CharacterAdded:Connect(function()
        blockCache = nil
        task.wait(1)
        refreshCosmetics()
    end)
end

-- ============================== BAC ==============================

local echoed, echoConns, disabledScripts = {}, {}, {}

local function installEcho()
    if CONFIG.echo then return end
    CONFIG.echo = true
    local sec = ReplicatedStorage:FindFirstChild("Security")
    if not sec then return end
    for _, v in ipairs(sec:GetDescendants()) do
        if v:IsA("RemoteEvent") and not echoed[v] then
            echoed[v] = true
            table.insert(echoConns, v.OnClientEvent:Connect(function(...)
                local packed = table.pack(...)
                if packed.n == 0 then return end
                task.delay(0.02, function()
                    pcall(function() v:FireServer(unpack(packed, 1, packed.n)) end)
                end)
            end))
        end
    end
end

local function removeEcho()
    CONFIG.echo = false
    for _, c in ipairs(echoConns) do pcall(function() c:Disconnect() end) end
    table.clear(echoConns)
    table.clear(echoed)
end

local function removeBac()
    if status then
        status.Text = "снимаю проверки..."
        status.TextColor3 = WARNC
    end

    local function killScripts(c)
        if not c then return end
        for _, v in ipairs(c:GetChildren()) do
            if v:IsA("BaseScript") and not v.Name:match("[Dd]evice")
                and (v.Name:match("[Aa]nti") or v.Name:match("BAC") or v.Name:match("[Cc]heck")) then
                pcall(function() v.Disabled = true end)
                table.insert(disabledScripts, v)
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
                table.insert(disabledScripts, v)
            end
        end
    end

    task.wait(0.4)
    local dc = LP.PlayerScripts:FindFirstChild("Client")
    local dev = dc and dc:FindFirstChild("DeviceChecker")
    if dev then pcall(function() dev:Destroy() end) end

    if status then
        status.Text = string.format("снято %d · перезаход вернёт", #disabledScripts)
        status.TextColor3 = OKC
    end
end

local function restoreBac()
    for _, v in ipairs(disabledScripts) do pcall(function() v.Disabled = false end) end
    table.clear(disabledScripts)
    if status then
        status.Text = "проверки включены обратно"
        status.TextColor3 = OKC
    end
end

-- ============================== переключатели ==============================

local function cycleMethod()
    local list = { "packet", "touch", "click", "signal" }
    for i, m in ipairs(list) do
        if m == CONFIG.method then
            CONFIG.method = list[(i % #list) + 1]
            break
        end
    end
    print("[Venice] метод:", CONFIG.method)
    updateStatus()
end

local function cycleMount()
    local modes = { "auto", "hidden", "coregui", "playergui" }
    for i, m in ipairs(modes) do
        if m == CONFIG.mount then
            CONFIG.mount = modes[(i % #modes) + 1]
            break
        end
    end
    if status then
        status.Text = "контейнер: " .. CONFIG.mount
        status.TextColor3 = WARNC
    end
end

local function rebuild()
    if gui then pcall(function() gui:Destroy() end) end
    gui, main, body, status = nil, nil, nil, nil
    built = false
    order = 0
    if setGuiOpen then setGuiOpen(false) end
    task.wait(0.2)
    if ensure and ensure() then setGuiOpen(true) end
end

-- ============================== наполнение ==============================

local function build()
    toggleRow("BAC bypass", "debug.info + getfenv", CONFIG.bypass, function(v)
        CONFIG.bypass = v
        if v then applyBypass() else dropBypass() end
    end)
    task.wait(0.04)
    buttonRow("Захват пакета", "перевзвести, потом тапни Block", rearm)
    task.wait(0.04)
    buttonRow("Показать захват", "ремоут и аргументы в консоль", dumpCapture)
    task.wait(0.04)
    buttonRow("Метод", "packet → touch → click → signal", cycleMethod)
    task.wait(0.04)
    toggleRow("Auto Parry", "по дистанции от персонажа", CONFIG.autoParry, setParry)
    task.wait(0.04)
    sliderRow("Радиус", 5, 30, CONFIG.parryDist, function(v)
        CONFIG.parryDist = v
        updateStatus()
    end)
    task.wait(0.04)
    sliderRow("Разброс %", 0, 50, math.floor(CONFIG.jitter * 100), function(v)
        CONFIG.jitter = v / 100
        updateStatus()
    end)
    task.wait(0.04)
    sliderRow("Точность %", 40, 100, CONFIG.accuracy, function(v)
        CONFIG.accuracy = v
        updateStatus()
    end)
    task.wait(0.04)
    sliderRow("Кулдаун мс", 150, 600, math.floor(CONFIG.cooldown * 1000), function(v)
        CONFIG.cooldown = v / 1000
        updateStatus()
    end)
    task.wait(0.04)
    toggleRow("Лог парирований", "дистанция в консоль", CONFIG.dump, function(v)
        CONFIG.dump = v
    end)
    task.wait(0.04)
    toggleRow("BAC эхо", "повтор Security-ремоутов", CONFIG.echo, function(v)
        if v then installEcho() else removeEcho() end
    end)
    task.wait(0.04)
    buttonRow("Снять проверки", "anti/check скрипты, DeviceChecker", removeBac)
    task.wait(0.04)
    buttonRow("Вернуть проверки", "включить скрипты обратно", restoreBac)
    task.wait(0.04)
    toggleRow("Headless", "голова + face прозрачные", CONFIG.headless, function(v)
        CONFIG.headless = v
        ensureCosmeticConn()
        task.spawn(function()
            if CONFIG.safe then task.wait(1.2) end
            applyHeadless(v)
        end)
    end)
    task.wait(0.04)
    toggleRow("Korblox", "CharacterMesh на правую ногу", CONFIG.korblox, function(v)
        CONFIG.korblox = v
        ensureCosmeticConn()
        task.spawn(function()
            if CONFIG.safe then task.wait(1.2) end
            applyKorblox(v)
        end)
    end)
    task.wait(0.04)
    buttonRow("Контейнер GUI", "auto → hidden → coregui → playergui", cycleMount)
    task.wait(0.04)
    buttonRow("Пересоздать GUI", "перенести в выбранный контейнер", rebuild)
    task.wait(0.04)
    buttonRow("Выгрузить", "удалить GUI и все связи", function()
        capturing = false
        if loopConn then loopConn:Disconnect() end
        if childConn then childConn:Disconnect() end
        if cosmeticConn then cosmeticConn:Disconnect() end
        removeEcho()
        dropBypass()
        if oldNamecall then pcall(function() hookmetamethod(game, "__namecall", oldNamecall) end) end
        for _, c in ipairs(getgenv().VeniceBBConns) do pcall(function() c:Disconnect() end) end
        if gui then gui:Destroy() end
        getgenv().VeniceBB = nil
    end)
end

-- ============================== сборка GUI ==============================

local open = false

updateStatus = function()
    if not status then return end
    if CONFIG.method == "packet" then
        if cap.remote then
            status.Text = string.format("packet · %.0fст · %d%%", CONFIG.parryDist, CONFIG.accuracy)
            status.TextColor3 = OKC
        else
            status.Text = "packet · тапни Block для захвата"
            status.TextColor3 = WARNC
        end
    else
        status.Text = string.format("%s · %.0fст · %d%%", CONFIG.method, CONFIG.parryDist, CONFIG.accuracy)
        status.TextColor3 = CONFIG.autoParry and OKC or SUB
    end
end

setGuiOpen = function(force)
    if not gui or not main then return end
    local target = force ~= nil and force or not open
    if target == open then return end
    open = target
    if open then
        gui.Enabled = true
        main.Visible = true
        main.BackgroundTransparency = 1
        tw(main, 0.22, { BackgroundTransparency = 0.03 })
    else
        tw(main, 0.16, { BackgroundTransparency = 1 })
        task.delay(0.17, function()
            if not open and main then
                main.Visible = false
                if gui then gui.Enabled = false end
            end
        end)
    end
end

local function createGui()
    local g = Instance.new("ScreenGui")
    local where = mountGui(g)
    if not where then
        g:Destroy()
        return false
    end
    gui = g
    gui.Name = "MainGui"
    gui.DisplayOrder = 1
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Enabled = false
    getgenv().VeniceBB = gui

    main = Instance.new("Frame")
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.Size = UDim2.fromOffset(340, 500)
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

    status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -70, 0, 15)
    status.Position = UDim2.fromOffset(30, 31)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 10
    status.TextColor3 = WARNC
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Text = "контейнер: " .. mountLabel
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
    closeBtn.MouseButton1Click:Connect(function() setGuiOpen(false) end)

    body = Instance.new("ScrollingFrame")
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

    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
        end
    end)
    track(UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    return true
end

ensure = function()
    if built then return true end
    if not createGui() then return false end
    built = true
    build()
    updateStatus()
    return true
end

track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Z and not UserInputService:GetFocusedTextBox() then
        if not built then
            if ensure() then
                task.wait(0.1)
                setGuiOpen(true)
            end
        else
            setGuiOpen()
        end
    end
end))

print(string.format("[Venice] v16 · %s · радиус %d · bypass %s",
    CONFIG.method, CONFIG.parryDist, tostring(CONFIG.bypass)))
print("[Venice] тапни Block один раз — пойдёт захват пакета")
