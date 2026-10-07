-- PULSE AUTOCLICK 1.0.1 | Roblox / Delta mobile | Lua autocontido
-- Cole todo este arquivo no editor do Delta e execute.
-- Pontos > Adicionar > toque no local > Iniciar. Arraste o cabeçalho para mover.
-- Repete SOMENTE entradas de toque/clique. Não acessa remotes, inventário ou contas.
-- Não baixa nem executa código externo. Salvar/Ler usam apenas PulseAutoClick.json.
-- Compatibilidade: o executor precisa permitir ao menos uma API de entrada virtual.
-- Referências de mecânica: github.com/Nain57/Smart-AutoClicker/wiki/Action-%E2%80%90-Click
-- Interface: create.roblox.com/docs/ui/animation
-- Se não abrir: feche o editor do Delta e confira as mensagens [PULSE] no console.

local PulseBootstrap = {phase = "início", parent = nil, appGui = nil, reportGui = nil, reportLabel = nil}
local function pulseTrace(message)
    local text = tostring(message)
    if debug and type(debug.traceback) == "function" then
        local ok, trace = pcall(debug.traceback, text, 2)
        if ok then return trace end
    end
    return text
end
local function pulseReport(message, isError)
    local text = "[PULSE 1.0.1] " .. tostring(message)
    if isError and type(warn) == "function" then warn(text)
    elseif type(print) == "function" then print(text) end
    if PulseBootstrap.reportLabel then
        pcall(function()
            PulseBootstrap.reportLabel.Text = isError and
                (tostring(message):sub(1, 190) .. "\n\nErro completo no console do Delta.") or tostring(message)
            if isError then PulseBootstrap.reportLabel.TextColor3 = Color3.fromRGB(247, 149, 131) end
        end)
    end
    if isError then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "PULSE · erro de abertura", Text = tostring(message):sub(1, 170), Duration = 12,
            })
        end)
    end
end
local function pulseStage(name)
    PulseBootstrap.phase = name
    if PulseBootstrap.reportLabel then
        pcall(function() PulseBootstrap.reportLabel.Text = "Abrindo PULSE...\n" .. name end)
    end
end
local function pulsePickParent()
    local candidates = {}
    local accessors = {}
    if type(gethui) == "function" then table.insert(accessors, gethui) end
    if type(get_hidden_gui) == "function" then table.insert(accessors, get_hidden_gui) end
    for _, accessor in ipairs(accessors) do
        if type(accessor) == "function" then
            local ok, value = pcall(accessor)
            if ok and value then table.insert(candidates, value) end
        end
    end
    local coreOK, core = pcall(function() return game:GetService("CoreGui") end)
    if coreOK and core then table.insert(candidates, core) end
    local playerOK, playerGui = pcall(function()
        local localPlayer = game:GetService("Players").LocalPlayer
        return localPlayer and localPlayer:FindFirstChild("PlayerGui")
    end)
    if playerOK and playerGui then table.insert(candidates, playerGui) end
    for _, candidate in ipairs(candidates) do
        local probe = nil
        local ok = pcall(function()
            probe = Instance.new("ScreenGui")
            probe.Name = "PulseParentProbe"
            probe.Parent = candidate
            assert(probe.Parent == candidate, "A interface não aceitou o painel.")
        end)
        if probe then pcall(function() probe:Destroy() end) end
        if ok then return candidate end
    end
    return nil
end
pulseReport("Execução recebida. Preparando interface.")
local PulseOK, PulseResult = xpcall(function()
    pulseStage("selecionando camada de interface")
    PulseBootstrap.parent = pulsePickParent()
    if PulseBootstrap.parent then
        local oldReport = PulseBootstrap.parent:FindFirstChild("PulseStartup")
        if oldReport then oldReport:Destroy() end
        local report = Instance.new("ScreenGui")
        PulseBootstrap.reportGui = report
        report.Name, report.ResetOnSpawn, report.IgnoreGuiInset = "PulseStartup", false, true
        report.DisplayOrder = 2147483647
        report.Parent = PulseBootstrap.parent
        local box = Instance.new("Frame")
        box.Size, box.Position = UDim2.new(0.86, 0, 0, 180), UDim2.new(0.07, 0, 0.25, 0)
        box.BackgroundColor3, box.BorderSizePixel = Color3.fromRGB(22, 24, 23), 0
        box.Parent = report
        local message = Instance.new("TextLabel")
        message.Size, message.Position = UDim2.new(1, -68, 1, -16), UDim2.new(0, 12, 0, 8)
        message.BackgroundTransparency, message.TextWrapped = 1, true
        message.Font, message.TextSize = Enum.Font.SourceSans, 16
        message.TextColor3, message.Text = Color3.fromRGB(216, 241, 134), "Abrindo PULSE..."
        message.Parent = box
        PulseBootstrap.reportLabel = message
        local dismiss = Instance.new("TextButton")
        dismiss.Size, dismiss.Position = UDim2.new(0, 44, 0, 44), UDim2.new(1, -48, 0, 4)
        dismiss.Text, dismiss.Font, dismiss.TextSize = "×", Enum.Font.SourceSans, 24
        dismiss.BackgroundColor3, dismiss.TextColor3 = Color3.fromRGB(43, 47, 44), Color3.fromRGB(247, 149, 131)
        dismiss.BorderSizePixel, dismiss.Parent = 0, box
        dismiss.Activated:Connect(function()
            PulseBootstrap.reportLabel = nil
            pcall(function() report:Destroy() end)
        end)
    end
    pulseStage("aguardando cliente")

local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")
local Http = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local playerDeadline = os.clock() + 15
while not player and os.clock() < playerDeadline do task.wait(0.1) player = Players.LocalPlayer end
assert(player, "Jogador local não encontrado. Execute dentro de um jogo carregado.")
local parent = PulseBootstrap.parent or pulsePickParent()
assert(parent, "Nenhuma camada de interface aceitou o painel. Veja o console do Delta.")
pulseStage("preparando painel")
local previous = parent:FindFirstChild("PulseAutoClick")
if previous then
    local closer = previous:FindFirstChild("ClosePulse")
    if closer and closer:IsA("BindableEvent") then closer:Fire() end
    if previous.Parent then previous:Destroy() end
end

local C = {
    bg = Color3.fromRGB(22, 24, 23), card = Color3.fromRGB(31, 34, 32),
    raised = Color3.fromRGB(43, 47, 44), border = Color3.fromRGB(66, 73, 66),
    text = Color3.fromRGB(244, 243, 235), muted = Color3.fromRGB(160, 168, 158),
    accent = Color3.fromRGB(216, 241, 134), blue = Color3.fromRGB(182, 214, 150),
    mint = Color3.fromRGB(146, 225, 182), danger = Color3.fromRGB(247, 149, 131),
    amber = Color3.fromRGB(240, 201, 121), ink = Color3.fromRGB(22, 29, 20),
}
local defaults = {
    interval = 200, hold = 40, startDelay = 3, doubleGap = 90,
    maxClicks = 0, maxCycles = 0, maxSeconds = 0, double = false,
    sequence = true, selected = 1, engine = "auto", animations = true,
    minimizeOnStart = true, pauseOnFocus = true, showMarkers = true,
}
local S = {
    alive = true, mode = "idle", minimized = false, editing = false,
    picking = false, tab = "painel", generation = 0, viewGeneration = 0,
    cfg = {}, points = {}, count = 0, cycles = 0, elapsed = 0, runSince = nil,
    pressed = nil, activeEngine = nil, engines = {}, engineIndex = 1,
    connections = {}, markers = {}, drag = nil, status = "Pronto para configurar",
    lastError = "", currentPoint = 0, countdown = 0, toastGeneration = 0,
    workerBusy = false, miniSuppressUntil = 0,
}
for k, v in pairs(defaults) do S.cfg[k] = v end
local UI, U = {}, {}
local refresh, rebuildPoints, start, stop, pause, setMinimized, beginPick, shutdown
local layoutMarkers, finishEdit
local activeTweens = setmetatable({}, {__mode = "k"})
local function clock() return os.clock() end
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(S.connections, connection)
    return connection
end
local function make(class, props, target)
    local object = Instance.new(class)
    for key, value in pairs(props or {}) do
        local ok, err = pcall(function() object[key] = value end)
        if not ok then
            object:Destroy()
            error("Falha em " .. class .. "." .. key .. ": " .. tostring(err), 0)
        end
    end
    object.Parent = target
    return object
end
local function round(object, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, object)
end
local function stroke(object, color, transparency, thickness)
    return make("UIStroke", {Color = color or C.border,
        Transparency = transparency or 0.35, Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, object)
end
local function frame(target, name, x, y, w, h, color)
    return make("Frame", {Name = name, Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h), BackgroundColor3 = color or C.card,
        BorderSizePixel = 0, Active = false}, target)
end
local function label(target, name, value, x, y, w, h, size, color, bold)
    return make("TextLabel", {Name = name, Text = value,
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
        BackgroundTransparency = 1, TextColor3 = color or C.text,
        TextSize = math.max(11, size or 14), Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd}, target)
end
function U.animate(object, properties, seconds, style)
    local old = activeTweens[object]
    if old then old:Cancel() end
    if not S.cfg.animations then
        for key, value in pairs(properties) do object[key] = value end
        return
    end
    local animation = Tween:Create(object, TweenInfo.new(seconds or 0.18,
        style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties)
    activeTweens[object] = animation
    animation:Play()
end
local function button(target, name, value, x, y, w, h, color, callback)
    local object = make("TextButton", {Name = name, Text = value,
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
        BackgroundColor3 = color or C.raised, TextColor3 = C.text,
        BorderSizePixel = 0, AutoButtonColor = false, TextSize = 13,
        Font = Enum.Font.GothamMedium, ClipsDescendants = true}, target)
    round(object, 11)
    stroke(object)
    local original = object.BackgroundColor3
    object.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
            input.UserInputType == Enum.UserInputType.MouseButton1 then
            U.animate(object, {BackgroundColor3 = object.BackgroundColor3:Lerp(C.text, 0.10)}, 0.08)
        end
    end)
    object.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
            input.UserInputType == Enum.UserInputType.MouseButton1 then
            U.animate(object, {BackgroundColor3 = original}, 0.16)
        end
    end)
    object.Activated:Connect(function()
        if not S.alive then return end
        if callback then callback() end
    end)
    return object
end
local function section(target, value, y)
    label(target, "Section", value, 4, y, 322, 24, 11, C.muted, true)
end
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function bounded(value, min, max, fallback)
    value = tonumber(value)
    if not finite(value) then return fallback end
    return math.clamp(math.floor(value + 0.5), min, max)
end
local function lockConfig()
    if S.mode ~= "idle" or S.workerBusy then
        U.toast("Pare a execução para alterar os ajustes.", C.amber)
        return true
    end
    return false
end
function U.toast(value, color)
    if not S.alive then return end
    S.toastGeneration = S.toastGeneration + 1
    local id = S.toastGeneration
    UI.toastText.Text = value
    UI.toastText.TextColor3 = color or C.text
    UI.toast.Visible = true
    UI.toastScale.Scale = S.cfg.animations and 0.93 or 1
    U.animate(UI.toastScale, {Scale = 1}, 0.22, Enum.EasingStyle.Back)
    task.delay(3.2, function()
        if S.alive and S.toastGeneration == id then UI.toast.Visible = false end
    end)
end
local function dimensions()
    local size = UI.surface.AbsoluteSize
    if size.X < 32 or size.Y < 32 then
        local ok, viewport = pcall(function() return workspace.CurrentCamera.ViewportSize end)
        if ok and viewport and viewport.X > 32 and viewport.Y > 32 then size = viewport end
    end
    if size.X < 32 or size.Y < 32 then size = Vector2.new(800, 450) end
    return Vector2.new(math.max(2, size.X), math.max(2, size.Y))
end
-- AbsolutePosition e InputObject.Position usam as coordenadas CoreUISafeInsets.
-- A diferença dá os pixels do viewport e evita deslocamento em telas com recorte.
local function rawInput(input)
    local p = input.Position
    local origin = UI.surface.AbsolutePosition
    return Vector2.new(p.X - origin.X, p.Y - origin.Y)
end
local function rawPosition(object)
    return object.AbsolutePosition - UI.surface.AbsolutePosition
end
local function contains(object, p)
    if not object.Visible then return false end
    local pos, size = rawPosition(object), object.AbsoluteSize
    return p.X >= pos.X and p.Y >= pos.Y and
        p.X <= pos.X + size.X and p.Y <= pos.Y + size.Y
end
local function blocked(p)
    return contains(UI.main, p) or contains(UI.mini, p) or
        (UI.pickHud.Visible and contains(UI.pickHud, p))
end
local function pointPixels(point)
    local size = dimensions()
    return Vector2.new(math.clamp(math.floor(point.x * size.X + 0.5), 1, size.X - 1),
        math.clamp(math.floor(point.y * size.Y + 0.5), 1, size.Y - 1))
end
local function activeSeconds()
    return S.elapsed + (S.runSince and (clock() - S.runSince) or 0)
end
local function formatTime(value)
    value = math.max(0, math.floor(value))
    return string.format("%02d:%02d", math.floor(value / 60), value % 60)
end

UI.gui = make("ScreenGui", {Name = "PulseAutoClick", ResetOnSpawn = false,
    IgnoreGuiInset = true, DisplayOrder = 2147483646,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, parent)
PulseBootstrap.appGui = UI.gui
pcall(function() UI.gui.ScreenInsets = Enum.ScreenInsets.None end)
UI.closer = make("BindableEvent", {Name = "ClosePulse"}, UI.gui)
UI.surface = make("Frame", {Name = "Surface", Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1, Active = false, BorderSizePixel = 0}, UI.gui)
UI.main = frame(UI.surface, "Panel", 20, 20, 370, 566, C.bg)
UI.main.ZIndex = 5
round(UI.main, 18)
stroke(UI.main, C.border, 0.15)
UI.mainScale = make("UIScale", {Scale = 1}, UI.main)
UI.header = frame(UI.main, "DragHeader", 0, 0, 370, 78, C.bg)
UI.header.BackgroundTransparency = 1
UI.header.Active = true
local logo = frame(UI.header, "Logo", 18, 17, 42, 42, C.accent)
round(logo, 10)
local aim = frame(logo, "Aim", 10, 10, 22, 22, C.accent)
aim.BackgroundTransparency = 1
round(aim, 12)
stroke(aim, C.ink, 0, 2)
local aimDot = frame(logo, "AimDot", 18, 18, 6, 6, C.ink)
round(aimDot, 4)
label(UI.header, "Title", "PULSE", 73, 17, 145, 24, 21, C.text, true)
label(UI.header, "Subtitle", "AUTOCLICK · MOBILE", 74, 43, 155, 16, 10, C.muted, true)
UI.minimize = button(UI.header, "Minimize", "—", 278, 19, 34, 36, C.card,
    function() setMinimized(true) end)
UI.close = button(UI.header, "Close", "×", 318, 19, 34, 36, C.card, function() shutdown() end)
UI.close.TextColor3 = C.danger
UI.headerLine = frame(UI.main, "HeaderLine", 18, 77, 334, 1, C.border)
UI.headerLine.BackgroundTransparency = 0.45
UI.tabs = frame(UI.main, "Tabs", 18, 88, 334, 40, C.card)
round(UI.tabs, 12)
UI.tabIndicator = frame(UI.tabs, "ActiveTab", 3, 3, 106, 34, C.raised)
round(UI.tabIndicator, 8)
local activeLine = frame(UI.tabIndicator, "ActiveLine", 33, 30, 40, 2, C.accent)
round(activeLine, 2)
UI.tabButtons = {}
for i, item in ipairs({{"painel", "Painel"}, {"pontos", "Pontos"}, {"ajustes", "Ajustes"}}) do
    local name = item[1]
    local b = button(UI.tabs, "Tab_" .. name, item[2], (i - 1) * 110 + 3, 3, 106, 34, C.card, function()
        S.tab = name
        U.animate(UI.tabIndicator, {Position = UDim2.fromOffset((i - 1) * 110 + 3, 3)}, 0.22)
        refresh()
    end)
    b.BackgroundTransparency = 1
    local outline = b:FindFirstChildOfClass("UIStroke")
    if outline then outline.Transparency = 1 end
    UI.tabButtons[name] = b
end
UI.pages, UI.fields = {}, {}
for _, name in ipairs({"painel", "pontos", "ajustes"}) do
    local page = make("ScrollingFrame", {Name = "Page_" .. name,
        Position = UDim2.fromOffset(18, 140), Size = UDim2.fromOffset(334, 322),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.fromOffset(0, 800),
        ScrollingDirection = Enum.ScrollingDirection.Y, Visible = name == "painel"}, UI.main)
    UI.pages[name] = page
end
UI.footer = frame(UI.main, "Footer", 18, 478, 334, 74, C.bg)
UI.footer.BackgroundTransparency = 1
UI.statusDot = frame(UI.footer, "StatusDot", 1, 3, 7, 7, C.muted)
round(UI.statusDot, 8)
UI.status = label(UI.footer, "Status", S.status, 16, -3, 318, 21, 11, C.muted)
UI.progressTrack = frame(UI.footer, "LimitProgress", 0, 20, 334, 3, C.raised)
round(UI.progressTrack, 2)
UI.progressTrack.Visible = false
UI.progressFill = frame(UI.progressTrack, "ProgressFill", 0, 0, 0, 3, C.accent)
round(UI.progressFill, 2)
UI.start = button(UI.footer, "Start", "Iniciar", 0, 28, 220, 46, C.accent, function()
    if S.mode == "idle" then start() elseif S.mode == "paused" then pause() else stop("Interrompido") end
end)
UI.start.TextColor3 = C.ink
UI.pause = button(UI.footer, "Pause", "Ⅱ", 228, 28, 48, 46, C.card, function() pause() end)
UI.stop = button(UI.footer, "Stop", "■", 284, 28, 50, 46, C.card, function() stop("Interrompido") end)
UI.stop.TextColor3 = C.danger

UI.mini = frame(UI.surface, "FloatingControls", 18, 18, 242, 66, C.bg)
UI.mini.Visible = false
UI.mini.ZIndex = 8
round(UI.mini, 20)
stroke(UI.mini, C.accent, 0.4)
UI.miniScale = make("UIScale", {Scale = 1}, UI.mini)
UI.miniOpen = button(UI.mini, "OpenPanel", "", 5, 5, 132, 56, C.bg, function()
    if clock() < S.miniSuppressUntil then return end
    if S.editing then finishEdit() else setMinimized(false) end
end)
UI.miniOpen.BackgroundTransparency = 1
UI.miniOpen:FindFirstChildOfClass("UIStroke").Transparency = 1
UI.miniDot = frame(UI.miniOpen, "LiveDot", 12, 12, 8, 8, C.accent)
round(UI.miniDot, 8)
UI.miniTitle = label(UI.miniOpen, "MiniTitle", "PULSE", 29, 5, 98, 20, 12, C.text, true)
UI.miniStats = label(UI.miniOpen, "MiniStats", "Abrir painel", 12, 29, 118, 18, 10, C.muted)
UI.miniToggle = button(UI.mini, "QuickPause", "▶", 140, 11, 43, 44, C.raised, function()
    if S.editing then finishEdit()
    elseif S.mode == "idle" then start()
    elseif S.mode == "countdown" then stop("Início cancelado")
    else pause() end
end)
UI.miniStop = button(UI.mini, "QuickStop", "■", 188, 11, 43, 44, C.card, function() stop("Interrompido") end)
UI.miniStop.TextColor3 = C.danger

UI.pickOverlay = make("TextButton", {Name = "PickSurface", Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.ink, BackgroundTransparency = 0.65, Text = "",
    BorderSizePixel = 0, AutoButtonColor = false, Visible = false, ZIndex = 20}, UI.surface)
UI.pickHud = frame(UI.surface, "PickInstructions", 0, 18, 322, 76, C.bg)
UI.pickHud.ZIndex = 21
UI.pickHud.Visible = false
round(UI.pickHud, 18)
stroke(UI.pickHud, C.accent, 0.1)
label(UI.pickHud, "PickTitle", "Toque no local do clique", 16, 10, 234, 22, 14, C.text, true)
label(UI.pickHud, "PickHelp", "O ponto será marcado ao soltar o dedo.", 16, 35, 265, 25, 10, C.muted)
button(UI.pickHud, "CancelPick", "×", 272, 14, 36, 38, C.card, function()
    S.picking = false
    S.pickInput = nil
    UI.pickOverlay.Visible = false
    UI.pickHud.Visible = false
    UI.main.Visible = not S.minimized
    UI.mini.Visible = S.minimized
    refresh()
end)
UI.toast = frame(UI.surface, "Notification", 0, 0, 330, 60, C.raised)
UI.toast.Visible = false
UI.toast.ZIndex = 30
round(UI.toast, 16)
stroke(UI.toast, C.border, 0.1)
UI.toastScale = make("UIScale", {Scale = 1}, UI.toast)
UI.toastText = label(UI.toast, "NotificationText", "", 14, 6, 302, 48, 12, C.text)
UI.toastText.TextWrapped = true
UI.toastText.TextTruncate = Enum.TextTruncate.None

local function numeric(target, key, title, hint, y, min, max, step)
    local row = frame(target, "Field_" .. key, 0, y, 330, 78, C.card)
    round(row, 14)
    label(row, "Name", title, 13, 8, 158, 23, 12, C.text, true)
    local explanation = label(row, "Hint", hint, 13, 32, 158, 37, 11, C.muted)
    explanation.TextWrapped = true
    explanation.TextTruncate = Enum.TextTruncate.None
    local box = make("TextBox", {Name = "Value", Position = UDim2.fromOffset(222, 16),
        Size = UDim2.fromOffset(62, 46), BackgroundColor3 = C.bg,
        Text = tostring(S.cfg[key]), TextColor3 = C.text, TextSize = 15,
        Font = Enum.Font.GothamMedium, BorderSizePixel = 0,
        ClearTextOnFocus = false}, row)
    round(box, 10)
    stroke(box, C.border, 0.4)
    UI.fields[key] = {box = box, min = min, max = max, fallback = S.cfg[key]}
    local function change(delta)
        if lockConfig() then return end
        S.cfg[key] = bounded(S.cfg[key] + delta, min, max, S.cfg[key])
        if key == "hold" then S.cfg.interval = math.max(S.cfg.interval, S.cfg.hold + 10) end
        if key == "interval" then S.cfg.hold = math.min(S.cfg.hold, S.cfg.interval - 10) end
        refresh()
    end
    button(row, "Decrease", "−", 176, 16, 40, 46, C.raised, function() change(-step) end)
    button(row, "Increase", "+", 290, 16, 36, 46, C.raised, function() change(step) end)
    box.FocusLost:Connect(function()
        if S.mode ~= "idle" or S.workerBusy then refresh() return end
        S.cfg[key] = bounded(box.Text, min, max, S.cfg[key])
        if key == "hold" then S.cfg.interval = math.max(S.cfg.interval, S.cfg.hold + 10) end
        if key == "interval" then S.cfg.hold = math.min(S.cfg.hold, S.cfg.interval - 10) end
        refresh()
    end)
end
local function toggle(target, key, title, hint, y)
    local row = frame(target, "Toggle_" .. key, 0, y, 330, 64, C.card)
    round(row, 14)
    label(row, "Name", title, 13, 8, 242, 20, 13, C.text, true)
    label(row, "Hint", hint, 13, 30, 242, 22, 10, C.muted)
    local track = button(row, "Switch", "", 268, 18, 47, 27, C.raised, function()
        if lockConfig() then return end
        S.cfg[key] = not S.cfg[key]
        refresh()
    end)
    round(track, 14)
    local knob = frame(track, "Knob", 4, 4, 19, 19, C.text)
    round(knob, 12)
    UI["switch_" .. key] = {track = track, knob = knob}
end

pulseStage("criando controles")
local dashboard = UI.pages.painel
local hero = frame(dashboard, "Hero", 0, 0, 330, 109, C.card)
round(hero, 18)
stroke(hero, C.accent, 0.75)
label(hero, "Eyebrow", "CONTROLE OS SEUS TOQUES", 15, 11, 302, 18, 10, C.accent, true)
UI.rate = label(hero, "Rate", "5.0", 15, 33, 110, 43, 34, C.text, true)
label(hero, "RateUnit", "passos / segundo", 121, 47, 195, 20, 12, C.muted)
UI.heroHint = label(hero, "TimingHint", "200 ms entre pontos · toque de 40 ms", 15, 81, 306, 18, 10, C.muted)
UI.stats = {}
for i, item in ipairs({{"count", "ENVIADOS"}, {"time", "TEMPO ATIVO"}, {"cycles", "CICLOS"}}) do
    local tile = frame(dashboard, "Stat_" .. item[1], (i - 1) * 113, 120, 104, 71, C.card)
    round(tile, 14)
    label(tile, "Caption", item[2], 10, 10, 85, 16, 8, C.muted, true)
    UI.stats[item[1]] = label(tile, "Metric", i == 2 and "00:00" or "0", 10, 31, 89, 30, 20, C.text, true)
end
section(dashboard, "RITMO", 205)
numeric(dashboard, "interval", "Intervalo entre pontos", "Milissegundos entre o início de cada passo.", 234, 50, 60000, 50)
for i, item in ipairs({{"Calmo", 1000}, {"Equilibrado", 200}, {"Rápido", 100}}) do
    button(dashboard, "Preset_" .. item[1], item[1], (i - 1) * 113, 323, 104, 39, C.raised, function()
        if lockConfig() then return end
        S.cfg.interval = item[2]
        S.cfg.hold = math.min(S.cfg.hold, S.cfg.interval - 10)
        refresh()
    end)
end
local targetCard = frame(dashboard, "TargetSummary", 0, 376, 330, 81, C.card)
round(targetCard, 14)
label(targetCard, "TargetCaption", "DESTINO DOS CLIQUES", 13, 9, 300, 16, 10, C.muted, true)
UI.targetSummary = label(targetCard, "Targets", "Nenhum ponto definido", 13, 31, 300, 24, 13, C.text, true)
UI.engineSummary = label(targetCard, "Engine", "Entrada: seleção automática", 13, 56, 300, 16, 10, C.muted)
button(dashboard, "GoToPoints", "+  Configurar pontos", 0, 468, 330, 44, C.raised, function()
    S.tab = "pontos"
    U.animate(UI.tabIndicator, {Position = UDim2.fromOffset(113, 3)}, 0.2)
    refresh()
end)
label(dashboard, "CounterHelp", "Enviados = pares de entrada aceitos pela API; o jogo pode tratar cada toque de outra forma.",
    4, 525, 321, 45, 10, C.muted).TextWrapped = true
dashboard.CanvasSize = UDim2.fromOffset(0, 580)

local pointsPage = UI.pages.pontos
section(pointsPage, "SELEÇÃO E SEQUÊNCIA", 0)
UI.singleMode = button(pointsPage, "SinglePointMode", "Um ponto", 0, 31, 160, 43, C.card, function()
    if lockConfig() then return end S.cfg.sequence = false refresh()
end)
UI.sequenceMode = button(pointsPage, "SequenceMode", "Sequência", 170, 31, 160, 43, C.card, function()
    if lockConfig() then return end S.cfg.sequence = true refresh()
end)
button(pointsPage, "AddPoint", "+  Adicionar", 0, 85, 160, 44, C.raised, function() beginPick(nil) end)
button(pointsPage, "DragPoints", "Mover alvos", 170, 85, 160, 44, C.raised, function()
    if lockConfig() then return end
    if #S.points == 0 then U.toast("Adicione um ponto primeiro.", C.amber) return end
    S.editing = true
    setMinimized(true)
    refresh()
    U.toast("Arraste os alvos. Toque em Concluir para voltar.")
end)
UI.selectedInfo = label(pointsPage, "SelectedInfo", "Selecione um ponto na lista.", 4, 140, 323, 24, 11, C.muted)
UI.pointGap = make("TextBox", {Name = "PointExtraWait", Position = UDim2.fromOffset(222, 173),
    Size = UDim2.fromOffset(103, 41), BackgroundColor3 = C.card, Text = "0",
    TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamMedium,
    ClearTextOnFocus = false, BorderSizePixel = 0}, pointsPage)
round(UI.pointGap, 10)
label(pointsPage, "ExtraWaitCaption", "Espera extra do ponto (ms)", 4, 171, 211, 22, 12, C.text)
label(pointsPage, "ExtraWaitHint", "Somada ao intervalo após esse ponto.", 4, 195, 211, 18, 9, C.muted)
UI.pointGap.FocusLost:Connect(function()
    if lockConfig() then refresh() return end
    local point = S.points[S.cfg.selected]
    if point then point.extra = bounded(UI.pointGap.Text, 0, 60000, point.extra or 0) end
    rebuildPoints() refresh()
end)
UI.pointList = frame(pointsPage, "PointList", 0, 230, 330, 1, C.card)
UI.pointList.BackgroundTransparency = 1

local settings = UI.pages.ajustes
section(settings, "MECÂNICA DO TOQUE", 0)
numeric(settings, "hold", "Duração do toque", "40 ms é um ponto de partida. Aumente para segurar.", 31, 10, 59990, 10)
numeric(settings, "startDelay", "Contagem antes de iniciar", "Segundos para preparar a tela; 0 inicia direto.", 120, 0, 60, 1)
toggle(settings, "double", "Clique duplo", "Dois toques por ponto; cada um entra na contagem.", 209)
numeric(settings, "doubleGap", "Intervalo do clique duplo", "Espera em ms entre soltar e pressionar novamente.", 284, 30, 5000, 10)
section(settings, "PARAR AUTOMATICAMENTE · 0 = SEM LIMITE", 377)
numeric(settings, "maxClicks", "Limite de cliques", "Conta os toques enviados, inclusive os duplos.", 408, 0, 1000000, 10)
numeric(settings, "maxSeconds", "Limite de tempo ativo", "Em segundos; o tempo pausado não é contado.", 497, 0, 86400, 10)
numeric(settings, "maxCycles", "Limite de ciclos", "Um ciclo percorre todos os pontos ativos.", 586, 0, 1000000, 1)
section(settings, "INTERFACE E COMPORTAMENTO", 679)
toggle(settings, "minimizeOnStart", "Minimizar ao iniciar", "Mantém o jogo livre com os controles flutuantes.", 710)
toggle(settings, "pauseOnFocus", "Pausar ao sair ou abrir menu", "Retome manualmente quando quiser continuar.", 785)
toggle(settings, "showMarkers", "Mostrar alvos ao configurar", "Os marcadores somem durante a execução.", 860)
toggle(settings, "animations", "Animações", "Transições suaves e resposta ao pressionar.", 935)
UI.engineMode = button(settings, "InputMode", "Entrada: Automático", 0, 1010, 330, 44, C.raised, function()
    if lockConfig() then return end
    local nextMode = {auto = "touch", touch = "mouse", mouse = "auto"}
    S.cfg.engine = nextMode[S.cfg.engine] or "auto"
    S.activeEngine = nil
    refresh()
end)
section(settings, "SEU PERFIL", 1070)
button(settings, "SaveProfile", "Salvar", 0, 1101, 104, 42, C.raised, function() U.saveProfile() end)
button(settings, "LoadProfile", "Ler", 113, 1101, 104, 42, C.raised, function() U.loadProfile() end)
button(settings, "ResetProfile", "Padrão", 226, 1101, 104, 42, C.raised, function()
    if lockConfig() then return end
    for k, v in pairs(defaults) do S.cfg[k] = v end
    S.activeEngine = nil
    refresh()
    U.toast("Ajustes restaurados. Os seus pontos foram mantidos.")
end)
label(settings, "ProfileHint", "Salvar/Ler depende das funções locais do Delta. O perfil guarda apenas ajustes e posições.",
    4, 1154, 321, 46, 10, C.muted).TextWrapped = true
UI.errorLabel = label(settings, "LastError", "", 4, 1210, 321, 74, 10, C.danger)
UI.errorLabel.TextWrapped = true
UI.errorLabel.TextTruncate = Enum.TextTruncate.None
settings.CanvasSize = UDim2.fromOffset(0, 1295)

function U.registerDrag(handle, onMove, onFinish)
    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch and
            input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if S.picking or S.drag then return end
        S.drag = {input = input, from = rawInput(input), move = onMove,
            finish = onFinish, moved = false}
    end)
end
local function clampPosition(object, x, y)
    local size = dimensions()
    local w, h = object.AbsoluteSize.X, object.AbsoluteSize.Y
    return Vector2.new(math.clamp(x, 8, math.max(8, size.X - w - 8)),
        math.clamp(y, 8, math.max(8, size.Y - h - 8)))
end
local function draggable(object, handle, finished)
    local origin
    U.registerDrag(handle, function(delta, first)
        if first then origin = rawPosition(object) end
        local p = clampPosition(object, origin.X + delta.X, origin.Y + delta.Y)
        object.Position = UDim2.fromOffset(p.X, p.Y)
    end, finished)
end
draggable(UI.main, UI.header)
draggable(UI.mini, UI.miniOpen, function(moved)
    if moved then S.miniSuppressUntil = clock() + 0.25 end
end)
connect(Input.InputChanged, function(input)
    local drag = S.drag
    if not drag then return end
    if input ~= drag.input and not (drag.input.UserInputType == Enum.UserInputType.MouseButton1
        and input.UserInputType == Enum.UserInputType.MouseMovement) then return end
    local delta = rawInput(input) - drag.from
    if delta.Magnitude < 6 and not drag.moved then return end
    local first = not drag.moved
    drag.moved = true
    drag.move(delta, first)
end)
connect(Input.InputEnded, function(input)
    if S.drag and input == S.drag.input then
        local drag = S.drag
        S.drag = nil
        if drag.finish then drag.finish(drag.moved) end
    end
    if not S.picking or input ~= S.pickInput then return end
    local pixels = rawInput(input)
    local size = dimensions()
    if contains(UI.pickHud, pixels) then S.pickInput = nil return end
    local chosen = {x = math.clamp(pixels.X / size.X, 0.001, 0.999),
        y = math.clamp(pixels.Y / size.Y, 0.001, 0.999), extra = 0}
    if S.pickReplace then
        chosen.extra = S.points[S.pickReplace].extra or 0
        S.points[S.pickReplace] = chosen
        S.cfg.selected = S.pickReplace
    else
        table.insert(S.points, chosen)
        S.cfg.selected = #S.points
    end
    S.picking, S.pickInput = false, nil
    UI.pickOverlay.Visible, UI.pickHud.Visible = false, false
    UI.main.Visible = not S.minimized
    UI.mini.Visible = S.minimized
    rebuildPoints() refresh()
    U.toast("Ponto " .. S.cfg.selected .. " definido.", C.mint)
end)
UI.pickOverlay.InputBegan:Connect(function(input)
    if not S.picking or S.pickInput then return end
    if input.UserInputType ~= Enum.UserInputType.Touch and
        input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if contains(UI.pickHud, rawInput(input)) then return end
    S.pickInput = input
end)

beginPick = function(replaceIndex)
    if lockConfig() then return end
    if not replaceIndex and #S.points >= 20 then U.toast("Limite de 20 pontos por sequência.", C.amber) return end
    S.picking, S.pickReplace, S.pickInput, S.editing = true, replaceIndex, nil, false
    UI.main.Visible, UI.mini.Visible = false, false
    UI.pickOverlay.Visible, UI.pickHud.Visible = true, true
    for _, marker in ipairs(S.markers) do marker.Visible = false end
end
finishEdit = function()
    S.editing = false
    setMinimized(false)
    rebuildPoints() refresh()
end
layoutMarkers = function()
    for i, marker in ipairs(S.markers) do
        local point = S.points[i]
        if point then
            local p = pointPixels(point)
            marker.Position = UDim2.fromOffset(p.X - 19, p.Y - 19)
            marker.Visible = not S.picking and S.mode == "idle" and
                (S.cfg.showMarkers or S.editing)
            marker.Active = S.editing
        end
    end
end
rebuildPoints = function()
    for _, item in ipairs(UI.pointList:GetChildren()) do item:Destroy() end
    for _, marker in ipairs(S.markers) do marker:Destroy() end
    S.markers = {}
    S.cfg.selected = math.clamp(S.cfg.selected, 1, math.max(1, #S.points))
    if #S.points == 0 then
        local empty = frame(UI.pointList, "EmptyPoints", 0, 0, 330, 127, C.card)
        round(empty, 16)
        label(empty, "EmptyTitle", "Seu primeiro ponto", 15, 16, 300, 26, 17, C.text, true)
        local help = label(empty, "EmptyHelp", "Toque em Adicionar e depois no lugar da tela em que deseja repetir os toques.",
            15, 50, 298, 62, 12, C.muted)
        help.TextWrapped, help.TextTruncate = true, Enum.TextTruncate.None
    end
    for i, point in ipairs(S.points) do
        local index = i
        local row = frame(UI.pointList, "Point_" .. i, 0, (i - 1) * 117, 330, 106, C.card)
        round(row, 14)
        if i == S.cfg.selected then stroke(row, C.accent, 0.15) end
        local choose = button(row, "Select", tostring(i), 9, 12, 42, 44, C.raised, function()
            if lockConfig() then return end S.cfg.selected = index rebuildPoints() refresh()
        end)
        choose.TextColor3 = C.accent
        local p = pointPixels(point)
        label(row, "Coordinates", string.format("x %d · y %d", p.X, p.Y), 63, 10, 206, 21, 12, C.text, true)
        label(row, "Wait", "+ " .. (point.extra or 0) .. " ms de espera", 63, 33, 206, 20, 11, C.muted)
        button(row, "Reposition", "Mover", 63, 57, 83, 42, C.raised, function() beginPick(index) end)
        button(row, "MoveUp", "↑", 155, 57, 49, 42, C.raised, function()
            if lockConfig() or index == 1 then return end
            S.points[index], S.points[index - 1] = S.points[index - 1], S.points[index]
            S.cfg.selected = index - 1 rebuildPoints() refresh()
        end)
        button(row, "Remove", "×", 278, 10, 43, 43, C.raised, function()
            if lockConfig() then return end table.remove(S.points, index) rebuildPoints() refresh()
        end).TextColor3 = C.danger
        button(row, "TestPoint", "Testar", 213, 57, 108, 42, C.raised, function() U.testPoint(index) end)
        local marker = frame(UI.surface, "Target_" .. i, 0, 0, 38, 38, C.bg)
        marker.ZIndex = 3
        marker.BackgroundTransparency = 0.10
        round(marker, 20)
        stroke(marker, i == S.cfg.selected and C.mint or C.accent, 0, 2)
        label(marker, "TargetNumber", tostring(i), 0, 0, 38, 38, 14, C.text, true).TextXAlignment = Enum.TextXAlignment.Center
        local origin
        U.registerDrag(marker, function(delta, first)
            if not S.editing then return end
            if first then origin = pointPixels(S.points[index]) end
            local size = dimensions()
            local moved = origin + delta
            S.points[index].x = math.clamp(moved.X / size.X, 0.001, 0.999)
            S.points[index].y = math.clamp(moved.Y / size.Y, 0.001, 0.999)
            S.cfg.selected = index
            layoutMarkers()
        end, function()
            if S.editing then S.cfg.selected = index refresh() end
        end)
        table.insert(S.markers, marker)
    end
    local height = math.max(127, #S.points * 117)
    UI.pointList.Size = UDim2.fromOffset(330, height)
    pointsPage.CanvasSize = UDim2.fromOffset(0, 242 + height)
    layoutMarkers()
end

setMinimized = function(value)
    if S.picking then return end
    S.minimized = value
    S.viewGeneration = S.viewGeneration + 1
    local version = S.viewGeneration
    if value then
        UI.mini.Visible = true
        UI.miniScale.Scale = S.cfg.animations and 0.88 or 1
        U.animate(UI.miniScale, {Scale = 1}, 0.24, Enum.EasingStyle.Back)
        U.animate(UI.mainScale, {Scale = 0.95}, 0.14)
        task.delay(S.cfg.animations and 0.15 or 0, function()
            if S.alive and S.viewGeneration == version then UI.main.Visible = false end
        end)
    else
        UI.mini.Visible = false
        UI.main.Visible = true
        UI.mainScale.Scale = S.cfg.animations and 0.94 or 1
        U.animate(UI.mainScale, {Scale = 1}, 0.24, Enum.EasingStyle.Back)
    end
end

local function method(object, key)
    if not object then return false end
    local ok, value = pcall(function() return object[key] end)
    return ok and type(value) == "function"
end
function U.discoverEngines()
    local engines = {}
    local ok, vim = pcall(function() return game:GetService("VirtualInputManager") end)
    if not ok then vim = nil end
    local function add(name, down, up)
        table.insert(engines, {name = name, down = down, up = up})
    end
    if S.cfg.engine ~= "mouse" and method(vim, "SendTouchEvent") then
        local touchId = 730000
        add("Toque virtual", function(p)
            touchId = touchId + 1
            vim:SendTouchEvent(touchId, Enum.UserInputState.Begin.Value, p.X, p.Y)
        end, function(p)
            vim:SendTouchEvent(touchId, Enum.UserInputState.End.Value, p.X, p.Y)
        end)
    end
    if S.cfg.engine ~= "touch" then
        local nativeOK, native = pcall(function() return Input:CreateVirtualInput() end)
        if nativeOK and method(native, "SendMouseButton") then
            add("VirtualInput", function(p)
                native:SendMousePosition(p)
                native:SendMouseButton(p, Enum.UserInputType.MouseButton1, true, 0)
            end, function(p)
                native:SendMouseButton(p, Enum.UserInputType.MouseButton1, false, 0)
            end)
        end
        if method(vim, "SendMouseButtonEvent") then
            add("Clique virtual", function(p)
                if method(vim, "SendMouseMoveEvent") then vim:SendMouseMoveEvent(p.X, p.Y, nil) end
                vim:SendMouseButtonEvent(p.X, p.Y, 0, true, nil, 0)
            end, function(p) vim:SendMouseButtonEvent(p.X, p.Y, 0, false, nil, 0) end)
        end
        if type(mousemoveabs) == "function" and type(mouse1press) == "function" and
            type(mouse1release) == "function" then
            add("Clique Delta", function(p) mousemoveabs(p.X, p.Y) mouse1press() end,
                function() mouse1release() end)
        end
    end
    S.engines, S.engineIndex, S.activeEngine = engines, 1, nil
end
local function releasePressed()
    local held = S.pressed
    if not held then return true end
    S.pressed = nil
    local ok, err = pcall(held.engine.up, held.position)
    if ok and held.sent then S.count = S.count + 1 end
    if not ok then S.lastError = tostring(err):sub(1, 260) end
    return ok
end
local function reachedLimit()
    if S.cfg.maxClicks > 0 and S.count >= S.cfg.maxClicks then return "Limite de cliques atingido" end
    if S.cfg.maxSeconds > 0 and activeSeconds() >= S.cfg.maxSeconds then return "Tempo concluído" end
    if S.cfg.maxCycles > 0 and S.cycles >= S.cfg.maxCycles then return "Ciclos concluídos" end
end
local function waitActive(seconds, generation, pauseAllowed, checkLimits)
    local remaining, before = seconds, clock()
    while remaining > 0 do
        if not S.alive or S.generation ~= generation or S.mode == "idle" then return false end
        if checkLimits and reachedLimit() then return false end
        if S.mode == "paused" and not pauseAllowed then return false end
        local now = clock()
        if S.mode == "running" then remaining = remaining - (now - before) end
        before = now
        task.wait(math.min(0.025, math.max(0.001, remaining)))
    end
    return S.alive and S.generation == generation and S.mode ~= "idle"
end
local function sendPair(point, generation)
    local position = pointPixels(point)
    if blocked(position) then return false, "Alvo coberto pelos controles. Mova ou minimize o painel." end
    local engine = S.activeEngine
    while not engine do
        engine = S.engines[S.engineIndex]
        if not engine then return false, "Esta versão do Delta não permitiu simular entradas." end
        local held = {engine = engine, position = position, sent = false}
        S.pressed = held
        local ok, err = pcall(engine.down, position)
        if ok then
            held.sent = true
            S.activeEngine = engine
        else
            pcall(engine.up, position)
            S.pressed = nil
            S.lastError = tostring(err):sub(1, 260)
            S.engineIndex = S.engineIndex + 1
            engine = nil
        end
    end
    if not S.pressed then
        S.pressed = {engine = engine, position = position, sent = false}
        local ok, err = pcall(engine.down, position)
        if not ok then
            pcall(engine.up, position)
            S.pressed = nil
            S.lastError = tostring(err):sub(1, 260)
            return false, "A API de entrada parou de responder. Veja Ajustes."
        end
        S.pressed.sent = true
    end
    waitActive(S.cfg.hold / 1000, generation, false, true)
    if not releasePressed() then return false, "Não foi possível soltar a entrada. Veja Ajustes." end
    return true
end
stop = function(message)
    if S.runSince then S.elapsed = activeSeconds() end
    S.runSince = nil
    S.generation = S.generation + 1
    S.mode = "idle"
    local released = releasePressed()
    S.status = released and (message or "Interrompido") or "Falha ao soltar a entrada"
    S.currentPoint, S.countdown = 0, 0
    if refresh then refresh() end
end
pause = function()
    if S.mode == "running" then
        S.elapsed = activeSeconds()
        S.runSince = nil
        S.mode = "paused"
        if not releasePressed() then stop("Falha ao pausar") return end
        S.status = "Pausado · toque para continuar"
    elseif S.mode == "paused" then
        S.mode = "running"
        S.runSince = clock()
        S.status = "Executando"
    end
    refresh()
end
local function commitFields()
    for key, field in pairs(UI.fields) do
        S.cfg[key] = bounded(field.box.Text, field.min, field.max, S.cfg[key])
    end
    S.cfg.interval = math.max(S.cfg.interval, S.cfg.hold + 10)
    local selected = S.points[S.cfg.selected]
    if selected then selected.extra = bounded(UI.pointGap.Text, 0, 60000, selected.extra or 0) end
    local focusOK, focused = pcall(function() return Input:GetFocusedTextBox() end)
    if not focusOK then focused = nil end
    if focused then focused:ReleaseFocus() end
end
start = function(testIndex)
    if S.mode ~= "idle" or S.workerBusy or S.picking then return end
    if #S.points == 0 then U.toast("Adicione pelo menos um ponto na aba Pontos.", C.amber) return end
    commitFields()
    S.editing = false
    local sequence = {}
    if testIndex then
        table.insert(sequence, {index = testIndex, point = S.points[testIndex]})
    elseif S.cfg.sequence then
        for i, point in ipairs(S.points) do table.insert(sequence, {index = i, point = point}) end
    else
        table.insert(sequence, {index = S.cfg.selected, point = S.points[S.cfg.selected]})
    end
    U.discoverEngines()
    if #S.engines == 0 then U.toast("Nenhuma API de entrada disponível no Delta.", C.danger) return end
    S.generation = S.generation + 1
    local generation = S.generation
    S.count, S.cycles, S.elapsed, S.lastError = 0, 0, 0, ""
    S.currentPoint = 0
    S.mode, S.status, S.workerBusy = "countdown", "Preparando", true
    if S.cfg.minimizeOnStart or testIndex then setMinimized(true) end
    refresh()
    task.spawn(function()
        local ok, unexpected = pcall(function()
            local deadline = clock() + (testIndex and 1 or S.cfg.startDelay)
            -- Aguarda também a animação do painel, sem atrasar os cliques seguintes.
            if S.minimized then deadline = math.max(deadline, clock() + 0.20) end
            while clock() < deadline do
                if not S.alive or S.generation ~= generation then return end
                local remaining = math.ceil(deadline - clock())
                if remaining ~= S.countdown then
                    S.countdown = remaining
                    S.status = "Iniciando em " .. remaining .. "..."
                    refresh()
                end
                task.wait(0.05)
            end
            if not S.alive or S.generation ~= generation then return end
            S.mode, S.status, S.runSince = "running", "Executando", clock()
            refresh()
            local index = 1
            while S.alive and S.generation == generation do
                if S.mode == "paused" then task.wait(0.05)
                elseif S.mode == "running" then
                    local limit = reachedLimit()
                    if limit then stop(limit) break end
                    local step = sequence[index]
                    S.currentPoint = step.index
                    local began = activeSeconds()
                    local repeats = (S.cfg.double and not testIndex) and 2 or 1
                    local completedTaps = 0
                    for tap = 1, repeats do
                        if reachedLimit() or S.generation ~= generation then break end
                        if S.mode == "paused" then
                            while S.mode == "paused" and S.generation == generation do task.wait(0.05) end
                        end
                        if S.generation ~= generation then break end
                        local sent, reason = sendPair(step.point, generation)
                        if not sent then stop(reason) U.toast(reason, C.danger) break end
                        completedTaps = completedTaps + 1
                        if tap < repeats then waitActive(S.cfg.doubleGap / 1000, generation, true, true) end
                    end
                    if S.generation ~= generation then break end
                    if index == #sequence and completedTaps == repeats then S.cycles = S.cycles + 1 end
                    if testIndex then stop("Teste enviado · confira o efeito no jogo") break end
                    index = index % #sequence + 1
                    local after = reachedLimit()
                    if after then stop(after) break end
                    local elapsed = activeSeconds() - began
                    local spacing = math.max(0.01, S.cfg.interval / 1000 - elapsed) + (step.point.extra or 0) / 1000
                    waitActive(spacing, generation, true, true)
                else break end
            end
        end)
        if not ok and S.alive and S.generation == generation then
            S.lastError = tostring(unexpected):sub(1, 260)
            stop("Erro de execução · veja Ajustes")
            U.toast("A execução foi interrompida. Veja o erro em Ajustes.", C.danger)
        end
        releasePressed()
        S.workerBusy = false
        if S.alive then refresh() end
    end)
end
function U.testPoint(index)
    if lockConfig() then return end
    start(index)
end

function U.saveProfile()
    if lockConfig() then return end
    if type(writefile) ~= "function" then U.toast("O Delta não disponibilizou gravação local.", C.amber) return end
    commitFields()
    local ok, err = pcall(function()
        writefile("PulseAutoClick.json", Http:JSONEncode({version = 1, config = S.cfg, points = S.points}))
    end)
    if ok then U.toast("Perfil salvo neste executor.", C.mint)
    else S.lastError = tostring(err):sub(1, 260) U.toast("Não foi possível salvar o perfil.", C.danger) end
    refresh()
end
function U.loadProfile()
    if lockConfig() then return end
    if type(readfile) ~= "function" then U.toast("O Delta não disponibilizou leitura local.", C.amber) return end
    local ok, data = pcall(function() return Http:JSONDecode(readfile("PulseAutoClick.json")) end)
    if not ok or type(data) ~= "table" or data.version ~= 1 or type(data.config) ~= "table"
        or type(data.points) ~= "table" then U.toast("Nenhum perfil válido encontrado.", C.amber) return end
    local config, points = {}, {}
    for key, value in pairs(defaults) do
        config[key] = value
        if type(value) == "boolean" and type(data.config[key]) == "boolean" then config[key] = data.config[key] end
    end
    for key, field in pairs(UI.fields) do
        config[key] = bounded(data.config[key], field.min, field.max, defaults[key])
    end
    config.interval = math.max(config.interval, config.hold + 10)
    if data.config.engine == "touch" or data.config.engine == "mouse" then config.engine = data.config.engine end
    for _, point in ipairs(data.points) do
        if #points >= 20 then break end
        if type(point) == "table" and finite(point.x) and finite(point.y) then
            table.insert(points, {x = math.clamp(point.x, 0.001, 0.999),
                y = math.clamp(point.y, 0.001, 0.999), extra = bounded(point.extra, 0, 60000, 0)})
        end
    end
    config.selected = bounded(data.config.selected, 1, math.max(1, #points), 1)
    S.cfg, S.points, S.activeEngine = config, points, nil
    rebuildPoints() refresh()
    U.toast("Perfil carregado. Confira os pontos antes de iniciar.", C.mint)
end

function U.updateProgress()
    local fraction, limited = 0, false
    for _, limit in ipairs({{S.cfg.maxClicks, S.count}, {S.cfg.maxSeconds, activeSeconds()},
        {S.cfg.maxCycles, S.cycles}}) do
        if limit[1] > 0 then limited = true fraction = math.max(fraction, limit[2] / limit[1]) end
    end
    UI.progressTrack.Visible = limited
    UI.progressFill.Size = UDim2.fromOffset(334 * math.clamp(fraction, 0, 1), 3)
end
local function focusedTextBox()
    local ok, value = pcall(function() return Input:GetFocusedTextBox() end)
    return ok and value or nil
end
refresh = function()
    if not S.alive then return end
    local stateColor = S.mode == "running" and C.mint or
        ((S.mode == "paused" or S.mode == "countdown") and C.amber or C.muted)
    UI.status.Text = S.status
    UI.status.TextColor3 = stateColor
    UI.statusDot.BackgroundColor3 = stateColor
    UI.miniDot.BackgroundColor3 = stateColor
    UI.rate.Text = string.format("%.1f", 1000 / S.cfg.interval)
    UI.heroHint.Text = S.cfg.interval .. " ms entre pontos · toque de " .. S.cfg.hold .. " ms"
    UI.stats.count.Text = tostring(S.count)
    UI.stats.time.Text = formatTime(activeSeconds())
    UI.stats.cycles.Text = tostring(S.cycles)
    UI.targetSummary.Text = #S.points == 0 and "Nenhum ponto definido" or
        (S.cfg.sequence and ("Sequência com " .. #S.points .. " ponto(s)") or ("Somente ponto " .. S.cfg.selected))
    UI.engineSummary.Text = "Entrada: " .. (S.activeEngine and S.activeEngine.name or "seleção automática")
    UI.start.Text = S.mode == "idle" and (S.workerBusy and "Aguarde..." or "▶   Iniciar") or
        (S.mode == "paused" and "▶   Continuar" or (S.mode == "countdown" and "Cancelar início" or "■   Parar"))
    UI.pause.Text = S.mode == "paused" and "▶" or "Ⅱ"
    UI.miniToggle.Text = S.editing and "✓" or ((S.mode == "running") and "Ⅱ" or
        (S.mode == "countdown" and "×" or "▶"))
    UI.miniTitle.Text = S.editing and "CONCLUIR" or "PULSE"
    UI.miniStats.Text = S.editing and "Arraste os alvos" or (S.mode == "countdown" and
        ("Iniciando em " .. S.countdown) or (S.count .. " toques · " .. formatTime(activeSeconds())))
    for name, page in pairs(UI.pages) do page.Visible = name == S.tab end
    for name, tab in pairs(UI.tabButtons) do tab.TextColor3 = name == S.tab and C.text or C.muted end
    if not focusedTextBox() then
        for key, field in pairs(UI.fields) do field.box.Text = tostring(S.cfg[key]) end
        local point = S.points[S.cfg.selected]
        UI.pointGap.Text = tostring(point and point.extra or 0)
    end
    UI.singleMode.TextColor3 = not S.cfg.sequence and C.accent or C.muted
    UI.sequenceMode.TextColor3 = S.cfg.sequence and C.accent or C.muted
    local selected = S.points[S.cfg.selected]
    UI.selectedInfo.Text = selected and ("Selecionado: ponto " .. S.cfg.selected .. " · toque no número para trocar") or
        "Selecione um ponto na lista."
    for key in pairs(defaults) do
        local switch = UI["switch_" .. key]
        if switch then
            U.animate(switch.track, {BackgroundColor3 = S.cfg[key] and C.accent or C.raised}, 0.14)
            U.animate(switch.knob, {Position = UDim2.fromOffset(S.cfg[key] and 24 or 4, 4)}, 0.18)
        end
    end
    local modeName = {auto = "Automático", touch = "Toque", mouse = "Clique"}
    UI.engineMode.Text = "Entrada: " .. (modeName[S.cfg.engine] or "Automático") .. "  ›"
    UI.errorLabel.Text = S.lastError ~= "" and ("Último retorno da API: " .. S.lastError) or
        "Se a API enviar entradas sem efeito, teste o modo Toque ou Clique e use Testar para conferir."
    U.updateProgress()
    layoutMarkers()
end

function U.layout()
    local size = dimensions()
    local width = math.min(370, math.max(300, size.X - 28))
    local height = math.min(566, math.max(280, size.Y - 28))
    UI.main.Size = UDim2.fromOffset(width, height)
    UI.header.Size = UDim2.fromOffset(width, 78)
    UI.headerLine.Size = UDim2.fromOffset(width - 36, 1)
    UI.minimize.Position = UDim2.fromOffset(width - 92, 19)
    UI.close.Position = UDim2.fromOffset(width - 52, 19)
    -- A área de conteúdo rola na vertical; largura menor recebe escala proporcional.
    local contentScale = math.min(1, (width - 36) / 334)
    UI.tabs.Size = UDim2.fromOffset(334, 40)
    local tabsScale = UI.tabs:FindFirstChildOfClass("UIScale") or make("UIScale", {}, UI.tabs)
    tabsScale.Scale = contentScale
    local footerY = height - 18 - 74 * contentScale
    for _, page in pairs(UI.pages) do
        page.Size = UDim2.fromOffset(334, (footerY - 152) / contentScale)
        local pageScale = page:FindFirstChildOfClass("UIScale") or make("UIScale", {}, page)
        pageScale.Scale = contentScale
    end
    UI.footer.Position = UDim2.fromOffset(18, footerY)
    local footerScale = UI.footer:FindFirstChildOfClass("UIScale") or make("UIScale", {}, UI.footer)
    footerScale.Scale = contentScale
    local pos = clampPosition(UI.main, UI.main.Position.X.Offset, UI.main.Position.Y.Offset)
    UI.main.Position = UDim2.fromOffset(pos.X, pos.Y)
    local mini = clampPosition(UI.mini, UI.mini.Position.X.Offset, UI.mini.Position.Y.Offset)
    UI.mini.Position = UDim2.fromOffset(mini.X, mini.Y)
    UI.pickHud.Position = UDim2.fromOffset(math.max(8, (size.X - 322) / 2), 16)
    UI.toast.Position = UDim2.fromOffset(math.max(8, (size.X - 330) / 2), math.max(8, size.Y - 82))
    layoutMarkers()
end
shutdown = function(alreadyDestroying)
    if not S.alive then return end
    stop("Encerrado")
    S.alive = false
    S.drag = nil
    for _, connection in ipairs(S.connections) do connection:Disconnect() end
    S.connections = {}
    for _, animation in pairs(activeTweens) do animation:Cancel() end
    if not alreadyDestroying and UI.gui.Parent then UI.gui:Destroy() end
end
connect(UI.closer.Event, shutdown)
connect(UI.gui.Destroying, function() shutdown(true) end)
local function optionalEvent(source, name, callback)
    local ok, err = pcall(function() connect(source[name], callback) end)
    if not ok then pulseReport("Aviso: evento " .. name .. " indisponível: " .. tostring(err)) end
end
optionalEvent(Input, "WindowFocusReleased", function()
    if S.cfg.pauseOnFocus then
        if S.mode == "running" then pause()
        elseif S.mode == "countdown" then stop("Início cancelado ao sair") end
    end
end)
optionalEvent(GuiService, "MenuOpened", function()
    if S.cfg.pauseOnFocus then
        if S.mode == "running" then pause()
        elseif S.mode == "countdown" then stop("Início cancelado pelo menu") end
    end
end)
connect(UI.surface:GetPropertyChangedSignal("AbsoluteSize"), function()
    if S.mode ~= "idle" then stop("Tela mudou · confira os pontos") end
    U.layout()
    rebuildPoints() refresh()
end)
pulseStage("ajustando tela")
U.layout()
rebuildPoints()
refresh()
UI.mainScale.Scale = S.cfg.animations and 0.94 or 1
U.animate(UI.mainScale, {Scale = 1}, 0.30, Enum.EasingStyle.Back)
for _, delay in ipairs({0.15, 0.5, 1}) do
    task.delay(delay, function()
        if S.alive and S.mode == "idle" then U.layout() refresh() end
    end)
end
task.spawn(function()
    while S.alive do
        if S.mode ~= "idle" then
            UI.stats.count.Text = tostring(S.count)
            UI.stats.time.Text = formatTime(activeSeconds())
            UI.stats.cycles.Text = tostring(S.cycles)
            UI.miniStats.Text = S.mode == "countdown" and ("Iniciando em " .. S.countdown) or
                (S.count .. " toques · " .. formatTime(activeSeconds()))
            UI.engineSummary.Text = "Entrada: " .. (S.activeEngine and S.activeEngine.name or "seleção automática")
            U.updateProgress()
        end
        task.wait(0.15)
    end
end)
-- PULSE_INIT_END
end, pulseTrace)
if PulseOK then
    if PulseBootstrap.reportGui then pcall(function() PulseBootstrap.reportGui:Destroy() end) end
    PulseBootstrap.reportGui, PulseBootstrap.reportLabel = nil, nil
    pulseReport("Painel pronto. Feche o editor do Delta para visualizar.")
else
    if PulseBootstrap.appGui then pcall(function() PulseBootstrap.appGui:Destroy() end) end
    pulseReport("Falha na etapa " .. PulseBootstrap.phase .. ":\n" .. tostring(PulseResult), true)
end
