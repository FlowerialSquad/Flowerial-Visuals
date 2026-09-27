-- flowerial | client-side Luau
local HUB_NAME      = "flowerial"
local CONFIG_FILE   = "flowerial_config.json"

local TEX = {
    Rain   = "rbxasset://textures/particles/sparkles_main.dds",
    Snow   = "rbxasset://textures/particles/sparkles_main.dds",
    Leaf   = "rbxasset://textures/particles/sparkles_main.dds",
    Dust   = "rbxasset://textures/particles/sparkles_main.dds",
    Aura   = "rbxasset://textures/particles/sparkles_main.dds",
}
local THUNDER_SOUND = "rbxasset://sounds/impact_explosion_03.mp3"

local KORBLOX = {
    UpperLeg = "rbxassetid://902942096", -- R15
    LowerLeg = "rbxassetid://902942093", -- R15
    Foot     = "rbxassetid://902942089", -- R15
    R6Leg    = "rbxassetid://902942093", -- R6
    Texture  = "rbxassetid://902843398",
}

local ACCESSORIES = {
    { key = "acc_wings" }, { key = "acc_horns" }, { key = "acc_halo" },
    { key = "acc_tail" }, { key = "acc_cape" }, { key = "acc_crown" },
}

local DESIGN_W, DESIGN_H = 520, 430

local Players          = game:GetService("Players")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Workspace        = game:GetService("Workspace")
local SoundService     = game:GetService("SoundService")
local Stats            = game:GetService("Stats")
local LocalPlayer      = Players.LocalPlayer

local genv = (getgenv and getgenv()) or _G
if genv.__FlowerialCleanup then pcall(genv.__FlowerialCleanup) end
if genv.__HubCleanup then pcall(genv.__HubCleanup) end

local WHITE   = Color3.new(1, 1, 1)
local BLACK   = Color3.new(0, 0, 0)
local GRAY    = Color3.fromRGB(140, 140, 150)
local OFF_COL = Color3.fromRGB(72, 72, 80)
local ROW_BG  = Color3.fromRGB(40, 40, 45)
local NSK     = NumberSequenceKeypoint.new
local CSK     = ColorSequenceKeypoint.new

local function new(class, props, parent)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do o[k] = v end
    end
    if parent then o.Parent = parent end
    return o
end

local function corner(o, r)
    return new("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end

local function stroke(o, color, thick, transp)
    return new("UIStroke", {
        Color = color, Thickness = thick or 1, Transparency = transp or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, o)
end

local conns = {}
local function connect(sig, fn)
    local c = sig:Connect(fn)
    conns[#conns + 1] = c
    return c
end

local function safeDestroy(o)
    if o then pcall(function() o:Destroy() end) end
end

local cfg = { theme = 5, lang = "RU", anim = false, restore = true, profiles = {} }
pcall(function()
    if isfile then
        local file = isfile(CONFIG_FILE) and CONFIG_FILE or (isfile("MyHub_config.json") and "MyHub_config.json")
        if file then
            local d = HttpService:JSONDecode(readfile(file))
            for k, v in pairs(d) do cfg[k] = v end
        end
    end
end)
if type(cfg.profiles) ~= "table" then cfg.profiles = {} end

local REG, REG_ORDER = {}, {}
local function reg(key, ctl)
    REG[key] = ctl
    REG_ORDER[#REG_ORDER + 1] = key
end
local function snapshotState()
    local s = {}
    for _, k in ipairs(REG_ORDER) do
        local ok, v = pcall(REG[k].Get)
        if ok and v ~= nil then s[k] = v end
    end
    return s
end
local function applyState(s)
    for _, k in ipairs(REG_ORDER) do
        local v = s[k]
        if v ~= nil then pcall(REG[k].Set, v) end
    end
end

local dirty = false
local function markDirty() dirty = true end

local THEMES = {
    { key = "t_blood",  color = Color3.fromRGB(226, 32, 44) },
    { key = "t_gold",   color = Color3.fromRGB(212, 160, 30) },
    { key = "t_honey",  color = Color3.fromRGB(48, 151, 94) },
    { key = "t_amber",  color = Color3.fromRGB(171, 181, 193) },
    { key = "t_rose",   color = Color3.fromRGB(240, 110, 175) },
    { key = "t_ice",    color = Color3.fromRGB(110, 200, 255) },
    { key = "t_violet", color = Color3.fromRGB(150, 90, 255) },
    { key = "t_mint",   color = Color3.fromRGB(60, 220, 160) },
    { key = "t_ocean",  color = Color3.fromRGB(40, 120, 255) },
    { key = "t_toxic",  color = Color3.fromRGB(140, 255, 60) },
}
if type(cfg.theme) ~= "number" or cfg.theme < 1 or cfg.theme > #THEMES then cfg.theme = 5 end

local function T(en, ru) return { EN = en, RU = ru } end
local L = {
    themes    = T("Themes", "Темы"),
    world     = T("World", "Мир"),
    sky       = T("Sky", "Небо"),
    shaders   = T("Shaders", "Шейдеры"),
    camera    = T("Camera", "Камера"),
    character = T("Character", "Персонаж"),
    music     = T("Music", "Музыка"),
    settings  = T("Settings", "Настройки"),

    hd_time     = T("DAY / NIGHT", "ДЕНЬ / НОЧЬ"),
    time_lock   = T("Lock time", "Фиксировать время"),
    time        = T("Time of day", "Время суток"),
    day         = T("Day", "День"),
    night       = T("Night", "Ночь"),
    cycle       = T("Auto day/night cycle", "Авто-смена дня и ночи"),
    cycle_speed = T("Cycle speed", "Скорость смены"),
    hd_weather  = T("WEATHER", "ПОГОДА"),
    rain        = T("Rain", "Дождь"),
    snow        = T("Snow", "Снег"),
    leaves      = T("Falling leaves", "Листопад"),
    dust        = T("Fireflies / dust", "Светлячки / пыль"),
    storm       = T("Storm (lightning)", "Гроза (молнии)"),
    rain_int    = T("Intensity", "Интенсивность"),

    hd_sky      = T("SKY", "НЕБО"),
    sky_def     = T("Game default", "Как в игре"),
    sky_sunset  = T("Sunset", "Закат"),
    sky_purple  = T("Purple night", "Фиолетовая ночь"),
    sky_space   = T("Space", "Космос"),
    sky_overcast= T("Overcast", "Пасмурно"),
    stars       = T("Stars", "Звёзды"),
    hd_fog      = T("FOG", "ТУМАН"),
    fog_off     = T("Off", "Выключен"),
    fog_morning = T("Morning", "Утренний"),
    fog_dense   = T("Dense", "Густой"),
    fog_blood   = T("Blood", "Кровавый"),
    fog_night   = T("Night mist", "Ночная дымка"),
    fog_dist    = T("Fog distance", "Дальность тумана"),
    hd_skyfx    = T("EFFECTS", "ЭФФЕКТЫ"),
    aurora      = T("Aurora", "Северное сияние"),
    rainbow     = T("Rainbow", "Радуга"),

    sh_off       = T("Off", "Выключено"),
    sh_cinematic = T("Cinematic", "Кино"),
    sh_vibrant   = T("Vibrant", "Яркий"),
    sh_realistic = T("Realistic", "Реализм"),
    sh_moody     = T("Moody", "Мрачный"),
    sh_warm      = T("Warm", "Тёплый"),

    hd_cine     = T("CINEMA", "КИНО"),
    cine        = T("Cinema bars", "Кинорежим (полосы)"),
    cine_size   = T("Bar size", "Размер полос"),
    vignette    = T("Vignette", "Виньетка"),
    vig_int     = T("Vignette strength", "Сила виньетки"),
    mblur       = T("Motion blur", "Размытие в движении"),
    mblur_int   = T("Blur strength", "Сила размытия"),
    hd_cam      = T("CAMERA", "КАМЕРА"),
    bob         = T("Head bob", "Покачивание при беге"),
    bob_amp     = T("Bob amount", "Сила покачивания"),
    fov_on      = T("Custom FOV", "Свой FOV"),
    fov         = T("Field of view", "Угол обзора"),
    zoom        = T("Max zoom distance", "Макс. дальность камеры"),
    photo       = T("Photo mode (hide menu)", "Режим фото (скрыть меню)"),

    headless  = T("Fake Headless", "Безголовый (фейк)"),
    korblox   = T("Fake Korblox", "Корблокс (фейк)"),
    hide_acc  = T("Hide accessories", "Скрыть аксессуары"),
    rig       = T("Rig type", "Тип рига"),
    hd_look   = T("LOOK", "ВНЕШНИЙ ВИД"),
    tint      = T("Body color", "Цвет тела"),
    tint_r    = T("Red", "Красный"),
    tint_g    = T("Green", "Зелёный"),
    tint_b    = T("Blue", "Синий"),
    mat_off   = T("Default material", "Материал как есть"),
    mat_neon  = T("Neon", "Неон"),
    mat_glass = T("Glass", "Стекло"),
    mat_ff    = T("Force field", "Силовое поле"),
    mat_metal = T("Metal", "Металл"),
    mat_ice   = T("Ice", "Лёд"),
    ghost     = T("Ghost (transparency)", "Призрак (прозрачность)"),
    aura      = T("Glowing aura", "Светящаяся аура"),
    trail     = T("Trail", "След за персонажем"),
    hd_acc    = T("ACCESSORIES", "АКСЕССУАРЫ"),
    acc_wings = T("Wings", "Крылья"),
    acc_horns = T("Horns", "Рога"),
    acc_halo  = T("Halo", "Нимб"),
    acc_tail  = T("Tail", "Хвост"),
    acc_cape  = T("Cape", "Плащ"),
    acc_crown = T("Crown", "Корона"),

    hd_music    = T("PLAYER", "ПЛЕЕР"),
    music_ph    = T("Audio asset ID", "ID аудио"),
    music_play  = T("Play", "Играть"),
    music_pause = T("Pause / resume", "Пауза / продолжить"),
    music_stop  = T("Stop", "Стоп"),
    music_vol   = T("Volume", "Громкость"),
    music_loop  = T("Loop", "Повтор"),
    music_bad   = T("Invalid audio ID", "Неверный ID аудио"),

    anim_grad  = T("Animated gradient", "Анимированный градиент"),
    restore    = T("Restore settings on launch", "Восстанавливать настройки при запуске"),
    menu_alpha = T("Menu transparency", "Прозрачность меню"),
    hotkey     = T("Menu shortcut", "Клавиша меню"),
    bind_wait  = T("Press a key...", "Нажмите клавишу..."),
    hud        = T("Status panel", "Панель показателей"),
    hud_ping   = T("PING", "ПИНГ"),
    hud_clock  = T("TIME", "ВРЕМЯ"),
    hd_prof    = T("CONFIGS", "КОНФИГИ"),
    prof_name  = T("Config name", "Название конфига"),
    prof_ph    = T("Enter a name", "Введите название"),
    prof_save  = T("Save", "Сохранить"),
    prof_load  = T("Load", "Загрузить"),
    prof_delete = T("Delete", "Удалить"),
    prof_saved = T("Config saved", "Конфиг сохранён"),
    prof_done  = T("Config loaded", "Конфиг загружен"),
    prof_empty = T("Config not found", "Конфиг не найден"),
    prof_bad   = T("Enter a name (up to 32 characters)", "Введите название (до 32 символов)"),
    prof_none  = T("No saved configs", "Нет сохранённых конфигов"),
    prof_again = T("Press Delete again", "Нажмите «Удалить» ещё раз"),
    prof_deleted = T("Config deleted", "Конфиг удалён"),
    reset      = T("Reset all effects", "Сбросить все эффекты"),
    saved      = T("Config saved", "Конфиг сохранён"),
    nosave     = T("Saving not supported", "Сохранение не поддерживается"),
    reset_done = T("Effects reset", "Эффекты сброшены"),

    t_blood  = T("Blood", "Кровь"),
    t_gold   = T("Gold", "Золото"),
    t_honey  = T("Forest", "Лесной"),
    t_amber  = T("Silver", "Серебро"),
    t_rose   = T("Rose", "Роза"),
    t_ice    = T("Ice", "Лёд"),
    t_violet = T("Violet", "Фиолет"),
    t_mint   = T("Mint", "Мята"),
    t_ocean  = T("Ocean", "Океан"),
    t_toxic  = T("Toxic", "Токсик"),
}

local lang = (cfg.lang == "EN") and "EN" or "RU"
local bindings = {}
local function tr(key)
    local e = L[key]
    return e and e[lang] or key
end
local function bind(obj, key, prop)
    prop = prop or "Text"
    obj[prop] = tr(key)
    bindings[#bindings + 1] = { obj, key, prop }
    return obj
end

local function mountGui(g)
    local ok = pcall(function()
        if gethui then g.Parent = gethui() else error("no gethui") end
    end)
    if not (ok and g.Parent) then
        ok = pcall(function() g.Parent = game:GetService("CoreGui") end)
    end
    if not (ok and g.Parent) then
        g.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local gui = new("ScreenGui", {
    Name = HUB_NAME .. tostring(math.random(1000, 9999)),
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
})
mountGui(gui)

local accent = new("Color3Value", { Value = THEMES[cfg.theme].color }, gui)
local accentFns = {}
local function onAccent(fn)
    accentFns[#accentFns + 1] = fn
    fn(accent.Value)
end
connect(accent.Changed, function()
    for _, fn in ipairs(accentFns) do fn(accent.Value) end
end)

local ORIG = {}
for _, p in ipairs({ "Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "FogEnd",
    "FogStart", "FogColor", "ExposureCompensation", "ColorShift_Top", "ColorShift_Bottom" }) do
    ORIG[p] = Lighting[p]
end

local Tm  = { lock = false, value = ORIG.ClockTime, cycle = false, speed = 0.25, skyOwnsTime = false }
local Wx  = { rain = false, snow = false, leaves = false, dust = false, storm = false,
              mult = 1, nextStrike = 0, aurora = nil, rainbow = nil }
local Env = { skyPreset = nil, stars = nil, fogIdx = 1, fogDist = 800,
              shaderAtm = nil, skyAtm = nil }
local C   = {}  -- все элементы управления

local SKY_ORDER = { "sunset", "purple", "space", "overcast" }
local SKIES = {
    sunset = {
        time = 18.3, stars = 0, bright = 0.9,
        ambient = Color3.fromRGB(120, 72, 84), outdoor = Color3.fromRGB(196, 112, 92),
        top = Color3.fromRGB(255, 150, 90), bottom = Color3.fromRGB(190, 80, 120),
        atm = { Density = 0.36, Offset = 0.2, Color = Color3.fromRGB(255, 170, 130),
                Decay = Color3.fromRGB(190, 90, 70), Glare = 0.7, Haze = 2 },
    },
    purple = {
        time = 0, stars = 4000, bright = 0.8,
        ambient = Color3.fromRGB(60, 36, 100), outdoor = Color3.fromRGB(90, 60, 150),
        top = Color3.fromRGB(150, 90, 255), bottom = Color3.fromRGB(70, 40, 140),
        atm = { Density = 0.3, Offset = 0, Color = Color3.fromRGB(120, 80, 190),
                Decay = Color3.fromRGB(60, 35, 110), Glare = 0, Haze = 1.5 },
    },
    space = {
        time = 0, stars = 5000, bright = 0.7,
        ambient = Color3.fromRGB(24, 24, 44), outdoor = Color3.fromRGB(36, 36, 66),
        top = Color3.fromRGB(60, 60, 120), bottom = Color3.fromRGB(20, 20, 40),
        atm = { Density = 0, Offset = 0, Color = Color3.fromRGB(0, 0, 0),
                Decay = Color3.fromRGB(0, 0, 0), Glare = 0, Haze = 0 },
    },
    overcast = {
        time = 13, stars = 0, bright = 0.7,
        ambient = Color3.fromRGB(110, 116, 126), outdoor = Color3.fromRGB(150, 156, 166),
        top = Color3.fromRGB(200, 205, 215), bottom = Color3.fromRGB(140, 145, 155),
        atm = { Density = 0.45, Offset = 0, Color = Color3.fromRGB(185, 190, 200),
                Decay = Color3.fromRGB(120, 125, 135), Glare = 0, Haze = 3 },
    },
}

local FOGS = {
    [2] = { color = Color3.fromRGB(200, 210, 225) },
    [3] = { color = Color3.fromRGB(150, 155, 165) },
    [4] = { color = Color3.fromRGB(150, 20, 25) },
    [5] = { color = Color3.fromRGB(60, 70, 110) },
}

local SHADER_ORDER = { "cinematic", "vibrant", "realistic", "moody", "warm" }
local SHADERS = {
    cinematic = {
        bloom = { Intensity = 0.5, Size = 30, Threshold = 1.8 },
        rays  = { Intensity = 0.10, Spread = 0.7 },
        color = { Brightness = 0, Contrast = 0.2, Saturation = 0.1, TintColor = Color3.fromRGB(255, 246, 236) },
        dof   = { FarIntensity = 0.12, FocusDistance = 70, InFocusRadius = 60, NearIntensity = 0 },
        atm   = { Density = 0.28, Offset = 0.15, Color = Color3.fromRGB(199, 210, 225),
                  Decay = Color3.fromRGB(106, 112, 125), Glare = 0.15, Haze = 1.4 },
        exposure = 0.15,
    },
    vibrant = {
        bloom = { Intensity = 0.35, Size = 24, Threshold = 2 },
        rays  = { Intensity = 0.15, Spread = 1 },
        color = { Brightness = 0.02, Contrast = 0.12, Saturation = 0.45, TintColor = WHITE },
        exposure = 0.05,
    },
    realistic = {
        bloom = { Intensity = 0.25, Size = 20, Threshold = 2.2 },
        rays  = { Intensity = 0.08, Spread = 0.6 },
        color = { Brightness = 0, Contrast = 0.08, Saturation = -0.05, TintColor = Color3.fromRGB(255, 252, 246) },
        atm   = { Density = 0.32, Offset = 0.25, Color = Color3.fromRGB(190, 205, 225),
                  Decay = Color3.fromRGB(92, 100, 115), Glare = 0.1, Haze = 1.8 },
        exposure = 0,
    },
    moody = {
        bloom = { Intensity = 0.7, Size = 36, Threshold = 1.4 },
        color = { Brightness = -0.06, Contrast = 0.28, Saturation = -0.25, TintColor = Color3.fromRGB(200, 215, 255) },
        dof   = { FarIntensity = 0.2, FocusDistance = 50, InFocusRadius = 40, NearIntensity = 0 },
        atm   = { Density = 0.4, Offset = 0, Color = Color3.fromRGB(120, 130, 155),
                  Decay = Color3.fromRGB(60, 65, 85), Glare = 0, Haze = 2.2 },
        exposure = -0.25,
    },
    warm = {
        bloom = { Intensity = 0.55, Size = 32, Threshold = 1.6 },
        rays  = { Intensity = 0.25, Spread = 1 },
        color = { Brightness = 0.03, Contrast = 0.1, Saturation = 0.2, TintColor = Color3.fromRGB(255, 224, 190) },
        atm   = { Density = 0.3, Offset = 0.2, Color = Color3.fromRGB(255, 214, 170),
                  Decay = Color3.fromRGB(150, 95, 60), Glare = 0.4, Haze = 1.6 },
        exposure = 0.1,
    },
}
local SHADER_CLASS = { bloom = "BloomEffect", rays = "SunRaysEffect", color = "ColorCorrectionEffect", dof = "DepthOfFieldEffect" }
local SHADER_NAME  = { bloom = "FlowerialBloom", rays = "FlowerialSunRays", color = "FlowerialColor", dof = "FlowerialDoF" }

local skyObj, skyOwned, skyOrigStars
do
    skyObj = Lighting:FindFirstChildOfClass("Sky")
    if skyObj then skyOrigStars = skyObj.StarCount end
end

function Env.applyStars()
    if Env.stars == nil then
        if skyOwned then
            safeDestroy(skyOwned)
            skyOwned = nil
            skyObj = nil
        elseif skyObj and skyOrigStars then
            pcall(function() skyObj.StarCount = skyOrigStars end)
        end
        return
    end
    if not (skyObj and skyObj.Parent) then
        skyObj = Lighting:FindFirstChildOfClass("Sky")
        if not skyObj then
            skyObj = new("Sky", { Name = "FlowerialSky" }, Lighting)
            skyOwned = skyObj
        elseif not skyOrigStars then
            skyOrigStars = skyObj.StarCount
        end
    end
    pcall(function() skyObj.StarCount = Env.stars end)
end

local atmOwned, atmSnap
function Env.setAtmosphere(props)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atm then
        atm = new("Atmosphere", { Name = "FlowerialAtmosphere" }, Lighting)
        atmOwned = atm
    elseif atm ~= atmOwned and not atmSnap then
        atmSnap = { inst = atm, props = {} }
        for _, p in ipairs({ "Density", "Offset", "Color", "Decay", "Glare", "Haze" }) do
            atmSnap.props[p] = atm[p]
        end
    end
    for k, v in pairs(props) do
        pcall(function() atm[k] = v end)
    end
end
function Env.restoreAtmosphere()
    if atmOwned then
        safeDestroy(atmOwned)
        atmOwned = nil
    end
    if atmSnap then
        for k, v in pairs(atmSnap.props) do
            pcall(function() atmSnap.inst[k] = v end)
        end
        atmSnap = nil
    end
end
function Env.refreshAtmosphere()
    local p = Env.skyAtm or Env.shaderAtm
    if p then Env.setAtmosphere(p) else Env.restoreAtmosphere() end
end

function Env.refresh()
    local sky = Env.skyPreset and SKIES[Env.skyPreset] or nil
    local precip = Wx.rain or Wx.snow
    local mul = (precip and 0.75 or 1) * ((sky and sky.bright) or 1)
    local fp = FOGS[Env.fogIdx]
    pcall(function()
        Lighting.Brightness = ORIG.Brightness * mul
        Lighting.Ambient = (sky and sky.ambient) or ORIG.Ambient
        Lighting.OutdoorAmbient = (sky and sky.outdoor) or ORIG.OutdoorAmbient
        Lighting.ColorShift_Top = (sky and sky.top) or ORIG.ColorShift_Top
        Lighting.ColorShift_Bottom = (sky and sky.bottom) or ORIG.ColorShift_Bottom
        if fp then
            Lighting.FogColor = fp.color
            Lighting.FogStart = 0
            Lighting.FogEnd = Env.fogDist
        elseif precip then
            Lighting.FogColor = Color3.fromRGB(120, 130, 145)
            Lighting.FogStart = ORIG.FogStart
            Lighting.FogEnd = math.min(ORIG.FogEnd, 1200)
        else
            Lighting.FogColor = ORIG.FogColor
            Lighting.FogStart = ORIG.FogStart
            Lighting.FogEnd = ORIG.FogEnd
        end
    end)
end

function Env.selectSky(i)
    if i <= 1 then
        Env.skyPreset = nil
        Env.stars = nil
        Env.skyAtm = nil
        if C.stars then C.stars.Set(0, true) end
        if Tm.skyOwnsTime then
            Tm.skyOwnsTime = false
            Tm.lock = false
            Tm.value = ORIG.ClockTime
            if C.time then C.time.Set(ORIG.ClockTime, true) end
            if C.lock then C.lock.Set(false, true) end
            Lighting.ClockTime = ORIG.ClockTime
        end
    else
        local name = SKY_ORDER[i - 1]
        local p = SKIES[name]
        Env.skyPreset = name
        Env.stars = p.stars
        Env.skyAtm = p.atm
        if C.stars then C.stars.Set(p.stars or 0, true) end
        if p.time and C.time and C.lock and not Tm.cycle and (Tm.skyOwnsTime or not Tm.lock) then
            C.time.Set(p.time, true)
            Tm.value = p.time
            Tm.skyOwnsTime = true
            C.lock.Set(true)
        end
    end
    Env.applyStars()
    Env.refreshAtmosphere()
    Env.refresh()
end

function Env.clearShader()
    for _, n in pairs(SHADER_NAME) do
        local e = Lighting:FindFirstChild(n)
        if e then e:Destroy() end
    end
    Env.shaderAtm = nil
    pcall(function() Lighting.ExposureCompensation = ORIG.ExposureCompensation end)
end

function Env.applyShader(name)
    Env.clearShader()
    local p = name and SHADERS[name]
    if p then
        for k, class in pairs(SHADER_CLASS) do
            if p[k] then
                local e = new(class, { Name = SHADER_NAME[k] })
                for prop, v in pairs(p[k]) do
                    pcall(function() e[prop] = v end)
                end
                e.Parent = Lighting
            end
        end
        Env.shaderAtm = p.atm
        if p.exposure then
            pcall(function() Lighting.ExposureCompensation = p.exposure end)
        end
    end
    Env.refreshAtmosphere()
end

function Env.restoreAll()
    Env.clearShader()
    Env.skyPreset, Env.stars, Env.skyAtm, Env.fogIdx = nil, nil, nil, 1
    Env.applyStars()
    Env.refreshAtmosphere()
    for k, v in pairs(ORIG) do
        pcall(function() Lighting[k] = v end)
    end
end

local WEATHER_BASE = { rain = 700, snow = 300, leaves = 22, dust = 32 }
local wPart, dPart, wEm = nil, nil, {}

local function weatherParent()
    return Workspace.CurrentCamera or Workspace
end

local function ensureWeather()
    if wPart and wPart.Parent then return end
    wEm = {}
    wPart = new("Part", {
        Name = "FlowerialWeather", Anchored = true, CanCollide = false, CanQuery = false,
        CanTouch = false, CastShadow = false, Transparency = 1, Size = Vector3.new(90, 1, 90),
    })
    wEm.rain = new("ParticleEmitter", {
        Texture = TEX.Rain,
        Color = ColorSequence.new(Color3.fromRGB(190, 215, 255)),
        Transparency = NumberSequence.new({ NSK(0, 0.35), NSK(1, 0.6) }),
        Size = NumberSequence.new(0.25),
        Lifetime = NumberRange.new(0.9, 1.1),
        Speed = NumberRange.new(70, 90),
        EmissionDirection = Enum.NormalId.Bottom,
        SpreadAngle = Vector2.new(2, 2),
        Orientation = Enum.ParticleOrientation.VelocityParallel,
        LightEmission = 0.35, LightInfluence = 0, LockedToPart = false,
        Rate = WEATHER_BASE.rain, Enabled = false,
    }, wPart)
    wEm.snow = new("ParticleEmitter", {
        Texture = TEX.Snow,
        Color = ColorSequence.new(WHITE),
        Transparency = NumberSequence.new({ NSK(0, 0.15), NSK(0.9, 0.25), NSK(1, 1) }),
        Size = NumberSequence.new(0.35),
        Lifetime = NumberRange.new(8, 10),
        Speed = NumberRange.new(5, 8),
        EmissionDirection = Enum.NormalId.Bottom,
        SpreadAngle = Vector2.new(25, 25),
        Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-60, 60),
        Acceleration = Vector3.new(2, 0, 0),
        LightEmission = 0.4, LightInfluence = 0.2, LockedToPart = false,
        Rate = WEATHER_BASE.snow, Enabled = false,
    }, wPart)
    wEm.leaves = new("ParticleEmitter", {
        Texture = TEX.Leaf,
        Color = ColorSequence.new({
            CSK(0, Color3.fromRGB(230, 120, 40)),
            CSK(0.5, Color3.fromRGB(200, 60, 30)),
            CSK(1, Color3.fromRGB(130, 160, 50)),
        }),
        Transparency = NumberSequence.new({ NSK(0, 0), NSK(0.85, 0.1), NSK(1, 1) }),
        Size = NumberSequence.new(0.7),
        Lifetime = NumberRange.new(9, 12),
        Speed = NumberRange.new(3, 5),
        EmissionDirection = Enum.NormalId.Bottom,
        SpreadAngle = Vector2.new(40, 40),
        Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-120, 120),
        Acceleration = Vector3.new(3, 0, 1),
        LightEmission = 0, LightInfluence = 1, LockedToPart = false,
        Rate = WEATHER_BASE.leaves, Enabled = false,
    }, wPart)
    wPart.Parent = weatherParent()

    dPart = new("Part", {
        Name = "FlowerialDust", Anchored = true, CanCollide = false, CanQuery = false,
        CanTouch = false, CastShadow = false, Transparency = 1, Size = Vector3.new(70, 18, 70),
    })
    wEm.dust = new("ParticleEmitter", {
        Texture = TEX.Dust,
        Color = ColorSequence.new(Color3.fromRGB(230, 255, 140)),
        Transparency = NumberSequence.new({ NSK(0, 1), NSK(0.2, 0.3), NSK(0.8, 0.3), NSK(1, 1) }),
        Size = NumberSequence.new(0.18),
        Lifetime = NumberRange.new(5, 9),
        Speed = NumberRange.new(0.3, 1.2),
        EmissionDirection = Enum.NormalId.Top,
        SpreadAngle = Vector2.new(180, 180),
        LightEmission = 1, LightInfluence = 0, LockedToPart = false,
        Rate = WEATHER_BASE.dust, Enabled = false,
    }, dPart)
    dPart.Parent = weatherParent()
end

function Wx.update()
    if Wx.rain or Wx.snow or Wx.leaves or Wx.dust then ensureWeather() end
    for k, base in pairs(WEATHER_BASE) do
        local e = wEm[k]
        if e then
            e.Enabled = Wx[k] and true or false
            e.Rate = base * Wx.mult
        end
    end
    Env.refresh()
end

local flashCC
function Wx.flash()
    if not (flashCC and flashCC.Parent) then
        flashCC = new("ColorCorrectionEffect", { Name = "FlowerialFlash", Brightness = 0 }, Lighting)
    end
    flashCC.Brightness = 0.55
    TweenService:Create(flashCC, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
    task.delay(0.16, function()
        if flashCC and flashCC.Parent then
            flashCC.Brightness = 0.4
            TweenService:Create(flashCC, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
        end
    end)
    task.delay(0.3 + math.random() * 1.4, function()
        local s = new("Sound", {
            Name = "FlowerialThunder", SoundId = THUNDER_SOUND,
            Volume = 0.9, PlaybackSpeed = 0.5 + math.random() * 0.15,
        }, SoundService)
        s:Play()
        task.delay(6, function() safeDestroy(s) end)
    end)
end
function Wx.clearFlash()
    safeDestroy(flashCC)
    flashCC = nil
end

local AURORA_COLORS = {
    { Color3.fromRGB(120, 90, 255), Color3.fromRGB(60, 255, 160) },
    { Color3.fromRGB(200, 90, 255), Color3.fromRGB(80, 255, 220) },
    { Color3.fromRGB(90, 140, 255), Color3.fromRGB(110, 255, 140) },
}
function Wx.setAurora(on)
    if not on then
        if Wx.aurora then safeDestroy(Wx.aurora.folder) end
        Wx.aurora = nil
        return
    end
    if Wx.aurora then return end
    local folder = new("Folder", { Name = "FlowerialAurora" }, weatherParent())
    local list = {}
    local N = 24
    for i = 1, 3 do
        local part = new("Part", {
            Name = "Ribbon" .. i, Anchored = true, CanCollide = false, CanQuery = false,
            CanTouch = false, CastShadow = false, Transparency = 1, Size = Vector3.new(720, 160, 1),
        }, folder)
        local sg = new("SurfaceGui", {
            Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.FixedSize,
            CanvasSize = Vector2.new(1440, 320), LightInfluence = 0, AlwaysOnTop = false,
        }, part)
        local strips = {}
        for s = 1, N do
            local strip = new("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new((s - 1) / N, 0, 1, 0),
                Size = UDim2.new(1 / N + 0.002, 0, 0.7, 0),
                BackgroundColor3 = WHITE, BorderSizePixel = 0,
            }, sg)
            new("UIGradient", {
                Rotation = 90,
                Color = ColorSequence.new(AURORA_COLORS[i][1], AURORA_COLORS[i][2]),
                Transparency = NumberSequence.new({ NSK(0, 1), NSK(0.45, 0.55), NSK(1, 0.15) }),
            }, strip)
            strips[s] = strip
        end
        list[i] = { part = part, strips = strips, w = 1 / N + 0.002 }
    end
    Wx.aurora = { folder = folder, ribbons = list }
end

local RAINBOW_COLORS = {
    Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 150, 40), Color3.fromRGB(255, 230, 60),
    Color3.fromRGB(80, 220, 90), Color3.fromRGB(70, 150, 255), Color3.fromRGB(90, 80, 220),
    Color3.fromRGB(170, 80, 220),
}
function Wx.setRainbow(on)
    if not on then
        if Wx.rainbow then safeDestroy(Wx.rainbow.part) end
        Wx.rainbow = nil
        return
    end
    if Wx.rainbow then return end
    local part = new("Part", {
        Name = "FlowerialRainbow", Anchored = true, CanCollide = false, CanQuery = false,
        CanTouch = false, CastShadow = false, Transparency = 1, Size = Vector3.new(1300, 650, 1),
    })
    local sg = new("SurfaceGui", {
        Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.FixedSize,
        CanvasSize = Vector2.new(2000, 1000), LightInfluence = 0, AlwaysOnTop = false,
    }, part)
    local root = new("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true,
    }, sg)
    for i, col in ipairs(RAINBOW_COLORS) do
        local D = 1900 - (i - 1) * 70
        local ring = new("Frame", {
            Size = UDim2.fromOffset(D, D),
            Position = UDim2.new(0.5, -D / 2, 1, -D / 2),
            BackgroundTransparency = 1, BorderSizePixel = 0,
        }, root)
        corner(ring, D / 2)
        stroke(ring, col, 60, 0.35)
    end
    part.Parent = weatherParent()
    Wx.rainbow = { part = part }
end

function Wx.step(dt, cam)
    local cp = cam.CFrame.Position
    if wPart and wPart.Parent then
        wPart.CFrame = CFrame.new(cp + Vector3.new(0, 50, 0))
    end
    if dPart and dPart.Parent then
        dPart.CFrame = CFrame.new(cp + Vector3.new(0, 6, 0))
    end
    local t = os.clock()
    if Wx.storm and t >= Wx.nextStrike then
        Wx.nextStrike = t + 4 + math.random() * 8
        Wx.flash()
    end
    if Wx.aurora then
        for i, r in ipairs(Wx.aurora.ribbons) do
            local ang = (i - 1) * (math.pi * 2 / 3) + t * 0.015
            local pos = cp + Vector3.new(math.cos(ang) * 380, 170 + math.sin(t * 0.3 + i) * 10, math.sin(ang) * 380)
            r.part.CFrame = CFrame.lookAt(pos, Vector3.new(cp.X, pos.Y, cp.Z))
            for s, strip in ipairs(r.strips) do
                local h = 0.55 + 0.4 * math.sin(t * 0.8 + s * 0.55 + i * 1.7)
                strip.Size = UDim2.new(r.w, 0, h, 0)
            end
        end
    end
    if Wx.rainbow then
        local sd = Lighting:GetSunDirection()
        local h = Vector3.new(-sd.X, 0, -sd.Z)
        if h.Magnitude < 0.05 then h = Vector3.new(0, 0, -1) end
        local pos = cp + h.Unit * 650 + Vector3.new(0, 180, 0)
        Wx.rainbow.part.CFrame = CFrame.lookAt(pos, Vector3.new(cp.X, pos.Y, cp.Z))
    end
end

function Wx.destroyAll()
    Wx.rain, Wx.snow, Wx.leaves, Wx.dust, Wx.storm = false, false, false, false, false
    safeDestroy(wPart); safeDestroy(dPart)
    wPart, dPart, wEm = nil, nil, {}
    Wx.setAurora(false)
    Wx.setRainbow(false)
    Wx.clearFlash()
end

local function drawIcon(parent, kind)
    local root = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1 }, parent)
    local shapes = {}
    local function shape(x, y, w, h, radius, rotation)
        local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), Rotation = rotation or 0, BackgroundColor3 = accent.Value, BorderSizePixel = 0 }, root)
        if radius then corner(f, radius) end
        shapes[#shapes + 1] = f
        return f
    end
    local function rays(n, cx, cy, radius, w, h)
        for i = 0, n - 1 do
            local angle = i * math.pi * 2 / n
            shape(cx + math.sin(angle) * radius, cy - math.cos(angle) * radius, w, h, w / 2, math.deg(angle))
        end
    end
    if kind == "flower" or kind == "themes" then
        rays(5, 15, 15, 7.8, 7, 11)
        shape(15, 15, 6, 6, 6)
    elseif kind == "world" then
        rays(8, 15, 15, 11, 1.5, 4)
        shape(15, 15, 10, 10, 10)
    elseif kind == "sky" then
        shape(12, 13, 15, 15, 15)
        shape(20, 10, 12, 14, 12).BackgroundColor3 = Color3.fromRGB(20, 20, 23)
        shape(24, 23, 2, 2, 2)
    elseif kind == "shaders" then
        shape(15, 15, 2, 20, 2)
        shape(15, 15, 20, 2, 2)
        shape(15, 15, 2, 12, 2, 45)
        shape(15, 15, 2, 12, 2, -45)
    elseif kind == "camera" then
        shape(15, 8, 19, 1.5, 1)
        shape(15, 22, 19, 1.5, 1)
        shape(6, 15, 1.5, 14, 1)
        shape(24, 15, 1.5, 14, 1)
        shape(15, 15, 8, 8, 8)
    elseif kind == "character" then
        shape(15, 9, 9, 9, 9)
        shape(15, 21, 18, 9, 5)
    elseif kind == "music" then
        shape(11, 23, 7, 4, 4, -20)
        shape(22, 19, 7, 4, 4, -20)
        shape(14, 13, 1.5, 18, 1)
        shape(25, 10, 1.5, 17, 1)
        shape(20, 4, 12, 2, 1, -10)
    elseif kind == "settings" then
        rays(8, 15, 15, 10, 3, 6)
        shape(15, 15, 12, 12, 12)
        shape(15, 15, 5, 5, 5).BackgroundColor3 = Color3.fromRGB(20, 20, 23)
    elseif kind == "close" then
        shape(15, 15, 17, 2, 1, 45)
        shape(15, 15, 17, 2, 1, -45)
    elseif kind == "minus" then
        shape(15, 15, 17, 2, 1)
    end
    local cutouts = { sky = { 2 }, settings = { 10 } }
    return function(color, alpha)
        for i, f in ipairs(shapes) do
            if kind == "flower" or kind == "themes" then
                f.BackgroundColor3 = (i == 6) and color:Lerp(WHITE, 0.72) or color
            elseif not (cutouts[kind] and table.find(cutouts[kind], i)) then
                f.BackgroundColor3 = color
            end
            f.BackgroundTransparency = alpha or 0
        end
    end
end

local main = new("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(DESIGN_W, DESIGN_H),
    BackgroundColor3 = WHITE,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)
corner(main, 14)
stroke(main, Color3.fromRGB(70, 70, 78), 1, 0.3)
local uiScale = new("UIScale", { Scale = 1 }, main)
local grad = new("UIGradient", { Rotation = 35 }, main)

onAccent(function(c)
    local base = Color3.fromRGB(26, 26, 30)
    grad.Color = ColorSequence.new({
        CSK(0,    base),
        CSK(0.36, base),
        CSK(0.50, base:Lerp(c, 0.30)),
        CSK(0.64, base),
        CSK(1,    base:Lerp(c, 0.08)),
    })
end)

local baseScale = 1
local function fit()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    baseScale = math.clamp(math.min(vp.X * 0.9 / DESIGN_W, vp.Y * 0.9 / DESIGN_H), 0.4, 1.2)
    uiScale.Scale = baseScale
end
fit()
if Workspace.CurrentCamera then
    connect(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), fit)
end

local header = new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1 }, main)

local logo = new("Frame", { Position = UDim2.fromOffset(12, 11), Size = UDim2.fromOffset(38, 38), BackgroundTransparency = 1 }, header)
onAccent(drawIcon(logo, "flower"))

local titleLbl = new("TextLabel", {
    Position = UDim2.fromOffset(60, 18), Size = UDim2.fromOffset(150, 24),
    BackgroundTransparency = 1, Text = HUB_NAME, Font = Enum.Font.GothamMedium,
    TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = accent.Value,
}, header)
onAccent(function(c) titleLbl.TextColor3 = c end)

local function headerBtn(kind, offsetX, cb)
    local b = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, offsetX, 0, 14), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, header)
    onAccent(drawIcon(b, kind))
    connect(b.MouseButton1Click, cb)
    return b
end

local langPill = new("Frame", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -90, 0, 17),
    Size = UDim2.fromOffset(78, 26), BackgroundColor3 = Color3.fromRGB(30, 30, 34),
    BorderSizePixel = 0,
}, header)
corner(langPill, 8)
stroke(langPill, Color3.fromRGB(70, 70, 78), 1, 0.4)
local function pillBtn(text, x)
    local b = new("TextButton", {
        Position = UDim2.new(0, x, 0, 2), Size = UDim2.new(0.5, -3, 1, -4),
        BackgroundColor3 = accent.Value, BackgroundTransparency = 1, Text = text,
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = GRAY,
        AutoButtonColor = false, BorderSizePixel = 0,
    }, langPill)
    corner(b, 6)
    return b
end
local enBtn = pillBtn("EN", 2)
local ruBtn = pillBtn("RU", 37)
local function paintLang()
    local en = (lang == "EN")
    enBtn.BackgroundTransparency = en and 0 or 1
    enBtn.BackgroundColor3 = accent.Value
    enBtn.TextColor3 = en and WHITE or GRAY
    ruBtn.BackgroundTransparency = en and 1 or 0
    ruBtn.BackgroundColor3 = accent.Value
    ruBtn.TextColor3 = en and GRAY or WHITE
end
onAccent(paintLang)

new("Frame", {
    Position = UDim2.new(0, 0, 0, 60), Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = Color3.fromRGB(80, 80, 88), BackgroundTransparency = 0.5, BorderSizePixel = 0,
}, main)

local TAB_STEP, TAB_H = 40, 38
local sidebar = new("Frame", {
    Name = "Sidebar", Position = UDim2.fromOffset(0, 61), Size = UDim2.new(0, 68, 1, -61),
    BackgroundColor3 = Color3.fromRGB(20, 20, 23), BackgroundTransparency = 0.1, BorderSizePixel = 0,
}, main)
local indicator = new("Frame", {
    Position = UDim2.fromOffset(0, 14), Size = UDim2.fromOffset(3, 26),
    BackgroundColor3 = accent.Value, BorderSizePixel = 0,
}, sidebar)
corner(indicator, 2)
onAccent(function(c) indicator.BackgroundColor3 = c end)

local footer = new("Frame", {
    Name = "Footer", Position = UDim2.new(0, 0, 1, -26), Size = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = Color3.fromRGB(18, 18, 20), BackgroundTransparency = 0.05,
    BorderSizePixel = 0, ZIndex = 3,
}, main)
local statusLbl = new("TextLabel", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0), Size = UDim2.fromOffset(260, 26),
    BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamMedium, TextSize = 12,
    TextColor3 = accent.Value, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4,
}, footer)
onAccent(function(c) statusLbl.TextColor3 = c end)

local toastToken = 0
local function toast(key)
    toastToken = toastToken + 1
    local my = toastToken
    statusLbl.Text = tr(key)
    task.delay(2.4, function()
        if toastToken == my and statusLbl.Parent then statusLbl.Text = "" end
    end)
end

local function saveConfig(silent)
    cfg.state = snapshotState()
    local ok = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(cfg))
    end)
    if not silent then toast(ok and "saved" or "nosave") end
    return ok
end

local content = new("Frame", {
    Name = "Content", Position = UDim2.fromOffset(68, 61), Size = UDim2.new(1, -68, 1, -87),
    BackgroundTransparency = 1,
}, main)
local sectionTitle = new("TextLabel", {
    Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -30, 0, 20), BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = GRAY,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "",
}, content)

local function newPage()
    local sf = new("ScrollingFrame", {
        Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 1, -32),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = Color3.fromRGB(120, 120, 128),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
    }, content)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 16),
        PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 10),
    }, sf)
    return sf
end

local function rowBase(page, h, class, extra)
    local props = {
        Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = ROW_BG,
        BackgroundTransparency = 0.35, BorderSizePixel = 0,
    }
    if extra then
        for k, v in pairs(extra) do props[k] = v end
    end
    local f = new(class or "Frame", props, page)
    corner(f, 9)
    return f
end

local function rowLabel(parent, key, x)
    x = x or 14
    return bind(new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(x, 0),
        Size = UDim2.new(1, -x - 70, 1, 0), Font = Enum.Font.GothamMedium, TextSize = 15,
        TextColor3 = Color3.fromRGB(235, 235, 240), TextXAlignment = Enum.TextXAlignment.Left, Text = "",
    }, parent), key)
end

local function addHeader(page, key)
    return bind(new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
        TextSize = 12, TextColor3 = GRAY, TextXAlignment = Enum.TextXAlignment.Left,
    }, page), key)
end

local function flash(b)
    b.BackgroundTransparency = 0.05
    TweenService:Create(b, TweenInfo.new(0.25), { BackgroundTransparency = 0.35 }):Play()
end

local function drawAccessoryIcon(row, kind)
    local root = new("Frame", {
        Position = UDim2.new(0, 9, 0.5, -17), Size = UDim2.fromOffset(34, 34),
        BackgroundColor3 = Color3.fromRGB(25, 25, 31), BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
    }, row)
    corner(root, 9)
    local border = stroke(root, accent.Value, 1, 0.67)
    local parts = {}
    local function piece(x, y, w, h, rotation, round)
        local p = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(w, h), Rotation = rotation or 0,
            BackgroundColor3 = accent.Value, BorderSizePixel = 0,
        }, root)
        if round then corner(p, round) end
        parts[#parts + 1] = p
        return p
    end
    local outline
    if kind == "acc_wings" then
        for _, side in ipairs({ -1, 1 }) do
            for i = 1, 3 do piece(17 + side * (5 + i * 2.4), 15 + i * 1.3, 4, 13 - i * 2, -side * (20 + i * 9), 3) end
        end
        piece(17, 14, 4, 4, 0, 4)
    elseif kind == "acc_horns" then
        piece(17, 23, 13, 5, 0, 4)
        piece(11, 13, 5, 17, -20, 3)
        piece(23, 13, 5, 17, 20, 3)
        piece(17, 17, 3, 3, 0, 3)
    elseif kind == "acc_halo" then
        local ring = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(17, 14),
            Size = UDim2.fromOffset(23, 9), BackgroundTransparency = 1,
        }, root)
        corner(ring, 9)
        outline = stroke(ring, accent.Value, 2, 0)
        piece(17, 24, 4, 4, 0, 4)
    elseif kind == "acc_tail" then
        for i = 1, 5 do piece(8 + i * 4, 8 + i * 3 - (i == 5 and 4 or 0), 5 - i * 0.35, 5 - i * 0.35, 0, 4) end
        piece(28, 20, 5, 5, 0, 4)
    elseif kind == "acc_cape" then
        piece(17, 8, 19, 4, 0, 3)
        for i = -1, 1 do piece(17 + i * 6, 19, 6, 17, i * 7, 3) end
        piece(17, 9, 4, 4, 0, 4)
    elseif kind == "acc_crown" then
        piece(17, 24, 22, 5, 0, 2)
        for i = -1, 1 do piece(17 + i * 8, 16 - (i == 0 and 3 or 0), 5, 12, i * 9, 2) end
        piece(17, 21, 3, 3, 0, 3)
    end
    onAccent(function(c)
        border.Color = c
        for i, p in ipairs(parts) do p.BackgroundColor3 = (i == #parts) and c:Lerp(WHITE, 0.65) or c end
        if outline then outline.Color = c end
    end)
end

local function addToggle(page, key, default, cb, iconKind)
    local row = rowBase(page, 42)
    rowLabel(row, key, iconKind and 55 or nil)
    if iconKind then drawAccessoryIcon(row, iconKind) end
    local sw = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(42, 22), BackgroundColor3 = OFF_COL, BorderSizePixel = 0,
    }, row)
    corner(sw, 11)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = WHITE, BorderSizePixel = 0,
    }, sw)
    corner(knob, 8)
    local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5 }, row)

    local state = default and true or false
    local obj = {}
    local function paint(animate)
        local pos = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        local col = state and accent.Value or OFF_COL
        if animate then
            TweenService:Create(knob, TweenInfo.new(0.15), { Position = pos }):Play()
            TweenService:Create(sw, TweenInfo.new(0.15), { BackgroundColor3 = col }):Play()
        else
            knob.Position = pos
            sw.BackgroundColor3 = col
        end
    end
    function obj.Set(v, silent)
        state = v and true or false
        paint(true)
        if not silent then
            markDirty()
            if cb then cb(state) end
        end
    end
    function obj.Get() return state end
    connect(hit.MouseButton1Click, function() obj.Set(not state) end)
    onAccent(function(c) if state then sw.BackgroundColor3 = c end end)
    paint(false)
    return obj
end

local function addButtons(page, entries)
    local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 }, page)
    local n = #entries
    for i, e in ipairs(entries) do
        local b = new("TextButton", {
            Position = UDim2.new((i - 1) / n, (i == 1) and 0 or 3, 0, 0),
            Size = UDim2.new(1 / n, (i == 1 or i == n) and -3 or -6, 1, 0),
            BackgroundColor3 = ROW_BG, BackgroundTransparency = 0.35, BorderSizePixel = 0,
            Text = "", AutoButtonColor = false,
        }, holder)
        corner(b, 9)
        local lbl = new("TextLabel", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
            TextSize = 14, TextColor3 = WHITE, Text = e.text or "", TextWrapped = true,
        }, b)
        if e.key then bind(lbl, e.key) end
        onAccent(function(c) lbl.TextColor3 = c end)
        connect(b.MouseButton1Click, function() flash(b); e.cb() end)
    end
end

local function addButton(page, key, cb)
    addButtons(page, { { key = key, cb = cb } })
end

local function addOption(page, key, swatch, cb)
    local row = rowBase(page, 42, "TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 0.43 })
    local st = stroke(row, accent.Value, 1, 1)
    local x = 14
    if swatch then
        local sq = new("Frame", {
            Position = UDim2.new(0, 12, 0.5, -11), Size = UDim2.fromOffset(22, 22),
            BackgroundColor3 = swatch, BorderSizePixel = 0,
        }, row)
        corner(sq, 6)
        x = 48
    end
    bind(new("TextLabel", {
        Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x - 10, 1, 0), BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 16, TextColor3 = WHITE,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "",
    }, row), key)
    local obj = {}
    function obj.Select(v)
        TweenService:Create(row, TweenInfo.new(0.15), { BackgroundTransparency = v and 0.19 or 0.43 }):Play()
        st.Transparency = v and 0.2 or 1
    end
    onAccent(function(c) st.Color = c end)
    connect(row.MouseButton1Click, cb)
    return obj
end

local function optionGroup(page, items, onPick)
    local group = { opts = {}, sel = 1 }
    function group.Select(i, silent)
        i = math.clamp(math.floor(tonumber(i) or 1), 1, #items)
        group.sel = i
        for j, o in ipairs(group.opts) do o.Select(j == i) end
        if not silent then
            markDirty()
            onPick(i)
        end
    end
    group.Set = group.Select
    function group.Get() return group.sel end
    for i, it in ipairs(items) do
        group.opts[i] = addOption(page, it.key, it.swatch, function() group.Select(i) end)
    end
    group.Select(1, true)
    return group
end

local function addSlider(page, key, minV, maxV, default, fmt, cb)
    local row = rowBase(page, 56)
    bind(new("TextLabel", {
        Position = UDim2.fromOffset(14, 4), Size = UDim2.new(1, -100, 0, 24), BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 15, TextColor3 = Color3.fromRGB(235, 235, 240),
        TextXAlignment = Enum.TextXAlignment.Left, Text = "",
    }, row), key)
    local val = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 4), Size = UDim2.fromOffset(80, 24),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = GRAY,
        TextXAlignment = Enum.TextXAlignment.Right, Text = "",
    }, row)
    local track = new("Frame", {
        Position = UDim2.new(0, 14, 0, 38), Size = UDim2.new(1, -28, 0, 6),
        BackgroundColor3 = OFF_COL, BorderSizePixel = 0,
    }, row)
    corner(track, 3)
    local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = accent.Value, BorderSizePixel = 0 }, track)
    corner(fill, 3)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = WHITE, BorderSizePixel = 0,
    }, track)
    corner(knob, 8)
    local hit = new("TextButton", {
        Position = UDim2.new(0, 6, 0, 26), Size = UDim2.new(1, -12, 0, 28),
        BackgroundTransparency = 1, Text = "", ZIndex = 5,
    }, row)

    local value = default
    local obj = {}
    local function render()
        local a = (value - minV) / (maxV - minV)
        fill.Size = UDim2.fromScale(a, 1)
        knob.Position = UDim2.fromScale(a, 0.5)
        val.Text = fmt(value)
    end
    local function setFromX(x)
        local w = track.AbsoluteSize.X
        if w <= 0 then return end
        local a = math.clamp((x - track.AbsolutePosition.X) / w, 0, 1)
        value = minV + (maxV - minV) * a
        render()
        markDirty()
        if cb then cb(value) end
    end
    function obj.Set(v, silent)
        value = math.clamp(tonumber(v) or minV, minV, maxV)
        render()
        if not silent then
            markDirty()
            if cb then cb(value) end
        end
    end
    function obj.Get() return value end

    local dragging = false
    connect(hit.InputBegan, function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging = true
            page.ScrollingEnabled = false
            setFromX(input.Position.X)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        local t = input.UserInputType
        if dragging and (t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        local t = input.UserInputType
        if dragging and (t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch) then
            dragging = false
            page.ScrollingEnabled = true
        end
    end)
    onAccent(function(c) fill.BackgroundColor3 = c end)
    render()
    return obj
end

local function addInfo(page, key, value)
    local row = rowBase(page, 40)
    rowLabel(row, key)
    local v = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(60, 24),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Right, Text = value or "-", TextColor3 = accent.Value,
    }, row)
    onAccent(function(c) v.TextColor3 = c end)
    return { Set = function(t) v.Text = t end }
end

local function addInput(page, placeholderKey, initial, onSubmit)
    local row = rowBase(page, 42)
    local box = new("TextBox", {
        Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 1, -12),
        BackgroundColor3 = Color3.fromRGB(28, 28, 32), BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = WHITE,
        PlaceholderColor3 = GRAY, Text = initial or "", PlaceholderText = "",
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    corner(box, 7)
    new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)
    bind(box, placeholderKey, "PlaceholderText")
    if onSubmit then
        connect(box.FocusLost, function(enter) onSubmit(box.Text, enter) end)
    end
    return box
end

local Char = {
    headless = false, korblox = false, hideAcc = false,
    tint = false, r = 255, g = 60, b = 60, mat = 1, ghost = 0,
    aura = false, trail = false,
}
local MATERIALS = { [2] = Enum.Material.Neon, [3] = Enum.Material.Glass, [4] = Enum.Material.ForceField,
                    [5] = Enum.Material.Metal, [6] = Enum.Material.Ice }
local snap = setmetatable({}, { __mode = "k" })
local createdMeshes = setmetatable({}, { __mode = "k" })
local auraObjs = setmetatable({}, { __mode = "k" })
local trailObjs = setmetatable({}, { __mode = "k" })
local ours = setmetatable({}, { __mode = "k" }) -- наши аксессуары (их не скрываем)

local function setProp(inst, prop, value)
    if not inst then return end
    local s = snap[inst]
    if not s then s = {}; snap[inst] = s end
    if s[prop] == nil then
        local ok, v = pcall(function() return inst[prop] end)
        if ok then s[prop] = v end
    end
    pcall(function() inst[prop] = value end)
end

local function restoreProp(inst, prop)
    local s = snap[inst]
    if s and s[prop] ~= nil then
        local v = s[prop]
        pcall(function() inst[prop] = v end)
        s[prop] = nil
    end
end

local function origTransparency(p)
    local s = snap[p]
    if s and s.Transparency ~= nil then return s.Transparency end
    return p.Transparency
end

function Char.applyLook(char)
    local tintColor = Color3.fromRGB(math.floor(Char.r), math.floor(Char.g), math.floor(Char.b))
    local mat = MATERIALS[Char.mat]
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            if Char.tint then setProp(p, "Color", tintColor) else restoreProp(p, "Color") end
            if mat then setProp(p, "Material", mat) else restoreProp(p, "Material") end
            local want = nil
            if Char.headless and p.Name == "Head" then
                want = 1
            elseif Char.ghost > 0 then
                want = math.max(origTransparency(p), Char.ghost)
            end
            if want then setProp(p, "Transparency", want) else restoreProp(p, "Transparency") end
            if p.Name == "Head" then
                for _, d in ipairs(p:GetChildren()) do
                    if d:IsA("Decal") then
                        if Char.headless then setProp(d, "Transparency", 1) else restoreProp(d, "Transparency") end
                    end
                end
            end
        elseif p:IsA("Accessory") and not ours[p] then
            local h = p:FindFirstChild("Handle")
            if h then
                if Char.hideAcc then setProp(h, "Transparency", 1) else restoreProp(h, "Transparency") end
            end
        end
    end
end

function Char.applyKorblox(char, on)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local r6 = hum and hum.RigType == Enum.HumanoidRigType.R6
    if r6 then
        local leg = char:FindFirstChild("Right Leg")
        if not leg then return end
        local mesh = leg:FindFirstChildOfClass("SpecialMesh")
        if on then
            if not mesh then
                mesh = new("SpecialMesh", nil, leg)
                createdMeshes[char] = mesh
            end
            setProp(mesh, "MeshType", Enum.MeshType.FileMesh)
            setProp(mesh, "MeshId", KORBLOX.R6Leg)
            setProp(mesh, "TextureId", KORBLOX.Texture)
        else
            if createdMeshes[char] then
                createdMeshes[char]:Destroy()
                createdMeshes[char] = nil
            elseif mesh then
                restoreProp(mesh, "MeshType")
                restoreProp(mesh, "MeshId")
                restoreProp(mesh, "TextureId")
            end
        end
    else
        local map = {
            RightUpperLeg = KORBLOX.UpperLeg,
            RightLowerLeg = KORBLOX.LowerLeg,
            RightFoot     = KORBLOX.Foot,
        }
        for name, id in pairs(map) do
            local p = char:FindFirstChild(name)
            if p then
                if on then
                    setProp(p, "MeshId", id)
                    setProp(p, "TextureID", KORBLOX.Texture)
                else
                    restoreProp(p, "MeshId")
                    restoreProp(p, "TextureID")
                end
            end
        end
    end
end

function Char.applyAura(char, on)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local o = auraObjs[char]
    if on and not (o and o.light.Parent) then
        safeDestroy(o and o.light); safeDestroy(o and o.emit)
        o = {}
        o.light = new("PointLight", { Name = "FlowerialAura", Brightness = 2, Range = 16, Color = accent.Value, Shadows = false }, hrp)
        o.emit = new("ParticleEmitter", {
            Name = "FlowerialAuraFx", Texture = TEX.Aura, Rate = 25,
            Color = ColorSequence.new(accent.Value),
            Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(1, 3),
            SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360),
            Size = NumberSequence.new({ NSK(0, 0.6), NSK(1, 0) }),
            Transparency = NumberSequence.new({ NSK(0, 0.2), NSK(1, 1) }),
            LightEmission = 0.8, LightInfluence = 0,
        }, hrp)
        auraObjs[char] = o
    elseif not on and o then
        safeDestroy(o.light); safeDestroy(o.emit)
        auraObjs[char] = nil
    end
end

function Char.applyTrail(char, on)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local o = trailObjs[char]
    if on and not (o and o.trail.Parent) then
        if o then safeDestroy(o.a0); safeDestroy(o.a1); safeDestroy(o.trail) end
        o = {}
        o.a0 = new("Attachment", { Name = "FlowerialTrailA0", Position = Vector3.new(0, 1, 0) }, hrp)
        o.a1 = new("Attachment", { Name = "FlowerialTrailA1", Position = Vector3.new(0, -1, 0) }, hrp)
        o.trail = new("Trail", {
            Name = "FlowerialTrail", Attachment0 = o.a0, Attachment1 = o.a1, Lifetime = 0.7,
            LightEmission = 0.7, FaceCamera = true,
            Color = ColorSequence.new(accent.Value, accent.Value:Lerp(WHITE, 0.45)),
            Transparency = NumberSequence.new({ NSK(0, 0.1), NSK(1, 1) }),
        }, hrp)
        trailObjs[char] = o
    elseif not on and o then
        safeDestroy(o.a0); safeDestroy(o.a1); safeDestroy(o.trail)
        trailObjs[char] = nil
    end
end

onAccent(function(c)
    for _, o in pairs(auraObjs) do
        pcall(function()
            o.light.Color = c
            o.emit.Color = ColorSequence.new(c)
        end)
    end
    for _, o in pairs(trailObjs) do
        pcall(function() o.trail.Color = ColorSequence.new(c, c:Lerp(WHITE, 0.45)) end)
    end
end)

local Acc = { worn = {} }
local accessoryParts = setmetatable({}, { __mode = "k" })
local accessoryLights = setmetatable({}, { __mode = "k" })
local accessoryEmitters = setmetatable({}, { __mode = "k" })
local accessoryHighlights = setmetatable({}, { __mode = "k" })
local accBloom
local function accessoryTint(c, shade, glow)
    local color = (shade >= 0) and c:Lerp(WHITE, shade) or c:Lerp(BLACK, -shade)
    return glow and color:Lerp(WHITE, 0.15) or color
end
local function accessoryPart(model, target, name, size, offset, shade, style)
    local glow = style == "glow" or style == "glowrod"
    local class = style == "wedge" and "WedgePart" or "Part"
    local p = new(class, {
        Name = name, Size = size, Material = glow and Enum.Material.Neon or Enum.Material.SmoothPlastic,
        Color = accessoryTint(accent.Value, shade or 0, glow),
        CanCollide = false, CanTouch = false, CanQuery = false,
        CastShadow = false, Massless = true, Anchored = false,
    })
    if class == "Part" then
        p.Shape = (style == "rod" or style == "glowrod") and Enum.PartType.Block or Enum.PartType.Ball
    end
    p.CFrame = target.CFrame * offset
    p.Parent = model
    new("WeldConstraint", { Part0 = target, Part1 = p }, p)
    accessoryParts[p] = { shade or 0, glow }
    return p
end
local function accessoryGlow(model, core, range)
    local light = new("PointLight", {
        Name = "FlowerialLight", Color = accent.Value, Brightness = 1.55,
        Range = range or 12, Shadows = false,
    }, core)
    accessoryLights[light] = true
    local emitter = new("ParticleEmitter", {
        Name = "FlowerialGlints", Texture = "rbxasset://textures/particles/sparkles_main.dds",
        Color = ColorSequence.new(accent.Value:Lerp(WHITE, 0.35)),
        Size = NumberSequence.new({ NSK(0, 0), NSK(0.25, 0.19), NSK(1, 0) }),
        Transparency = NumberSequence.new({ NSK(0, 1), NSK(0.28, 0.15), NSK(1, 1) }),
        Lifetime = NumberRange.new(0.5, 1.15), Speed = NumberRange.new(0.4, 1.6),
        SpreadAngle = Vector2.new(160, 160), Rate = 8,
        LightEmission = 1, LightInfluence = 0,
    }, core)
    accessoryEmitters[emitter] = true
    local highlight = new("Highlight", {
        Name = "FlowerialAura", Adornee = model,
        FillColor = accent.Value, OutlineColor = accent.Value:Lerp(WHITE, 0.38),
        FillTransparency = 0.91, OutlineTransparency = 0.46,
        DepthMode = Enum.HighlightDepthMode.Occluded,
    }, model)
    accessoryHighlights[highlight] = true
end
onAccent(function(c)
    for p, info in pairs(accessoryParts) do
        if p.Parent then p.Color = accessoryTint(c, info[1], info[2]) end
    end
    for light in pairs(accessoryLights) do
        if light.Parent then light.Color = c end
    end
    for emitter in pairs(accessoryEmitters) do
        if emitter.Parent then emitter.Color = ColorSequence.new(c:Lerp(WHITE, 0.35)) end
    end
    for highlight in pairs(accessoryHighlights) do
        if highlight.Parent then
            highlight.FillColor = c
            highlight.OutlineColor = c:Lerp(WHITE, 0.38)
        end
    end
end)
function Acc.updateBloom()
    if next(Acc.worn) then
        if not (accBloom and accBloom.Parent) then
            accBloom = new("BloomEffect", {
                Name = "FlowerialAccessoryBloom", Intensity = 0.78,
                Size = 38, Threshold = 0.95,
            }, Lighting)
        end
    else
        safeDestroy(accBloom)
        accBloom = nil
    end
end
function Acc.wear(char, e)
    if e.inst and e.inst.Parent and e.char == char then return end
    safeDestroy(e.inst)
    e.inst, e.char = nil, nil
    if not char or not char.Parent then return end
    local head = char:FindFirstChild("Head")
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    local headItem = e.key == "acc_horns" or e.key == "acc_halo" or e.key == "acc_crown"
    local target = headItem and head or torso
    if not target then return end
    local model = new("Model", { Name = "Flowerial_" .. e.key }, char)
    local function make(name, size, off, shade, style)
        return accessoryPart(model, target, name, size, off, shade, style)
    end
    local core
    if e.key == "acc_wings" then
        core = make("WingHeart", Vector3.new(0.42, 0.48, 0.2), CFrame.new(0, 0.43, 0.67), 0.48, "glow")
        for _, side in ipairs({ -1, 1 }) do
            make("WingSpine", Vector3.new(0.16, 1.64, 0.15),
                CFrame.new(side * 0.82, 0.31, 0.72) * CFrame.Angles(0, 0, math.rad(-side * 32)), -0.28, "rod")
            for layer = 1, 3 do
                for i = 1, 5 do
                    local x = side * (0.55 + i * 0.24 + layer * 0.11)
                    local y = 0.92 - i * 0.16 - layer * 0.25
                    local z = 0.55 + layer * 0.13
                    local angle = math.rad(-side * (17 + i * 9))
                    make("WingPlume", Vector3.new(0.33, 1.3 - i * 0.14, 0.15),
                        CFrame.new(x, y, z) * CFrame.Angles(0, 0, angle), -0.22 + layer * 0.18)
                    if layer == 3 and i <= 4 then
                        make("PlumeEdge", Vector3.new(0.1, 0.63 - i * 0.08, 0.08),
                            CFrame.new(x + side * 0.09, y - 0.1, z + 0.12) * CFrame.Angles(0, 0, angle), 0.62, "glow")
                    end
                end
            end
            for i = 1, 3 do
                make("WingGlyph", Vector3.new(0.14, 0.14, 0.14),
                    CFrame.new(side * (0.87 + i * 0.37), 0.57 - i * 0.26, 1.02), 0.86, "glow")
            end
        end
    elseif e.key == "acc_horns" then
        core = make("HornSigil", Vector3.new(0.27, 0.17, 0.15), CFrame.new(0, 0.55, -0.36), 0.75, "glow")
        for _, side in ipairs({ -1, 1 }) do
            make("HornSocket", Vector3.new(0.36, 0.18, 0.37), CFrame.new(side * 0.36, 0.5, -0.12), -0.35)
            for i = 1, 6 do
                local t = (i - 1) / 5
                local x = side * (0.36 + t * 0.33)
                local y = 0.65 + t * 0.78
                local z = -0.13 + t * 0.08
                make("HornCurve", Vector3.new(0.31 - t * 0.23, 0.23, 0.3 - t * 0.2),
                    CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(-side * (10 + t * 35))),
                    -0.2 + t * 0.51, "wedge")
                if i < 6 and i % 2 == 0 then
                    make("HornRune", Vector3.new(0.21 - t * 0.1, 0.06, 0.2 - t * 0.08),
                        CFrame.new(x, y + 0.1, z - 0.13), 0.7, "glow")
                end
            end
            make("HornTip", Vector3.new(0.1, 0.22, 0.1), CFrame.new(side * 0.7, 1.5, -0.05), 0.85, "glow")
        end
    elseif e.key == "acc_halo" then
        core = make("HaloHeart", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 1.19, 0), 0.65, "glow")
        for i = 1, 24 do
            local a = i * math.pi * 2 / 24
            make("OuterArc", Vector3.new(0.1, 0.1, 0.22),
                CFrame.new(math.cos(a) * 0.74, 1.19, math.sin(a) * 0.74) * CFrame.Angles(0, -a, 0), 0.6, "glowrod")
        end
        for i = 1, 16 do
            local a = i * math.pi * 2 / 16
            make("InnerArc", Vector3.new(0.05, 0.06, 0.23),
                CFrame.new(math.cos(a) * 0.56, 1.19, math.sin(a) * 0.56) * CFrame.Angles(0, -a, 0), 0.87, "glowrod")
        end
        for i = 1, 8 do
            local a = i * math.pi / 4
            make("HaloCrystal", Vector3.new(0.16, 0.19, 0.16),
                CFrame.new(math.cos(a) * 0.74, 1.2, math.sin(a) * 0.74), 0.89, "glow")
        end
    elseif e.key == "acc_tail" then
        core = make("TailSocket", Vector3.new(0.36, 0.34, 0.35), CFrame.new(0, -0.9, 0.42), -0.25)
        for i = 1, 12 do
            local t = i / 12
            local x = math.sin(t * math.pi) * 0.29
            local y = -1.03 + t * t * 0.94
            local z = 0.49 + t * 1.64
            make("TailPlate", Vector3.new(0.36 - t * 0.2, 0.32 - t * 0.16, 0.29),
                CFrame.new(x, y, z) * CFrame.Angles(math.rad(t * 25), math.rad(t * 32), 0),
                -0.18 + t * 0.24)
            if i % 2 == 0 then
                make("TailSigil", Vector3.new(0.2 - t * 0.08, 0.06, 0.12),
                    CFrame.new(x, y + 0.16, z), 0.74, "glow")
            end
        end
        for _, side in ipairs({ -1, 1 }) do
            for i = 1, 2 do
                make("TailFin", Vector3.new(0.2, 0.41 - i * 0.09, 0.12),
                    CFrame.new(side * (0.16 + i * 0.1), -0.02, 2.16 - i * 0.12) *
                    CFrame.Angles(0, 0, math.rad(side * (20 + i * 17))), 0.12, "wedge")
            end
        end
        make("TailTip", Vector3.new(0.22, 0.3, 0.31), CFrame.new(0, 0.08, 2.28), 0.83, "glow")
    elseif e.key == "acc_cape" then
        core = make("CapeStone", Vector3.new(0.3, 0.32, 0.2), CFrame.new(0, 0.44, 0.58), 0.81, "glow")
        for i = -3, 3 do
            local x = i * 0.29
            local z = 0.58 + math.abs(i) * 0.055
            local length = 1.75 + (3 - math.abs(i)) * 0.12
            make("CapeFold", Vector3.new(0.3, length, 0.11),
                CFrame.new(x, -0.64, z) * CFrame.Angles(math.rad(-10), 0, math.rad(i * 4)),
                -0.32 + (i + 3) * 0.06, "wedge")
            make("CapeGlowHem", Vector3.new(0.27, 0.085, 0.12),
                CFrame.new(x, -1.58 - (3 - math.abs(i)) * 0.06, z + 0.18), 0.71, "glowrod")
            if i % 2 == 0 then
                make("CapeInlay", Vector3.new(0.06, 1.1, 0.06),
                    CFrame.new(x, -0.75, z + 0.13) * CFrame.Angles(math.rad(-9), 0, 0), 0.43, "glowrod")
            end
        end
        for _, side in ipairs({ -1, 1 }) do
            make("CapeBorder", Vector3.new(0.1, 1.8, 0.1),
                CFrame.new(side * 1.03, -0.64, 0.83) * CFrame.Angles(math.rad(-10), 0, math.rad(side * 8)),
                0.7, "glowrod")
        end
        make("CapeCollar", Vector3.new(1.95, 0.17, 0.22), CFrame.new(0, 0.37, 0.54), 0.18)
    elseif e.key == "acc_crown" then
        core = make("CrownFrontGem", Vector3.new(0.28, 0.3, 0.17), CFrame.new(0, 0.59, -0.52), 0.91, "glow")
        for i = 1, 18 do
            local a = i * math.pi * 2 / 18
            make("CrownFiligree", Vector3.new(0.12, 0.19, 0.2),
                CFrame.new(math.cos(a) * 0.53, 0.49, math.sin(a) * 0.53) * CFrame.Angles(0, -a, 0),
                -0.18, "rod")
        end
        for i = 1, 9 do
            local a = i * math.pi * 2 / 9
            local x, z = math.cos(a) * 0.52, math.sin(a) * 0.52
            make("CrownSpire", Vector3.new(0.18, 0.46 + (i % 2) * 0.15, 0.21),
                CFrame.new(x, 0.82, z) * CFrame.Angles(0, -a, 0), 0.28, "wedge")
            make("CrownGem", Vector3.new(0.13, 0.17, 0.13), CFrame.new(x, 0.67, z * 1.02), 0.85, "glow")
        end
        make("CrownStar", Vector3.new(0.15, 0.19, 0.15), CFrame.new(0, 1.18, 0), 0.96, "glow")
    end
    e.inst, e.char = model, char
    if core then accessoryGlow(model, core, e.key == "acc_wings" and 14 or 11) end
    Acc.updateBloom()
end
function Acc.unwear(key)
    local e = Acc.worn[key]
    if e then safeDestroy(e.inst); Acc.worn[key] = nil end
    Acc.updateBloom()
end
function Acc.wearAll(char)
    for _, e in pairs(Acc.worn) do Acc.wear(char, e) end
end

function Char.applyAll(char)
    Char.applyLook(char)
    if Char.korblox then Char.applyKorblox(char, true) end
    Char.applyAura(char, Char.aura)
    Char.applyTrail(char, Char.trail)
    Acc.wearAll(char)
end

function Char.onSpawn(char)
    char:WaitForChild("Humanoid", 8)
    char:WaitForChild("Head", 8)
    task.wait(0.6)
    if not gui.Parent then return end
    if C.rig then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            C.rig.Set(hum.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15")
        else
            C.rig.Set("-")
        end
    end
    for _, e in pairs(Acc.worn) do
        safeDestroy(e.inst)
        e.inst, e.char = nil, nil
    end
    Char.applyAll(char)
end

local overlay = new("ScreenGui", {
    Name = gui.Name .. "Fx", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 900,
})
mountGui(overlay)

local Cam = {
    cine = false, cineSize = 0.10, vig = false, vigK = 0.6,
    mblur = false, mblurK = 1, blurCur = 0, lastLook = nil, lastPos = nil, blurFx = nil,
    bob = false, bobSize = 0.2, bobT = 0, bobAmp = 0,
    fovOn = false, fov = 70,
    fovOrig = (Workspace.CurrentCamera and Workspace.CurrentCamera.FieldOfView) or 70,
    zoomOrig = LocalPlayer.CameraMaxZoomDistance, zoomTouched = false,
    hud = false, photo = false,
}

local barTop = new("Frame", { Name = "BarTop", Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = BLACK, BorderSizePixel = 0 }, overlay)
local barBot = new("Frame", {
    Name = "BarBottom", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
    Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = BLACK, BorderSizePixel = 0,
}, overlay)

local vigGradients, vigFrames = {}, {}
local function vigEdge(pos, anchor, size, rot)
    local f = new("Frame", {
        Position = pos, AnchorPoint = anchor, Size = size,
        BackgroundColor3 = BLACK, BorderSizePixel = 0, Visible = false,
    }, overlay)
    local g = new("UIGradient", { Rotation = rot }, f)
    vigFrames[#vigFrames + 1] = f
    vigGradients[#vigGradients + 1] = g
end
vigEdge(UDim2.fromScale(0, 0), Vector2.new(0, 0), UDim2.fromScale(1, 0.3), 90)
vigEdge(UDim2.fromScale(0, 1), Vector2.new(0, 1), UDim2.fromScale(1, 0.3), 270)
vigEdge(UDim2.fromScale(0, 0), Vector2.new(0, 0), UDim2.fromScale(0.22, 1), 0)
vigEdge(UDim2.fromScale(1, 0), Vector2.new(1, 0), UDim2.fromScale(0.22, 1), 180)

local hudPanel = new("Frame", {
    Name = "Status", AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(370, 52),
    BackgroundColor3 = Color3.fromRGB(22, 23, 30), BackgroundTransparency = 0.12,
    BorderSizePixel = 0, Visible = false,
}, overlay)
corner(hudPanel, 17)
local hudScale = new("UIScale", { Scale = 1 }, hudPanel)
local function fitHud()
    local cam = Workspace.CurrentCamera
    if cam then hudScale.Scale = math.clamp(cam.ViewportSize.X / 390, 0.76, 1) end
end
local hudCameraConn
local function watchHudCamera()
    if hudCameraConn then hudCameraConn:Disconnect() end
    local cam = Workspace.CurrentCamera
    if cam then hudCameraConn = connect(cam:GetPropertyChangedSignal("ViewportSize"), fitHud) end
    fitHud()
end
watchHudCamera()
connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), watchHudCamera)
local hudOutline = stroke(hudPanel, accent.Value, 1, 0.68)
onAccent(function(c) hudOutline.Color = c end)
new("UIGradient", { Rotation = 35, Color = ColorSequence.new({
    CSK(0, Color3.fromRGB(27, 29, 36)), CSK(0.55, Color3.fromRGB(34, 31, 42)),
    CSK(1, Color3.fromRGB(22, 24, 32)),
}) }, hudPanel)
local hudBrand = new("Frame", {
    Position = UDim2.fromOffset(9, 5), Size = UDim2.fromOffset(110, 42), BackgroundTransparency = 1,
}, hudPanel)
local hudFlower = new("Frame", {
    Position = UDim2.fromOffset(0, 6), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1,
}, hudBrand)
onAccent(drawIcon(hudFlower, "flower"))
local hudName = new("TextLabel", {
    Position = UDim2.fromOffset(32, 0), Size = UDim2.fromOffset(78, 42),
    BackgroundTransparency = 1, Text = HUB_NAME, Font = Enum.Font.GothamMedium,
    TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = accent.Value,
}, hudBrand)
onAccent(function(c) hudName.TextColor3 = c end)
local hudValues = {}
for i, key in ipairs({ "fps", "hud_ping", "hud_clock" }) do
    local item = new("Frame", {
        Position = UDim2.fromOffset(122 + (i - 1) * 81, 5), Size = UDim2.fromOffset(76, 42),
        BackgroundColor3 = Color3.fromRGB(46, 47, 57), BackgroundTransparency = 0.66,
        BorderSizePixel = 0,
    }, hudPanel)
    corner(item, 12)
    local label = new("TextLabel", {
        Position = UDim2.fromOffset(0, 3), Size = UDim2.new(1, 0, 0, 13),
        BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham,
        TextSize = 10, TextColor3 = GRAY,
    }, item)
    if i == 1 then label.Text = "FPS" else bind(label, key) end
    hudValues[i] = new("TextLabel", {
        Position = UDim2.fromOffset(0, 17), Size = UDim2.new(1, 0, 0, 21),
        BackgroundTransparency = 1, Text = "-", Font = Enum.Font.GothamMedium,
        TextSize = 16, TextColor3 = WHITE,
    }, item)
end
onAccent(function(c) hudValues[1].TextColor3 = c end)

function Cam.setBars()
    local h = Cam.cine and Cam.cineSize or 0
    local info = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(barTop, info, { Size = UDim2.new(1, 0, h, 0) }):Play()
    TweenService:Create(barBot, info, { Size = UDim2.new(1, 0, h, 0) }):Play()
end

function Cam.setVignette()
    for _, f in ipairs(vigFrames) do f.Visible = Cam.vig end
    for _, g in ipairs(vigGradients) do
        g.Transparency = NumberSequence.new(1 - Cam.vigK, 1)
    end
end

function Cam.setBlur(on)
    Cam.mblur = on
    Cam.lastLook, Cam.lastPos, Cam.blurCur = nil, nil, 0
    if on then
        if not (Cam.blurFx and Cam.blurFx.Parent) then
            Cam.blurFx = new("BlurEffect", { Name = "FlowerialMotionBlur", Size = 0 }, Lighting)
        end
    else
        safeDestroy(Cam.blurFx)
        Cam.blurFx = nil
    end
end

function Cam.setBob(on)
    Cam.bob = on
    if not on then
        local c = LocalPlayer.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.CameraOffset = Vector3.new(0, 0, 0) end) end
        Cam.bobT, Cam.bobAmp = 0, 0
    end
end

function Cam.setFov(on)
    Cam.fovOn = on
    if not on then
        pcall(function() Workspace.CurrentCamera.FieldOfView = Cam.fovOrig end)
    end
end

function Cam.setZoom(v)
    Cam.zoomTouched = true
    pcall(function() LocalPlayer.CameraMaxZoomDistance = v end)
end

function Cam.step(dt, cam)
    if Cam.mblur and Cam.blurFx then
        local look = cam.CFrame.LookVector
        local pos = cam.CFrame.Position
        if Cam.lastLook then
            local d = math.max(dt, 0.001)
            local ang = math.acos(math.clamp(look:Dot(Cam.lastLook), -1, 1))
            local spd = (pos - Cam.lastPos).Magnitude
            local target = math.clamp((ang / d) * 2.2 + (spd / d) * 0.04, 0, 30) * Cam.mblurK
            Cam.blurCur = Cam.blurCur + (target - Cam.blurCur) * math.min(1, dt * 12)
            Cam.blurFx.Size = math.clamp(Cam.blurCur, 0, 45)
        end
        Cam.lastLook, Cam.lastPos = look, pos
    end
    if Cam.fovOn then cam.FieldOfView = Cam.fov end
end

function Cam.stepBob(dt)
    if not Cam.bob then return end
    local c = LocalPlayer.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local moving = hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air
    Cam.bobT = Cam.bobT + dt * (moving and math.max(hum.WalkSpeed, 8) * 0.7 or 0)
    Cam.bobAmp = Cam.bobAmp + ((moving and Cam.bobSize or 0) - Cam.bobAmp) * math.min(1, dt * 8)
    hum.CameraOffset = Vector3.new(math.sin(Cam.bobT * 0.5) * Cam.bobAmp * 0.5, math.abs(math.sin(Cam.bobT)) * Cam.bobAmp, 0)
end

function Cam.reset()
    Cam.setBlur(false)
    Cam.setBob(false)
    pcall(function() Workspace.CurrentCamera.FieldOfView = Cam.fovOrig end)
    Cam.fovOn = false
    if Cam.zoomTouched then
        pcall(function() LocalPlayer.CameraMaxZoomDistance = Cam.zoomOrig end)
        Cam.zoomTouched = false
    end
end

local hudAcc, fpsSmooth = 0, 60
local function getPing()
    local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    return ok and math.floor(v) or 0
end
function Cam.stepHud(dt)
    if not Cam.hud then return end
    fpsSmooth = fpsSmooth + ((1 / math.max(dt, 0.001)) - fpsSmooth) * 0.1
    hudAcc = hudAcc + dt
    if hudAcc >= 0.4 then
        hudAcc = 0
        hudValues[1].Text = tostring(math.floor(fpsSmooth + 0.5))
        hudValues[2].Text = tostring(getPing()) .. " ms"
        hudValues[3].Text = os.date("%H:%M")
    end
end

local Music = { sound = nil, vol = 0.5, loop = true }
function Music.stop()
    safeDestroy(Music.sound)
    Music.sound = nil
end
function Music.play(text)
    local id = tonumber(tostring(text):match("%d+"))
    if not id then toast("music_bad"); return end
    Music.stop()
    Music.sound = new("Sound", {
        Name = "FlowerialMusic", SoundId = "rbxassetid://" .. id,
        Volume = Music.vol, Looped = Music.loop,
    }, SoundService)
    Music.sound:Play()
end
function Music.toggle()
    local s = Music.sound
    if not s then return end
    if s.IsPlaying then s:Pause() else s:Resume() end
end

local themePage    = newPage()
local worldPage    = newPage()
local skyPage      = newPage()
local shaderPage   = newPage()
local cameraPage   = newPage()
local charPage     = newPage()
local musicPage    = newPage()
local settingsPage = newPage()

local function fmtTime(v)
    return string.format("%02d:%02d", math.floor(v) % 24, math.floor((v % 1) * 60))
end
local function fmtInt(v) return tostring(math.floor(v + 0.5)) end
local function fmtPct(v) return math.floor(v * 100 + 0.5) .. "%" end

do
    local items = {}
    for i, t in ipairs(THEMES) do items[i] = { key = t.key, swatch = t.color } end
    C.theme = optionGroup(themePage, items, function(i)
        cfg.theme = i
        TweenService:Create(accent, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { Value = THEMES[i].color }):Play()
    end)
    C.theme.Select(cfg.theme, true)
    reg("theme", C.theme)
end

do
    local p = skyPage
    addHeader(p, "hd_sky")
    C.sky = optionGroup(p, {
        { key = "sky_def" }, { key = "sky_sunset" }, { key = "sky_purple" },
        { key = "sky_space" }, { key = "sky_overcast" },
    }, function(i) Env.selectSky(i) end)
    C.stars = addSlider(p, "stars", 0, 5000, 3000, fmtInt, function(v)
        Env.stars = math.floor(v)
        Env.applyStars()
    end)

    addHeader(p, "hd_fog")
    C.fog = optionGroup(p, {
        { key = "fog_off" }, { key = "fog_morning" }, { key = "fog_dense" },
        { key = "fog_blood" }, { key = "fog_night" },
    }, function(i) Env.fogIdx = i; Env.refresh() end)
    C.fogdist = addSlider(p, "fog_dist", 100, 3000, 800, fmtInt, function(v)
        Env.fogDist = v
        Env.refresh()
    end)

    addHeader(p, "hd_skyfx")
    C.aurora  = addToggle(p, "aurora",  false, function(v) Wx.setAurora(v) end)
    C.rainbow = addToggle(p, "rainbow", false, function(v) Wx.setRainbow(v) end)

    reg("sky", C.sky)
    reg("stars", { Get = function() return Env.stars end,
                   Set = function(v) C.stars.Set(v) end })
    reg("fog_dist", C.fogdist)
    reg("fog", C.fog)
    reg("aurora", C.aurora)
    reg("rainbow", C.rainbow)
end

do
    local p = worldPage
    addHeader(p, "hd_time")
    C.lock = addToggle(p, "time_lock", false, function(v)
        Tm.lock = v
        if not v then Tm.skyOwnsTime = false end
        if v then Tm.value = C.time.Get() end
    end)
    addButtons(p, {
        { key = "day", cb = function()
            Tm.skyOwnsTime = false
            C.cycle.Set(false)
            C.time.Set(14, true); Tm.value = 14; C.lock.Set(true)
        end },
        { key = "night", cb = function()
            Tm.skyOwnsTime = false
            C.cycle.Set(false)
            C.time.Set(0, true); Tm.value = 0; C.lock.Set(true)
        end },
    })
    C.time = addSlider(p, "time", 0, 24, ORIG.ClockTime % 24, fmtTime, function(v)
        Tm.value = v
        Tm.skyOwnsTime = false
        if C.cycle.Get() then C.cycle.Set(false) end
        if not C.lock.Get() then C.lock.Set(true) end
    end)
    C.cycle = addToggle(p, "cycle", false, function(v)
        Tm.cycle = v
        if v then
            Tm.skyOwnsTime = false
            if not C.lock.Get() then C.lock.Set(true) end
        end
    end)
    C.speed = addSlider(p, "cycle_speed", 0.05, 3, 0.25, function(v)
        return string.format("%.2f h/s", v)
    end, function(v) Tm.speed = v end)

    addHeader(p, "hd_weather")
    C.rain   = addToggle(p, "rain",   false, function(v) Wx.rain = v;   Wx.update() end)
    C.snow   = addToggle(p, "snow",   false, function(v) Wx.snow = v;   Wx.update() end)
    C.leaves = addToggle(p, "leaves", false, function(v) Wx.leaves = v; Wx.update() end)
    C.dust   = addToggle(p, "dust",   false, function(v) Wx.dust = v;   Wx.update() end)
    C.wint   = addSlider(p, "rain_int", 20, 300, 100, function(v)
        return math.floor(v + 0.5) .. "%"
    end, function(v) Wx.mult = v / 100; Wx.update() end)
    C.storm  = addToggle(p, "storm", false, function(v)
        Wx.storm = v
        if v then
            Wx.nextStrike = os.clock() + 2
            if not C.rain.Get() then C.rain.Set(true) end
        else
            Wx.clearFlash()
        end
    end)

    reg("sky_time", { Get = function() return C.time.Get() end,
                      Set = function(v)
                          C.time.Set(v, true)
                          Tm.value = C.time.Get()
                          local sky = Env.skyPreset and SKIES[Env.skyPreset]
                          if sky and math.abs(Tm.value - sky.time) > 0.01 then Tm.skyOwnsTime = false end
                      end })
    reg("time_lock", C.lock)
    reg("cycle", C.cycle)
    reg("sky_time_auto", {
        Get = function() return Tm.skyOwnsTime end,
        Set = function(v) Tm.skyOwnsTime = v == true and Env.skyPreset ~= nil and Tm.lock and not Tm.cycle end,
    })
    reg("cycle_speed", C.speed)
    reg("rain", C.rain)
    reg("snow", C.snow)
    reg("leaves", C.leaves)
    reg("dust", C.dust)
    reg("w_int", C.wint)
    reg("storm", C.storm)
end

do
    local items = { { key = "sh_off" } }
    for _, name in ipairs(SHADER_ORDER) do items[#items + 1] = { key = "sh_" .. name } end
    C.shader = optionGroup(shaderPage, items, function(i)
        Env.applyShader(i > 1 and SHADER_ORDER[i - 1] or nil)
    end)
    reg("shader", C.shader)
end

do
    local p = cameraPage
    addHeader(p, "hd_cine")
    C.cine = addToggle(p, "cine", false, function(v) Cam.cine = v; Cam.setBars() end)
    C.cinesize = addSlider(p, "cine_size", 4, 18, 10, function(v) return math.floor(v + 0.5) .. "%" end,
        function(v) Cam.cineSize = v / 100; if Cam.cine then Cam.setBars() end end)
    C.vig = addToggle(p, "vignette", false, function(v) Cam.vig = v; Cam.setVignette() end)
    C.vigk = addSlider(p, "vig_int", 0.1, 1, 0.6, fmtPct, function(v) Cam.vigK = v; Cam.setVignette() end)
    C.mblur = addToggle(p, "mblur", false, function(v) Cam.setBlur(v) end)
    C.mblurk = addSlider(p, "mblur_int", 0.2, 2, 1, function(v) return string.format("x%.1f", v) end,
        function(v) Cam.mblurK = v end)

    addHeader(p, "hd_cam")
    C.bob = addToggle(p, "bob", false, function(v) Cam.setBob(v) end)
    C.bobamp = addSlider(p, "bob_amp", 0.05, 0.6, 0.2, function(v) return string.format("%.2f", v) end,
        function(v) Cam.bobSize = v end)
    Cam.fov = math.clamp(math.floor(Cam.fovOrig + 0.5), 30, 120)
    C.fovon = addToggle(p, "fov_on", false, function(v) Cam.setFov(v) end)
    C.fov = addSlider(p, "fov", 30, 120, Cam.fov, fmtInt, function(v) Cam.fov = v end)
    C.zoom = addSlider(p, "zoom", 20, 1000, math.clamp(Cam.zoomOrig, 20, 1000), fmtInt, function(v) Cam.setZoom(v) end)
    addButton(p, "photo", function() Cam.photo = true; C.enterPhoto() end)

    reg("cine_size", C.cinesize)
    reg("cine", C.cine)
    reg("vig_int", C.vigk)
    reg("vignette", C.vig)
    reg("mblur_int", C.mblurk)
    reg("mblur", C.mblur)
    reg("bob_amp", C.bobamp)
    reg("bob", C.bob)
    reg("fov", C.fov)
    reg("fov_on", C.fovon)
end

local function applyNow()
    local c = LocalPlayer.Character
    if c then Char.applyAll(c) end
end

do
    local p = charPage
    C.headless = addToggle(p, "headless", false, function(v) Char.headless = v; applyNow() end)
    C.korblox = addToggle(p, "korblox", false, function(v)
        Char.korblox = v
        local c = LocalPlayer.Character
        if c then Char.applyKorblox(c, v) end
    end)
    C.hideacc = addToggle(p, "hide_acc", false, function(v) Char.hideAcc = v; applyNow() end)
    C.rig = addInfo(p, "rig", "-")

    addHeader(p, "hd_look")
    C.tint = addToggle(p, "tint", false, function(v) Char.tint = v; applyNow() end)
    C.tr = addSlider(p, "tint_r", 0, 255, Char.r, fmtInt, function(v) Char.r = v; applyNow() end)
    C.tg = addSlider(p, "tint_g", 0, 255, Char.g, fmtInt, function(v) Char.g = v; applyNow() end)
    C.tb = addSlider(p, "tint_b", 0, 255, Char.b, fmtInt, function(v) Char.b = v; applyNow() end)
    C.mat = optionGroup(p, {
        { key = "mat_off" }, { key = "mat_neon" }, { key = "mat_glass" },
        { key = "mat_ff" }, { key = "mat_metal" }, { key = "mat_ice" },
    }, function(i) Char.mat = i; applyNow() end)
    C.ghost = addSlider(p, "ghost", 0, 0.9, 0, fmtPct, function(v) Char.ghost = v; applyNow() end)
    C.aura = addToggle(p, "aura", false, function(v)
        Char.aura = v
        local c = LocalPlayer.Character
        if c then Char.applyAura(c, v) end
    end)
    C.trail = addToggle(p, "trail", false, function(v)
        Char.trail = v
        local c = LocalPlayer.Character
        if c then Char.applyTrail(c, v) end
    end)

    addHeader(p, "hd_acc")
    C.acc = {}
    for _, slot in ipairs(ACCESSORIES) do
        local toggle = addToggle(p, slot.key, false, function(v)
            if v then
                local e = { key = slot.key }
                Acc.worn[slot.key] = e
                if LocalPlayer.Character then Acc.wear(LocalPlayer.Character, e) end
                Acc.updateBloom()
            else
                Acc.unwear(slot.key)
            end
        end, slot.key)
        C.acc[slot.key] = toggle
        reg(slot.key, toggle)
    end

    reg("headless", C.headless)
    reg("korblox", C.korblox)
    reg("hide_acc", C.hideacc)
    reg("tint_r", C.tr)
    reg("tint_g", C.tg)
    reg("tint_b", C.tb)
    reg("tint", C.tint)
    reg("mat", C.mat)
    reg("ghost", C.ghost)
    reg("aura", C.aura)
    reg("trail", C.trail)
end

connect(LocalPlayer.CharacterAdded, function(c) task.spawn(Char.onSpawn, c) end)
if LocalPlayer.Character then task.spawn(Char.onSpawn, LocalPlayer.Character) end

do
    local p = musicPage
    addHeader(p, "hd_music")
    C.mbox = addInput(p, "music_ph", "", function(text, enter)
        if enter and text ~= "" then Music.play(text) end
    end)
    addButtons(p, {
        { key = "music_play", cb = function()
            if C.mbox.Text ~= "" then Music.play(C.mbox.Text) end
        end },
        { key = "music_pause", cb = function() Music.toggle() end },
        { key = "music_stop", cb = function() Music.stop() end },
    })
    C.mvol = addSlider(p, "music_vol", 0, 1, Music.vol, fmtPct, function(v)
        Music.vol = v
        if Music.sound then Music.sound.Volume = v end
    end)
    C.mloop = addToggle(p, "music_loop", true, function(v)
        Music.loop = v
        if Music.sound then Music.sound.Looped = v end
    end)

    reg("music_id", { Get = function() return C.mbox.Text end,
                      Set = function(v) C.mbox.Text = tostring(v) end })
    reg("music_vol", C.mvol)
    reg("music_loop", C.mloop)
end

local Hub = { keyName = "RightShift", binding = false }
local function validBindName(v)
    if type(v) ~= "string" then return false end
    if v == "" then return true end
    if v == "MouseButton1" or v == "MouseButton2" or v == "MouseButton3" then return true end
    local ok, key = pcall(function() return Enum.KeyCode[v] end)
    return ok and key ~= nil and v ~= "Unknown"
end
if validBindName(cfg.hotkeyName) then Hub.keyName = cfg.hotkeyName end

do
    local p = settingsPage
    C.anim = addToggle(p, "anim_grad", cfg.anim and true or false, function(v)
        cfg.anim = v
        if not v then TweenService:Create(grad, TweenInfo.new(0.3), { Rotation = 35 }):Play() end
    end)
    C.restore = addToggle(p, "restore", cfg.restore ~= false, function(v) cfg.restore = v end)
    C.alpha = addSlider(p, "menu_alpha", 0, 0.7, 0, fmtPct, function(v)
        main.BackgroundTransparency = v
    end)
    local keyRow = rowBase(p, 42)
    rowLabel(keyRow, "hotkey")
    local keyButton = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(145, 30), BackgroundColor3 = Color3.fromRGB(30, 29, 36),
        Text = Hub.keyName ~= "" and Hub.keyName or "-", Font = Enum.Font.GothamMedium,
        TextSize = 13, TextColor3 = accent.Value, BorderSizePixel = 0, AutoButtonColor = false,
    }, keyRow)
    corner(keyButton, 8)
    Hub.button = keyButton
    onAccent(function(c) keyButton.TextColor3 = c end)
    connect(keyButton.MouseButton1Click, function()
        Hub.binding = not Hub.binding
        keyButton.Text = Hub.binding and tr("bind_wait") or (Hub.keyName ~= "" and Hub.keyName or "-")
    end)
    C.hud = addToggle(p, "hud", false, function(v)
        Cam.hud = v
        hudPanel.Visible = v
    end)
    for n = 1, 3 do
        local old = "p" .. n
        if type(cfg.profiles[old]) == "table" then
            local name = "Preset " .. n
            if not cfg.profiles[name] then cfg.profiles[name] = cfg.profiles[old] end
            cfg.profiles[old] = nil
        end
    end
    addHeader(p, "hd_prof")
    addHeader(p, "prof_name")
    local nameBox = addInput(p, "prof_ph", "", nil)
    local savedList = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 114), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = accent.Value, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, p)
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, savedList)
    local listButtons, armedName, armedUntil = {}, nil, 0
    local function nameFromBox()
        local name = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        local ok, count = pcall(utf8.len, name)
        if not ok or not count or count < 1 or count > 32 or name:find("%c") then
            toast("prof_bad")
            return nil
        end
        return name
    end
    local function refreshConfigs()
        for _, child in ipairs(savedList:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        listButtons = {}
        local names = {}
        for name, value in pairs(cfg.profiles) do
            if type(name) == "string" and type(value) == "table" then names[#names + 1] = name end
        end
        table.sort(names)
        if #names == 0 then
            new("TextLabel", {
                Size = UDim2.new(1, -6, 0, 34), BackgroundTransparency = 1,
                Text = tr("prof_none"), TextColor3 = GRAY, TextSize = 13,
                Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
            }, savedList)
        end
        for _, name in ipairs(names) do
            local button = new("TextButton", {
                Size = UDim2.new(1, -6, 0, 34), BackgroundColor3 = ROW_BG,
                BackgroundTransparency = 0.35, Text = name, TextColor3 = GRAY,
                TextSize = 14, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false, BorderSizePixel = 0,
            }, savedList)
            corner(button, 8)
            new("UIPadding", { PaddingLeft = UDim.new(0, 12) }, button)
            listButtons[name] = button
            connect(button.MouseButton1Click, function() nameBox.Text = name end)
        end
        for name, button in pairs(listButtons) do
            button.TextColor3 = (name == nameBox.Text) and accent.Value or GRAY
        end
    end
    connect(nameBox:GetPropertyChangedSignal("Text"), function()
        armedName = nil
        for name, button in pairs(listButtons) do
            button.TextColor3 = (name == nameBox.Text) and accent.Value or GRAY
        end
    end)
    onAccent(function(c)
        savedList.ScrollBarImageColor3 = c
        for name, button in pairs(listButtons) do
            button.TextColor3 = (name == nameBox.Text) and c or GRAY
        end
    end)
    addButtons(p, {
        { key = "prof_save", cb = function()
            local name = nameFromBox()
            if not name then return end
            cfg.profiles[name] = snapshotState()
            armedName = nil
            refreshConfigs()
            toast(saveConfig(true) and "prof_saved" or "nosave")
        end },
        { key = "prof_load", cb = function()
            local name = nameFromBox()
            if not name then return end
            local state = cfg.profiles[name]
            if type(state) ~= "table" then toast("prof_empty"); return end
            applyState(state)
            toast("prof_done")
        end },
        { key = "prof_delete", cb = function()
            local name = nameFromBox()
            if not name then return end
            if type(cfg.profiles[name]) ~= "table" then toast("prof_empty"); return end
            if armedName ~= name or os.clock() >= armedUntil then
                armedName, armedUntil = name, os.clock() + 3
                toast("prof_again")
                return
            end
            cfg.profiles[name] = nil
            armedName = nil
            refreshConfigs()
            toast(saveConfig(true) and "prof_deleted" or "nosave")
        end },
    })
    C.refreshConfigs = refreshConfigs
    refreshConfigs()
    reg("anim", C.anim)
    reg("menu_alpha", C.alpha)
    reg("hud", C.hud)
    reg("hotkey_name", {
        Get = function() return Hub.keyName end,
        Set = function(v)
            if not validBindName(v) then return end
            Hub.keyName = v
            cfg.hotkeyName = v
            Hub.button.Text = v ~= "" and v or "-"
        end,
    })
end

local function resetEffects()
    for _, k in ipairs({ "rain", "snow", "leaves", "dust", "storm", "aurora", "rainbow",
        "cine", "vig", "mblur", "bob", "fovon", "headless", "korblox", "hideacc",
        "tint", "aura", "trail", "cycle" }) do
        if C[k] then C[k].Set(false) end
    end
    Tm.lock = false
    Tm.skyOwnsTime = false
    C.lock.Set(false, true)
    C.sky.Select(1)
    C.fog.Select(1)
    C.shader.Select(1)
    C.mat.Select(1)
    C.ghost.Set(0)
    for _, t in pairs(C.acc) do t.Set(false) end
    Cam.reset()
    Music.stop()
    Env.restoreAll()
    C.time.Set(ORIG.ClockTime, true)
    Tm.value = ORIG.ClockTime
    toast("reset_done")
end
addButton(settingsPage, "reset", resetEffects)

local TABS = {
    { key = "themes", page = themePage }, { key = "world", page = worldPage },
    { key = "sky", page = skyPage }, { key = "shaders", page = shaderPage },
    { key = "camera", page = cameraPage }, { key = "character", page = charPage },
    { key = "music", page = musicPage }, { key = "settings", page = settingsPage },
}
local currentTab = 1
local function selectTab(i)
    currentTab = i
    for j, t in ipairs(TABS) do
        t.page.Visible = j == i
        t.paint((j == i) and accent.Value or GRAY)
    end
    TweenService:Create(indicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        { Position = UDim2.fromOffset(0, 8 + (i - 1) * TAB_STEP + (TAB_H - 26) / 2) }):Play()
    sectionTitle.Text = tr(TABS[i].key)
end
for i, t in ipairs(TABS) do
    t.btn = new("TextButton", { Position = UDim2.fromOffset(0, 8 + (i - 1) * TAB_STEP), Size = UDim2.fromOffset(68, TAB_H), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, sidebar)
    t.paint = drawIcon(t.btn, t.key)
    connect(t.btn.MouseButton1Click, function() selectTab(i) end)
end
onAccent(function(c)
    for j, t in ipairs(TABS) do t.paint((j == currentTab) and c or GRAY) end
end)

local function setLang(l)
    lang = l
    cfg.lang = l
    for _, b in ipairs(bindings) do
        b[1][b[3]] = tr(b[2])
    end
    sectionTitle.Text = tr(TABS[currentTab].key)
    if Hub.binding then Hub.button.Text = tr("bind_wait") end
    if C.refreshConfigs then C.refreshConfigs() end
    paintLang()
    markDirty()
end
connect(enBtn.MouseButton1Click, function() setLang("EN") end)
connect(ruBtn.MouseButton1Click, function() setLang("RU") end)

local bubble = new("TextButton", {
    Name = "Bubble", AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(48, 48), BackgroundColor3 = Color3.fromRGB(22, 22, 26),
    Text = "", Visible = false, Active = true, AutoButtonColor = false, BorderSizePixel = 0,
}, gui)
corner(bubble, 12)
local bubbleScale = new("UIScale", { Scale = 1 }, bubble)
local bubbleBorder = stroke(bubble, accent.Value, 1, 0.45)
local paintBubble = drawIcon(bubble, "flower")
onAccent(function(c)
    bubbleBorder.Color = c
    paintBubble(c, Cam.photo and 0.8 or 0)
end)
local bubbleX = type(cfg.bubbleX) == "number" and cfg.bubbleX == cfg.bubbleX and math.clamp(cfg.bubbleX, 0, 1) or 0.05
local bubbleY = type(cfg.bubbleY) == "number" and cfg.bubbleY == cfg.bubbleY and math.clamp(cfg.bubbleY, 0, 1) or 0.5
local function placeBubble(x, y)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    if vp.X <= 0 or vp.Y <= 0 then return end
    local size = math.clamp(math.floor(math.min(vp.X / 8, vp.Y / 13)), 46, 56)
    bubble.Size = UDim2.fromOffset(size, size)
    local half = size / 2 + 4
    x = math.clamp(x, half, math.max(half, vp.X - half))
    y = math.clamp(y, half, math.max(half, vp.Y - half))
    bubble.Position = UDim2.fromOffset(x, y)
    bubbleX, bubbleY = x / vp.X, y / vp.Y
end
local function resizeBubble()
    local cam = Workspace.CurrentCamera
    if cam then
        local vp = cam.ViewportSize
        placeBubble(bubbleX * vp.X, bubbleY * vp.Y)
    end
end
local bubbleCameraConn
local function watchBubbleCamera()
    if bubbleCameraConn then bubbleCameraConn:Disconnect() end
    local cam = Workspace.CurrentCamera
    if cam then bubbleCameraConn = connect(cam:GetPropertyChangedSignal("ViewportSize"), resizeBubble) end
    resizeBubble()
end
watchBubbleCamera()
connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), watchBubbleCamera)
local dragInput, dragStart, bubbleStart, bubbleMoved = nil, nil, nil, false
connect(bubble.InputBegan, function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        dragInput = input
        dragStart = Vector2.new(input.Position.X, input.Position.Y)
        bubbleStart = Vector2.new(bubble.Position.X.Offset, bubble.Position.Y.Offset)
        bubbleMoved = false
    end
end)
connect(UserInputService.InputChanged, function(input)
    if not dragInput then return end
    local touch = dragInput.UserInputType == Enum.UserInputType.Touch
    if (touch and input ~= dragInput) or (not touch and input.UserInputType ~= Enum.UserInputType.MouseMovement) then return end
    local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
    if delta.Magnitude > 6 then bubbleMoved = true end
    if bubbleMoved then placeBubble(bubbleStart.X + delta.X, bubbleStart.Y + delta.Y) end
end)
connect(UserInputService.InputEnded, function(input)
    if not dragInput then return end
    local touch = dragInput.UserInputType == Enum.UserInputType.Touch
    if (touch and input ~= dragInput) or (not touch and input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end
    dragInput = nil
    if bubbleMoved then
        cfg.bubbleX, cfg.bubbleY = bubbleX, bubbleY
        markDirty()
        saveConfig(true)
    end
end)
local minimized, transition = false, 0
local function setMinimized(v)
    transition = transition + 1
    local token = transition
    minimized = v
    if v then
        resizeBubble()
        if main.Visible then
            TweenService:Create(uiScale, TweenInfo.new(0.17, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = baseScale * 0.84 }):Play()
            task.delay(0.17, function()
                if token ~= transition or not gui.Parent then return end
                main.Visible = false
                bubble.Visible = true
                bubbleScale.Scale = 0.6
                TweenService:Create(bubbleScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            end)
        else bubble.Visible = true end
    else
        Cam.photo = false
        bubble.Visible = false
        bubble.BackgroundTransparency = 0
        paintBubble(accent.Value)
        main.Visible = true
        uiScale.Scale = baseScale * 0.84
        TweenService:Create(uiScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = baseScale }):Play()
    end
end
connect(bubble.MouseButton1Click, function()
    if not bubbleMoved then setMinimized(false) end
end)
function C.enterPhoto()
    transition = transition + 1
    minimized = true
    Cam.photo = true
    main.Visible = false
    bubble.Visible = true
    resizeBubble()
    bubble.BackgroundTransparency = 0.85
    paintBubble(accent.Value, 0.8)
end

connect(UserInputService.InputBegan, function(input, gpe)
    if Hub.binding then
        if gpe and input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local mouse = input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.UserInputType == Enum.UserInputType.MouseButton2 or
            input.UserInputType == Enum.UserInputType.MouseButton3
        if not mouse and input.KeyCode == Enum.KeyCode.Unknown then return end
        Hub.binding = false
        Hub.keyName = mouse and input.UserInputType.Name or input.KeyCode.Name
        Hub.button.Text = Hub.keyName
        cfg.hotkeyName = Hub.keyName
        markDirty()
        return
    end
    if gpe or UserInputService:GetFocusedTextBox() then return end
    if Hub.keyName ~= "" and
       (input.KeyCode.Name == Hub.keyName or input.UserInputType.Name == Hub.keyName) then
        setMinimized(not minimized)
    end
end)

local stepName = "FlowerialStep_" .. gui.Name
local function cleanup()
    pcall(function() RunService:UnbindFromRenderStep(stepName) end)
    pcall(function()
        if cfg.restore ~= false then saveConfig(true) end
    end)
    pcall(Wx.destroyAll)
    pcall(Env.restoreAll)
    pcall(Cam.reset)
    pcall(Music.stop)
    Tm.lock = false
    Tm.skyOwnsTime = false
    Char.headless, Char.korblox, Char.hideAcc = false, false, false
    Char.tint, Char.ghost, Char.mat, Char.aura, Char.trail = false, 0, 1, false, false
    for key in pairs(Acc.worn) do pcall(Acc.unwear, key) end
    local c = LocalPlayer.Character
    if c then
        pcall(Char.applyLook, c)
        pcall(Char.applyKorblox, c, false)
        pcall(Char.applyAura, c, false)
        pcall(Char.applyTrail, c, false)
    end
    for _, cn in ipairs(conns) do
        pcall(function() cn:Disconnect() end)
    end
    safeDestroy(overlay)
    safeDestroy(gui)
    genv.__FlowerialCleanup = nil
end
genv.__FlowerialCleanup = cleanup

headerBtn("close", -10, cleanup)
headerBtn("minus", -46, function() setMinimized(true) end)

local dragging, dragStart, startPos = false, nil, nil
connect(header.InputBegan, function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)
connect(UserInputService.InputChanged, function(input)
    local t = input.UserInputType
    if dragging and (t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
connect(UserInputService.InputEnded, function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local charAcc, saveAcc, warned = 0, 0, false
local function step(dt)
    local cam = Workspace.CurrentCamera

    if Tm.lock then
        if Tm.cycle then
            Tm.value = (Tm.value + dt * Tm.speed) % 24
            C.time.Set(Tm.value, true)
        end
        Lighting.ClockTime = Tm.value
    end

    if cam then
        Wx.step(dt, cam)
        Cam.step(dt, cam)
    end
    Cam.stepBob(dt)
    Cam.stepHud(dt)

    if cfg.anim then
        grad.Rotation = (grad.Rotation + dt * 25) % 360
    end

    charAcc = charAcc + dt
    if charAcc >= 1.5 then
        charAcc = 0
        local c = LocalPlayer.Character
        if c then Char.applyAll(c) end
    end

    saveAcc = saveAcc + dt
    if saveAcc >= 3 then
        saveAcc = 0
        if dirty then
            dirty = false
            saveConfig(true)
        end
    end
end

RunService:BindToRenderStep(stepName, Enum.RenderPriority.Camera.Value + 1, function(dt)
    local ok, err = pcall(step, dt)
    if not ok and not warned then
        warned = true
        warn("[" .. HUB_NAME .. "] " .. tostring(err))
    end
end)

paintLang()
selectTab(1)
uiScale.Scale = baseScale * 0.9
TweenService:Create(uiScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    { Scale = baseScale }):Play()

if cfg.restore ~= false and type(cfg.state) == "table" then
    task.delay(0.5, function()
        if gui.Parent then
            applyState(cfg.state)
            dirty = false
        end
    end)
end
