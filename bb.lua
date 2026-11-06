--[[ Blade Ball — Venice Hub v21 ]]

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
local Stats               = ref(game:GetService("Stats"))

local LP = Players.LocalPlayer
while not LP do task.wait() end

local function track(c) table.insert(getgenv().VeniceBBConns, c) return c end

local CONFIG = {
    bypassInfo      = true,
    bypassEnv       = true,
    method          = "click",
    autoParry       = false,
    pingBased       = true,
    pingOffset      = 1.95,
    distanceToParry = 0.65,
    emergencyRadius = 10,
    clashDistance   = 22,
    maxRange        = 170,
    clashSpeed      = 0.01,
    normalSpeed     = 0.05,
    visuals         = true,
    showRadius      = true,
    dump            = false,
    headless        = false,
    korblox         = false,
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

-- ============================== bypass ==============================

local function applyInfo()
    if not (hookfunction and getrenv) then return false end
    if getgenv().VeniceBBInfoHooked then return true end
    getgenv().VeniceBBInfoHooked = true

    local orig = getrenv().debug.info
    local new
    new = hookfunction(orig, function(f, t)
        if t ~= "s" then return orig(f, t) end
        if type(f) == "function" then return "[C]" end
        if f == 3 or f == 4 or f == 5 then
            return "ReplicatedStorage.Controllers.SwordsController"
        end
        return orig(f, t)
    end)
    getgenv().VeniceBBOrigInfo, getgenv().VeniceBBInfo = orig, new
    return true
end

local function dropInfo()
    if not getgenv().VeniceBBInfoHooked then return end
    pcall(function() hookfunction(getgenv().VeniceBBInfo, getgenv().VeniceBBOrigInfo) end)
    getgenv().VeniceBBInfoHooked = false
end

local function applyEnv()
    if not (hookfunction and getrenv) then return false end
    if getgenv().VeniceBBEnvHooked then return true end
    getgenv().VeniceBBEnvHooked = true

    local orig = getrenv().getfenv
    local new
    new = hookfunction(orig, function(l)
        if type(l) == "function" then return orig(l) end
        local lvl = (type(l) == "number" and l or 1) + 1
        return orig(lvl)
    end)
    getgenv().VeniceBBOrigEnv, getgenv().VeniceBBEnv = orig, new
    return true
end

local function dropEnv()
    if not getgenv().VeniceBBEnvHooked then return end
    pcall(function() hookfunction(getgenv().VeniceBBEnv, getgenv().VeniceBBOrigEnv) end)
    getgenv().VeniceBBEnvHooked = false
end

if CONFIG.bypassInfo then applyInfo() end
if CONFIG.bypassEnv then applyEnv() end

-- ============================== захват пакета ==============================

local cap = { remote = nil, args = nil }
local capturing = false
local attempts = 0
local oldNamecall = nil
local updateStatus = function() end

local function looksLikeParry(name, full)
    return name:match("[Pp]arry") or name:match("[Bb]lock")
        or full:match("[Pp]arry") or full:match("[Bb]lock")
end

local function uninstallCapture()
    if not oldNamecall then return end
    pcall(function() hookmetamethod(game, "__namecall", oldNamecall) end)
    oldNamecall = nil
end

local function installCapture()
    if oldNamecall or not (hookmetamethod and getnamecallmethod) then return end
    capturing = true
    attempts = 0
    pcall(function()
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            if capturing and getnamecallmethod() == "FireServer"
                and typeof(self) == "Instance" and self:IsA("RemoteEvent") then
                local full = self:GetFullName()
                local looks = looksLikeParry(self.Name, full)
                if looks or attempts < 5 then
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
                        if looks then
                            capturing = false
                            uninstallCapture()
                            if CONFIG.method ~= "packet" then
                                CONFIG.method = "packet"
                                print("[Venice] метод переключён на packet")
                            end
                        end
                        task.spawn(updateStatus)
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
    task.delay(20, function()
        if capturing then
            capturing = false
            uninstallCapture()
            print("[Venice] захват по таймауту снят")
        end
    end)
end

local function rearm()
    cap.remote, cap.args = nil, nil
    uninstallCapture()
    installCapture()
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

local function mountGui(g)
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and typeof(h) == "Instance" then
        if pcall(function() g.Parent = h end) then return "hidden" end
    end
    local prot = protectgui or protect_gui or (syn and syn.protect_gui)
    local okc, core = pcall(function() return game:GetService("CoreGui") end)
    if okc and core then
        if prot then pcall(prot, g) end
        if pcall(function() g.Parent = core end) then return "core" end
    end
    local pg = LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui", 10)
    if pg and pcall(function() g.Parent = pg end) then return "playergui" end
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

    r.Parent = body
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

-- ============================== кольцо ==============================

local ring, ringMesh

local function ensureRing()
    if ring and ring.Parent then return end
    ring = Instance.new("Part")
    ring.Name = "SmartCircle"
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanQuery = false
    ring.CanTouch = false
    ring.CastShadow = false
    ring.Transparency = 0.3
    ring.Material = Enum.Material.Neon
    ring.Size = Vector3.new(1, 1, 1)
    ringMesh = Instance.new("SpecialMesh", ring)
    ringMesh.MeshId = "rbxassetid://3270017"
    ring.Parent = workspace
end

local function dropRing()
    if ring then pcall(function() ring:Destroy() end) end
    ring, ringMesh = nil, nil
end

local function ringState()
    if CONFIG.autoParry and CONFIG.visuals and CONFIG.showRadius then ensureRing() else dropRing() end
end

-- ============================== внешность ==============================

local korbloxMesh = nil
local applying = false

local function waitAppearance()
    local char = LP.Character
    if not char then return nil end
    if not LP:HasAppearanceLoaded() then
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
        task.wait(1.2)
        if CONFIG.headless then applyHeadless(true) end
        task.wait(0.4)
        if CONFIG.korblox then applyKorblox(true) end
        applying = false
    end)
end

-- ============================== парринг ==============================

local Balls = workspace:FindFirstChild("Balls") or workspace:WaitForChild("Balls", 5)
local blockCache = nil
local LastClick, LastBallHit, IsParrying = 0, nil, false
local prevDist = {}

local NetworkStats = Stats:FindFirstChild("Network")
    and Stats.Network:FindFirstChild("ServerStatsItem")
    and Stats.Network.ServerStatsItem:FindFirstChild("Data Ping")

local function getBlock()
    if blockCache and blockCache.Parent then return blockCache end
    blockCache = nil
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return end
    local hotbar = pg:FindFirstChild("Hotbar")
    local direct = hotbar and hotbar:FindFirstChild("Block")
    if direct and direct:IsA("GuiButton") then blockCache = direct return direct end
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("GuiButton") and d.Name == "Block" then blockCache = d return d end
    end
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

local function Parry()
    if CONFIG.method == "packet" and cap.remote and cap.args then
        if pcall(function() cap.remote:FireServer(unpack(cap.args, 1, cap.args.n)) end) then
            return true
        end
    end

    local block = getBlock()
    if block then
        local p, s = block.AbsolutePosition, block.AbsoluteSize
        if s.X > 0 and s.Y > 0 then
            local x = p.X + s.X * (0.34 + math.random() * 0.32)
            local y = p.Y + s.Y * (0.34 + math.random() * 0.32)
            if CONFIG.method == "touch" then
                if sendTouch(x, y) then return true end
            end
            if sendMouse(x, y) then return true end
        end
    end

    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1000, 600)
    return sendMouse(vp.X * 0.5, vp.Y * 0.78)
end

local function IsTargeted()
    local char = LP.Character
    if not char then return false end
    return char:GetAttribute("Targeted") == true or char:FindFirstChild("Highlight") ~= nil
end

local function SendParry(isClashing, ball)
    if not CONFIG.autoParry or IsParrying then return end
    local now = os.clock()
    local cd = isClashing and CONFIG.clashSpeed or CONFIG.normalSpeed

    if not isClashing and LastBallHit == ball and (now - LastClick) < 0.5 then return end
    if (now - LastClick) < cd then return end

    IsParrying = true
    LastClick = now
    LastBallHit = ball

    if Parry() and CONFIG.dump then
        print(string.format("[Venice] parry · %s", isClashing and "clash" or "predict"))
    end

    task.delay(cd, function() IsParrying = false end)
end

local function UpdateVisuals(root, distance, state)
    if not ring or not ringMesh then return end
    ring.CFrame = root.CFrame * CFrame.new(0, -2.6, 0) * CFrame.Angles(math.rad(90), 0, 0)
    local targetSize = math.clamp(distance * 0.8, 5, 65)
    ringMesh.Scale = ringMesh.Scale:Lerp(Vector3.new(targetSize, targetSize, 0.5), 0.5)

    if state == "clash" then
        ring.Color = Color3.fromRGB(255, 0, 0)
        ring.Transparency = 0.05
    elseif state == "target" then
        ring.Color = Color3.fromRGB(0, 255, 255)
        ring.Transparency = 0.1
    else
        ring.Color = Color3.fromRGB(150, 240, 255)
        ring.Transparency = 0.5
    end
end

local function Scan(origin)
    local best, bestTTL = nil, math.huge
    local near, nearDist = nil, math.huge
    if not Balls then return nil, nil, nil, nil end
    local children = Balls:GetChildren()

    for i = 1, #children do
        local b = children[i]
        if b:GetAttribute("realBall") == true then
            local dist = (origin - b.Position).Magnitude
            local was = prevDist[b]
            prevDist[b] = dist
            local approaching = was ~= nil and dist < was

            if dist <= CONFIG.maxRange then
                if dist < nearDist then near, nearDist = b, dist end
                if approaching then
                    local speed = b.AssemblyLinearVelocity.Magnitude
                    if speed > 1 then
                        local ttl = dist / speed
                        if ttl < bestTTL then best, bestTTL = b, ttl end
                    end
                end
            end
        end
    end

    return best, bestTTL, near, nearDist
end

track(RunService.PostSimulation:Connect(function()
    if not CONFIG.autoParry then
        if ring then ring.Transparency = 1 end
        return
    end

    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        if ring then ring.Transparency = 1 end
        return
    end

    local ball, ttl, near, nearDist = Scan(root.Position)
    local focus = ball or near
    if not focus then
        LastBallHit = nil
        if ring then ring.Transparency = 1 end
        return
    end

    local targeted = IsTargeted()
    local isClashing = targeted and nearDist <= CONFIG.clashDistance

    if ring then
        ring.Transparency = 0.3
        UpdateVisuals(root, math.min(nearDist, 65), isClashing and "clash" or (targeted and "target" or "neutral"))
    end

    if isClashing then
        SendParry(true, near)
        return
    end

    if nearDist <= CONFIG.emergencyRadius then
        SendParry(false, near)
        return
    end

    if ball and targeted then
        local ping = (CONFIG.pingBased and NetworkStats and NetworkStats.Value / 1000) or 0.04
        local threshold = CONFIG.distanceToParry + (CONFIG.pingBased and ping * CONFIG.pingOffset or 0)
        if ttl > 0.15 then threshold = threshold * 1.15 end
        if ttl <= threshold then
            SendParry(false, ball)
        end
    end
end))

track(LP.CharacterAdded:Connect(function()
    LastBallHit = nil
    IsParrying = false
    blockCache = nil
    table.clear(prevDist)
    task.wait(1)
    refreshCosmetics()
end))

-- ============================== наполнение ==============================

local function cycleMethod()
    local list = { "click", "touch", "packet" }
    for i, m in ipairs(list) do
        if m == CONFIG.method then
            CONFIG.method = list[(i % #list) + 1]
            break
        end
    end
    print("[Venice] метод:", CONFIG.method)
    if CONFIG.method == "packet" and cap.remote and not looksLikeParry(cap.remote.Name, "") then
        print("[Venice] внимание: захваченный ремоут не похож на парирование")
    end
    updateStatus()
end

local builders = {}

local function add(fn) table.insert(builders, fn) end

add(function()
    toggleRow("bypass: debug.info", "подмена источника", CONFIG.bypassInfo, function(v)
        CONFIG.bypassInfo = v
        if v then applyInfo() else dropInfo() end
    end)
end)
add(function()
    toggleRow("bypass: getfenv", "подмена окружения", CONFIG.bypassEnv, function(v)
        CONFIG.bypassEnv = v
        if v then applyEnv() else dropEnv() end
    end)
end)
add(function()
    buttonRow("Захват пакета", "перевзвести, потом тапни Block", rearm)
end)
add(function()
    buttonRow("Метод", "click → touch → packet", cycleMethod)
end)
add(function()
    toggleRow("Auto Parry", "L — то же самое", CONFIG.autoParry, function(v)
        CONFIG.autoParry = v
        ringState()
        updateStatus()
    end)
end)
add(function()
    toggleRow("Visuals", "кольцо на земле", CONFIG.visuals, function(v)
        CONFIG.visuals = v
        ringState()
    end)
end)
add(function()
    toggleRow("Показывать радиус", "скрыть кольцо", CONFIG.showRadius, function(v)
        CONFIG.showRadius = v
        ringState()
    end)
end)
add(function()
    sliderRow("Порог (мс×100)", 10, 150, math.floor(CONFIG.distanceToParry * 100), function(v)
        CONFIG.distanceToParry = v / 100
        updateStatus()
    end)
end)
add(function()
    sliderRow("Аварийный радиус", 3, 30, CONFIG.emergencyRadius, function(v)
        CONFIG.emergencyRadius = v
        updateStatus()
    end)
end)
add(function()
    sliderRow("Клаш-зона", 8, 40, CONFIG.clashDistance, function(v)
        CONFIG.clashDistance = v
        updateStatus()
    end)
end)
add(function()
    sliderRow("Дальность", 60, 250, CONFIG.maxRange, function(v)
        CONFIG.maxRange = v
        updateStatus()
    end)
end)
add(function()
    toggleRow("Учёт пинга", "прогноз по Data Ping", CONFIG.pingBased, function(v)
        CONFIG.pingBased = v
        updateStatus()
    end)
end)
add(function()
    sliderRow("Пинг-множитель", 5, 40, math.floor(CONFIG.pingOffset * 10), function(v)
        CONFIG.pingOffset = v / 10
        updateStatus()
    end)
end)
add(function()
    sliderRow("Кулдаун клаша мс", 5, 100, math.floor(CONFIG.clashSpeed * 1000), function(v)
        CONFIG.clashSpeed = v / 1000
        updateStatus()
    end)
end)
add(function()
    sliderRow("Кулдаун мс", 20, 150, math.floor(CONFIG.normalSpeed * 1000), function(v)
        CONFIG.normalSpeed = v / 1000
        updateStatus()
    end)
end)
add(function()
    toggleRow("Лог", "срабатывания в консоль", CONFIG.dump, function(v)
        CONFIG.dump = v
    end)
end)
add(function()
    toggleRow("Headless", "голова + face прозрачные", CONFIG.headless, function(v)
        CONFIG.headless = v
        task.spawn(function() task.wait(1.2) applyHeadless(v) end)
    end)
end)
add(function()
    toggleRow("Korblox", "CharacterMesh на правую ногу", CONFIG.korblox, function(v)
        CONFIG.korblox = v
        task.spawn(function() task.wait(1.2) applyKorblox(v) end)
    end)
end)
add(function()
    buttonRow("Выгрузить", "удалить GUI, кольцо, связи", function()
        capturing = false
        uninstallCapture()
        dropRing()
        if korbloxMesh then pcall(function() korbloxMesh:Destroy() end) end
        dropInfo()
        dropEnv()
        for _, c in ipairs(getgenv().VeniceBBConns) do pcall(function() c:Disconnect() end) end
        if gui then gui:Destroy() end
        getgenv().VeniceBB = nil
    end)
end)

local function build()
    task.spawn(function()
        for i = 1, #builders do
            local ok, err = pcall(builders[i])
            if not ok then
                print("[Venice] строка " .. i .. ": " .. tostring(err))
            end
            if i % 2 == 0 then task.wait() end
        end
        body.CanvasSize = UDim2.new()
        body.AutomaticCanvasSize = Enum.AutomaticSize.Y
        updateStatus()
        print("[Venice] меню собрано, строк: " .. tostring(#body:GetChildren() - 1))
    end)
end

-- ============================== GUI ==============================

local open = false

updateStatus = function()
    if not status then return end
    status.Text = string.format("%s · порог %.2f · %s",
        CONFIG.method, CONFIG.distanceToParry, CONFIG.autoParry and "вкл" or "выкл")
    status.TextColor3 = CONFIG.autoParry and OKC or SUB
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
    status.Text = "сборка меню"
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
    body.CanvasSize = UDim2.new(0, 0, 0, 1400)
    body.AutomaticCanvasSize = Enum.AutomaticSize.None
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
    footer.Text = "Z — меню · L — парринг"
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

local function ensure()
    if built then return true end
    if not createGui() then return false end
    built = true
    build()
    return true
end

track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if UserInputService:GetFocusedTextBox() then return end

    if input.KeyCode == Enum.KeyCode.Z then
        if not built then
            if ensure() then
                task.wait(0.1)
                setGuiOpen(true)
            end
        else
            setGuiOpen()
        end
    elseif input.KeyCode == Enum.KeyCode.L then
        CONFIG.autoParry = not CONFIG.autoParry
        ringState()
        updateStatus()
    end
end))

print("[Venice] v21 · метод click по умолчанию")
