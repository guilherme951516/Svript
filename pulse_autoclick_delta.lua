-- PULSE AUTOCLICK 1.1.0 | Delta mobile
-- Velocidade de 1 a 1000 CPS; 100 CPS ao abrir. Clique duplo conta dois cliques.
-- Escolher ponto > tocar na tela > Iniciar. O cursor marca os pixels enviados.
-- Botão ↔: mostra a alça ↘ para redimensionar. Arraste PULSE para mover.
-- Repete apenas entradas de clique/toque; sem remotes ou código externo.
-- A taxa reconhecida pelo jogo depende do executor, dos FPS e do próprio jogo.
-- Diagnóstico: mensagens [PULSE 1.1.0] no console do Delta.

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
    local text = "[PULSE 1.1.0] " .. tostring(message)
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

local Run = game:GetService("RunService")
local C = {
    bg = Color3.fromRGB(22, 24, 23), card = Color3.fromRGB(31, 34, 32),
    raised = Color3.fromRGB(43, 47, 44), border = Color3.fromRGB(66, 73, 66),
    text = Color3.fromRGB(244, 243, 235), muted = Color3.fromRGB(160, 168, 158),
    accent = Color3.fromRGB(216, 241, 134), mint = Color3.fromRGB(146, 225, 182),
    danger = Color3.fromRGB(247, 149, 131), ink = Color3.fromRGB(22, 29, 20),
}
local WIDTH, HEIGHT = 286, 326
local MIN_SCALE, MAX_SCALE, MAX_CPS, FRAME_CLICKS = 0.60, 1.40, 1000, 32
local S = {
    alive = true, mode = "idle", minimized = false, resizing = false,
    cfg = {cps = 100, double = false, scale = 0.85}, point = nil,
    count = 0, liveCps = 0, credit = 0, tickBusy = false, generation = 0,
    pressed = nil, activeEngine = nil, engines = {}, engineIndex = 1,
    connections = {}, drag = nil, picking = false, pickInput = nil,
    cursorAt = nil, lastClick = -1, sampleAt = 0, sampleCount = 0,
    status = "Escolha o ponto do clique", lastError = "", toastId = 0,
    miniSuppressUntil = 0, viewId = 0, sliderDrag = nil,
}
local UI, U = {}, {}
local refresh, start, stop, pause, beginPick, setMinimized, shutdown
local tweens = setmetatable({}, {__mode = "k"})
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
        if not ok then object:Destroy() error("Falha em " .. class .. "." .. key .. ": " .. tostring(err), 0) end
    end
    object.Parent = target
    return object
end
local function frame(target, name, x, y, w, h, color)
    return make("Frame", {Name = name, Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h), BackgroundColor3 = color or C.card,
        BorderSizePixel = 0, Active = false}, target)
end
local function round(object, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, object)
end
local function stroke(object, color, transparency, thickness)
    return make("UIStroke", {Color = color or C.border, Transparency = transparency or 0.5,
        Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, object)
end
local function label(target, name, text, x, y, w, h, size, color, bold)
    return make("TextLabel", {Name = name, Text = text, Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1,
        TextColor3 = color or C.text, TextSize = size or 13,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd, Active = false}, target)
end
function U.animate(object, properties, seconds)
    local old = tweens[object]
    if old then old:Cancel() end
    local animation = Tween:Create(object, TweenInfo.new(seconds or 0.18,
        Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties)
    tweens[object] = animation
    animation:Play()
end
local function button(target, name, text, x, y, w, h, color, callback)
    local object = make("TextButton", {Name = name, Text = text,
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
        BackgroundColor3 = color or C.raised, TextColor3 = C.text,
        BorderSizePixel = 0, AutoButtonColor = false, TextSize = 13,
        Font = Enum.Font.GothamMedium, ClipsDescendants = true}, target)
    round(object, 10)
    connect(object.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            U.animate(object, {BackgroundTransparency = 0.18}, 0.08)
        end
    end)
    connect(object.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            U.animate(object, {BackgroundTransparency = 0}, 0.12)
        end
    end)
    connect(object.Activated, function() if S.alive and callback then callback() end end)
    return object
end
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
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
local function rawInput(input)
    local p, origin = input.Position, UI.surface.AbsolutePosition
    return Vector2.new(p.X - origin.X, p.Y - origin.Y)
end
local function rawPosition(object) return object.AbsolutePosition - UI.surface.AbsolutePosition end
local function contains(object, p)
    if not object.Visible then return false end
    local pos, size = rawPosition(object), object.AbsoluteSize
    return p.X >= pos.X and p.Y >= pos.Y and p.X <= pos.X + size.X and p.Y <= pos.Y + size.Y
end
local function pointPixels()
    if not S.point then return nil end
    local size = dimensions()
    return Vector2.new(math.clamp(math.floor(S.point.x * size.X + 0.5), 1, size.X - 1),
        math.clamp(math.floor(S.point.y * size.Y + 0.5), 1, size.Y - 1))
end
local function clampPosition(object, x, y)
    local view, size = dimensions(), object.AbsoluteSize
    return Vector2.new(math.clamp(x, 8, math.max(8, view.X - size.X - 8)),
        math.clamp(y, 8, math.max(8, view.Y - size.Y - 8)))
end
local function blocked(p) return contains(UI.main, p) or contains(UI.mini, p) end
local function focusedTextBox()
    local ok, value = pcall(function() return Input:GetFocusedTextBox() end)
    return ok and value or nil
end
function U.toast(text, color)
    S.toastId = S.toastId + 1
    local id = S.toastId
    UI.toastText.Text, UI.toastText.TextColor3 = text, color or C.text
    UI.toast.Visible = true
    task.delay(3, function() if S.alive and id == S.toastId then UI.toast.Visible = false end end)
end

UI.gui = make("ScreenGui", {Name = "PulseAutoClick", ResetOnSpawn = false,
    IgnoreGuiInset = true, DisplayOrder = 2147483646, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, parent)
PulseBootstrap.appGui = UI.gui
pcall(function() UI.gui.ScreenInsets = Enum.ScreenInsets.None end)
UI.closer = make("BindableEvent", {Name = "ClosePulse"}, UI.gui)
UI.surface = frame(UI.gui, "Surface", 0, 0, 1, 1, C.bg)
UI.surface.Size, UI.surface.BackgroundTransparency = UDim2.fromScale(1, 1), 1

UI.main = frame(UI.surface, "Panel", 24, 30, WIDTH, HEIGHT, C.bg)
round(UI.main, 18) stroke(UI.main, C.border, 0.32)
UI.mainScale = make("UIScale", {Scale = S.cfg.scale}, UI.main)
UI.body = frame(UI.main, "Content", 0, 0, WIDTH, HEIGHT, C.bg)
UI.body.BackgroundTransparency = 1
UI.bodyScale = make("UIScale", {Scale = 1}, UI.body)

UI.headerDrag = button(UI.body, "DragHeader", "", 10, 8, 150, 32, C.bg, nil)
UI.headerDrag.BackgroundTransparency = 1
local logo = frame(UI.headerDrag, "Logo", 4, 4, 26, 26, C.accent)
round(logo, 9)
local logoRing = frame(logo, "LogoRing", 6, 6, 14, 14, C.accent)
logoRing.BackgroundTransparency = 1 round(logoRing, 7) stroke(logoRing, C.ink, 0, 1.5)
round(frame(logo, "LogoDot", 11, 11, 4, 4, C.ink), 2)
label(UI.headerDrag, "Brand", "PULSE", 39, 0, 106, 32, 16, C.text, true)
UI.resizeButton = button(UI.body, "Redimensionar", "↔", 172, 8, 30, 32, C.card, function()
    S.resizing = not S.resizing refresh()
end)
UI.resizeButton.TextSize = 20
UI.minimize = button(UI.body, "Minimize", "−", 210, 8, 30, 32, C.card, function() setMinimized(true) end)
UI.minimize.TextSize = 20
UI.close = button(UI.body, "Close", "×", 248, 8, 28, 32, C.card, function() shutdown() end)
UI.close.TextSize, UI.close.TextColor3 = 20, C.muted
frame(UI.body, "HeaderLine", 14, 47, 258, 1, C.raised)

label(UI.body, "SpeedLabel", "Velocidade", 18, 58, 174, 18, 12, C.muted)
UI.speed = make("TextBox", {Name = "CPS", Position = UDim2.fromOffset(14, 77),
    Size = UDim2.fromOffset(108, 42), Text = "100", ClearTextOnFocus = false,
    BackgroundTransparency = 1, BorderSizePixel = 0, TextColor3 = C.text,
    TextSize = 34, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}, UI.body)
label(UI.body, "CPSUnit", "CPS", 124, 94, 48, 20, 13, C.accent, true)
UI.minus = button(UI.body, "Slower", "−", 190, 83, 34, 36, C.card, function() U.setCps(S.cfg.cps - 10) end)
UI.plus = button(UI.body, "Faster", "+", 234, 83, 38, 36, C.card, function() U.setCps(S.cfg.cps + 10) end)
UI.minus.TextSize, UI.plus.TextSize = 21, 21
UI.speedHit = button(UI.body, "SpeedSlider", "", 14, 126, 258, 22, C.bg, nil)
UI.speedHit.BackgroundTransparency = 1
UI.track = frame(UI.speedHit, "SpeedTrack", 4, 9, 250, 4, C.raised) round(UI.track, 2)
UI.fill = frame(UI.track, "SpeedFill", 0, 0, 1, 4, C.accent) round(UI.fill, 2)
UI.knob = frame(UI.speedHit, "SpeedKnob", 0, 2, 18, 18, C.accent) round(UI.knob, 9)

UI.double = button(UI.body, "DoubleClick", "", 14, 158, 258, 34, C.card, function()
    S.cfg.double = not S.cfg.double S.credit = 0 refresh()
end)
label(UI.double, "DoubleLabel", "Clique duplo", 12, 4, 174, 26, 13, C.text)
UI.switch = frame(UI.double, "DoubleSwitch", 208, 8, 38, 18, C.raised) round(UI.switch, 9)
UI.switchDot = frame(UI.switch, "DoubleKnob", 2, 2, 14, 14, C.muted) round(UI.switchDot, 7)
UI.target = button(UI.body, "ChoosePoint", "Escolher ponto", 14, 202, 258, 36, C.card, function() beginPick() end)
UI.go = button(UI.body, "StartPause", "Iniciar", 14, 250, 196, 38, C.accent, function()
    if S.mode == "idle" then start() else pause() end
end)
UI.go.TextColor3 = C.ink
UI.stop = button(UI.body, "Stop", "■", 218, 250, 54, 38, C.card, function() stop("Parado") end)
UI.stop.TextColor3 = C.danger
UI.footer = label(UI.body, "Status", S.status, 16, 295, 250, 18, 11, C.muted)
UI.resizeHint = label(UI.body, "ResizeHint", "", 16, 295, 223, 18, 11, C.accent)
UI.resizeHint.Visible = false
UI.resizeHandle = button(UI.body, "ResizeHandle", "↘", 250, 292, 32, 30, C.raised, nil)
UI.resizeHandle.TextSize, UI.resizeHandle.TextColor3 = 22, C.accent
UI.resizeHandle.Visible = false

UI.mini = frame(UI.surface, "Mini", 18, 24, 174, 44, C.bg)
UI.mini.Visible = false round(UI.mini, 15) stroke(UI.mini, C.border, 0.28)
UI.miniOpen = button(UI.mini, "OpenPanel", "", 3, 3, 84, 38, C.bg, function()
    if clock() < S.miniSuppressUntil then return end
    if S.mode == "running" then pause() end
    setMinimized(false)
end)
label(UI.miniOpen, "MiniBrand", "PULSE", 10, 0, 72, 20, 11, C.text, true)
UI.miniRate = label(UI.miniOpen, "MiniRate", "100 CPS", 10, 19, 72, 16, 11, C.accent)
UI.miniPause = button(UI.mini, "MiniPause", "II", 91, 6, 33, 32, C.accent, function()
    if S.mode == "idle" then start() else pause() end
end)
UI.miniPause.TextColor3 = C.ink
UI.miniStop = button(UI.mini, "MiniStop", "■", 131, 6, 33, 32, C.card, function() stop("Parado") end)
UI.miniStop.TextColor3 = C.danger

-- A passive cursor sits at the same viewport pixels sent to the input API.
UI.cursor = frame(UI.surface, "ClickCursor", 0, 0, 1, 1, C.text)
UI.cursor.BackgroundTransparency, UI.cursor.Visible, UI.cursor.ZIndex = 1, false, 50
UI.cursorScale = make("UIScale", {Scale = 1.25}, UI.cursor)
UI.ring = frame(UI.cursor, "ClickRing", -9, -9, 18, 18, C.accent)
UI.ring.BackgroundTransparency = 1 round(UI.ring, 999)
UI.ringStroke = stroke(UI.ring, C.accent, 0.4, 1.3)
local function polygon(target, name, points, color, ox, oy)
    local lastY = 0
    for _, p in ipairs(points) do lastY = math.max(lastY, p[2]) end
    for row = 0, math.ceil(lastY) - 1 do
        local y, edges = row + 0.5, {}
        for i, a in ipairs(points) do
            local b = points[i % #points + 1]
            if (a[2] <= y and b[2] > y) or (b[2] <= y and a[2] > y) then
                edges[#edges + 1] = a[1] + (y - a[2]) * (b[1] - a[1]) / (b[2] - a[2])
            end
        end
        table.sort(edges)
        for i = 1, #edges - 1, 2 do
            local left, right = math.floor(edges[i]), math.ceil(edges[i + 1])
            if right > left then
                local strip = frame(target, name .. row .. "_" .. i, ox + left, oy + row, right - left, 1, color)
                strip.ZIndex = 52
            end
        end
    end
end
local outline = {{0, 0}, {0, 20}, {5.4, 14.3}, {9, 22}, {12, 20.5}, {8.7, 13}, {17, 13}}
local inside = {{1.5, 3.5}, {1.5, 16.3}, {5.6, 11.9}, {9.5, 20.3}, {10, 20}, {6.9, 11.5}, {13.5, 11.5}}
polygon(UI.cursor, "CursorShadow", outline, C.ink, 1, 2)
polygon(UI.cursor, "CursorBorder", outline, C.ink, 0, 0)
polygon(UI.cursor, "CursorFill", inside, C.text, 0, 0)

UI.pickOverlay = frame(UI.surface, "PickOverlay", 0, 0, 1, 1, C.bg)
UI.pickOverlay.Size = UDim2.fromScale(1, 1)
UI.pickOverlay.BackgroundTransparency, UI.pickOverlay.Active, UI.pickOverlay.Visible = 0.86, true, false
UI.pickOverlay.ZIndex = 60
UI.pickHud = frame(UI.surface, "PickHUD", 0, 16, 278, 62, C.bg)
UI.pickHud.Visible, UI.pickHud.ZIndex = false, 65 round(UI.pickHud, 14) stroke(UI.pickHud)
label(UI.pickHud, "PickTitle", "Toque onde quer clicar", 12, 7, 211, 23, 13, C.text, true)
label(UI.pickHud, "PickCaption", "O cursor vai marcar esse ponto.", 12, 31, 211, 20, 11, C.muted)
UI.cancelPick = button(UI.pickHud, "CancelPick", "×", 238, 13, 30, 34, C.card, function() U.cancelPick() end)
UI.cancelPick.TextSize = 22
UI.toast = frame(UI.surface, "Toast", 0, 0, 278, 52, C.bg)
UI.toast.Visible, UI.toast.ZIndex = false, 70 round(UI.toast, 13) stroke(UI.toast)
UI.toastText = label(UI.toast, "ToastText", "", 12, 4, 254, 44, 12, C.text)
UI.toastText.TextWrapped, UI.toastText.TextTruncate = true, Enum.TextTruncate.None

function U.setCps(value)
    local previous = S.cfg.cps
    local text = tostring(value):gsub(",", ".")
    value = tonumber(text)
    if not finite(value) then value = previous end
    S.cfg.cps = math.clamp(math.floor(value + 0.5), 1, MAX_CPS)
    if S.cfg.cps ~= previous then S.credit = 0 end
    refresh()
end
connect(UI.speed.FocusLost, function() U.setCps(UI.speed.Text) end)
function U.setScale(value)
    if not finite(value) then return end
    S.cfg.scale = math.clamp(value, MIN_SCALE, MAX_SCALE)
    U.layout() refresh()
end
function U.updateCursor()
    local p = (S.mode == "running" and S.cursorAt) or pointPixels()
    UI.cursor.Visible = p ~= nil and not S.picking
    if not p then return end
    UI.cursor.Position = UDim2.fromOffset(p.X, p.Y)
    local phase = S.mode == "running" and ((clock() * 2.5) % 1) or 0
    local radius = 9 + phase * 5
    UI.ring.Position, UI.ring.Size = UDim2.fromOffset(-radius, -radius), UDim2.fromOffset(radius * 2, radius * 2)
    UI.ringStroke.Transparency = S.mode == "running" and (0.25 + phase * 0.65) or 0.55
end
function U.registerDrag(handle, move, finish)
    connect(handle.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if S.picking or S.drag then return end
        S.drag = {input = input, from = rawInput(input), move = move, finish = finish, moved = false}
    end)
end
local function draggable(object, handle, finish)
    local origin
    U.registerDrag(handle, function(delta, first)
        if first then origin = rawPosition(object) end
        local p = clampPosition(object, origin.X + delta.X, origin.Y + delta.Y)
        object.Position = UDim2.fromOffset(p.X, p.Y)
    end, finish)
end
draggable(UI.main, UI.headerDrag)
draggable(UI.mini, UI.miniOpen, function(moved)
    if moved then S.miniSuppressUntil = clock() + 0.25 end
end)
local resizeStart
U.registerDrag(UI.resizeHandle, function(delta, first)
    if not S.resizing then return end
    if first then resizeStart = UI.mainScale.Scale end
    local change = (delta.X * WIDTH + delta.Y * HEIGHT) / (WIDTH * WIDTH + HEIGHT * HEIGHT)
    U.setScale(resizeStart + change)
end)
local function sliderPosition(input)
    local p, left, width = rawInput(input), rawPosition(UI.track).X, UI.track.AbsoluteSize.X
    local fraction = math.clamp((p.X - left) / math.max(1, width), 0, 1)
    U.setCps(math.exp(fraction * math.log(MAX_CPS)))
end
connect(UI.speedHit.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        S.sliderDrag = input sliderPosition(input)
    end
end)
connect(Input.InputChanged, function(input)
    if S.sliderDrag and (input == S.sliderDrag or (S.sliderDrag.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)) then
        sliderPosition(input)
    end
    local drag = S.drag
    if not drag then return end
    if input ~= drag.input and not (drag.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then return end
    local delta = rawInput(input) - drag.from
    if delta.Magnitude < 4 and not drag.moved then return end
    local first = not drag.moved drag.moved = true drag.move(delta, first)
end)
connect(Input.InputEnded, function(input)
    if S.sliderDrag == input then S.sliderDrag = nil end
    if S.drag and input == S.drag.input then
        local drag = S.drag S.drag = nil
        if drag.finish then drag.finish(drag.moved) end
    end
    if not S.picking or input ~= S.pickInput then return end
    local p, size = rawInput(input), dimensions()
    S.pickInput = nil
    if contains(UI.pickHud, p) then return end
    S.point = {x = math.clamp(p.X / size.X, 0.001, 0.999), y = math.clamp(p.Y / size.Y, 0.001, 0.999)}
    S.cursorAt = pointPixels()
    S.status = "Ponto definido"
    U.cancelPick() refresh()
end)
connect(UI.pickOverlay.InputBegan, function(input)
    if not S.picking or S.pickInput then return end
    if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not contains(UI.pickHud, rawInput(input)) then S.pickInput = input end
end)
function U.cancelPick()
    S.picking, S.pickInput = false, nil
    UI.pickOverlay.Visible, UI.pickHud.Visible = false, false
    UI.main.Visible, UI.mini.Visible = not S.minimized, S.minimized
    U.updateCursor()
end
beginPick = function()
    if S.mode ~= "idle" then stop("Escolhendo ponto") end
    S.drag, S.sliderDrag, S.picking, S.pickInput = nil, nil, true, nil
    UI.main.Visible, UI.mini.Visible, UI.cursor.Visible = false, false, false
    UI.pickOverlay.Visible, UI.pickHud.Visible = true, true
end
setMinimized = function(value)
    if S.picking then U.cancelPick() end
    S.minimized, S.viewId = value, S.viewId + 1
    local id = S.viewId
    if value then
        UI.mini.Visible = true
        U.animate(UI.bodyScale, {Scale = 0.97}, 0.12)
        task.delay(0.12, function() if S.alive and S.viewId == id then UI.main.Visible = false end end)
    else
        UI.mini.Visible, UI.main.Visible = false, true
        UI.bodyScale.Scale = 0.97 U.animate(UI.bodyScale, {Scale = 1}, 0.18)
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
    local function add(name, down, up) engines[#engines + 1] = {name = name, down = down, up = up} end
    if method(vim, "SendTouchEvent") then
        local touchId = 730000
        add("Toque virtual", function(p)
            touchId = touchId + 1 vim:SendTouchEvent(touchId, Enum.UserInputState.Begin.Value, p.X, p.Y)
        end, function(p) vim:SendTouchEvent(touchId, Enum.UserInputState.End.Value, p.X, p.Y) end)
    end
    local nativeOK, native = pcall(function() return Input:CreateVirtualInput() end)
    if nativeOK and method(native, "SendMouseButton") and method(native, "SendMousePosition") then
        add("VirtualInput", function(p)
            native:SendMousePosition(p) native:SendMouseButton(p, Enum.UserInputType.MouseButton1, true, 0)
        end, function(p) native:SendMouseButton(p, Enum.UserInputType.MouseButton1, false, 0) end)
    end
    if method(vim, "SendMouseButtonEvent") then
        add("Clique virtual", function(p)
            if method(vim, "SendMouseMoveEvent") then vim:SendMouseMoveEvent(p.X, p.Y, nil) end
            vim:SendMouseButtonEvent(p.X, p.Y, 0, true, nil, 0)
        end, function(p) vim:SendMouseButtonEvent(p.X, p.Y, 0, false, nil, 0) end)
    end
    if type(mousemoveabs) == "function" and type(mouse1press) == "function" and type(mouse1release) == "function" then
        add("Clique Delta", function(p) mousemoveabs(p.X, p.Y) mouse1press() end, function() mouse1release() end)
    end
    S.engines, S.engineIndex, S.activeEngine = engines, 1, nil
end
local function releasePressed()
    local held = S.pressed
    if not held then return true end
    local ok, err = pcall(held.engine.up, held.position)
    if ok then
        S.pressed = nil
        if held.sent then S.count = S.count + 1 end
    end
    if not ok then S.lastError = tostring(err):sub(1, 220) end
    return ok
end
local function sendClick(p)
    local engine = S.activeEngine
    while not engine do
        engine = S.engines[S.engineIndex]
        if not engine then return false, "O Delta bloqueou as APIs de clique." end
        local held = {engine = engine, position = p, sent = false}
        S.pressed = held
        local ok, err = pcall(engine.down, p)
        if ok then held.sent, S.activeEngine = true, engine
        else
            pcall(engine.up, p) S.pressed = nil
            S.lastError = tostring(err):sub(1, 220)
            S.engineIndex, engine = S.engineIndex + 1, nil
        end
    end
    if not S.pressed then
        S.pressed = {engine = engine, position = p, sent = false}
        local ok, err = pcall(engine.down, p)
        if not ok then
            pcall(engine.up, p) S.pressed = nil S.lastError = tostring(err):sub(1, 220)
            return false, "A API de clique parou de responder."
        end
        S.pressed.sent = true
    end
    if not releasePressed() then return false, "A API não conseguiu soltar o clique." end
    S.cursorAt, S.lastClick = p, clock()
    return true
end
stop = function(message)
    S.generation, S.mode, S.credit, S.liveCps = S.generation + 1, "idle", 0, 0
    local ok = releasePressed()
    S.status = ok and (message or "Parado") or "Falha ao soltar o clique"
    if refresh and S.alive then refresh() end
end
local function resetSample()
    S.sampleAt, S.sampleCount, S.liveCps, S.credit = clock(), S.count, 0, 0
end
pause = function()
    if S.mode == "running" then
        S.mode, S.status, S.credit, S.liveCps = "paused", "Pausado", 0, 0
        if not releasePressed() then stop("Falha ao pausar") end
    elseif S.mode == "paused" then
        S.mode, S.status = "running", "Clicando" resetSample() setMinimized(true)
    end
    refresh()
end
start = function()
    if S.mode ~= "idle" or S.picking or S.tickBusy then return end
    if not S.point then U.toast("Toque em Escolher ponto primeiro.", C.accent) return end
    if not releasePressed() then U.toast("A API ainda não conseguiu soltar o clique.", C.danger) return end
    U.setCps(UI.speed.Text)
    local focused = focusedTextBox()
    if focused then focused:ReleaseFocus() end
    U.discoverEngines()
    if #S.engines == 0 then U.toast("Nenhuma API de clique disponível no Delta.", C.danger) return end
    S.generation, S.count, S.lastError = S.generation + 1, 0, ""
    S.mode, S.status, S.cursorAt = "starting", "Iniciando", pointPixels()
    resetSample() setMinimized(true) refresh()
    local generation = S.generation
    -- One short transition is allowed before the first click, never between clicks.
    task.delay(0.14, function()
        if S.alive and S.generation == generation and S.mode == "starting" then
            S.mode, S.status = "running", "Clicando" resetSample() refresh()
        end
    end)
end
function U.tick(delta)
    if S.mode ~= "running" or not S.alive or S.tickBusy then return end
    if focusedTextBox() then pause() return end
    local p = pointPixels()
    if not p then stop("Escolha um ponto") return end
    if blocked(p) then
        stop("Alvo coberto") U.toast("Mova o controle flutuante para liberar o ponto.", C.danger) return
    end
    if not finite(delta) or delta <= 0 then return end
    -- Fractional credits retain timing across frames. Stalls never create a large backlog.
    S.credit = math.min(FRAME_CLICKS, S.credit + S.cfg.cps * math.min(delta, 0.1))
    local taps = S.cfg.double and 2 or 1
    local groups = math.floor((S.credit + 0.0000001) / taps)
    if groups == 0 then return end
    S.credit = math.max(0, S.credit - groups * taps)
    S.tickBusy = true
    local generation, began = S.generation, clock()
    local ok, err = pcall(function()
        for _ = 1, groups do
            if not S.alive or S.mode ~= "running" or S.generation ~= generation then break end
            for _ = 1, taps do
                local sent, reason = sendClick(p)
                if not sent then stop(reason) U.toast(reason, C.danger) return end
            end
            -- Keep input work bounded even when an executor's API is slow.
            if clock() - began >= 0.004 then break end
        end
    end)
    S.tickBusy = false
    if not ok then
        S.lastError = tostring(err):sub(1, 220) stop("Erro de clique")
        U.toast("Clique interrompido. Veja o console do Delta.", C.danger)
        pulseReport(S.lastError, true)
    end
end
refresh = function()
    if not S.alive then return end
    if focusedTextBox() ~= UI.speed then UI.speed.Text = tostring(S.cfg.cps) end
    local fraction = math.log(S.cfg.cps) / math.log(MAX_CPS)
    UI.fill.Size, UI.knob.Position = UDim2.fromOffset(250 * fraction, 4), UDim2.fromOffset(4 + 250 * fraction - 9, 2)
    U.animate(UI.switch, {BackgroundColor3 = S.cfg.double and C.accent or C.raised}, 0.15)
    U.animate(UI.switchDot, {Position = UDim2.fromOffset(S.cfg.double and 22 or 2, 2),
        BackgroundColor3 = S.cfg.double and C.ink or C.muted}, 0.15)
    local p = pointPixels()
    UI.target.Text = p and string.format("Ponto %d, %d  ·  trocar", p.X, p.Y) or "Escolher ponto"
    UI.go.Text = S.mode == "running" and "Pausar" or S.mode == "paused" and "Continuar" or S.mode == "starting" and "Iniciando" or "Iniciar"
    UI.miniPause.Text = S.mode == "running" and "II" or "▶"
    UI.miniRate.Text = S.mode == "paused" and "Pausado" or tostring(S.cfg.cps) .. " CPS"
    UI.resizeHint.Visible, UI.resizeHandle.Visible, UI.footer.Visible = S.resizing, S.resizing, not S.resizing
    UI.resizeButton.TextColor3 = S.resizing and C.accent or C.text
    UI.resizeHint.Text = string.format("%d%%  ·  arraste o canto", math.floor(UI.mainScale.Scale * 100 + 0.5))
    if S.mode == "running" then
        UI.footer.Text = string.format("%d CPS enviados  ·  %d cliques", math.floor(S.liveCps + 0.5), S.count)
    else UI.footer.Text = S.status end
    U.updateCursor()
end
function U.layout()
    local view = dimensions()
    local fit = math.min((view.X - 20) / WIDTH, (view.Y - 20) / HEIGHT)
    UI.mainScale.Scale = math.max(0.2, math.min(S.cfg.scale, fit))
    local p = clampPosition(UI.main, UI.main.Position.X.Offset, UI.main.Position.Y.Offset)
    UI.main.Position = UDim2.fromOffset(p.X, p.Y)
    local mini = clampPosition(UI.mini, UI.mini.Position.X.Offset, UI.mini.Position.Y.Offset)
    UI.mini.Position = UDim2.fromOffset(mini.X, mini.Y)
    UI.pickHud.Position = UDim2.fromOffset(math.max(4, (view.X - 278) / 2), 12)
    UI.toast.Position = UDim2.fromOffset(math.max(4, (view.X - 278) / 2), math.max(4, view.Y - 66))
    U.updateCursor()
end
shutdown = function(alreadyDestroying)
    if not S.alive then return end
    stop("Encerrado") S.alive = false
    S.drag, S.sliderDrag = nil, nil
    for _, connection in ipairs(S.connections) do connection:Disconnect() end
    for _, animation in pairs(tweens) do animation:Cancel() end
    S.connections = {}
    if not alreadyDestroying and UI.gui.Parent then UI.gui:Destroy() end
end
connect(UI.closer.Event, shutdown)
connect(UI.gui.Destroying, function() shutdown(true) end)
local function optionalEvent(source, name, callback)
    pcall(function() connect(source[name], callback) end)
end
local function focusReleased()
    if S.mode == "running" then pause()
    elseif S.mode == "starting" then stop("Início cancelado") end
end
optionalEvent(Input, "WindowFocusReleased", focusReleased)
optionalEvent(GuiService, "MenuOpened", focusReleased)
connect(UI.surface:GetPropertyChangedSignal("AbsoluteSize"), function()
    if S.mode ~= "idle" then stop("Tela mudou · confira o ponto") end
    S.cursorAt = nil U.layout() refresh()
end)
connect(Run.Heartbeat, function(delta)
    if not S.alive then return end
    U.tick(delta) U.updateCursor()
    local elapsed = clock() - S.sampleAt
    if elapsed >= 0.25 then
        S.liveCps = S.mode == "running" and (S.count - S.sampleCount) / elapsed or 0
        S.sampleAt, S.sampleCount = clock(), S.count
        if S.mode == "running" then
            UI.footer.Text = string.format("%d CPS enviados  ·  %d cliques", math.floor(S.liveCps + 0.5), S.count)
            UI.miniRate.Text = string.format("%d CPS", math.floor(S.liveCps + 0.5))
        end
    end
end)
pulseStage("ajustando painel compacto")
U.layout() refresh()
UI.bodyScale.Scale = 0.97 U.animate(UI.bodyScale, {Scale = 1}, 0.24)
for _, delay in ipairs({0.15, 0.5, 1}) do
    task.delay(delay, function() if S.alive and S.mode == "idle" then U.layout() refresh() end end)
end
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
