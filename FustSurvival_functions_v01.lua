local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local lp = Players.LocalPlayer

----------------------------------------------------------------- ESP
local espEnabled = false
local cfg = {
	box=true, hpBar=true, hpNum=true, distance=true, nickname=true, skeleton=true,
	maxDist=500, hpPos="Right", armorBar=true, weapon=true, arrows=true, visCheck=true,
	visColor=Color3.fromRGB(80,255,120), hidColor=Color3.fromRGB(255,70,70), arrowColor=Color3.fromRGB(255,70,70),
	cornerColor=Color3.fromRGB(124,240,208), skelColor=Color3.new(1,1,1),
}
local HP_POS = {"Left","Right","Top","Bottom"}
local COLOR_OPTS = {
	Color3.fromRGB(255,255,255), Color3.fromRGB(124,240,208), Color3.fromRGB(80,255,120), Color3.fromRGB(255,70,70),
	Color3.fromRGB(255,225,70), Color3.fromRGB(80,140,255), Color3.fromRGB(255,110,200), Color3.fromRGB(255,150,50),
}
local PRESETS = {
	{skeleton=false, cornerColor=Color3.new(1,1,1)},
	{skeleton=true, cornerColor=Color3.fromRGB(124,240,208)},
}
local BONES_R15 = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local BONES_R6 = {
	{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
}
local MAXB = 14
local espObjs = {}

local function newDraw(class, props)
	local d = Drawing.new(class)
	for k, v in pairs(props) do pcall(function() d[k] = v end) end
	return d
end

local function hpColor(p)
	return Color3.fromRGB(math.floor(255 * (1 - p)), math.floor(215 * p + 40), 70)
end

local function makeObj(z)
	local o = {all={}, c={}, cOut={}, bones={}}
	local function reg(d) o.all[#o.all + 1] = d return d end
	for i = 1, 8 do
		o.cOut[i] = reg(newDraw("Line", {Thickness=3.5, Color=Color3.new(0,0,0), Transparency=0.85, Visible=false, ZIndex=z}))
		o.c[i] = reg(newDraw("Line", {Thickness=1.5, Transparency=1, Visible=false, ZIndex=z + 1}))
	end
	for i = 1, MAXB do
		o.bones[i] = reg(newDraw("Line", {Thickness=1, Transparency=0.8, Visible=false, ZIndex=z}))
	end
	o.hpBg = reg(newDraw("Square", {Filled=true, Color=Color3.new(0,0,0), Transparency=0.7, Visible=false, ZIndex=z}))
	o.hpFill = reg(newDraw("Square", {Filled=true, Transparency=1, Visible=false, ZIndex=z + 1}))
	o.armBg = reg(newDraw("Square", {Filled=true, Color=Color3.new(0,0,0), Transparency=0.7, Visible=false, ZIndex=z}))
	o.armFill = reg(newDraw("Square", {Filled=true, Color=Color3.fromRGB(80,140,255), Transparency=1, Visible=false, ZIndex=z + 1}))
	local function txt(size)
		return reg(newDraw("Text", {Size=size, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0), Color=Color3.new(1,1,1), Transparency=1, Visible=false, ZIndex=z + 1}))
	end
	o.name = txt(13)
	o.hpNum = txt(11)
	o.dist = txt(11)
	o.dist.Color = Color3.fromRGB(170, 178, 195)
	o.weapon = txt(10)
	o.weapon.Color = Color3.fromRGB(150, 158, 175)
	o.arrow = reg(newDraw("Triangle", {Filled=true, Transparency=0.9, Visible=false, ZIndex=z + 1}))
	return o
end

local function hideObj(o)
	for _, x in ipairs(o.all) do x.Visible = false end
end

local function renderObj(o, d)
	local top, bot, cx, hw = d.top, d.bot, d.cx, d.hw
	local compact = false
	local far = (bot - top) < 45
	local cy = (top + bot) / 2
	local l, r, h = cx - hw, cx + hw, bot - top
	local col = hpColor(d.hp)
	local pos = cfg.hpPos
	local th, gap = 3, 5
	o.arrow.Visible = false
	local cc = cfg.visCheck and (d.vis and cfg.visColor or cfg.hidColor) or cfg.cornerColor
	local armor = (cfg.armorBar and d.armor and d.armor > 0) and math.clamp(d.armor / 100, 0, 1) or nil

	for i = 1, 8 do
		o.c[i].Visible = cfg.box
		o.cOut[i].Visible = cfg.box
	end
	if cfg.box then
		local L = math.min(math.clamp(h * 0.18, 6, 14), h * 0.3)
		local q = {{l, top, 1, 1}, {r, top, -1, 1}, {l, bot, 1, -1}, {r, bot, -1, -1}}
		for i = 1, 4 do
			local c = q[i]
			local a = Vector2.new(c[1], c[2])
			local hEnd = Vector2.new(c[1] + c[3] * L, c[2])
			local vEnd = Vector2.new(c[1], c[2] + c[4] * L)
			local i1, i2 = i * 2 - 1, i * 2
			o.c[i1].From, o.c[i1].To = a, hEnd
			o.c[i2].From, o.c[i2].To = a, vEnd
			o.cOut[i1].From, o.cOut[i1].To = a, hEnd
			o.cOut[i2].From, o.cOut[i2].To = a, vEnd
			o.c[i1].Color = cc
			o.c[i2].Color = cc
		end
	end

	o.hpBg.Visible = false
	o.hpFill.Visible = false
	o.armBg.Visible = false
	o.armFill.Visible = false

	local bx, by, bw, bh, ax, ay
	local armExtra = armor and (th + 2) or 0
	if compact then
		if cfg.hpBar then
			o.hpFill.Position = Vector2.new(r + 4, cy - 7)
			o.hpFill.Size = Vector2.new(6, 6)
			o.hpFill.Color = col
			o.hpFill.Visible = true
		end
		if armor then
			o.armFill.Position = Vector2.new(r + 4, cy + 1)
			o.armFill.Size = Vector2.new(6, 6)
			o.armFill.Visible = true
		end
	else
		if pos == "Left" then
			bx, by, bw, bh = l - gap - th, top, th, h
			ax, ay = bx - th - 2, top
		elseif pos == "Right" then
			bx, by, bw, bh = r + gap, top, th, h
			ax, ay = bx + th + 2, top
		elseif pos == "Top" then
			bx, by, bw, bh = l, top - gap - th, r - l, th
			ax, ay = l, by - th - 2
		else
			bx, by, bw, bh = l, bot + gap, r - l, th
			ax, ay = l, by + th + 2
		end
		local vert = pos == "Left" or pos == "Right"
		if cfg.hpBar then
			o.hpBg.Visible, o.hpFill.Visible = true, true
			o.hpBg.Position = Vector2.new(bx, by)
			o.hpBg.Size = Vector2.new(bw, bh)
			if vert then
				o.hpFill.Position = Vector2.new(bx, by + bh * (1 - d.hp))
				o.hpFill.Size = Vector2.new(bw, bh * d.hp)
			else
				o.hpFill.Position = Vector2.new(bx, by)
				o.hpFill.Size = Vector2.new(bw * d.hp, bh)
			end
			o.hpFill.Color = col
		end
		if armor then
			o.armBg.Visible, o.armFill.Visible = true, true
			o.armBg.Position = Vector2.new(ax, ay)
			if vert then
				o.armBg.Size = Vector2.new(th, bh)
				o.armFill.Position = Vector2.new(ax, ay + bh * (1 - armor))
				o.armFill.Size = Vector2.new(th, bh * armor)
			else
				o.armBg.Size = Vector2.new(bw, th)
				o.armFill.Position = Vector2.new(ax, ay)
				o.armFill.Size = Vector2.new(bw * armor, th)
			end
		end
	end

	local barTop = (not compact and cfg.hpBar and pos == "Top") and (gap + th + armExtra) or 0
	local barBot = (not compact and cfg.hpBar and pos == "Bottom") and (gap + th + armExtra) or 0

	o.name.Size = far and 10 or 13
	o.name.Visible = far and (cfg.nickname or cfg.distance) or cfg.nickname
	if o.name.Visible then
		if far then
			o.name.Text = cfg.nickname and (d.name .. (cfg.distance and (" " .. d.dist .. "m") or "")) or (d.dist .. "m")
		else
			o.name.Text = d.name
		end
		o.name.Position = Vector2.new(cx, top - (far and 13 or 16) - barTop)
	end

	o.dist.Visible = cfg.distance and not far
	if o.dist.Visible then
		o.dist.Text = d.dist .. "m"
		o.dist.Position = Vector2.new(cx, bot + 3 + barBot)
	end

	o.weapon.Visible = cfg.weapon and d.weapon ~= nil and not far
	if o.weapon.Visible then
		o.weapon.Text = d.weapon
		o.weapon.Position = Vector2.new(cx, bot + 3 + barBot + (cfg.distance and 12 or 0))
	end

	o.hpNum.Visible = cfg.hpNum and not far
	if o.hpNum.Visible then
		o.hpNum.Text = tostring(d.hpn)
		local px, py
		if compact then px, py = r + 24, cy - 7
		elseif pos == "Left" then px, py = (armor and ax or bx) - 11, bot - 12
		elseif pos == "Right" then px, py = (armor and ax or bx) + th + 11, bot - 12
		else px, py = r + 12, by - 5 end
		o.hpNum.Position = Vector2.new(px, py)
	end

	for i = 1, MAXB do
		local b = (cfg.skeleton and (bot - top) >= 60 and d.bones) and d.bones[i]
		local ln = o.bones[i]
		if b then
			ln.From = Vector2.new(b[1], b[2])
			ln.To = Vector2.new(b[3], b[4])
			ln.Color = cfg.skelColor
			ln.Visible = true
		else
			ln.Visible = false
		end
	end
end

local function removeESP(p)
	local o = espObjs[p]
	if not o then return end
	for _, x in ipairs(o.all) do pcall(function() x:Remove() end) end
	espObjs[p] = nil
end

local function buildESP(p)
	if p == lp then return end
	removeESP(p)
	espObjs[p] = makeObj(2)
end

local function setESP(on)
	espEnabled = on
	if on then
		for _, p in ipairs(Players:GetPlayers()) do buildESP(p) end
	else
		for p in pairs(espObjs) do removeESP(p) end
	end
end

Players.PlayerAdded:Connect(function(p)
	if espEnabled then buildESP(p) end
end)
Players.PlayerRemoving:Connect(removeESP)

local visParams = RaycastParams.new()
visParams.FilterType = Enum.RaycastFilterType.Exclude
visParams.RespectCanCollide = true

local function isVisible(cam, char, head)
	visParams.FilterDescendantsInstances = {lp.Character}
	local origin = cam.CFrame.Position
	local res = workspace:Raycast(origin, head.Position - origin, visParams)
	return res == nil or res.Instance:IsDescendantOf(char)
end

local function drawArrow(o, cam, pos, show)
	local ar = o.arrow
	if not show then ar.Visible = false return end
	local vs = cam.ViewportSize
	local rel = cam.CFrame:PointToObjectSpace(pos)
	local dir = Vector2.new(rel.X, -rel.Y)
	dir = dir.Magnitude > 1e-3 and dir.Unit or Vector2.new(0, 1)
	local bc = vs / 2 + dir * (math.min(vs.X, vs.Y) * 0.4)
	local perp = Vector2.new(-dir.Y, dir.X)
	ar.PointA = bc + dir * 14
	ar.PointB = bc + perp * 8
	ar.PointC = bc - perp * 8
	ar.Color = cfg.arrowColor
	ar.Visible = true
end

local function getArmor(char)
	local be = char:FindFirstChild("BodyEffects")
	local a = be and be:FindFirstChild("Armor")
	if a and a:IsA("ValueBase") then return a.Value end
	return nil
end

RunService.RenderStepped:Connect(function()
	if not espEnabled then return end
	local cam = workspace.CurrentCamera
	local lpRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")

	for p, o in pairs(espObjs) do
		local char = p.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local head = char and char:FindFirstChild("Head")

		if not (hum and root and head) or hum.Health <= 0 then
			hideObj(o)
			continue
		end

		local dist = lpRoot and math.floor((lpRoot.Position - root.Position).Magnitude) or 0
		if dist > cfg.maxDist then
			hideObj(o)
			continue
		end

		local rp3 = cam:WorldToViewportPoint(root.Position)
		local vs = cam.ViewportSize
		if rp3.Z <= 0 or rp3.X < 0 or rp3.X > vs.X or rp3.Y < 0 or rp3.Y > vs.Y then
			hideObj(o)
			drawArrow(o, cam, root.Position, cfg.arrows)
			continue
		end

		local hp = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.7, 0))
		local fp = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
		if not (hp.Z > 0 and fp.Z > 0) then
			hideObj(o)
			continue
		end

		local top, bot = math.min(hp.Y, fp.Y), math.max(hp.Y, fp.Y)

		local bl
		if cfg.skeleton then
			bl = {}
			local set = char:FindFirstChild("UpperTorso") and BONES_R15 or BONES_R6
			for _, pair in ipairs(set) do
				local b1, b2 = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
				if b1 and b2 then
					local p1 = cam:WorldToViewportPoint(b1.Position)
					local p2 = cam:WorldToViewportPoint(b2.Position)
					if p1.Z > 0 and p2.Z > 0 then
						bl[#bl + 1] = {p1.X, p1.Y, p2.X, p2.Y}
					end
				end
			end
		end

		local tool = cfg.weapon and char:FindFirstChildOfClass("Tool")
		renderObj(o, {
			vis = (not cfg.visCheck) or isVisible(cam, char, head), weapon = tool and tool.Name or nil,
			top = top, bot = bot, cx = (hp.X + fp.X) / 2, hw = (bot - top) * 0.275,
			hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1),
			hpn = math.floor(hum.Health), dist = dist, name = p.DisplayName, bones = bl, armor = getArmor(char),
		})
	end
end)

----------------------------------------------------------------- LANGUAGE
local LANG = {
	en = {},
	ru = {
		["Aim"]="Прицел",["Player"]="Игрок",["Visual"]="Визуал",["Ambient"]="Окружение",
		["Lists"]="Списки",["Miscellaneous"]="Разное",["Configs"]="Конфиги",
		["Gameplay"]="Геймплей",["World"]="Мир",["Library"]="Библиотека",
		["Crosshair"]="Прицел",["Zoom"]="Зум",["Sensitivity"]="Чувствительность",
		["Feedback"]="Фидбек",["Movement"]="Движение",["Health display"]="Здоровье",
		["Camera"]="Камера",["ESP"]="ESP",["Time"]="Время",["Fog"]="Туман",
		["Lighting"]="Освещение",["Effects"]="Эффекты",["Favorites"]="Избранное",
		["Recent"]="Недавние",["Performance"]="Производительность",["Audio"]="Аудио",
		["Language"]="Язык",["Profiles"]="Профили",["Menu"]="Меню",
		["Animations"]="Анимации",["Auto-save"]="Автосохранение",["Menu sounds"]="Звуки меню",
		["Size"]="Размер",["Gap"]="Зазор",["Style"]="Стиль",["Outline"]="Обводка",
		["Thickness"]="Толщина",["Opacity"]="Прозрачность",["Color"]="Цвет",
		["Center dot"]="Центр. точка",["Hotkey"]="Горячая клавиша",
		["Zoom key"]="Клавиша зума",["Toggle mode"]="Режим переключения",
		["Level"]="Уровень",["Speed"]="Скорость",["Vignette"]="Виньетка",
		["Raw input"]="Сырой ввод",["Base"]="Базовая",["Curve"]="Кривая",
		["Invert Y"]="Инверт Y",["Acceleration"]="Ускорение",["Deadzone"]="Мёртвая зона",
		["Snap to target"]="Притяжение",["Hit marker"]="Маркер попадания",
		["Sound"]="Звук",["Volume"]="Громкость",["Marker color"]="Цвет маркера",
		["Marker size"]="Размер маркера",["Duration"]="Длительность",
		["Kill confirm"]="Подтв. убийства",["Auto sprint"]="Авто-спринт",
		["Hold to crouch"]="Зажать для приседа",["Walk speed"]="Скорость ходьбы",
		["Sprint key"]="Клавиша спринта",["Show health"]="Показать HP",
		["Show armor"]="Показать броню",["Position"]="Позиция",["Scale"]="Масштаб",
		["Field of view"]="Поле зрения",["Smoothing"]="Сглаживание",
		["Head bob"]="Покачивание",["Perspective"]="Перспектива",
		["Box"]="Бокс",["HpBar"]="Полоса HP",["hpNum"]="Число HP",
		["Distance"]="Дистанция",["Nickname"]="Ник",["Max distance"]="Макс. дист.",
		["Box color"]="Цвет бокса",["Bar color"]="Цвет полосы",
		["Enabled"]="Включено",["Time of day"]="Время суток",
		["Clock hour"]="Час",["Freeze time"]="Заморозить время",
		["Enable fog"]="Включить туман",["Fog start"]="Начало тумана",
		["Fog end"]="Конец тумана",["Fog color"]="Цвет тумана",
		["Brightness"]="Яркость",["Ambient"]="Окружение",["Shadows"]="Тени",
		["Shadow softness"]="Мягкость теней",["Bloom"]="Блум",
		["Bloom intensity"]="Интенсивность блума",["Blur"]="Размытие",
		["Blur size"]="Размытие",["Color correction"]="Цветокоррекция",
		["Saturation"]="Насыщенность",["Contrast"]="Контраст",
		["Master"]="Мастер",["Music"]="Музыка",
		["Mute when unfocused"]="Без звука не в фокусе",
		["Frame limit"]="Лимит кадров",["VSync"]="ВСинк",
		["Show watermark"]="Показать вотермарк",["Low latency mode"]="Низкая задержка",
		["Menu key"]="Клавиша меню",["Loading screen"]="Экран загрузки",
		["Logo animation"]="Анимация лого",["Loading music"]="Музыка загрузки",
		["Save on exit"]="Сохр. при выходе",["Backups kept"]="Кол-во бэкапов",
		["Cloud sync"]="Облачная синхр.",["Click sounds"]="Звуки кликов",
		["Appear sounds"]="Звуки появления",["Sound pack"]="Пак звуков",
		["Open recent"]="Открыть недавние",["History size"]="Размер истории",
		["Clear on exit"]="Очистить при выходе",
		["Loadout A"]="Сборка A",["Loadout B"]="Сборка B",["Loadout C"]="Сборка C",
		["Sync favorites"]="Синхр. избранного",
	},
	uk = {
		["Aim"]="Приціл",["Player"]="Гравець",["Visual"]="Візуал",["Ambient"]="Оточення",
		["Lists"]="Списки",["Miscellaneous"]="Різне",["Configs"]="Конфіги",
		["Gameplay"]="Геймплей",["World"]="Світ",["Library"]="Бібліотека",
		["Crosshair"]="Приціл",["Zoom"]="Зум",["Sensitivity"]="Чутливість",
		["Feedback"]="Фідбек",["Movement"]="Рух",["Health display"]="Здоров'я",
		["Camera"]="Камера",["ESP"]="ESP",["Time"]="Час",["Fog"]="Туман",
		["Lighting"]="Освітлення",["Effects"]="Ефекти",["Favorites"]="Обране",
		["Recent"]="Нещодавні",["Performance"]="Продуктивність",["Audio"]="Аудіо",
		["Language"]="Мова",["Profiles"]="Профілі",["Menu"]="Меню",
		["Animations"]="Анімації",["Auto-save"]="Автозбереження",["Menu sounds"]="Звуки меню",
		["Size"]="Розмір",["Gap"]="Проміжок",["Style"]="Стиль",["Outline"]="Обводка",
		["Thickness"]="Товщина",["Opacity"]="Прозорість",["Color"]="Колір",
		["Center dot"]="Центр. точка",["Hotkey"]="Гаряча клавіша",
		["Zoom key"]="Клавіша зуму",["Toggle mode"]="Режим перемикання",
		["Level"]="Рівень",["Speed"]="Швидкість",["Vignette"]="Віньєтка",
		["Raw input"]="Сирий ввід",["Base"]="Базова",["Curve"]="Крива",
		["Invert Y"]="Інверсія Y",["Acceleration"]="Прискорення",["Deadzone"]="Мертва зона",
		["Snap to target"]="Притягання",["Hit marker"]="Маркер влучання",
		["Sound"]="Звук",["Volume"]="Гучність",["Marker color"]="Колір маркера",
		["Marker size"]="Розмір маркера",["Duration"]="Тривалість",
		["Kill confirm"]="Підтв. вбивства",["Auto sprint"]="Авто-спринт",
		["Hold to crouch"]="Утримувати для присіду",["Walk speed"]="Швидкість ходьби",
		["Sprint key"]="Клавіша спринту",["Show health"]="Показати HP",
		["Show armor"]="Показати броню",["Position"]="Позиція",["Scale"]="Масштаб",
		["Field of view"]="Поле зору",["Smoothing"]="Згладжування",
		["Head bob"]="Похитування",["Perspective"]="Перспектива",
		["Box"]="Бокс",["HpBar"]="Смуга HP",["hpNum"]="Число HP",
		["Distance"]="Дистанція",["Nickname"]="Нік",["Max distance"]="Макс. дист.",
		["Box color"]="Колір боксу",["Bar color"]="Колір смуги",
		["Enabled"]="Увімкнено",["Time of day"]="Час доби",
		["Clock hour"]="Година",["Freeze time"]="Заморозити час",
		["Enable fog"]="Увімкнути туман",["Fog start"]="Початок туману",
		["Fog end"]="Кінець туману",["Fog color"]="Колір туману",
		["Brightness"]="Яскравість",["Shadows"]="Тіні",
		["Shadow softness"]="М'якість тіней",["Bloom"]="Блум",
		["Bloom intensity"]="Інтенсивність блуму",["Blur"]="Розмиття",
		["Blur size"]="Розмиття",["Color correction"]="Кольорокорекція",
		["Saturation"]="Насиченість",["Contrast"]="Контраст",
		["Master"]="Майстер",["Music"]="Музика",
		["Mute when unfocused"]="Без звуку не у фокусі",
		["Frame limit"]="Ліміт кадрів",["VSync"]="ВСинк",
		["Show watermark"]="Показати вотермарк",["Low latency mode"]="Низька затримка",
		["Menu key"]="Клавіша меню",["Loading screen"]="Екран завантаження",
		["Logo animation"]="Анімація лого",["Loading music"]="Музика завантаження",
		["Save on exit"]="Збер. при виході",["Backups kept"]="К-сть бекапів",
		["Cloud sync"]="Хмарна синхр.",["Click sounds"]="Звуки кліків",
		["Appear sounds"]="Звуки появи",["Sound pack"]="Пак звуків",
		["Open recent"]="Відкрити нещодавні",["History size"]="Розмір історії",
		["Clear on exit"]="Очистити при виході",
		["Loadout A"]="Збірка A",["Loadout B"]="Збірка B",["Loadout C"]="Збірка C",
		["Sync favorites"]="Синхр. обраного",
	},
}
local langMap = {[1]="en",[2]="ru",[3]="uk"}
local LANG_ALIAS = {
	en="en", english="en", ["английский"]="en", ["англійська"]="en", ["Английский"]="en", ["Англійська"]="en",
	ru="ru", russian="ru", ["русский"]="ru", ["російська"]="ru", ["Русский"]="ru", ["Російська"]="ru",
	uk="uk", ua="uk", ukrainian="uk", ["украинский"]="uk", ["українська"]="uk", ["Украинский"]="uk", ["Українська"]="uk",
}

local EXTRA = {
	ru = {["Skeleton"]="Скелет",["HP position"]="Позиция HP",["Left"]="Слева",["Right"]="Справа",["Top"]="Сверху",["Bottom"]="Снизу",["Corners"]="Углы",["Corners + skeleton"]="Углы + скелет",["ESP preview"]="Предпросмотр ESP",["Armor bar"]="Броня",["Weapon"]="Оружие",["Arrows"]="Стрелки",["Vis check"]="Видимость",["Corner color"]="Цвет углов",["Visible color"]="Цвет видимого",["Hidden color"]="Цвет за стеной",["Arrow color"]="Цвет стрелок",["White"]="Белый",["Mint"]="Мятный",["Green"]="Зелёный",["Red"]="Красный",["Yellow"]="Жёлтый",["Blue"]="Синий",["Pink"]="Розовый",["Orange"]="Оранжевый",["Combat"]="Бой",["Bullet tracer"]="Трассер пуль",["Tracer color"]="Цвет трассера",["Tracer time"]="Время трассера",["Hit effect"]="Эффект попадания",["Hit color"]="Цвет эффекта",["Damage numbers"]="Числа урона",["Hit marker"]="Хит-маркер",["Headshot color"]="Цвет хедшота",["Zoom FOV"]="FOV зума",["Chams"]="Чамсы",["Material"]="Материал",["Fill color"]="Цвет заливки",["Outline color"]="Цвет контура",["Fill transparency"]="Прозрачность заливки",["Outline transparency"]="Прозрачность контура",["Through walls"]="Сквозь стены",["Rainbow"]="Радуга",["Pulse"]="Пульс",["Color by visibility"]="Цвет по видимости",["Highlight"]="Подсветка",["Neon"]="Неон",["ForceField"]="Силовое поле",["Glass"]="Стекло",["Metal"]="Металл",["Look line"]="Линия взгляда",["All players"]="Все игроки",["Line length"]="Длина линии",["Line color"]="Цвет линии",["Alert color"]="Цвет тревоги",["Stop at walls"]="Обрыв на стенах",["Hit flash"]="Вспышка при попадании",["Flash color"]="Цвет вспышки",["Ore ESP"]="ESP руды",["Animal ESP"]="ESP животных",["X-ray"]="X-Ray",["Stone"]="Камень",["Sulfur"]="Сера",["Stone color"]="Цвет камня",["Metal color"]="Цвет металла",["Sulfur color"]="Цвет серы",["Show distance"]="Показывать дистанцию",["Show name"]="Показывать имя",["Animal color"]="Цвет животных",["Walls"]="Стены",["Floors"]="Полы",["Doors"]="Двери",["Transparency"]="Прозрачность",["Night Vision"]="Ночное зрение",["NV brightness"]="Яркость НЗ",["NV saturation"]="Насыщенность НЗ",["Shadows"]="Тени",["No shadows"]="Без теней",["Foliage"]="Растительность",["No leaves"]="Без листьев",["No grass"]="Без травы",["Fog"]="Туман",["Remove fog"]="Убрать туман"},
	uk = {["Skeleton"]="Скелет",["HP position"]="Позиція HP",["Left"]="Ліворуч",["Right"]="Праворуч",["Top"]="Зверху",["Bottom"]="Знизу",["Corners"]="Кути",["Corners + skeleton"]="Кути + скелет",["ESP preview"]="Попередній перегляд ESP",["Armor bar"]="Броня",["Weapon"]="Зброя",["Arrows"]="Стрілки",["Vis check"]="Видимість",["Corner color"]="Колір кутів",["Visible color"]="Колір видимого",["Hidden color"]="Колір за стіною",["Arrow color"]="Колір стрілок",["White"]="Білий",["Mint"]="М'ятний",["Green"]="Зелений",["Red"]="Червоний",["Yellow"]="Жовтий",["Blue"]="Синій",["Pink"]="Рожевий",["Orange"]="Помаранчевий",["Combat"]="Бій",["Bullet tracer"]="Трасер куль",["Tracer color"]="Колір трасера",["Tracer time"]="Час трасера",["Hit effect"]="Ефект влучання",["Hit color"]="Колір ефекту",["Damage numbers"]="Числа шкоди",["Hit marker"]="Хіт-маркер",["Headshot color"]="Колір хедшота",["Zoom FOV"]="FOV зуму",["Chams"]="Чамси",["Material"]="Матеріал",["Fill color"]="Колір заливки",["Outline color"]="Колір контуру",["Fill transparency"]="Прозорість заливки",["Outline transparency"]="Прозорість контуру",["Through walls"]="Крізь стіни",["Rainbow"]="Веселка",["Pulse"]="Пульс",["Color by visibility"]="Колір за видимістю",["Highlight"]="Підсвічування",["Neon"]="Неон",["ForceField"]="Силове поле",["Glass"]="Скло",["Metal"]="Метал",["Look line"]="Лінія погляду",["All players"]="Усі гравці",["Line length"]="Довжина лінії",["Line color"]="Колір лінії",["Alert color"]="Колір тривоги",["Stop at walls"]="Обрив на стінах",["Hit flash"]="Спалах при влучанні",["Flash color"]="Колір спалаху",["Ore ESP"]="ESP руди",["Animal ESP"]="ESP тварин",["X-ray"]="X-Ray",["Stone"]="Камінь",["Sulfur"]="Сірка",["Stone color"]="Колір каменю",["Metal color"]="Колір металу",["Sulfur color"]="Колір сірки",["Show distance"]="Показувати дистанцію",["Show name"]="Показувати ім'я",["Animal color"]="Колір тварин",["Walls"]="Стіни",["Floors"]="Підлоги",["Doors"]="Двері",["Transparency"]="Прозорість",["Night Vision"]="Нічний зір",["NV brightness"]="Яскравість НЗ",["NV saturation"]="Насиченість НЗ",["Shadows"]="Тіні",["No shadows"]="Без тіней",["Foliage"]="Рослинність",["No leaves"]="Без листя",["No grass"]="Без трави",["Fog"]="Туман",["Remove fog"]="Прибрати туман"},
}
for code, tbl in pairs(EXTRA) do
	for k, v in pairs(tbl) do LANG[code][k] = v end
end
local curLang = "ru"
local langListeners = {}

local KEYS = {}
for k in pairs(LANG.ru) do KEYS[k] = true end
for k in pairs(LANG.uk) do KEYS[k] = true end

local origText, lastText = setmetatable({}, {__mode="k"}), setmetatable({}, {__mode="k"})

local function uiRoots()
	local r = {}
	pcall(function() if gethui then r[#r+1] = gethui() end end)
	pcall(function() r[#r+1] = game:GetService("CoreGui") end)
	pcall(function() r[#r+1] = lp:FindFirstChildOfClass("PlayerGui") end)
	return r
end

local function translateGui(dict)
	for _, root in ipairs(uiRoots()) do
		for _, g in ipairs(root:GetChildren()) do
			if g:IsA("ScreenGui") and g.Name:sub(1, 5) == "Drama" then
				local ok, list = pcall(function() return g:GetDescendants() end)
				if ok then
					for _, d in ipairs(list) do
						if d:IsA("TextLabel") or d:IsA("TextButton") then
							local o = origText[d]
							if o and d.Text ~= lastText[d] and not KEYS[d.Text] then
								origText[d] = nil
								o = nil
							end
							if not o and KEYS[d.Text] then
								o = d.Text
								origText[d] = o
							end
							if o then
								local new = dict[o] or o
								if d.Text ~= new then d.Text = new end
								lastText[d] = new
							end
						end
					end
				end
			end
		end
	end
end

local function resolveLang(v)
	if type(v) == "number" then return langMap[math.floor(v)] or "en" end
	if type(v) == "string" then return LANG_ALIAS[v] or LANG_ALIAS[v:lower()] or "en" end
	return "en"
end

-- Aim tab labels
do
	local ADD = {
		ru = {["Aimbot"]="Аимбот",["Silent aim"]="Silent aim",["Auto predict"]="Авто-упреждение",["Wall check"]="Проверка стен",["Sleep check"]="Проверка сна"},
		uk = {["Aimbot"]="Аімбот",["Silent aim"]="Silent aim",["Auto predict"]="Авто-упередження",["Wall check"]="Перевірка стін",["Sleep check"]="Перевірка сну"},
	}
	for code, add in pairs(ADD) do
		LANG[code] = LANG[code] or {}
		for k, v in pairs(add) do
			if LANG[code][k] == nil then LANG[code][k] = v end
		end
	end
end

local function setLang(v)
	local code = resolveLang(v)
	curLang = code
	local dict = LANG[code] or {}
	local fn = getgenv().DramaApplyLang
	if type(fn) == "function" then pcall(fn, dict, code) end
	translateGui(dict)
	for _, f in ipairs(langListeners) do pcall(f) end
end

----------------------------------------------------------------- ESP PREVIEW PANEL
local UIS = game:GetService("UserInputService")
local PW, PV_H = 280, 290
local PK, XS = 1.15, 1.35

local function T(key)
	local d = LANG[curLang]
	return (d and d[key]) or key
end

local pvGui = Instance.new("ScreenGui")
pvGui.Name = "DramaESPPreview"
pvGui.ResetOnSpawn = false
pvGui.DisplayOrder = 1000
pvGui.IgnoreGuiInset = true
pvGui.Enabled = false
pcall(function() pvGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not pvGui.Parent then pvGui.Parent = lp:WaitForChild("PlayerGui") end

local C_BG, C_PV = Color3.fromRGB(18,20,26), Color3.fromRGB(13,15,20)
local C_OFF, C_ON, C_TXT = Color3.fromRGB(30,34,44), Color3.fromRGB(34,150,124), Color3.fromRGB(225,229,238)

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(PW, 510)
panel.Position = UDim2.fromOffset(math.max(workspace.CurrentCamera.ViewportSize.X - PW - 20, 0), 60)
panel.BackgroundColor3 = C_BG
panel.BorderSizePixel = 0
panel.Parent = pvGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(38, 43, 54)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 0)
title.Size = UDim2.fromOffset(PW - 50, 28)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamMedium
title.TextSize = 13
title.TextColor3 = C_TXT
title.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.BackgroundTransparency = 1
closeBtn.Position = UDim2.fromOffset(PW - 32, 2)
closeBtn.Size = UDim2.fromOffset(26, 24)
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamMedium
closeBtn.TextSize = 18
closeBtn.TextColor3 = C_TXT
closeBtn.Parent = panel
closeBtn.MouseButton1Click:Connect(function() pvGui.Enabled = false end)

local dragging, dragStart, startPos
title.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, i.Position, panel.Position
	end
end)
UIS.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local dlt = i.Position - dragStart
		panel.Position = UDim2.fromOffset(startPos.X.Offset + dlt.X, startPos.Y.Offset + dlt.Y)
	end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

local pv = Instance.new("Frame")
pv.Position = UDim2.fromOffset(8, 30)
pv.Size = UDim2.fromOffset(PW - 16, PV_H)
pv.BackgroundColor3 = C_PV
pv.BorderSizePixel = 0
pv.Parent = panel
Instance.new("UICorner", pv).CornerRadius = UDim.new(0, 6)

local hpLbl = Instance.new("TextLabel")
hpLbl.BackgroundTransparency = 1
hpLbl.Position = UDim2.fromOffset(10, 362)
hpLbl.Size = UDim2.fromOffset(PW - 20, 14)
hpLbl.TextXAlignment = Enum.TextXAlignment.Left
hpLbl.Font = Enum.Font.Gotham
hpLbl.TextSize = 11
hpLbl.TextColor3 = Color3.fromRGB(138, 146, 163)
hpLbl.Parent = panel

local refreshPanel
local btns = {}
local function mkBtn(x, y, w, key, onClick, isOn)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 11
	b.TextColor3 = C_TXT
	b.Position = UDim2.fromOffset(x, y)
	b.Size = UDim2.fromOffset(w, 26)
	b.Parent = panel
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
	b.MouseButton1Click:Connect(function()
		onClick()
		refreshPanel()
	end)
	btns[#btns + 1] = {b = b, key = key, isOn = isOn}
end

local function applyPreset(i)
	for k, v in pairs(PRESETS[i]) do cfg[k] = v end
end

mkBtn(8, 328, 129, "Corners", function() applyPreset(1) end, function() return not cfg.skeleton end)
mkBtn(143, 328, 129, "Corners + skeleton", function() applyPreset(2) end, function() return cfg.skeleton end)

for i, name in ipairs(HP_POS) do
	mkBtn(8 + (i - 1) * 67, 378, 63, name, function() cfg.hpPos = name end, function() return cfg.hpPos == name end)
end

local TOGGLES = {{"Box","box"},{"HpBar","hpBar"},{"hpNum","hpNum"},{"Distance","distance"},{"Nickname","nickname"},{"Skeleton","skeleton"},{"Weapon","weapon"},{"Arrows","arrows"},{"Vis check","visCheck"}}
for i, t in ipairs(TOGGLES) do
	local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
	mkBtn(8 + col * 89, 412 + row * 30, 85, t[1], function() cfg[t[2]] = not cfg[t[2]] end, function() return cfg[t[2]] end)
end

refreshPanel = function()
	title.Text = T("ESP preview")
	hpLbl.Text = T("HP position")
	for _, x in ipairs(btns) do
		x.b.Text = T(x.key)
		x.b.BackgroundColor3 = x.isOn() and C_ON or C_OFF
	end
end
refreshPanel()
langListeners[#langListeners + 1] = refreshPanel

local function setCfg(k, v)
	cfg[k] = v
	refreshPanel()
end

local HP_ALIAS = {
	left=1, right=2, top=3, bottom=4,
	["слева"]=1, ["справа"]=2, ["сверху"]=3, ["снизу"]=4,
	["Слева"]=1, ["Справа"]=2, ["Сверху"]=3, ["Снизу"]=4,
	["ліворуч"]=1, ["праворуч"]=2, ["зверху"]=3, ["знизу"]=4,
	["Ліворуч"]=1, ["Праворуч"]=2, ["Зверху"]=3, ["Знизу"]=4,
}
local function resolveHpPos(v)
	if type(v) == "number" then return HP_POS[math.floor(v)] or "Right" end
	if type(v) == "string" then return HP_POS[HP_ALIAS[v] or HP_ALIAS[v:lower()] or 2] end
	return "Right"
end

local function setPreview(on)
	pvGui.Enabled = on and true or false
end

UIS.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.F6 then setPreview(not pvGui.Enabled) end
end)

local BODY_COL = Color3.fromRGB(43, 48, 60)
local LIMBS = {
	{"chest","pelvis",24},{"lsh","rsh",12},{"lsh","lel",8},{"lel","lh",8},{"rsh","rel",8},{"rel","rh",8},
	{"lhip","lkn",10},{"lkn","lft",10},{"rhip","rkn",10},{"rkn","rft",10},
}
local PV_BONES = {
	{"head","neck"},{"neck","chest"},{"chest","pelvis"},
	{"lsh","rsh"},{"lsh","lel"},{"lel","lh"},{"rsh","rel"},{"rel","rh"},
	{"pelvis","lhip"},{"pelvis","rhip"},{"lhip","lkn"},{"lkn","lft"},{"rhip","rkn"},{"rkn","rft"},
}
local pvBody = {limbs = {}}
for i, L in ipairs(LIMBS) do
	local w = L[3] * PK
	pvBody.limbs[i] = {
		line = newDraw("Line", {Color=BODY_COL, Thickness=w, Transparency=1, Visible=false, ZIndex=1}),
		c1 = newDraw("Circle", {Color=BODY_COL, Filled=true, NumSides=24, Radius=w / 2, Transparency=1, Visible=false, ZIndex=1}),
		c2 = newDraw("Circle", {Color=BODY_COL, Filled=true, NumSides=24, Radius=w / 2, Transparency=1, Visible=false, ZIndex=1}),
	}
end
pvBody.head = newDraw("Circle", {Color=BODY_COL, Filled=true, NumSides=32, Radius=12 * PK, Transparency=1, Visible=false, ZIndex=1})
local pvObj = makeObj(3)
local pvShown = false

local function setBodyVisible(v)
	for _, x in ipairs(pvBody.limbs) do
		x.line.Visible, x.c1.Visible, x.c2.Visible = v, v, v
	end
	pvBody.head.Visible = v
end

local function pvPose(t)
	local sw = math.sin(t * 2.2) * 6
	return {
		head={0,-172}, neck={0,-155}, chest={0,-140}, pelvis={0,-95},
		lsh={-17,-148}, rsh={17,-148}, lel={-24+sw*.5,-120}, rel={24-sw*.5,-120},
		lh={-22+sw,-92}, rh={22-sw,-92},
		lhip={-8,-95}, rhip={8,-95}, lkn={-10+sw,-48}, rkn={10-sw,-48},
		lft={-10+sw*1.4,0}, rft={10-sw*1.4,0},
	}
end

RunService.RenderStepped:Connect(function()
	if not pvGui.Enabled then
		if pvShown then
			pvShown = false
			hideObj(pvObj)
			setBodyVisible(false)
		end
		return
	end
	pvShown = true
	local t = os.clock()
	local pose = pvPose(t)
	local ap, asz = pv.AbsolutePosition, pv.AbsoluteSize
	local ox, oy = ap.X + asz.X / 2, ap.Y + asz.Y - 34
	local function pt(n) return Vector2.new(ox + pose[n][1] * PK * XS, oy + pose[n][2] * PK) end

	for i, L in ipairs(LIMBS) do
		local a, b = pt(L[1]), pt(L[2])
		local x = pvBody.limbs[i]
		x.line.From, x.line.To = a, b
		x.c1.Position, x.c2.Position = a, b
	end
	pvBody.head.Position = pt("head")
	setBodyVisible(true)

	local bones = {}
	for _, pr in ipairs(PV_BONES) do
		local a, b = pt(pr[1]), pt(pr[2])
		bones[#bones + 1] = {a.X, a.Y, b.X, b.Y}
	end
	local top, bot = oy - 186 * PK, oy
	local hp = math.clamp(0.55 + 0.45 * math.sin(t * 0.6), 0.12, 1)
	renderObj(pvObj, {
		top = top, bot = bot, cx = ox, hw = (bot - top) * 0.275,
		hp = hp, hpn = math.floor(hp * 100), dist = 24, name = lp.DisplayName, bones = bones, armor = 60 + 40 * math.sin(t * 0.5),
		vis = (math.floor(t / 3) % 2 == 0), weapon = "AK-47",
	})
end)

----------------------------------------------------------------- FUST: ORE / ANIMAL / X-RAY
do
	local ROWS, CARDS, ready = {}, {}, false
	local function reindex()
		local tabs = getgenv().DramaTABS
		if type(tabs) ~= "table" then return end
		local function walk(rows)
			for _, r in ipairs(rows) do
				if r.t == "g" then walk(r.rows) elseif r.path then ROWS[r.path] = r end
			end
		end
		for _, tab in ipairs(tabs) do
			for _, c in ipairs(tab.cards or {}) do
				if c.path then CARDS[c.path] = c end
				walk(c.rows or {})
			end
		end
		ready = next(ROWS) ~= nil
	end
	local function V(path, def)
		if not ready then reindex() end
		local r = ROWS[path]
		if r and r.val ~= nil then return r.val end
		return def
	end
	local function ON(path)
		if not ready then reindex() end
		local c = CARDS[path]
		return c ~= nil and c.enabled == true
	end

	local function pivot(m)
		local ok, cf = pcall(function() return m:GetPivot() end)
		if ok and cf then return cf.Position end
	end
	local function newLabel(size)
		return newDraw("Text", {Size = size, Center = true, Outline = true, OutlineColor = Color3.new(0, 0, 0),
			Color = Color3.new(1, 1, 1), Transparency = 1, Visible = false, ZIndex = 3})
	end
	local function prune(labels, keep)
		for m, t in pairs(labels) do
			if not keep[m] then
				pcall(function() t:Remove() end)
				labels[m] = nil
			end
		end
	end

	----------------------------------------------------------- ore
	local ORE = {
		Stone = {words = {"stone"}, row = "Visual/Ore ESP/Stone", col = "Visual/Ore ESP/Stone color", def = 1},
		Metal = {words = {"metal"}, row = "Visual/Ore ESP/Metal", col = "Visual/Ore ESP/Metal color", def = 8},
		Sulfur = {words = {"sulfur", "sulphur"}, row = "Visual/Ore ESP/Sulfur", col = "Visual/Ore ESP/Sulfur color", def = 5},
	}
	local function oreKind(name)
		local n = name:lower()
		for kind, t in pairs(ORE) do
			for _, w in ipairs(t.words) do
				if n:find(w, 1, true) then return kind end
			end
		end
	end

	local oreList, oreLabels, animalList, animalLabels = {}, {}, {}, {}

	local function refreshOres()
		local list, keep = {}, {}
		for _, fname in ipairs({"Nodes", "Pickups"}) do
			local f = workspace:FindFirstChild(fname)
			if f then
				for _, m in ipairs(f:GetChildren()) do
					local k = oreKind(m.Name)
					if k then
						list[#list + 1] = {m = m, k = k}
						keep[m] = true
					end
				end
			end
		end
		oreList = list
		prune(oreLabels, keep)
	end

	local function refreshAnimals()
		local list, keep = {}, {}
		local f = workspace:FindFirstChild("Animals")
		if f then
			for _, m in ipairs(f:GetChildren()) do
				if m:IsA("Model") then
					list[#list + 1] = m
					keep[m] = true
				end
			end
		end
		animalList = list
		prune(animalLabels, keep)
	end

	local function healthOf(m)
		local hum = m:FindFirstChildOfClass("Humanoid")
		if hum then return hum.Health end
		local a = m:GetAttribute("Health")
		if type(a) == "number" then return a end
		local v = m:FindFirstChild("Health")
		if v and v:IsA("ValueBase") then return v.Value end
	end

	local function hideAll(labels)
		for _, t in pairs(labels) do t.Visible = false end
	end

	local lastRefresh = 0
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local lpRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
		local from = lpRoot and lpRoot.Position or cam.CFrame.Position
		local oreOn, aniOn = ON("Visual/Ore ESP"), ON("Visual/Animal ESP")

		if (oreOn or aniOn) and now - lastRefresh > 1.5 then
			lastRefresh = now
			if oreOn then refreshOres() end
			if aniOn then refreshAnimals() end
		end

		if oreOn then
			local maxD = V("Visual/Ore ESP/Max distance", 300)
			local showD = V("Visual/Ore ESP/Show distance", true)
			for _, e in ipairs(oreList) do
				local t = oreLabels[e.m]
				local shown = false
				local info = ORE[e.k]
				if e.m.Parent and V(info.row, true) then
					local pos = pivot(e.m)
					if pos then
						local dist = (pos - from).Magnitude
						if dist <= maxD then
							local sp = cam:WorldToViewportPoint(pos)
							if sp.Z > 0 then
								if not t then
									t = newLabel(12)
									oreLabels[e.m] = t
								end
								t.Text = showD and (e.k .. " " .. math.floor(dist) .. "m") or e.k
								t.Color = COLOR_OPTS[V(info.col, info.def)] or COLOR_OPTS[info.def]
								t.Position = Vector2.new(sp.X, sp.Y)
								t.Visible = true
								shown = true
							end
						end
					end
				end
				if not shown and t then t.Visible = false end
			end
		else
			hideAll(oreLabels)
		end

		if aniOn then
			local maxD = V("Visual/Animal ESP/Max distance", 300)
			local showN = V("Visual/Animal ESP/Show name", true)
			local showH = V("Visual/Animal ESP/Show health", true)
			local showD = V("Visual/Animal ESP/Show distance", true)
			local col = COLOR_OPTS[V("Visual/Animal ESP/Animal color", 7)] or COLOR_OPTS[7]
			for _, m in ipairs(animalList) do
				local t = animalLabels[m]
				local shown = false
				if m.Parent then
					local pos = pivot(m)
					if pos then
						local dist = (pos - from).Magnitude
						if dist <= maxD then
							local sp = cam:WorldToViewportPoint(pos + Vector3.new(0, 2, 0))
							if sp.Z > 0 then
								local parts = {}
								if showN then parts[#parts + 1] = m.Name end
								local hp = showH and healthOf(m)
								if hp then parts[#parts + 1] = "[" .. math.floor(hp) .. "]" end
								if showD then parts[#parts + 1] = math.floor(dist) .. "m" end
								if #parts > 0 then
									if not t then
										t = newLabel(13)
										animalLabels[m] = t
									end
									t.Text = table.concat(parts, " ")
									t.Color = col
									t.Position = Vector2.new(sp.X, sp.Y)
									t.Visible = true
									shown = true
								end
							end
						end
					end
				end
				if not shown and t then t.Visible = false end
			end
		else
			hideAll(animalLabels)
		end
	end)

	----------------------------------------------------------- x-ray
	local xTouched = setmetatable({}, {__mode = "k"})
	local function category(name)
		local n = name:lower()
		if n:find("doorway", 1, true) then return "walls" end
		if n:find("door", 1, true) then return "doors" end
		if n:find("wall", 1, true) or n:find("window", 1, true) then return "walls" end
		for _, w in ipairs({"floor", "foundation", "roof", "ceiling", "ramp", "stairs"}) do
			if n:find(w, 1, true) then return "floors" end
		end
	end
	local function xrayRestore()
		for d in pairs(xTouched) do
			pcall(function() d.LocalTransparencyModifier = 0 end)
			xTouched[d] = nil
		end
	end

	local lastX = 0
	RunService.Heartbeat:Connect(function()
		if not ON("Visual/X-ray") then
			if next(xTouched) then xrayRestore() end
			return
		end
		local now = os.clock()
		if now - lastX < 0.5 then return end
		lastX = now
		local b = workspace:FindFirstChild("Buildings")
		if not b then return end
		local a = V("Visual/X-ray/Transparency", 70) / 100
		local want = {
			walls = V("Visual/X-ray/Walls", true),
			floors = V("Visual/X-ray/Floors", false),
			doors = V("Visual/X-ray/Doors", true),
		}
		for _, model in ipairs(b:GetChildren()) do
			local cat = category(model.Name)
			local val = (cat and want[cat]) and a or 0
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then
					if val > 0 then
						if d.LocalTransparencyModifier ~= val then d.LocalTransparencyModifier = val end
						xTouched[d] = true
					elseif xTouched[d] then
						d.LocalTransparencyModifier = 0
						xTouched[d] = nil
					end
				end
			end
		end
	end)
end

----------------------------------------------------------------- AIM (Fust Survival): Aimbot + Silent aim
do
	local UIS = game:GetService("UserInputService")
	local Stats = game:GetService("Stats")
	local TweenService = game:GetService("TweenService")
	local ACCENT = Color3.fromHex("E5312B")
	local WHITE = Color3.new(1, 1, 1)

	----------------------------------------------------------- live UI state
	local ROWS, CARDS = {}, {}
	local function reindex()
		local tabs = getgenv().DramaTABS
		if type(tabs) ~= "table" then return end
		local function walk(rows)
			for _, r in ipairs(rows) do
				if r.t == "g" then walk(r.rows) elseif r.path then ROWS[r.path] = r end
			end
		end
		for _, tab in ipairs(tabs) do
			for _, c in ipairs(tab.cards or {}) do
				if c.path then CARDS[c.path] = c end
				walk(c.rows or {})
			end
		end
	end
	local function V(path, def)
		local r = ROWS[path]
		if r and r.val ~= nil then return r.val end
		return def
	end
	local function ON(path)
		local c = CARDS[path]
		return c ~= nil and c.enabled == true
	end

	local function hit(bind, input)
		if type(bind) ~= "string" then return false end
		local ut = input.UserInputType.Name
		if ut == "MouseButton1" or ut == "MouseButton2" or ut == "MouseButton3" then
			local short = ut:gsub("MouseButton", "Mouse")
			return bind == ut or (bind:gsub("%s", "")) == short
		end
		return input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name == bind
	end

	local function guiRoot()
		local ok, h = pcall(function() return gethui and gethui() end)
		if ok and typeof(h) == "Instance" then return h end
		return lp:FindFirstChild("PlayerGui")
	end
	local function newGui(name, order)
		local root = guiRoot()
		if not root then return nil end
		local old = root:FindFirstChild(name)
		if old then old:Destroy() end
		local g = Instance.new("ScreenGui")
		g.Name = name
		g.ResetOnSpawn = false
		g.IgnoreGuiInset = true
		g.DisplayOrder = order
		g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		g.Parent = root
		return g
	end

	----------------------------------------------------------- shared state (хуки ставятся один раз)
	local S = getgenv().FustAimState
	if type(S) ~= "table" then S = {}; getgenv().FustAimState = S end
	S.on, S.pos, S.part, S.cam, S.camPos = false, nil, nil, nil, nil
	S.firing, S.lastFire = false, -10

	----------------------------------------------------------- auto predict: упреждение = пинг
	local pingMs = 0
	local function updPing(dt)
		local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		if ok and type(v) == "number" then
			if pingMs == 0 then pingMs = v else pingMs = pingMs + (v - pingMs) * math.min(1, dt * 2) end
		end
	end

	----------------------------------------------------------- sleep check
	-- спящий: флаг/значение со словом "sleep" на игроке, персонаже или его детях,
	-- либо персонаж неподвижно лежит (корпус горизонтально)
	local function flagged(inst)
		local ok, attrs = pcall(function() return inst:GetAttributes() end)
		if ok then
			for k, v in pairs(attrs) do
				if (v == true or (type(v) == "number" and v > 0)) and k:lower():find("sleep", 1, true) then return true end
			end
		end
		return false
	end
	local function isSleeping(ch, p)
		if (p and flagged(p)) or flagged(ch) then return true end
		for _, c in ipairs(ch:GetChildren()) do
			if c:IsA("ValueBase") and c.Name:lower():find("sleep", 1, true) then
				local v = c.Value
				if v == true or (type(v) == "number" and v > 0) then return true end
			end
		end
		local root = ch:FindFirstChild("HumanoidRootPart")
		if root and root.AssemblyLinearVelocity.Magnitude < 0.5 and root.CFrame.UpVector.Y < 0.35 then return true end
		return false
	end

	----------------------------------------------------------- wall check
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.IgnoreWater = true
	rp.RespectCanCollide = true
	local function visible(part, ch, origin)
		local mine = lp.Character
		rp.FilterDescendantsInstances = mine and {mine} or {}
		local res = workspace:Raycast(origin, part.Position - origin, rp)
		return res == nil or res.Instance:IsDescendantOf(ch)
	end

	----------------------------------------------------------- выбор цели: ближайшая к центру экрана
	-- o: {dist, wall, sleep, auto}
	local function pick(cam, center, o)
		local origin = cam.CFrame.Position
		local best, bestD
		for _, p in ipairs(Players:GetPlayers()) do
			local ch = p.Character
			if p ~= lp and ch then
				local hum = ch:FindFirstChildOfClass("Humanoid")
				local root = ch:FindFirstChild("HumanoidRootPart")
				local part = ch:FindFirstChild("Head") or root
				if hum and root and part and hum.Health > 0 and not (o.sleep and isSleeping(ch, p)) then
					if (part.Position - origin).Magnitude <= o.dist then
						local sp, vis = cam:WorldToViewportPoint(part.Position)
						if vis then
							local scr = Vector2.new(sp.X, sp.Y)
							local d = (scr - center).Magnitude
							if (not bestD or d < bestD) and (not o.wall or visible(part, ch, origin)) then
								local pos = part.Position
								if o.auto then pos = pos + root.AssemblyLinearVelocity * (pingMs / 1000) end
								best = {part = part, pos = pos, char = ch}
								bestD = d
							end
						end
					end
				end
			end
		end
		return best
	end

	----------------------------------------------------------- silent aim hooks (ставятся один раз)
	local HAS = type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" and type(checkcaller) == "function"
	if not HAS then
		warn("[Fust/Aim] executor не поддерживает hookmetamethod/getnamecallmethod/checkcaller: Silent aim не работает")
	elseif getgenv().FustAimHooked ~= 1 then
		getgenv().FustAimHooked = 1
		local newcc = (type(newcclosure) == "function") and newcclosure or function(f) return f end
		local mouse = lp:GetMouse()
		local RAY = {FindPartOnRay = true, FindPartOnRayWithIgnoreList = true, FindPartOnRayWithWhitelist = true}
		local VPR = {ScreenPointToRay = true, ViewportPointToRay = true}

		local oldNC
		oldNC = hookmetamethod(game, "__namecall", newcc(function(self, ...)
			local method = getnamecallmethod()
			if S.on and S.pos and (S.firing or os.clock() - S.lastFire < 0.25) and not checkcaller() then
				local cp = S.camPos
				if self == workspace then
					if method == "Raycast" then
						local o, d = ...
						if typeof(o) == "Vector3" and typeof(d) == "Vector3" and d.Magnitude >= 30 and cp and (o - cp).Magnitude < 60 then
							local v = S.pos - o
							if v.Magnitude > 0.001 then
								local args = table.pack(...)
								args[2] = v.Unit * d.Magnitude
								return oldNC(self, table.unpack(args, 1, args.n))
							end
						end
					elseif RAY[method] then
						local r = ...
						if typeof(r) == "Ray" and r.Direction.Magnitude >= 30 and cp and (r.Origin - cp).Magnitude < 60 then
							local v = S.pos - r.Origin
							if v.Magnitude > 0.001 then
								local args = table.pack(...)
								args[1] = Ray.new(r.Origin, v.Unit * r.Direction.Magnitude)
								return oldNC(self, table.unpack(args, 1, args.n))
							end
						end
					end
				elseif VPR[method] and cp and self == S.cam then
					local v = S.pos - cp
					if v.Magnitude > 0.001 then return Ray.new(cp, v.Unit) end
				end
			end
			return oldNC(self, ...)
		end))

		local oldIdx
		oldIdx = hookmetamethod(game, "__index", newcc(function(self, key)
			if self == mouse and (key == "Hit" or key == "Target" or key == "UnitRay") and S.on and S.pos
				and (S.firing or os.clock() - S.lastFire < 0.25) and not checkcaller() then
				if key == "Hit" then
					return CFrame.new(S.pos)
				elseif key == "Target" then
					return S.part
				else
					local cp = S.camPos
					if cp and (S.pos - cp).Magnitude > 0.001 then return Ray.new(cp, (S.pos - cp).Unit) end
				end
			end
			return oldIdx(self, key)
		end))
	end

	----------------------------------------------------------- детект выстрелов
	local aimHeld, touchOn = false, false
	UIS.InputBegan:Connect(function(input, gp)
		local ut = input.UserInputType
		if ut == Enum.UserInputType.Touch or ut == Enum.UserInputType.MouseButton1 then
			S.firing = true
			S.lastFire = os.clock()
		end
		if gp then return end
		if ON("Aim/Aimbot") and hit(V("Aim/Aimbot/Hotkey", "Mouse 2"), input) then aimHeld = true end
	end)
	UIS.InputEnded:Connect(function(input)
		local ut = input.UserInputType
		if ut == Enum.UserInputType.MouseButton1 or ut == Enum.UserInputType.Touch then
			S.firing = false
			S.lastFire = os.clock()
		end
		if hit(V("Aim/Aimbot/Hotkey", "Mouse 2"), input) then aimHeld = false end
	end)
	do
		local hooked = setmetatable({}, {__mode = "k"})
		local function hookTool(tool)
			if hooked[tool] or not tool:IsA("Tool") then return end
			hooked[tool] = true
			tool.Activated:Connect(function() S.lastFire = os.clock() end)
		end
		local function hookChar(ch)
			for _, o in ipairs(ch:GetChildren()) do hookTool(o) end
			ch.ChildAdded:Connect(hookTool)
		end
		if lp.Character then hookChar(lp.Character) end
		lp.CharacterAdded:Connect(hookChar)
	end

	----------------------------------------------------------- кнопка для телефона (Pill, перетаскивается)
	local ICON_IDLE = Color3.fromHex("C4C4C9")
	local KNOB_IDLE = Color3.fromHex("D0D0D4")
	local function buildPill(name, pos, onTap)
		local gui = newGui(name, 1001)
		if not gui then return nil end
		local function frame(parent, props, round)
			local f = Instance.new("Frame")
			f.BorderSizePixel = 0
			for k, v in pairs(props) do f[k] = v end
			if round then
				local uc = Instance.new("UICorner")
				uc.CornerRadius = UDim.new(1, 0)
				uc.Parent = f
			end
			f.Parent = parent
			return f
		end
		local b = Instance.new("TextButton")
		b.Text = ""
		b.AutoButtonColor = false
		b.AnchorPoint = Vector2.new(.5, .5)
		b.Position = pos
		b.Size = UDim2.fromOffset(94, 42)
		b.BackgroundColor3 = Color3.fromHex("121214")
		b.BackgroundTransparency = 0.4
		b.BorderSizePixel = 0
		b.Parent = gui
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(1, 0)
		bc.Parent = b
		local st = Instance.new("UIStroke")
		st.Thickness = 1
		st.Color = WHITE
		st.Transparency = 0.86
		st.Parent = b

		local icon = frame(b, {AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 14, .5, 0),
			Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1})
		local ring = frame(icon, {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
			Size = UDim2.fromOffset(13, 13), BackgroundTransparency = 1}, true)
		local rs = Instance.new("UIStroke")
		rs.Thickness = 1.5
		rs.Color = ICON_IDLE
		rs.Parent = ring
		local parts = {}
		local function tick(x, y, w, h)
			parts[#parts + 1] = frame(icon, {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(x, y),
				Size = UDim2.fromOffset(w, h), BackgroundColor3 = ICON_IDLE})
		end
		tick(11, 2, 2, 4); tick(11, 20, 2, 4); tick(2, 11, 4, 2); tick(20, 11, 4, 2)
		parts[#parts + 1] = frame(icon, {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
			Size = UDim2.fromOffset(3, 3), BackgroundColor3 = ICON_IDLE}, true)

		local track = frame(b, {AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -9, .5, 0),
			Size = UDim2.fromOffset(36, 22), BackgroundColor3 = WHITE, BackgroundTransparency = 0.86}, true)
		local knob = frame(track, {AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 3, .5, 0),
			Size = UDim2.fromOffset(16, 16), BackgroundColor3 = KNOB_IDLE}, true)

		local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local function apply(on)
			local c = on and ACCENT or ICON_IDLE
			TweenService:Create(rs, ti, {Color = c}):Play()
			for _, p in ipairs(parts) do TweenService:Create(p, ti, {BackgroundColor3 = c}):Play() end
			TweenService:Create(st, ti, {Color = on and ACCENT or WHITE, Transparency = on and 0.4 or 0.86}):Play()
			TweenService:Create(track, ti, {BackgroundColor3 = on and ACCENT or WHITE, BackgroundTransparency = on and 0.65 or 0.86}):Play()
			TweenService:Create(knob, ti, {Position = UDim2.new(0, on and 17 or 3, .5, 0), BackgroundColor3 = on and ACCENT or KNOB_IDLE}):Play()
		end

		local tracked, startPos, startCenter, moved
		b.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				tracked, moved = input, false
				startPos = input.Position
				startCenter = b.AbsolutePosition + b.AbsoluteSize / 2
			end
		end)
		UIS.InputChanged:Connect(function(input)
			if tracked and input == tracked then
				local d = input.Position - startPos
				if moved or Vector2.new(d.X, d.Y).Magnitude > 10 then
					moved = true
					local cam = workspace.CurrentCamera
					local vp = cam and cam.ViewportSize or Vector2.new(800, 400)
					b.Position = UDim2.fromOffset(math.clamp(startCenter.X + d.X, 47, vp.X - 47), math.clamp(startCenter.Y + d.Y, 21, vp.Y - 21))
				end
			end
		end)
		UIS.InputEnded:Connect(function(input)
			if input == tracked then tracked = nil end
		end)
		b.Activated:Connect(function()
			if moved then moved = false; return end
			onTap()
		end)
		return {gui = gui, apply = apply}
	end
	local pAim = {}
	local function pillStep(slot, wanted, state)
		if wanted then
			if not slot.gui or not slot.gui.Parent or not slot.apply then
				local r = buildPill("FustAimTouch", UDim2.fromScale(.84, .6), function() touchOn = not touchOn end)
				slot.gui, slot.apply, slot.shown = r and r.gui, r and r.apply, nil
			end
			if slot.gui and slot.apply then
				slot.gui.Enabled = true
				if slot.shown ~= state then slot.shown = state; slot.apply(state) end
			end
		elseif slot.gui then
			slot.gui.Enabled = false
		end
	end

	----------------------------------------------------------- loop
	local indexed = false
	local function update(dt)
		if not indexed then
			reindex()
			if next(ROWS) then indexed = true end
		end
		local cam = workspace.CurrentCamera
		if not cam then return end
		S.cam, S.camPos = cam, cam.CFrame.Position
		updPing(dt)
		local vp = cam.ViewportSize
		local center = Vector2.new(vp.X / 2, vp.Y / 2)

		-- Aimbot
		local abOn = ON("Aim/Aimbot")
		local tw = UIS.TouchEnabled and not UIS.KeyboardEnabled
		pillStep(pAim, abOn and tw, touchOn)
		if not (abOn and tw) then touchOn = false end
		if not abOn then aimHeld = false end
		if abOn and (aimHeld or touchOn) then
			local t = pick(cam, center, {
				dist = V("Aim/Aimbot/Distance", 300),
				wall = V("Aim/Aimbot/Wall check", true),
				sleep = V("Aim/Aimbot/Sleep check", true),
				auto = V("Aim/Aimbot/Auto predict", true),
			})
			if t then
				local cf = cam.CFrame
				local s = math.clamp(V("Aim/Aimbot/Smoothing", 20), 0, 95) / 100
				local alpha = math.clamp(1 - s ^ (dt * 60), 0, 1)
				cam.CFrame = cf:Lerp(CFrame.lookAt(cf.Position, t.pos), alpha)
			end
		end

		-- Silent aim
		if ON("Aim/Silent aim") then
			local t = pick(cam, center, {
				dist = V("Aim/Silent aim/Distance", 300),
				wall = V("Aim/Silent aim/Wall check", true),
				sleep = V("Aim/Silent aim/Sleep check", true),
				auto = V("Aim/Silent aim/Auto predict", true),
			})
			S.on = true
			if t then S.pos, S.part = t.pos, t.part else S.pos, S.part = nil, nil end
		else
			S.on, S.pos, S.part = false, nil, nil
		end
	end

	local warned = false
	pcall(function() RunService:UnbindFromRenderStep("FustAim") end)
	RunService:BindToRenderStep("FustAim", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local ok, err = pcall(update, dt)
		if not ok and not warned then
			warned = true
			warn("[Fust/Aim] " .. tostring(err))
		end
	end)
end

----------------------------------------------------------------- AMBIENT
do
	local Lighting = game:GetService("Lighting")
	local CC = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	if not CC.Parent then CC.Parent = Lighting end
	local origBrightness = Lighting.Brightness
	local origAmbient = Lighting.Ambient
	local origCC = {Brightness = CC.Brightness, Saturation = CC.Saturation, Contrast = CC.Contrast}

	-- Night Vision
	local nvEnabled = false
	local nvBrightness = 5
	local nvSaturation = 0

	local function applyNV()
		if nvEnabled then
			Lighting.Brightness = nvBrightness
			Lighting.Ambient = Color3.fromRGB(150, 150, 150)
			CC.Brightness = nvBrightness * 0.1
			CC.Saturation = nvSaturation
			CC.Contrast = 0.1
		else
			Lighting.Brightness = origBrightness
			Lighting.Ambient = origAmbient
			CC.Brightness = origCC.Brightness
			CC.Saturation = origCC.Saturation
			CC.Contrast = origCC.Contrast
		end
	end

	-- Shadows
	local function applyNoShadows(on)
		pcall(function()
			Lighting.GlobalShadows = not on
		end)
	end

	-- Foliage
	local function setDescTrans(folder, trans)
		local f = workspace:FindFirstChild(folder)
		if f then
			for _, d in ipairs(f:GetDescendants()) do
				if d:IsA("BasePart") or d:IsA("UnionOperation") then
					pcall(function() d.LocalTransparencyModifier = trans end)
				end
			end
		end
	end

	local function removeLeaves(on)
		-- скрываем листья через Terrain Decoration или Parts с "Leaf"/"Leaves" в имени
		for _, d in ipairs(workspace:GetDescendants()) do
			local n = d.Name:lower()
			if d:IsA("BasePart") and (n:find("leaf") or n:find("leave") or n:find("foliage") or n:find("bush") or n:find("canopy")) then
				pcall(function() d.LocalTransparencyModifier = on and 1 or 0 end)
			end
		end
		-- Terrain leaves
		pcall(function()
			workspace.Terrain.Decoration = not on
		end)
	end

	local function removeGrass(on)
		pcall(function()
			workspace.Terrain.Decoration = on and false or (not (getgenv()._noLeaves or false))
		end)
		for _, d in ipairs(workspace:GetDescendants()) do
			local n = d.Name:lower()
			if d:IsA("BasePart") and (n:find("grass") or n:find("weed") or n:find("plant")) then
				pcall(function() d.LocalTransparencyModifier = on and 1 or 0 end)
			end
		end
	end

	-- Fog
	local origFogEnd = Lighting.FogEnd
	local origFogStart = Lighting.FogStart
	local function applyNoFog(on)
		if on then
			Lighting.FogEnd = 1e6
			Lighting.FogStart = 1e6
		else
			Lighting.FogEnd = origFogEnd
			Lighting.FogStart = origFogStart
		end
	end

	getgenv()._ambientAPI = {
		setNV = function(on) nvEnabled = on applyNV() end,
		setNVBrightness = function(v) nvBrightness = v if nvEnabled then applyNV() end end,
		setNVSaturation = function(v) nvSaturation = v if nvEnabled then applyNV() end end,
		setNoShadows = applyNoShadows,
		setNoLeaves = removeLeaves,
		setNoGrass = removeGrass,
		setNoFog = applyNoFog,
	}
end

----------------------------------------------------------------- HOOKS
getgenv().DramaHooks = {
	-- ESP
	["Visual/ESP"] = function(on) setESP(on) end,
	["Visual/ESP/Box"] = function(v) setCfg("box", v) end,
	["Visual/ESP/HpBar"] = function(v) setCfg("hpBar", v) end,
	["Visual/ESP/hpNum"] = function(v) setCfg("hpNum", v) end,
	["Visual/ESP/Distance"] = function(v) setCfg("distance", v) end,
	["Visual/ESP/Nickname"] = function(v) setCfg("nickname", v) end,
	["Visual/ESP/Armor bar"] = function(v) setCfg("armorBar", v) end,
	["Visual/ESP/Weapon"] = function(v) setCfg("weapon", v) end,
	["Visual/ESP/Arrows"] = function(v) setCfg("arrows", v) end,
	["Visual/ESP/Vis check"] = function(v) setCfg("visCheck", v) end,
	["Visual/ESP/Corner color"] = function(v) setCfg("cornerColor", COLOR_OPTS[v] or COLOR_OPTS[2]) end,
	["Visual/ESP/Visible color"] = function(v) cfg.visColor = COLOR_OPTS[v] or COLOR_OPTS[3] end,
	["Visual/ESP/Hidden color"] = function(v) cfg.hidColor = COLOR_OPTS[v] or COLOR_OPTS[4] end,
	["Visual/ESP/Arrow color"] = function(v) cfg.arrowColor = COLOR_OPTS[v] or COLOR_OPTS[4] end,
	["Visual/ESP/Max distance"] = function(v) cfg.maxDist = v end,
	["Visual/ESP/Skeleton"] = function(v) setCfg("skeleton", v) end,
	["Visual/ESP/HP position"] = function(v) setCfg("hpPos", resolveHpPos(v)) end,
	["Visual/ESP/Preview"] = function(v) setPreview(v) end,
	["Miscellaneous/Language/Language"] = function(v) setLang(v) end,
	-- Ambient
	["Ambient/Night Vision"] = function(on) getgenv()._ambientAPI.setNV(on) end,
	["Ambient/Night Vision/NV brightness"] = function(v) getgenv()._ambientAPI.setNVBrightness(v) end,
	["Ambient/Night Vision/NV saturation"] = function(v) getgenv()._ambientAPI.setNVSaturation(v) end,
	["Ambient/Shadows/No shadows"] = function(v) getgenv()._ambientAPI.setNoShadows(v) end,
	["Ambient/Foliage/No leaves"] = function(v) getgenv()._ambientAPI.setNoLeaves(v) end,
	["Ambient/Foliage/No grass"] = function(v) getgenv()._ambientAPI.setNoGrass(v) end,
	["Ambient/Fog"] = function(on) getgenv()._ambientAPI.setNoFog(on) end,
	["Ambient/Fog/Remove fog"] = function(v) getgenv()._ambientAPI.setNoFog(v) end,
}

----------------------------------------------------------------- LOAD UI
loadstring(game:HttpGet("https://raw.githubusercontent.com/Gasantr12k/Ui-Drama/main/FustSurvival_Client_v01.client"))()

task.delay(0.5, function() setLang(2) end)
task.delay(2.5, function() setLang(2) end)
