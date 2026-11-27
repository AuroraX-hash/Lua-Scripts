--[[ Pinky Modz by Ian - Rayfield edition (Blox Fruits)
     Rebuilt from the Aurora/AuroraX feature list. Logic is re-implemented
     (the uploaded dump had its function bodies stripped). Game-specific parts
     are pcall-guarded so one broken feature cannot break the hub. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local RS = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera
local env = (getgenv and getgenv()) or _G

if env.PinkyModz_Unload then pcall(env.PinkyModz_Unload) end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

----------------------------------------------------------------- state
local S = {
    AimPlayers = false, AimNPC = false, TargetPart = "HumanoidRootPart", AimMode = "360",
    AimMethod = "Camera Lock", FOV = 150, ShowFOV = false, Prediction = false, Tracers = false,
    IgnorePvPOff = false, TeamCheck = false, SafeZone = false, IgnoreLow = false, MinLevel = 2000,
    FastAttack = false, AutoV4 = false, Tracker = false, TrackerDist = 3.5, AutoBuso = false,
    AutoKen = false, AntiStun = false, GunAura = false, FruitM1 = false, FruitM1Btn = false,
    FruitM1Delay = 0.2, ZBoost = false, ZBoostBtn = false, Hitbox = false, HitboxSize = 12,
    InfSoru = false, SoruAim = false, SoruTarget = "Nearest", SuperJump = false, SJPower = 150,
    SJBtn = false, SoulGuitar = false,
    ESPName = false, ESPFruit = false, ESPBounty = false, ESPHealth = false, ESPDist = false,
    ESPWeapon = false, ESPMax = 1500, Box = false, BoxStyle = "2D Box", Chams = false, NPCESP = false,
    CamFOV = 70,
}
local Blacklist = {}          -- skill blacklist: ["Melee Z"]=true
local PlayerBL = {}           -- player blacklist by name
local Conns, Cleanups = {}, {}
local function track(c) Conns[#Conns + 1] = c return c end
local Elements = {}           -- config registry: key -> {set=function}

local function char() return LP.Character end
local function root() local c = char() return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = char() return c and c:FindFirstChildOfClass("Humanoid") end
local function alive(m) local h = m and m:FindFirstChildOfClass("Humanoid") return h and h.Health > 0 end
local function net(name)
    local ok, r = pcall(function() return RS.Modules.Net[name] end)
    return ok and r or nil
end
local CommF = (function() local ok, r = pcall(function() return RS.Remotes.CommF_ end) return ok and r or nil end)()

----------------------------------------------------------------- window
local Window = Rayfield:CreateWindow({
    Name = "Pinky Modz by Ian",
    LoadingTitle = "Pinky Modz by Ian",
    LoadingSubtitle = "Blox Fruits Edition v1.1",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
    ToggleUIKeybind = "RightShift",
})

local function reg(key, el, getter) Elements[key] = { el = el } return el end
local function toggle(tab, key, name, desc, cb)
    local el = tab:CreateToggle({ Name = name, CurrentValue = S[key] or false, Flag = key, Callback = function(v)
        S[key] = v
        if cb then task.spawn(pcall, cb, v) end
    end })
    Elements[key] = el
    return el
end
local function slider(tab, key, name, min, max, inc, suffix, cb)
    local el = tab:CreateSlider({ Name = name, Range = { min, max }, Increment = inc, Suffix = suffix or "",
        CurrentValue = S[key], Flag = key, Callback = function(v) S[key] = v if cb then pcall(cb, v) end end })
    Elements[key] = el
    return el
end
local function dropdown(tab, key, name, options, cb)
    local el = tab:CreateDropdown({ Name = name, Options = options, CurrentOption = { S[key] }, MultipleOptions = false,
        Flag = key, Callback = function(o) local v = type(o) == "table" and o[1] or o S[key] = v if cb then pcall(cb, v) end end })
    Elements[key] = el
    return el
end

----------------------------------------------------------------- HOME
local Home = Window:CreateTab("Home", "home")
Home:CreateSection("Welcome")
Home:CreateLabel("Hi, " .. LP.DisplayName .. " - thanks for using Pinky Modz by Ian")
local gameName = "Unknown"
pcall(function() gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name end)
local execName = "Unknown"
pcall(function() execName = (identifyexecutor and identifyexecutor()) or "Unknown" end)
Home:CreateSection("Session")
Home:CreateLabel("Game: " .. gameName)
Home:CreateLabel("Executor: " .. execName)
local lblPlayers = Home:CreateLabel("Players: -")
local lblStats = Home:CreateLabel("FPS: - | Ping: -")
local lblPos = Home:CreateLabel("Pos: -")
local lblTime = Home:CreateLabel("Session: 00:00")
local t0 = os.clock()
task.spawn(function()
    local frames, last = 0, os.clock()
    track(RunService.RenderStepped:Connect(function() frames += 1 end))
    while task.wait(1) do
        if env.PinkyModz_Dead then break end
        local fps = frames; frames = 0
        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        local r = root()
        pcall(function()
            lblPlayers:Set(("Players: %d/%d"):format(#Players:GetPlayers(), Players.MaxPlayers))
            lblStats:Set(("FPS: %d | Ping: %d ms"):format(fps, ping))
            lblPos:Set(r and ("Pos: %d, %d, %d"):format(r.Position.X, r.Position.Y, r.Position.Z) or "Pos: -")
            local e = math.floor(os.clock() - t0)
            lblTime:Set(("Session: %02d:%02d"):format(e // 60, e % 60))
        end)
    end
end)
Home:CreateSection("Quick Actions")
Home:CreateButton({ Name = "Rejoin Server", Callback = function()
    if #Players:GetPlayers() <= 1 then LP:Kick("Rejoining...") task.wait() TeleportService:Teleport(game.PlaceId, LP)
    else TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end
end })
Home:CreateButton({ Name = "Copy Job ID", Callback = function()
    if setclipboard then setclipboard(game.JobId) end
    Rayfield:Notify({ Title = "Job ID", Content = "Copied: " .. game.JobId, Duration = 3 })
end })
Home:CreateButton({ Name = "Minimize UI (or press RightShift)", Callback = function() Rayfield:SetVisibility(false) end })
Home:CreateButton({ Name = "Toggle HUD Stats", Callback = function()
    for _, l in ipairs({ lblStats, lblPos }) do pcall(function() l:Set("HUD toggled - stats update on Home tab") end) end
end })
Home:CreateSection("Changelog v1.1")
Home:CreateLabel("Aimbot & PvP Off Filter")
Home:CreateLabel("Anti Stun & Gun Aura")
Home:CreateLabel("Fruits M1 One Shot Kit")
Home:CreateLabel("Blox Fruits Music Player")
Home:CreateSection("Music Player")
local music = Instance.new("Sound")
music.Name = "PinkyModz_MusicPlayer" music.Looped = true music.Volume = 0.5 music.Parent = SoundService
Home:CreateInput({ Name = "Sound ID", PlaceholderText = "rbxassetid or number", RemoveTextAfterFocusLost = false,
    Callback = function(t) local id = tostring(t):match("%d+") if id then music.SoundId = "rbxassetid://" .. id end end })
Home:CreateButton({ Name = "Play", Callback = function() music:Play() end })
Home:CreateButton({ Name = "Stop", Callback = function() music:Stop() end })
Home:CreateSlider({ Name = "Volume", Range = { 0, 10 }, Increment = 1, CurrentValue = 5, Callback = function(v) music.Volume = v / 10 end })

----------------------------------------------------------------- AIMBOT
local Aim = Window:CreateTab("Aimbot", "crosshair")
Aim:CreateSection("Aim Assist")
toggle(Aim, "AimPlayers", "Aim Assist Players")
toggle(Aim, "AimNPC", "Aim Assist NPC")
dropdown(Aim, "TargetPart", "Target Part", { "HumanoidRootPart", "Head", "UpperTorso" })
dropdown(Aim, "AimMode", "Aim Mode", { "360", "Screen (FOV only)" })
dropdown(Aim, "AimMethod", "Aim Method", { "Camera Lock", "Silent Aim" })
slider(Aim, "FOV", "FOV Radius", 30, 800, 5, " px")
toggle(Aim, "ShowFOV", "Show FOV")
toggle(Aim, "Prediction", "Prediction")
toggle(Aim, "Tracers", "Tracers")
Aim:CreateSection("Target Filters")
toggle(Aim, "IgnorePvPOff", "Ignore PvP Off")
toggle(Aim, "TeamCheck", "Team Check")
toggle(Aim, "SafeZone", "Safe Zone Check")
toggle(Aim, "IgnoreLow", "Ignore Low Level")
slider(Aim, "MinLevel", "Min Level", 1, 2600, 50)
Aim:CreateSection("Blacklist Master (disables aimbot on selected skills)")
local skillGroups = {
    { "Melee", { "Melee Z", "Melee X", "Melee C" } },
    { "Fruit", { "Fruit M1", "Fruit Z", "Fruit X", "Fruit C", "Fruit V", "Fruit F" } },
    { "Sword", { "Sword Z", "Sword X" } },
    { "Gun", { "Gun M1", "Gun Z", "Gun X" } },
}
local masterBL = false
Aim:CreateToggle({ Name = "Master Blacklist", CurrentValue = false, Callback = function(v) masterBL = v end })
for _, g in ipairs(skillGroups) do
    Aim:CreateSection(g[1] .. " Skills")
    Aim:CreateToggle({ Name = "Blacklist All " .. g[1], CurrentValue = false, Callback = function(v)
        for _, n in ipairs(g[2]) do Blacklist[n] = v and true or nil
            if Elements["BL_" .. n] then pcall(function() Elements["BL_" .. n]:Set(v) end) end end
    end })
    for _, n in ipairs(g[2]) do
        Elements["BL_" .. n] = Aim:CreateToggle({ Name = n, CurrentValue = false, Callback = function(v) Blacklist[n] = v and true or nil end })
    end
end

-- Targeting core ---------------------------------------------------------
local function isSafeZone(m)
    local r = m:FindFirstChild("HumanoidRootPart")
    if not r then return false end
    local ok, res = pcall(function()
        for _, z in ipairs(workspace._WorldOrigin.SafeZones:GetChildren()) do
            local d = (z.Position - r.Position).Magnitude
            if d < math.max(z.Size.X, z.Size.Z) / 2 then return true end
        end
    end)
    return ok and res or false
end
local function pvpOff(p)
    local ok, v = pcall(function() return p.Character:FindFirstChild("PvpDisabled") or p:GetAttribute("PvpDisabled") end)
    if ok and v then return (type(v) == "boolean" and v) or (typeof(v) == "Instance" and v.Value == true) end
    return false
end
local function levelOf(p)
    local ok, v = pcall(function() return p.Data.Level.Value end)
    return ok and v or 0
end
local function skillBlocked()
    return masterBL and next(Blacklist) ~= nil and env.PinkyModz_LastSkill and (os.clock() - env.PinkyModz_LastSkill) < 0.6
        and Blacklist[env.PinkyModz_LastSkillName or ""]
end
local function partOf(m)
    return m:FindFirstChild(S.TargetPart) or m:FindFirstChild("HumanoidRootPart")
end
local function candidates()
    local list = {}
    local mr = root()
    if not mr then return list end
    if S.AimPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and alive(p.Character) and not PlayerBL[p.Name] then
                local ok = true
                if S.TeamCheck and p.Team and p.Team == LP.Team then ok = false end
                if S.IgnorePvPOff and pvpOff(p) then ok = false end
                if S.SafeZone and isSafeZone(p.Character) then ok = false end
                if S.IgnoreLow and levelOf(p) < S.MinLevel then ok = false end
                if ok then list[#list + 1] = p.Character end
            end
        end
    end
    if S.AimNPC then
        local e = workspace:FindFirstChild("Enemies")
        if e then for _, m in ipairs(e:GetChildren()) do
            if alive(m) and not (S.SafeZone and isSafeZone(m)) then list[#list + 1] = m end end end
    end
    return list
end
local function bestTarget()
    local mr = root()
    if not mr then return end
    local best, bestScore, bestPart
    local center = UIS:GetMouseLocation()
    for _, m in ipairs(candidates()) do
        local part = partOf(m)
        if part then
            local sp, on = Cam:WorldToViewportPoint(part.Position)
            local score
            if S.AimMode == "360" then
                score = (part.Position - mr.Position).Magnitude
                if on then score = score * 0.5 end
                if (Vector2.new(sp.X, sp.Y) - center).Magnitude > S.FOV and not (not on) and false then score = nil end
            else
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= S.FOV then score = d end
                end
            end
            if score and (not bestScore or score < bestScore) then best, bestScore, bestPart = m, score, part end
        end
    end
    return best, bestPart
end
local function predicted(part)
    local pos = part.Position
    if S.Prediction then
        local ping = 0
        pcall(function() ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000 end)
        pos = pos + part.AssemblyLinearVelocity * (ping + 0.05)
    end
    return pos
end

-- drawings
local fovCircle, tracer
pcall(function()
    fovCircle = Drawing.new("Circle") fovCircle.Thickness = 1.8 fovCircle.Color = Color3.fromRGB(246, 60, 60)
    fovCircle.Filled = false fovCircle.NumSides = 64 fovCircle.Visible = false
    tracer = Drawing.new("Line") tracer.Thickness = 1.5 tracer.Color = Color3.fromRGB(255, 32, 56) tracer.Visible = false
end)
Cleanups[#Cleanups + 1] = function() pcall(function() fovCircle:Remove() tracer:Remove() end) end

env.PinkyModz_AimPos = nil
RunService:BindToRenderStep("PinkyModz_Aim", 201, function()
    local target, part = bestTarget()
    env.PinkyModz_AimPos = nil
    if fovCircle then
        fovCircle.Visible = S.ShowFOV and (S.AimPlayers or S.AimNPC)
        fovCircle.Radius = S.FOV
        fovCircle.Position = UIS:GetMouseLocation()
    end
    if tracer then tracer.Visible = false end
    if not target or not part or skillBlocked() then return end
    local pos = predicted(part)
    env.PinkyModz_AimPos = pos
    if S.Tracers and tracer then
        local sp, on = Cam:WorldToViewportPoint(pos)
        if on then tracer.From = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y) tracer.To = Vector2.new(sp.X, sp.Y) tracer.Visible = true end
    end
    if S.AimMethod == "Camera Lock" and (UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UIS.TouchEnabled) then
        Cam.CFrame = CFrame.new(Cam.CFrame.Position, pos)
    end
end)
Cleanups[#Cleanups + 1] = function() pcall(function() RunService:UnbindFromRenderStep("PinkyModz_Aim") end) end

-- silent aim: redirect Mouse.Hit / Mouse.Target reads
pcall(function()
    local mouse = LP:GetMouse()
    local old
    old = hookmetamethod(game, "__index", newcclosure(function(self, k)
        if self == mouse and not checkcaller() and S.AimMethod == "Silent Aim" and env.PinkyModz_AimPos and not env.PinkyModz_Dead then
            if k == "Hit" then return CFrame.new(env.PinkyModz_AimPos) end
        end
        return old(self, k)
    end))
end)

----------------------------------------------------------------- PVP / PLAYER LIST
local Pvp = Window:CreateTab("Pvp", "swords")
local PL = Window:CreateTab("Player List", "users")
local selectedPlayer
local function names()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then t[#t + 1] = p.Name end end
    if #t == 0 then t[1] = "(none)" end
    return t
end
PL:CreateSection("Player Controls")
local lblSrv = PL:CreateLabel("Server Players: 1")
local lblBL = PL:CreateLabel("Blacklisted Count: 0")
local lblSpec = PL:CreateLabel("Spectating: None")
local plDrop
local function refreshInfo()
    local c = 0 for _ in pairs(PlayerBL) do c += 1 end
    pcall(function()
        lblSrv:Set("Server Players: " .. #Players:GetPlayers())
        lblBL:Set("Blacklisted Count: " .. c)
    end)
end
plDrop = PL:CreateDropdown({ Name = "Server Players", Options = names(), CurrentOption = {}, MultipleOptions = false,
    Callback = function(o) selectedPlayer = type(o) == "table" and o[1] or o end })
PL:CreateButton({ Name = "Refresh Players", Callback = function() pcall(function() plDrop:Refresh(names()) end) refreshInfo() end })
PL:CreateButton({ Name = "Spectate Selected", Callback = function()
    local p = selectedPlayer and Players:FindFirstChild(selectedPlayer)
    if p and p.Character then Cam.CameraSubject = p.Character:FindFirstChildOfClass("Humanoid") lblSpec:Set("Spectating: " .. p.Name) end
end })
PL:CreateButton({ Name = "Stop Spectate", Callback = function()
    if hum() then Cam.CameraSubject = hum() end lblSpec:Set("Spectating: None")
end })
PL:CreateButton({ Name = "Blacklist Selected (aimbot ignores)", Callback = function()
    if selectedPlayer and selectedPlayer ~= "(none)" then PlayerBL[selectedPlayer] = true refreshInfo() end
end })
PL:CreateButton({ Name = "Clear Blacklist", Callback = function() PlayerBL = {} refreshInfo() end })
track(Players.PlayerAdded:Connect(function() pcall(function() plDrop:Refresh(names()) end) refreshInfo() end))
track(Players.PlayerRemoving:Connect(function() task.defer(function() pcall(function() plDrop:Refresh(names()) end) refreshInfo() end) end))

----------------------------------------------------------------- tool helpers
local function toolOfType(t)
    local c, bp = char(), LP:FindFirstChildOfClass("Backpack")
    for _, holder in ipairs({ c, bp }) do
        if holder then for _, x in ipairs(holder:GetChildren()) do
            if x:IsA("Tool") and x:GetAttribute("WeaponType") == t then return x end end end
    end
end
local function equip(t)
    local tool = toolOfType(t)
    if not tool then return nil end
    if tool.Parent ~= char() and hum() then hum():EquipTool(tool) end
    return tool
end
local function nearestEnemy(range)
    local r = root() if not r then return end
    local best, bd = nil, range or 1e9
    local function try(m)
        local rr = m:FindFirstChild("HumanoidRootPart")
        if rr and alive(m) then local d = (rr.Position - r.Position).Magnitude if d < bd then best, bd = m, d end end
    end
    local e = workspace:FindFirstChild("Enemies")
    if e then for _, m in ipairs(e:GetChildren()) do try(m) end end
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character and not PlayerBL[p.Name] then try(p.Character) end end
    return best, bd
end
local function key(k, down) VIM:SendKeyEvent(down, Enum.KeyCode[k], false, game) end

----------------------------------------------------------------- COMBAT & EXPLOITS (Pvp tab)
Pvp:CreateSection("Combat & Exploits")
toggle(Pvp, "FastAttack", "Fast Attack (Fruits Too)")
task.spawn(function()
    while task.wait(0.05) do
        if env.PinkyModz_Dead then break end
        if S.FastAttack and alive(char()) then pcall(function()
            local tool = char():FindFirstChildOfClass("Tool")
            local m, d = nearestEnemy(60)
            if tool and m then
                local reg, hit = net("RE/RegisterAttack"), net("RE/RegisterHit")
                if reg and hit then
                    reg:FireServer(0)
                    local part = m:FindFirstChild("Head") or m:FindFirstChild("HumanoidRootPart")
                    hit:FireServer(part, { { m, part } })
                end
                tool:Activate()
            end
        end) end
    end
end)
toggle(Pvp, "AutoV4", "Auto V4", "", nil)
task.spawn(function()
    while task.wait(0.5) do
        if env.PinkyModz_Dead then break end
        if S.AutoV4 and alive(char()) then pcall(function()
            local e = char():FindFirstChild("RaceEnergy")
            if e and e.Value >= 1 then key("Y", true) task.wait(0.05) key("Y", false) end
        end) end
    end
end)
toggle(Pvp, "Tracker", "Target Tracker")
slider(Pvp, "TrackerDist", "Tracker Distance", 1, 15, 0.5, " st")
local trackerBtn
Pvp:CreateToggle({ Name = "Tracker On-Screen Button", CurrentValue = false, Callback = function(v)
    if v then
        local g = Instance.new("ScreenGui") g.Name = "PM_Tracker" g.ResetOnSpawn = false g.Parent = (gethui and gethui()) or game:GetService("CoreGui")
        local b = Instance.new("TextButton") b.Size = UDim2.fromOffset(90, 40) b.Position = UDim2.new(0.85, 0, 0.4, 0) b.Text = "Tracker"
        b.BackgroundColor3 = Color3.fromRGB(255, 32, 56) b.TextColor3 = Color3.new(1, 1, 1) b.Font = Enum.Font.GothamBold b.Draggable = true b.Active = true b.Parent = g
        Instance.new("UICorner", b)
        b.MouseButton1Click:Connect(function() S.Tracker = not S.Tracker pcall(function() Elements.Tracker:Set(S.Tracker) end) end)
        trackerBtn = g
    elseif trackerBtn then trackerBtn:Destroy() trackerBtn = nil end
end })
track(RunService.Heartbeat:Connect(function()
    if S.Tracker and root() then
        local m = nearestEnemy(300)
        local r = m and m:FindFirstChild("HumanoidRootPart")
        if r then root().CFrame = r.CFrame * CFrame.new(0, 0, S.TrackerDist) root().AssemblyLinearVelocity = Vector3.zero end
    end
end))
toggle(Pvp, "AutoBuso", "Auto Haki / Buso")
toggle(Pvp, "AutoKen", "Auto Ken (Observation)")
task.spawn(function()
    while task.wait(1) do
        if env.PinkyModz_Dead then break end
        pcall(function()
            if S.AutoBuso and CommF and char() and not char():FindFirstChild("HasBuso") then CommF:InvokeServer("Buso") end
            if S.AutoKen and CommF and char() and not char():FindFirstChild("Ken") and not LP.PlayerGui:FindFirstChild("ScreenEffects") then
                CommF:InvokeServer("Ken", true)
            end
        end)
    end
end)
toggle(Pvp, "AntiStun", "Anti Stun")
track(RunService.Heartbeat:Connect(function()
    if not S.AntiStun then return end
    pcall(function()
        local c, h = char(), hum()
        if not c or not h then return end
        for _, n in ipairs({ "Stun", "Stunned", "Busy", "Knocked" }) do
            local v = c:FindFirstChild(n)
            if v and v:IsA("ValueBase") then if v:IsA("BoolValue") then v.Value = false else v.Value = 0 end end
        end
        if h.WalkSpeed < 16 then h.WalkSpeed = 16 end
        h.PlatformStand = false
        local r = root()
        for _, x in ipairs(r:GetChildren()) do if x:IsA("BodyVelocity") and x.MaxForce.Magnitude > 1e5 and x.Name ~= "PM_Dash" then x:Destroy() end end
    end)
end))
toggle(Pvp, "GunAura", "Gun Aura")
task.spawn(function()
    while task.wait(0.1) do
        if env.PinkyModz_Dead then break end
        if S.GunAura and alive(char()) then pcall(function()
            local gun = equip("Gun")
            local m = nearestEnemy(120)
            local part = m and (m:FindFirstChild("HumanoidRootPart"))
            if gun and part then
                env.PinkyModz_AimPos = part.Position
                gun:Activate()
                local shoot = net("RE/ShootGunEvent")
                if shoot then shoot:FireServer(part.Position, { part }) end
            end
        end) end
    end
end)
toggle(Pvp, "FruitM1", "Fruits M1 One Shot")
slider(Pvp, "FruitM1Delay", "Fruit M1 Delay", 0.05, 1, 0.05, " s")
task.spawn(function()
    while task.wait(0.05) do
        if env.PinkyModz_Dead then break end
        if S.FruitM1 and alive(char()) then pcall(function()
            local f = equip("Blox Fruit") or equip("Fruit")
            if f then
                f:SetAttribute("LocalOverheat", 0) f:SetAttribute("Cooldown", 0)
                f:Activate()
            end
        end) task.wait(S.FruitM1Delay) end
    end
end)
local function floatingButton(name, text, onClick, pos)
    local g = Instance.new("ScreenGui") g.Name = name g.ResetOnSpawn = false g.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    local b = Instance.new("TextButton") b.Size = UDim2.fromOffset(90, 40) b.Position = pos b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(255, 32, 56) b.TextColor3 = Color3.new(1, 1, 1) b.Font = Enum.Font.GothamBold b.Active = true b.Draggable = true b.Parent = g
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(onClick)
    return g
end
local btnGuis = {}
local function btnToggle(tab, name, flagKey, text, onClick, pos)
    tab:CreateToggle({ Name = name, CurrentValue = false, Callback = function(v)
        if v then btnGuis[flagKey] = floatingButton("PM_" .. flagKey, text, onClick, pos)
        elseif btnGuis[flagKey] then btnGuis[flagKey]:Destroy() btnGuis[flagKey] = nil end
    end })
end
btnToggle(Pvp, "Show Fruit M1 Button", "FruitM1Btn", "Fruit M1", function()
    S.FruitM1 = not S.FruitM1 pcall(function() Elements.FruitM1:Set(S.FruitM1) end)
end, UDim2.new(0.85, 0, 0.5, 0))

local function dash(dir, speed, t)
    local r = root() if not r then return end
    local bv = Instance.new("BodyVelocity") bv.Name = "PM_Dash" bv.MaxForce = Vector3.one * 1e6 bv.Velocity = dir * speed bv.Parent = r
    task.delay(t, function() bv:Destroy() end)
end
toggle(Pvp, "ZBoost", "Sanguine Z Boost")
track(UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    local names = { Z = "Z", X = "X", C = "C", V = "V", F = "F" }
    local n = names[i.KeyCode.Name]
    if n then
        local t = char() and char():FindFirstChildOfClass("Tool")
        if t then
            local wt = t:GetAttribute("WeaponType") or "Melee"
            env.PinkyModz_LastSkillName = wt .. " " .. n
            env.PinkyModz_LastSkill = os.clock()
        end
    end
    if i.KeyCode == Enum.KeyCode.Z and S.ZBoost then dash(Cam.CFrame.LookVector, 120, 0.25) end
end))
btnToggle(Pvp, "Show Z Boost Button", "ZBoostBtn", "Z Boost", function() dash(Cam.CFrame.LookVector, 120, 0.25) end, UDim2.new(0.85, 0, 0.6, 0))
Pvp:CreateParagraph({ Title = "FFlags", Content = "The original FFlag button pulled an unknown remote pastebin script. It is intentionally not included." })

Pvp:CreateSection("Hitbox Expander")
toggle(Pvp, "Hitbox", "Enable Hitbox")
slider(Pvp, "HitboxSize", "Hitbox Size", 2, 60, 1, " st")
local origSizes = setmetatable({}, { __mode = "k" })
local function setHitbox(m, on)
    local r = m:FindFirstChild("HumanoidRootPart")
    if not r then return end
    if on then
        origSizes[r] = origSizes[r] or r.Size
        r.Size = Vector3.one * S.HitboxSize r.Transparency = 0.8 r.CanCollide = false
    elseif origSizes[r] then r.Size = origSizes[r] r.Transparency = 1 origSizes[r] = nil end
end
task.spawn(function()
    while task.wait(0.3) do
        if env.PinkyModz_Dead then break end
        pcall(function()
            local e = workspace:FindFirstChild("Enemies")
            if e then for _, m in ipairs(e:GetChildren()) do setHitbox(m, S.Hitbox) end end
            for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character then setHitbox(p.Character, S.Hitbox) end end
        end)
    end
end)
Cleanups[#Cleanups + 1] = function()
    pcall(function()
        for _, m in ipairs(workspace.Enemies:GetChildren()) do setHitbox(m, false) end
        for _, p in ipairs(Players:GetPlayers()) do if p.Character then setHitbox(p.Character, false) end end
    end)
end

Pvp:CreateSection("Soru & Movement")
toggle(Pvp, "InfSoru", "Infinite Soru")
task.spawn(function()
    while task.wait(0.1) do
        if env.PinkyModz_Dead then break end
        if S.InfSoru and char() then pcall(function()
            for _, a in ipairs({ "SoruCooldown", "FlashstepCooldown", "Cooldown" }) do
                if char():GetAttribute(a) then char():SetAttribute(a, 0) end
            end
            local t = char():FindFirstChildOfClass("Tool")
            if t then t:SetAttribute("Cooldown", 0) end
            for _, n in ipairs({ "Soru", "Flashstep" }) do
                local v = char():FindFirstChild(n) if v and v:IsA("NumberValue") then v.Value = 0 end
            end
        end) end
    end
end)
toggle(Pvp, "SoruAim", "Aimbot Soru (1000 Studs)")
dropdown(Pvp, "SoruTarget", "Soru Target (When Aim Off)", { "Nearest", "Lowest HP", "Cursor" })
local function soruTarget()
    local r = root() if not r then return end
    local list = candidates()
    if #list == 0 then
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character and alive(p.Character) then list[#list + 1] = p.Character end end
    end
    local best, score
    for _, m in ipairs(list) do
        local rr = m:FindFirstChild("HumanoidRootPart")
        if rr then
            local d = (rr.Position - r.Position).Magnitude
            if d <= 1000 then
                local sc = d
                if S.SoruTarget == "Lowest HP" then sc = m:FindFirstChildOfClass("Humanoid").Health
                elseif S.SoruTarget == "Cursor" then
                    local sp = Cam:WorldToViewportPoint(rr.Position)
                    sc = (Vector2.new(sp.X, sp.Y) - UIS:GetMouseLocation()).Magnitude
                end
                if not score or sc < score then best, score = rr, sc end
            end
        end
    end
    return best
end
local function soruNow()
    local t, r = soruTarget(), root()
    if t and r then r.CFrame = t.CFrame * CFrame.new(0, 0, 3.5) end
end
Pvp:CreateButton({ Name = "Soru To Target Now", Callback = soruNow })
Pvp:CreateKeybind({ Name = "Soru Keybind", CurrentKeybind = "G", HoldToInteract = false, Callback = function()
    if S.SoruAim or S.InfSoru then soruNow() end
end })
toggle(Pvp, "SuperJump", "Super Jump")
slider(Pvp, "SJPower", "Super Jump Power", 50, 400, 10)
local function superJump()
    local r = root() if r then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, S.SJPower, r.AssemblyLinearVelocity.Z) end
end
track(UIS.JumpRequest:Connect(function() if S.SuperJump then superJump() end end))
Pvp:CreateButton({ Name = "Trigger Super Jump Now", Callback = superJump })
btnToggle(Pvp, "Show Super Jump Button", "SJBtn", "Jump", superJump, UDim2.new(0.85, 0, 0.7, 0))
toggle(Pvp, "SoulGuitar", "Soul Guitar Dash Glitch")
local function hookAnim(c)
    local h = c:WaitForChild("Humanoid", 5)
    if not h then return end
    track(h.AnimationPlayed:Connect(function(tr)
        if S.SoulGuitar and tostring(tr.Animation.AnimationId):find("14586872029") then
            dash(Cam.CFrame.LookVector, 400, 0.9)
        end
    end))
end
if char() then task.spawn(hookAnim, char()) end
track(LP.CharacterAdded:Connect(function(c) task.spawn(hookAnim, c) end))

----------------------------------------------------------------- ESP
local ESP = Window:CreateTab("Esp", "eye")
ESP:CreateSection("Player ESP (Vibrant Text)")
toggle(ESP, "ESPName", "Name & Level ESP")
toggle(ESP, "ESPFruit", "Fruit ESP")
toggle(ESP, "ESPBounty", "Bounty ESP")
toggle(ESP, "ESPHealth", "Health ESP")
toggle(ESP, "ESPDist", "Distance ESP")
toggle(ESP, "ESPWeapon", "Weapon ESP")
slider(ESP, "ESPMax", "Max Distance", 100, 5000, 50, " st")
ESP:CreateSection("Visual Elements & Targets")
toggle(ESP, "Box", "Box ESP")
dropdown(ESP, "BoxStyle", "Box Style", { "2D Box", "Corner Box" })
toggle(ESP, "Chams", "Chams ESP")
toggle(ESP, "NPCESP", "NPC ESP")
ESP:CreateSection("Camera & Lighting")
slider(ESP, "CamFOV", "Field of View", 30, 120, 1, "", function(v) Cam.FieldOfView = v end)

local espObjs = {}   -- [model] = {bb=, label=, hl=, box=}
local function drawNew(t) local ok, d = pcall(Drawing.new, t) return ok and d or nil end
local function getESP(m)
    local o = espObjs[m]
    if o then return o end
    o = {}
    local head = m:FindFirstChild("Head") or m:FindFirstChild("HumanoidRootPart")
    if head then
        local bb = Instance.new("BillboardGui") bb.Name = "PM_ESP" bb.AlwaysOnTop = true bb.Size = UDim2.fromOffset(200, 60)
        bb.StudsOffset = Vector3.new(0, 3, 0) bb.Adornee = head bb.Parent = head
        local l = Instance.new("TextLabel") l.BackgroundTransparency = 1 l.Size = UDim2.fromScale(1, 1) l.RichText = true
        l.Font = Enum.Font.GothamBold l.TextSize = 13 l.TextStrokeTransparency = 0 l.Text = "" l.Parent = bb
        o.bb, o.label = bb, l
    end
    o.box = {}
    for i = 1, 8 do o.box[i] = drawNew("Line") if o.box[i] then o.box[i].Thickness = 1.5 o.box[i].Visible = false end end
    espObjs[m] = o
    return o
end
local function killESP(m)
    local o = espObjs[m]
    if not o then return end
    pcall(function() if o.bb then o.bb:Destroy() end if o.hl then o.hl:Destroy() end end)
    for _, l in ipairs(o.box or {}) do pcall(function() l:Remove() end) end
    espObjs[m] = nil
end
local function hex(c) return ("#%02x%02x%02x"):format(c.R * 255, c.G * 255, c.B * 255) end
local function esc(c, t) return ('<font color="%s">%s</font>'):format(hex(c), t) end
local function hideBox(o) for _, l in ipairs(o.box or {}) do l.Visible = false end end
local function drawBox(o, m, color)
    hideBox(o)
    local r = m:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local top, on1 = Cam:WorldToViewportPoint(r.Position + Vector3.new(0, 3, 0))
    local bot, on2 = Cam:WorldToViewportPoint(r.Position - Vector3.new(0, 3.5, 0))
    if not (on1 and on2) then return end
    local h = math.abs(bot.Y - top.Y) local w = h * 0.55
    local x, y = top.X - w / 2, top.Y
    local L = o.box
    local function ln(i, a, b) if L[i] then L[i].From = a L[i].To = b L[i].Color = color L[i].Visible = true end end
    local tl, tr, bl, br = Vector2.new(x, y), Vector2.new(x + w, y), Vector2.new(x, y + h), Vector2.new(x + w, y + h)
    if S.BoxStyle == "2D Box" then
        ln(1, tl, tr) ln(2, tr, br) ln(3, br, bl) ln(4, bl, tl)
    else
        local c = w * 0.3
        ln(1, tl, tl + Vector2.new(c, 0)) ln(2, tl, tl + Vector2.new(0, c)) ln(3, tr, tr - Vector2.new(c, 0)) ln(4, tr, tr + Vector2.new(0, c))
        ln(5, bl, bl + Vector2.new(c, 0)) ln(6, bl, bl - Vector2.new(0, c)) ln(7, br, br - Vector2.new(c, 0)) ln(8, br, br - Vector2.new(0, c))
    end
end
local function updateOne(m, isPlayer, p)
    local r = m:FindFirstChild("HumanoidRootPart")
    local mr = root()
    if not r or not mr or not alive(m) then killESP(m) return end
    local dist = (r.Position - mr.Position).Magnitude
    if dist > S.ESPMax then killESP(m) return end
    local o = getESP(m)
    if o.label then
        local parts = {}
        if isPlayer then
            if S.ESPName then
                local c = p.TeamColor and p.TeamColor.Color or Color3.new(1, 1, 1)
                parts[#parts + 1] = esc(c, p.DisplayName) .. " " .. esc(Color3.fromRGB(255, 215, 0), "[Lv." .. levelOf(p) .. "]")
            end
            if S.ESPFruit then
                local f = "None" pcall(function() f = p.Data.DevilFruit.Value ~= "" and p.Data.DevilFruit.Value or "None" end)
                parts[#parts + 1] = esc(Color3.fromRGB(170, 85, 255), f)
            end
            if S.ESPBounty then
                local b = 0 pcall(function() b = p.leaderstats["Bounty/Honor"].Value end)
                parts[#parts + 1] = esc(Color3.fromRGB(255, 150, 40), "$" .. tostring(b))
            end
            if S.ESPWeapon then
                local t = m:FindFirstChildOfClass("Tool")
                if t then parts[#parts + 1] = esc(Color3.new(1, 1, 1), t.Name) end
            end
        else
            parts[#parts + 1] = esc(Color3.fromRGB(255, 90, 90), m.Name)
        end
        if S.ESPHealth or not isPlayer then
            local h = m:FindFirstChildOfClass("Humanoid")
            local pct = math.floor(h.Health / math.max(h.MaxHealth, 1) * 100)
            local c = pct > 66 and Color3.fromRGB(80, 255, 80) or pct > 33 and Color3.fromRGB(255, 230, 60) or Color3.fromRGB(255, 70, 70)
            if S.ESPHealth or true then parts[#parts + 1] = esc(c, pct .. "%") end
        end
        if S.ESPDist or not isPlayer then parts[#parts + 1] = esc(Color3.fromRGB(80, 230, 255), math.floor(dist) .. " st") end
        o.label.Text = table.concat(parts, "\n")
        o.label.Visible = #parts > 0
    end
    if S.Box and isPlayer then drawBox(o, m, Color3.fromRGB(255, 32, 56)) else hideBox(o) end
    local wantHL = (S.Chams and isPlayer) or (S.NPCESP and not isPlayer and S.Chams)
    if wantHL and not o.hl then
        local hl = Instance.new("Highlight") hl.FillColor = Color3.fromRGB(255, 32, 56) hl.FillTransparency = 0.6 hl.OutlineColor = Color3.new(1, 1, 1) hl.Parent = m o.hl = hl
    elseif not wantHL and o.hl then o.hl:Destroy() o.hl = nil end
end
task.spawn(function()
    while task.wait(0.1) do
        if env.PinkyModz_Dead then break end
        local anyPlayer = S.ESPName or S.ESPFruit or S.ESPBounty or S.ESPHealth or S.ESPDist or S.ESPWeapon or S.Box or S.Chams
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                if anyPlayer then pcall(updateOne, p.Character, true, p) else killESP(p.Character) end
            end
        end
        local e = workspace:FindFirstChild("Enemies")
        if e then for _, m in ipairs(e:GetChildren()) do
            if S.NPCESP then pcall(updateOne, m, false) else killESP(m) end end end
        for m in pairs(espObjs) do if not m.Parent then killESP(m) end end
    end
end)
track(RunService.RenderStepped:Connect(function()
    -- keep box lines current every frame (BillboardGui follows by itself)
    if not S.Box then return end
    for m, o in pairs(espObjs) do
        if m.Parent and Players:GetPlayerFromCharacter(m) then pcall(drawBox, o, m, Color3.fromRGB(255, 32, 56)) end
    end
end))
Cleanups[#Cleanups + 1] = function() for m in pairs(espObjs) do killESP(m) end end

----------------------------------------------------------------- MACRO
local Macro = Window:CreateTab("Macro", "zap")
local weaponOpts, skillOpts, modeOpts = { "Melee", "Blox Fruit", "Sword", "Gun" }, { "Z", "X", "C", "V", "F" }, { "Tap", "Hold" }
local defaults = {
    { "Melee Z", "Sword X", "Melee C", "Gun Z", "Fruit V", "Melee X" },
}
local M = { Enabled = false, Loop = false, AutoX = false, Running = false, Token = 0, Slot = 1, Key = "R" }
M.Slots = {}
for s = 1, 5 do
    M.Slots[s] = { Blocks = {} }
    for b = 1, 6 do M.Slots[s].Blocks[b] = { Enabled = b <= 2, Weapon = "Melee", Skill = ({ "Z", "X", "C", "V", "F", "Z" })[b], Mode = "Tap", Hold = 0 } end
end
local function runCombo()
    if M.Running or not M.Enabled then return end
    M.Running = true M.Token += 1
    local tok = M.Token
    task.spawn(function()
        repeat
            for _, b in ipairs(M.Slots[M.Slot].Blocks) do
                if tok ~= M.Token or not M.Enabled then break end
                if b.Enabled then
                    local wt = b.Weapon == "Blox Fruit" and "Blox Fruit" or b.Weapon
                    if not (equip(wt) or (wt == "Blox Fruit" and equip("Fruit"))) then task.wait(0.05) end
                    task.wait(0.1)
                    key(b.Skill, true)
                    if b.Mode == "Hold" then task.wait(math.max(b.Hold, 0.05)) else task.wait(0.05) end
                    key(b.Skill, false)
                    task.wait(0.15)
                end
            end
        until not M.Loop or tok ~= M.Token or not M.Enabled
        M.Running = false
        pcall(function() lblMacroStatus:Set("Status: Idle") end)
    end)
    pcall(function() lblMacroStatus:Set("Status: Running") end)
end
local function stopCombo() M.Token += 1 M.Running = false pcall(function() lblMacroStatus:Set("Status: Idle") end) end
Macro:CreateSection("Aurora Smart Macro")
Macro:CreateToggle({ Name = "Enable Smart Macro", CurrentValue = false, Callback = function(v) M.Enabled = v if not v then stopCombo() end end })
lblMacroStatus = Macro:CreateLabel("Status: Idle")
Macro:CreateDropdown({ Name = "Macro Slot", Options = { "Slot 1", "Slot 2", "Slot 3", "Slot 4", "Slot 5" }, CurrentOption = { "Slot 1" }, MultipleOptions = false,
    Callback = function(o) M.Slot = tonumber((type(o) == "table" and o[1] or o):match("%d")) or 1 end })
Macro:CreateToggle({ Name = "Loop Sequence", CurrentValue = false, Callback = function(v) M.Loop = v end })
local mobileGui
Macro:CreateToggle({ Name = "Show Mobile Button", CurrentValue = false, Callback = function(v)
    if v then mobileGui = floatingButton("PM_MacroBtn", "Combo", function() if M.Running then stopCombo() else runCombo() end end, UDim2.new(0.85, 0, 0.3, 0))
    elseif mobileGui then mobileGui:Destroy() mobileGui = nil end
end })
Macro:CreateToggle({ Name = "Auto Start on X", CurrentValue = false, Callback = function(v) M.AutoX = v end })
Macro:CreateKeybind({ Name = "Macro Key (PC)", CurrentKeybind = "R", HoldToInteract = false, Callback = function()
    if M.Running then stopCombo() else runCombo() end
end })
Macro:CreateButton({ Name = "Start Combo Sequence", Callback = runCombo })
Macro:CreateButton({ Name = "Stop Combo Sequence", Callback = stopCombo })
track(UIS.InputBegan:Connect(function(i, gp)
    if not gp and M.AutoX and M.Enabled and i.KeyCode == Enum.KeyCode.X and not M.Running then task.delay(0.3, runCombo) end
end))
Macro:CreateSection("Combo Sequence (6 Blocks) - edits the selected slot")
for b = 1, 6 do
    local function blk() return M.Slots[M.Slot].Blocks[b] end
    Macro:CreateToggle({ Name = "Block " .. b .. " Enabled", CurrentValue = b <= 2, Callback = function(v) blk().Enabled = v end })
    Macro:CreateDropdown({ Name = "B" .. b .. " Weapon", Options = weaponOpts, CurrentOption = { "Melee" }, MultipleOptions = false, Callback = function(o) blk().Weapon = type(o) == "table" and o[1] or o end })
    Macro:CreateDropdown({ Name = "B" .. b .. " Skill Key", Options = skillOpts, CurrentOption = { ({ "Z", "X", "C", "V", "F", "Z" })[b] }, MultipleOptions = false, Callback = function(o) blk().Skill = type(o) == "table" and o[1] or o end })
    Macro:CreateDropdown({ Name = "B" .. b .. " Cast Mode", Options = modeOpts, CurrentOption = { "Tap" }, MultipleOptions = false, Callback = function(o) blk().Mode = type(o) == "table" and o[1] or o end })
    Macro:CreateSlider({ Name = "B" .. b .. " Hold Time", Range = { 0, 5 }, Increment = 0.05, Suffix = " s", CurrentValue = 0, Callback = function(v) blk().Hold = v end })
end

----------------------------------------------------------------- CONFIGS
local Cfg = Window:CreateTab("Configs", "settings")
local cfgSlot = 1
local dir = "AuroraX"
pcall(function() if makefolder and not isfolder(dir) then makefolder(dir) end end)
local function path(n) return ("%s/config_%d.json"):format(dir, n) end
local persistKeys = {}
for k, v in pairs(S) do if type(v) ~= "table" then persistKeys[#persistKeys + 1] = k end end
local function saveCfg(n)
    local d = {}
    for _, k in ipairs(persistKeys) do d[k] = S[k] end
    writefile(path(n), HttpService:JSONEncode(d))
end
local function loadCfg(n)
    if not (isfile and isfile(path(n))) then return false end
    local d = HttpService:JSONDecode(readfile(path(n)))
    for k, v in pairs(d) do
        if S[k] ~= nil then
            S[k] = v
            local el = Elements[k]
            if el and el.Set then pcall(function() el:Set(v) end) end
        end
    end
    return true
end
Cfg:CreateSection("Configuration")
Cfg:CreateDropdown({ Name = "Slot", Options = { "Slot 1", "Slot 2", "Slot 3", "Slot 4", "Slot 5" }, CurrentOption = { "Slot 1" }, MultipleOptions = false,
    Callback = function(o) cfgSlot = tonumber((type(o) == "table" and o[1] or o):match("%d")) or 1 end })
Cfg:CreateButton({ Name = "Save Config", Callback = function()
    local ok = pcall(saveCfg, cfgSlot)
    Rayfield:Notify({ Title = "Config", Content = ok and ("Saved slot " .. cfgSlot) or "Save failed (no file support)", Duration = 3 })
end })
Cfg:CreateButton({ Name = "Load Config", Callback = function()
    local ok, res = pcall(loadCfg, cfgSlot)
    Rayfield:Notify({ Title = "Config", Content = (ok and res) and ("Loaded slot " .. cfgSlot) or "Nothing to load", Duration = 3 })
end })
Cfg:CreateButton({ Name = "Delete Config", Callback = function()
    pcall(function() if isfile(path(cfgSlot)) then delfile(path(cfgSlot)) end end)
    Rayfield:Notify({ Title = "Config", Content = "Deleted slot " .. cfgSlot, Duration = 3 })
end })
local autoPath = dir .. "/autoload.txt"
Cfg:CreateToggle({ Name = "Auto Load (loads selected slot on execute)", CurrentValue = false, Callback = function(v)
    pcall(function() if v then writefile(autoPath, tostring(cfgSlot)) elseif isfile(autoPath) then delfile(autoPath) end end)
end })
Cfg:CreateSection("Info")
Cfg:CreateLabel("Folder: AuroraX/")
Cfg:CreateLabel("File support: " .. ((writefile and readfile) and "Yes" or "No"))
Cfg:CreateButton({ Name = "Reset to Defaults", Callback = function()
    local defaultsS = { AimPlayers = false, AimNPC = false, TargetPart = "HumanoidRootPart", AimMode = "360", AimMethod = "Camera Lock",
        FOV = 150, MinLevel = 2000, TrackerDist = 3.5, FruitM1Delay = 0.2, HitboxSize = 12, SJPower = 150, ESPMax = 1500, CamFOV = 70 }
    for _, k in ipairs(persistKeys) do
        local v = defaultsS[k]
        if v == nil then v = (type(S[k]) == "boolean") and false or S[k] end
        S[k] = v
        local el = Elements[k] if el and el.Set then pcall(function() el:Set(v) end) end
    end
end })

----------------------------------------------------------------- INFORMATION
local Info = Window:CreateTab("Information", "info")
Info:CreateSection("Official Discord")
Info:CreateLabel("Pinky Modz by Ian Official Hub - discord.gg/wWJvsQ9Ed8")
Info:CreateButton({ Name = "Copy Discord Invite", Callback = function()
    if setclipboard then setclipboard("https://discord.gg/wWJvsQ9Ed8") end
    Rayfield:Notify({ Title = "Discord", Content = "Invite copied: discord.gg/wWJvsQ9Ed8", Duration = 3 })
end })
Info:CreateSection("Build & System")
Info:CreateLabel("Version: v1.1 (Blox Fruits Edition)")
Info:CreateLabel("Target Game: Blox Fruits (Sea 1, 2 & 3)")
Info:CreateLabel("Engine: Pinky Modz by Ian Next-Gen Runtime")
Info:CreateLabel("Status: All Systems Operational")
Info:CreateButton({ Name = "Unload Script", Callback = function() env.PinkyModz_Unload() end })

----------------------------------------------------------------- unload
env.PinkyModz_Unload = function()
    env.PinkyModz_Dead = true
    for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
    for _, f in ipairs(Cleanups) do pcall(f) end
    for _, g in pairs(btnGuis) do pcall(function() g:Destroy() end) end
    if mobileGui then pcall(function() mobileGui:Destroy() end) end
    pcall(function() music:Stop() music:Destroy() end)
    for k in pairs(S) do if type(S[k]) == "boolean" then S[k] = false end end
    env.PinkyModz_AimPos = nil
    pcall(function() Rayfield:Destroy() end)
    env.PinkyModz_Unload = nil
end
env.PinkyModz_Dead = false

pcall(function()
    if isfile and isfile(autoPath) then
        local n = tonumber(readfile(autoPath))
        if n then cfgSlot = n loadCfg(n) end
    end
end)
Rayfield:Notify({ Title = "Pinky Modz by Ian", Content = "Loaded! Press RightShift to minimize.", Duration = 5 })
