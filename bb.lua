--==================================================================
--  VENICE | Blade Ball  —  v2
--  Стек-спуф через __namecall + перехват реального remote
--  Режимы ввода: мышь / клавиатура / remote
--  RightShift — меню | L — автопарри
--==================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local cloneref = cloneref or function(o) return o end
local Players            = cloneref(game:GetService("Players"))
local RunService         = cloneref(game:GetService("RunService"))
local Stats              = cloneref(game:GetService("Stats"))
local UIS                = cloneref(game:GetService("UserInputService"))
local VIM                = cloneref(game:GetService("VirtualInputManager"))
local Tween              = cloneref(game:GetService("TweenService"))
local Lighting           = cloneref(game:GetService("Lighting"))
local RS                 = cloneref(game:GetService("ReplicatedStorage"))
local Player             = Players.LocalPlayer
local Camera             = workspace.CurrentCamera

local nc = newcclosure or function(f) return f end

--==================================================================
--  CONFIG
--==================================================================
local CFG = {
    AutoParry = true,
    InputMode = "mouse",        -- mouse | keyboard | remote | hybrid
    Key = Enum.KeyCode.Q,

    PingBased = true, PingOffset = 1.95,
    Distance  = 0.65, Emergency = 10,
    ClashDist = 22, ClashCD   = 0.01, NormalCD = 0.05,
    MaxPerSec = 12,

    Jitter    = 12,             -- мс
    MissChance= 0.02,           -- доля пропусков
    Humanize  = true,           -- рандомная позиция мыши перед кликом

    Visuals   = true,
    FOVOn = false, FOV = 90,
    SkyOn = false, Clock = 14, Bright = 2, FogEnd = 1000, AtmoD = 0.3, AtmoH = 1.5,
    Sat = 0, Contrast = 0, Tint = Color3.fromRGB(255,255,255),
}
getgenv().Venice = CFG

local ORIG = {
    Clock = Lighting.ClockTime, Bright = Lighting.Brightness,
    FogEnd = Lighting.FogEnd, FOV = Camera.FieldOfView,
}

--==================================================================
--  СТЕК-СПУФ
--==================================================================
local CTRL_PATH = "ReplicatedStorage.Controllers.SwordsController "
local controller = RS:FindFirstChild("Controllers")
controller = controller and controller:FindFirstChild("SwordsController")

local realEnv
pcall(function() realEnv = getfenv(10) end)
local proxy = setmetatable({ script = controller }, { __index = realEnv or {} })

local origInfo, origGetinfo, origGetfenv, origNamecall

origInfo = hookfunction(nc(debug.info), nc(function(f, t)
    if type(f) == "function" then return "[C]" end
    if type(f) == "number" and f >= 1 and f <= 6 and t == "s" then return CTRL_PATH end
    return origInfo(f, t)
end))

if debug.getinfo then
    pcall(function()
        origGetinfo = hookfunction(nc(debug.getinfo), nc(function(f, t)
            if type(f) == "function" then return "[C]" end
            if type(f) == "number" and f >= 1 and f <= 6 and t == "s" then return CTRL_PATH end
            return origGetinfo(f, t)
        end))
    end)
end

origGetfenv = hookfunction(nc(getfenv), nc(function(l)
    if type(l) == "number" and l >= 1 and l <= 10 then return proxy end
    return origGetfenv(l)
end))

--==================================================================
--  ПЕРЕХВАТ REMOTE
--==================================================================
local parryRemote, parryArgs = nil, {}
local spoofing = false

origNamecall = hookmetamethod(game, "__namecall", nc(function(self, ...)
    local m = getnamecallmethod()

    if not checkcaller() and (m == "FireServer" or m == "Fire") then
        if typeof(self) == "Instance" and self:IsA("RemoteEvent") then
            local n = self.Name
            if n == "ParryButtonPress" or n == "Parry" or n == "ParryButton" then
                parryRemote = self
                parryArgs = { ... }
            end
        end
    end

    return origNamecall(self, ...)
end))

--==================================================================
--  ГУМАНИЗАЦИЯ / ВВОД
--==================================================================
local lastFire = 0
local hitTimes = {}

local function rateOk()
    local now = tick()
    local keep = {}
    for _, t in ipairs(hitTimes) do
        if now - t < 1 then keep[#keep + 1] = t end
    end
    hitTimes = keep
    return #hitTimes < CFG.MaxPerSec
end

local function fireMouse()
    local p = UIS:GetMouseLocation()
    if CFG.Humanize then
        local x = p.X + math.random(-2, 2)
        local y = p.Y + math.random(-2, 2)
        pcall(function() VIM:SendMouseMoveEvent(x, y, game) end)
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    else
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 0)
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0)
    end
end

local function fireKey()
    local k = CFG.Key
    VIM:SendKeyEvent(true, k, false, game)
    task.wait(0.01)
    VIM:SendKeyEvent(false, k, false, game)
end

local function fireRemote()
    if not parryRemote then
        fireMouse()
        return
    end
    spoofing = true
    pcall(function()
        if #parryArgs > 0 then
            parryRemote:FireServer(table.unpack(parryArgs))
        else
            parryRemote:FireServer()
        end
    end)
    spoofing = false
end

local function dispatch(mode)
    if mode == "remote" then
        fireRemote()
    elseif mode == "keyboard" then
        fireKey()
    elseif mode == "hybrid" then
        if parryRemote then fireRemote() else fireMouse() end
        task.wait(0.008)
        fireKey()
    else
        fireMouse()
    end
end

--==================================================================
--  UI
--==================================================================
local ACCENT = Color3.fromRGB(150,240,255)
local BG, PANEL, SIDE, DIM = Color3.fromRGB(10,10,12), Color3.fromRGB(16,16,20), Color3.fromRGB(13,13,16), Color3.fromRGB(120,122,132)

local function new(c, p, par) local o = Instance.new(c) for k,v in pairs(p) do o[k]=v end if par then o.Parent=par end return o end
local function corner(o,r) return new("UICorner",{CornerRadius=UDim.new(0,r or 8)},o) end
local function stroke(o,c,t) return new("UIStroke",{Color=c or Color3.fromRGB(32,32,40),Thickness=t or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},o) end

local host = (gethui and gethui()) or game:GetService("CoreGui")
local prev = host:FindFirstChild("VeniceBB") if prev then prev:Destroy() end

local sg = new("ScreenGui",{Name="VeniceBB",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=999},host)

local main = new("Frame",{Size=UDim2.fromOffset(620,430),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=BG,BorderSizePixel=0,ClipsDescendants=true},sg)
corner(main,14) stroke(main,Color3.fromRGB(42,42,54),1)
new("UIGradient",{Color=ColorSequence.new(Color3.fromRGB(19,19,25),Color3.fromRGB(8,8,10)),Rotation=90},main)

local header = new("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=Color3.fromRGB(14,14,18),BorderSizePixel=0},main)
new("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=Color3.fromRGB(28,28,36),BorderSizePixel=0},header)

new("TextLabel",{Size=UDim2.fromOffset(140,20),Position=UDim2.fromOffset(20,16),BackgroundTransparency=1,Font=Enum.Font.GothamBlack,TextSize=17,TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Left,Text="VENICE"},header)
new("TextLabel",{Size=UDim2.fromOffset(100,20),Position=UDim2.fromOffset(112,17),BackgroundTransparency=1,Font=Enum.Font.GothamMedium,TextSize=11,TextColor3=ACCENT,TextXAlignment=Enum.TextXAlignment.Left,Text="blade ball v2"},header)

local statusLbl = new("TextLabel",{Size=UDim2.fromOffset(210,20),Position=UDim2.new(1,-290,0,16),BackgroundTransparency=1,Font=Enum.Font.GothamMedium,TextSize=11,TextColor3=DIM,TextXAlignment=Enum.TextXAlignment.Right,Text="hooks: active"},header)

local closeBtn = new("TextButton",{Size=UDim2.fromOffset(30,30),Position=UDim2.new(1,-42,0,11),BackgroundColor3=Color3.fromRGB(24,24,30),BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=15,TextColor3=Color3.fromRGB(255,110,110),Text="×"},header)
corner(closeBtn,8)

local drag, dStart, sPos
header.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true dStart=i.Position sPos=main.Position end end)
UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-dStart main.Position=UDim2.new(sPos.X.Scale,sPos.X.Offset+d.X,sPos.Y.Scale,sPos.Y.Offset+d.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)

local sidebar = new("Frame",{Size=UDim2.new(0,150,1,-52),Position=UDim2.fromOffset(0,52),BackgroundColor3=SIDE,BorderSizePixel=0},main)
new("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BackgroundColor3=Color3.fromRGB(26,26,32),BorderSizePixel=0},sidebar)
local content = new("Frame",{Size=UDim2.new(1,-150,1,-52),Position=UDim2.fromOffset(150,52),BackgroundTransparency=1,BorderSizePixel=0},main)

local pages, tabs = {}, {}
local function switchTab(n)
    for k,p in pairs(pages) do p.Visible = k==n end
    for k,b in pairs(tabs) do
        Tween:Create(b,TweenInfo.new(0.18),{BackgroundColor3 = k==n and Color3.fromRGB(24,24,32) or Color3.fromRGB(15,15,19),TextColor3 = k==n and ACCENT or DIM}):Play()
    end
end

local function makeTab(n,label,ord)
    local page = new("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=Color3.fromRGB(45,45,55),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},content)
    new("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14),PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,14)},page)
    new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},page)
    local b = new("TextButton",{Size=UDim2.new(1,-20,0,34),Position=UDim2.fromOffset(10,10+(ord-1)*40),BackgroundColor3=Color3.fromRGB(15,15,19),BorderSizePixel=0,Font=Enum.Font.GothamMedium,TextSize=13,TextColor3=DIM,TextXAlignment=Enum.TextXAlignment.Left,Text="   "..label,AutoButtonColor=false},sidebar)
    corner(b,8)
    b.MouseButton1Click:Connect(function() switchTab(n) end)
    pages[n]=page tabs[n]=b return page
end

local function section(p,t) return new("TextLabel",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=Color3.fromRGB(90,92,102),TextXAlignment=Enum.TextXAlignment.Left,Text=string.upper(t)},p) end

local function makeToggle(p,text,def,cb)
    local row = new("Frame",{Size=UDim2.new(1,0,0,38),BackgroundColor3=PANEL,BorderSizePixel=0},p) corner(row,8)
    new("TextLabel",{Size=UDim2.new(1,-70,1,0),Position=UDim2.fromOffset(12,0),BackgroundTransparency=1,Font=Enum.Font.GothamMedium,TextSize=13,TextColor3=Color3.fromRGB(215,217,225),TextXAlignment=Enum.TextXAlignment.Left,Text=text},row)
    local pill = new("TextButton",{Size=UDim2.fromOffset(40,20),Position=UDim2.new(1,-52,0.5,-10),BackgroundColor3=def and ACCENT or Color3.fromRGB(38,38,46),BorderSizePixel=0,Text="",AutoButtonColor=false},row) corner(pill,10)
    local knob = new("Frame",{Size=UDim2.fromOffset(16,16),Position=def and UDim2.new(1,-18,0,2) or UDim2.fromOffset(2,2),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},pill) corner(knob,8)
    local st = def
    local function set(v)
        st=v
        Tween:Create(pill,TweenInfo.new(0.16),{BackgroundColor3 = v and ACCENT or Color3.fromRGB(38,38,46)}):Play()
        Tween:Create(knob,TweenInfo.new(0.16),{Position = v and UDim2.new(1,-18,0,2) or UDim2.fromOffset(2,2)}):Play()
        if cb then cb(v) end
    end
    pill.MouseButton1Click:Connect(function() set(not st) end)
    return {Set=set}
end

local function makeSlider(p,text,min,max,def,dec,cb)
    local row = new("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=PANEL,BorderSizePixel=0},p) corner(row,8)
    new("TextLabel",{Size=UDim2.new(1,-90,0,22),Position=UDim2.fromOffset(12,8),BackgroundTransparency=1,Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=Color3.fromRGB(215,217,225),TextXAlignment=Enum.TextXAlignment.Left,Text=text},row)
    local vl = new("TextLabel",{Size=UDim2.fromOffset(60,22),Position=UDim2.new(1,-72,0,8),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=ACCENT,TextXAlignment=Enum.TextXAlignment.Right,Text=string.format("%."..dec.."f",def)},row)
    local track = new("Frame",{Size=UDim2.new(1,-24,0,4),Position=UDim2.fromOffset(12,38),BackgroundColor3=Color3.fromRGB(38,38,46),BorderSizePixel=0},row) corner(track,2)
    local fill = new("Frame",{Size=UDim2.fromScale((def-min)/(max-min),1),BackgroundColor3=ACCENT,BorderSizePixel=0},track) corner(fill,2)
    local knob = new("Frame",{Size=UDim2.fromOffset(12,12),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new((def-min)/(max-min),0,0.5,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},track) corner(knob,6)
    local val = def
    local function apply(v)
        val = math.clamp(v,min,max)
        local a = (val-min)/(max-min)
        fill.Size = UDim2.fromScale(a,1) knob.Position = UDim2.new(a,0,0.5,0)
        vl.Text = string.format("%."..dec.."f",val)
        if cb then cb(val) end
    end
    local hold = false
    local function fromX(x) apply(min+(max-min)*math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)) end
    row.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then hold=true fromX(i.Position.X) end end)
    UIS.InputChanged:Connect(function(i) if hold and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then fromX(i.Position.X) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then hold=false end end)
    return {Set=apply}
end

local function makeSegment(p,opts,def,cb)
    local row = new("Frame",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1},p)
    new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6)},row)
    local btns = {}
    local cur = def
    local function pick(v)
        cur = v
        for k,b in pairs(btns) do
            Tween:Create(b,TweenInfo.new(0.14),{BackgroundColor3 = k==v and ACCENT or PANEL,TextColor3 = k==v and Color3.fromRGB(10,10,12) or Color3.fromRGB(200,202,210)}):Play()
        end
        if cb then cb(v) end
    end
    for _,o in ipairs(opts) do
        local b = new("TextButton",{Size=UDim2.new(1/#opts,-4,1,0),BackgroundColor3 = o[2]==def and ACCENT or PANEL,BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=11,TextColor3 = o[2]==def and Color3.fromRGB(10,10,12) or Color3.fromRGB(200,202,210),Text=o[1],AutoButtonColor=false},row)
        corner(b,7)
        b.MouseButton1Click:Connect(function() pick(o[2]) end)
        btns[o[2]] = b
    end
    return {Set=pick,Get=function() return cur end}
end

local function makeButton(p,text,cb)
    local b = new("TextButton",{Size=UDim2.new(1,0,0,34),BackgroundColor3=PANEL,BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(220,222,230),Text=text,AutoButtonColor=false},p)
    corner(b,8)
    b.MouseEnter:Connect(function() Tween:Create(b,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(26,26,34)}):Play() end)
    b.MouseLeave:Connect(function() Tween:Create(b,TweenInfo.new(0.12),{BackgroundColor3=PANEL}):Play() end)
    b.MouseButton1Click:Connect(cb)
    return b
end

--==================================================================
--  СТРАНИЦЫ
--==================================================================
local pC = makeTab("combat","Бой",1)
local pI = makeTab("input","Ввод",2)
local pV = makeTab("visual","Визуал",3)
local pS = makeTab("sky","Небо",4)
local pM = makeTab("misc","Прочее",5)

section(pC,"Автопарри")
makeToggle(pC,"Включить автопарри",CFG.AutoParry,function(v) CFG.AutoParry=v end)
makeToggle(pC,"Учёт пинга",CFG.PingBased,function(v) CFG.PingBased=v end)
makeSlider(pC,"Множитель пинга",0.5,5,CFG.PingOffset,2,function(v) CFG.PingOffset=v end)
makeSlider(pC,"Дистанция парри",0.1,3,CFG.Distance,2,function(v) CFG.Distance=v end)
makeSlider(pC,"Аварийный радиус",2,40,CFG.Emergency,0,function(v) CFG.Emergency=v end)
section(pC,"Клэш")
makeSlider(pC,"Дистанция клэша",5,60,CFG.ClashDist,0,function(v) CFG.ClashDist=v end)
makeSlider(pC,"Задержка клэша",0.005,0.2,CFG.ClashCD,3,function(v) CFG.ClashCD=v end)
makeSlider(pC,"Обычная задержка",0.01,0.3,CFG.NormalCD,3,function(v) CFG.NormalCD=v end)

section(pI,"Способ отбива")
makeSegment(pI,{{"Мышь","mouse"},{"Клавиша","keyboard"},{"Remote","remote"},{"Гибрид","hybrid"}},CFG.InputMode,function(v) CFG.InputMode=v end)
section(pI,"Клавиша (для режима клавиатуры)")
local keyRow = new("Frame",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1},pI)
new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6)},keyRow)
local keyLbl = new("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundColor3=PANEL,BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=ACCENT,Text="  "..CFG.Key.Name.."  (нажми, чтобы сменить)"},keyRow)
corner(keyLbl,8)
keyLbl.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then CFG.Key = Enum.KeyCode.Q end end)
section(pI,"Гуманизация")
makeToggle(pI,"Случайная позиция мыши",CFG.Humanize,function(v) CFG.Humanize=v end)
makeSlider(pI,"Разброс тайминга (мс)",0,80,CFG.Jitter,0,function(v) CFG.Jitter=v end)
makeSlider(pI,"Шанс пропуска",0,0.15,CFG.MissChance,3,function(v) CFG.MissChance=v end)
makeSlider(pI,"Лимит парри/сек",4,30,CFG.MaxPerSec,0,function(v) CFG.MaxPerSec=v end)

section(pV,"Индикатор")
local circle = new("Part",{Name="VeniceCircle",Anchored=true,CanCollide=false,Transparency=1,Material=Enum.Material.Neon,Size=Vector3.new(1,1,1)},workspace)
local mesh = new("SpecialMesh",{MeshId="rbxassetid://3270017"},circle)
makeToggle(pV,"Круг-индикатор",CFG.Visuals,function(v) CFG.Visuals=v if not v then circle.Transparency=1 end end)
section(pV,"Камера")
makeToggle(pV,"Кастомный FOV",CFG.FOVOn,function(v) CFG.FOVOn=v end)
makeSlider(pV,"FOV",40,120,CFG.FOV,0,function(v) CFG.FOV=v end)
makeButton(pV,"Сбросить FOV",function() CFG.FOVOn=false Camera.FieldOfView=ORIG.FOV end)

section(pS,"Освещение")
makeToggle(pS,"Включить кастомизацию",CFG.SkyOn,function(v) CFG.SkyOn=v end)
makeSlider(pS,"Время суток",0,24,CFG.Clock,1,function(v) CFG.Clock=v end)
makeSlider(pS,"Яркость",0,6,CFG.Bright,1,function(v) CFG.Bright=v end)
makeSlider(pS,"Туман",50,5000,CFG.FogEnd,0,function(v) CFG.FogEnd=v end)
makeSlider(pS,"Плотность атмосферы",0,1,CFG.AtmoD,2,function(v) CFG.AtmoD=v end)
makeSlider(pS,"Дымка",0,10,CFG.AtmoH,1,function(v) CFG.AtmoH=v end)
section(pS,"Цветокоррекция")
makeSlider(pS,"Насыщенность",-1,1,CFG.Sat,2,function(v) CFG.Sat=v end)
makeSlider(pS,"Контраст",-1,1,CFG.Contrast,2,function(v) CFG.Contrast=v end)

section(pS,"Пресеты")
local pr = new("Frame",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1},pS)
new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6)},pr)
local presets = {
    ["Ночь"]={ct=0,br=0.4,d=0.45,h=3,s=-0.25,c=0.1,t=Color3.fromRGB(180,195,255),f=260},
    ["Кровь"]={ct=0,br=0.8,d=0.35,h=4,s=0.35,c=0.15,t=Color3.fromRGB(255,130,120),f=320},
    ["Пустота"]={ct=0,br=0,d=1,h=8,s=-1,c=0.3,t=Color3.fromRGB(255,255,255),f=70},
    ["Кибер"]={ct=17,br=2.5,d=0.25,h=2,s=1,c=0.2,t=Color3.fromRGB(140,220,255),f=500},
    ["Закат"]={ct=17.6,br=2.2,d=0.2,h=1,s=0.3,c=0.05,t=Color3.fromRGB(255,200,150),f=900},
}
for n,p in pairs(presets) do
    local b = new("TextButton",{Size=UDim2.new(0,92,0,30),BackgroundColor3=PANEL,BorderSizePixel=0,Font=Enum.Font.GothamMedium,TextSize=11,TextColor3=Color3.fromRGB(210,212,220),Text=n,AutoButtonColor=false},pr)
    corner(b,7)
    b.MouseButton1Click:Connect(function()
        CFG.SkyOn=true
        CFG.Clock,CFG.Bright,CFG.AtmoD,CFG.AtmoH,CFG.Sat,CFG.Contrast,CFG.Tint,CFG.FogEnd = p.ct,p.br,p.d,p.h,p.s,p.c,p.t,p.f
    end)
end
makeButton(pS,"Сбросить всё",function()
    CFG.SkyOn=false
    Lighting.ClockTime=ORIG.Clock Lighting.Brightness=ORIG.Bright Lighting.FogEnd=ORIG.FogEnd
    local cc=Lighting:FindFirstChild("VeniceCC") if cc then cc:Destroy() end
    local at=Lighting:FindFirstChild("VeniceAtmo") if at then at:Destroy() end
end)

section(pM,"Состояние")
local stLbl = new("TextLabel",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,Font=Enum.Font.GothamMedium,TextSize=11,TextColor3=DIM,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Text="remote: поиск..."},pM)
makeButton(pM,"Выгрузить скрипт",function() if getgenv().VeniceUnload then getgenv().VeniceUnload() end end)
new("TextLabel",{Size=UDim2.new(1,0,0,60),BackgroundTransparency=1,Font=Enum.Font.GothamMedium,TextSize=11,TextColor3=DIM,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Text="RightShift — меню\nL — автопарри\n\nRemote-режим работает только после того, как ты хотя бы раз кликнешь сам — скрипт запомнит настоящий remote и его аргументы."},pM)

--==================================================================
--  ЛОГИКА
--==================================================================
local Balls = workspace:FindFirstChild("Balls") or workspace:WaitForChild("Balls",5)
local NetStats = Stats:FindFirstChild("Network") and Stats.Network:FindFirstChild("ServerStatsItem") and Stats.Network.ServerStatsItem:FindFirstChild("Data Ping")

local lastClick, lastBall, busy, frame = 0, nil, false, 0

local function getBall()
    if not Balls then return nil end
    for _,v in ipairs(Balls:GetChildren()) do
        if v:GetAttribute("realBall") == true then return v end
    end
    for _,v in ipairs(Balls:GetChildren()) do
        if v:IsA("BasePart") and v.AssemblyLinearVelocity.Magnitude > 15 then return v end
    end
    return nil
end

local function targeted()
    local ch = Player.Character
    return ch and (ch:GetAttribute("Targeted") == true or ch:FindFirstChild("Highlight") ~= nil) or false
end

local function parry(isClash, ball)
    if not CFG.AutoParry or busy then return end
    local now = tick()
    local cd = isClash and CFG.ClashCD or CFG.NormalCD
    if not isClash and lastBall == ball and now - lastClick < 0.5 then return end
    if now - lastClick < cd then return end
    if not rateOk() then return end
    if CFG.MissChance > 0 and math.random() < CFG.MissChance then return end

    busy, lastClick, lastBall = true, now, ball
    hitTimes[#hitTimes+1] = now
    dispatch(CFG.InputMode)
    task.delay(cd, function() busy = false end)
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
    local spd = vel.Magnitude
    local dist = (pp - bp).Magnitude
    local dot = ((pp - bp).Unit):Dot(vel.Unit)
    if dot < 0 then lastBall = nil end

    local tgt = targeted()
    local clash = tgt and dist <= CFG.ClashDist

    frame += 1
    if CFG.Visuals and frame % 2 == 0 then
        circle.Transparency = clash and 0.05 or (tgt and 0.1 or 0.5)
        circle.CFrame = root.CFrame * CFrame.new(0,-2.6,0) * CFrame.Angles(math.rad(90),0,0)
        local s = math.clamp(dist*0.8,5,65)
        mesh.Scale = mesh.Scale:Lerp(Vector3.new(s,s,0.5),0.5)
        circle.Color = clash and Color3.fromRGB(255,60,60) or (tgt and ACCENT or Color3.fromRGB(150,240,255))
    elseif not CFG.Visuals then
        circle.Transparency = 1
    end

    if clash then
        parry(true, ball)
    elseif tgt and dot > 0 then
        local ping = (CFG.PingBased and NetStats and NetStats.Value/1000) or 0.04
        local jit = (CFG.Jitter > 0 and (math.random()*2-1) * CFG.Jitter/1000) or 0
        local thr = CFG.Distance + (ping * CFG.PingOffset) + jit
        if spd > 150 then thr *= 1.15 end
        if dist/math.max(spd,1) <= thr or dist <= CFG.Emergency then
            parry(false, ball)
        end
    end
end)

Player.CharacterAdded:Connect(function() lastBall, busy = nil, false end)

RunService.RenderStepped:Connect(function()
    if CFG.FOVOn and Camera then Camera.FieldOfView = CFG.FOV end
end)

RunService.Heartbeat:Connect(function()
    if not CFG.SkyOn then return end
    local cc = Lighting:FindFirstChild("VeniceCC") or new("ColorCorrectionEffect",{Name="VeniceCC"},Lighting)
    local at = Lighting:FindFirstChild("VeniceAtmo") or new("Atmosphere",{Name="VeniceAtmo"},Lighting)
    Lighting.ClockTime = CFG.Clock
    Lighting.Brightness = CFG.Bright
    Lighting.FogEnd = CFG.FogEnd
    cc.Saturation, cc.Contrast, cc.TintColor = CFG.Sat, CFG.Contrast, CFG.Tint
    at.Density, at.Haze, at.Color = CFG.AtmoD, CFG.AtmoH, CFG.Tint
end)

task.spawn(function()
    while sg.Parent do
        if parryRemote then
            stLbl.Text = "remote: " .. parryRemote.Name .. " (аргументов: " .. #parryArgs .. ")"
            statusLbl.Text = "hooks: active | remote: ok"
        else
            stLbl.Text = "remote: не найден — кликни один раз сам"
            statusLbl.Text = "hooks: active | remote: wait"
        end
        task.wait(0.5)
    end
end)

--==================================================================
--  ОТКРЫТИЕ / КЛАВИШИ / ВЫГРУЗКА
--==================================================================
local opened = true
local function setOpen(v)
    opened = v
    if v then
        main.Visible = true
        main.Size = UDim2.fromOffset(580,400) main.BackgroundTransparency = 1
        Tween:Create(main,TweenInfo.new(0.28,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(620,430),BackgroundTransparency=0}):Play()
    else
        local t = Tween:Create(main,TweenInfo.new(0.2,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Size=UDim2.fromOffset(580,400),BackgroundTransparency=1})
        t:Play() t.Completed:Connect(function() if not opened then main.Visible = false end end)
    end
end
closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)

local keyHooked = false
keyLbl.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then keyHooked=true end end)

UIS.InputBegan:Connect(function(i, gpe)
    if keyHooked and i.UserInputType == Enum.UserInputType.Keyboard then
        keyHooked = false
        CFG.Key = i.KeyCode
        keyLbl.Text = "  " .. i.KeyCode.Name .. "  (нажми, чтобы сменить)"
        return
    end
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        setOpen(not opened)
    elseif i.KeyCode == Enum.KeyCode.L then
        CFG.AutoParry = not CFG.AutoParry
    end
end)

getgenv().VeniceUnload = function()
    pcall(function()
        sg:Destroy() circle:Destroy()
        Camera.FieldOfView = ORIG.FOV
        Lighting.ClockTime = ORIG.Clock Brightness = ORIG.Bright FogEnd = ORIG.FogEnd
        for _, n in ipairs({"VeniceCC","VeniceAtmo"}) do
            local o = Lighting:FindFirstChild(n) if o then o:Destroy() end
        end
        hookfunction(debug.info, origInfo)
        if origGetinfo and debug.getinfo then hookfunction(debug.getinfo, origGetinfo) end
        hookfunction(getfenv, origGetfenv)
        if origNamecall then hookmetamethod(game, "__namecall", origNamecall) end
    end)
end

switchTab("combat")
setOpen(true)
