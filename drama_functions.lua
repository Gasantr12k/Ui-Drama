local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local lp = Players.LocalPlayer

----------------------------------------------------------------- ESP
local espEnabled = false
local cfg = {
	box=true, hpBar=true, hpNum=true, distance=true, nickname=true, skeleton=true,
	maxDist=500, hpPos="Right", armorBar=true,
	cornerColor=Color3.fromRGB(124,240,208), skelColor=Color3.new(1,1,1),
}
local HP_POS = {"Left","Right","Top","Bottom"}
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
	return o
end

local function hideObj(o)
	for _, x in ipairs(o.all) do x.Visible = false end
end

local function renderObj(o, d)
	local top, bot, cx, hw = d.top, d.bot, d.cx, d.hw
	local compact = (bot - top) < 40
	if compact then
		local cy0 = (top + bot) / 2
		top, bot, hw = cy0 - 7, cy0 + 7, 7
	end
	local cy = (top + bot) / 2
	local l, r, h = cx - hw, cx + hw, bot - top
	local col = hpColor(d.hp)
	local pos = cfg.hpPos
	local th, gap = 3, 5
	local armor = (cfg.armorBar and d.armor and d.armor > 0) and math.clamp(d.armor / 100, 0, 1) or nil

	for i = 1, 8 do
		o.c[i].Visible = cfg.box
		o.cOut[i].Visible = cfg.box
	end
	if cfg.box then
		local L = compact and 5 or math.clamp(h * 0.18, 6, 14)
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
			o.c[i1].Color = cfg.cornerColor
			o.c[i2].Color = cfg.cornerColor
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

	o.name.Visible = cfg.nickname
	if cfg.nickname then
		o.name.Text = d.name
		o.name.Position = Vector2.new(cx, top - 16 - barTop)
	end

	o.dist.Visible = cfg.distance
	if cfg.distance then
		o.dist.Text = d.dist .. "m"
		o.dist.Position = Vector2.new(cx, bot + 3 + barBot)
	end

	o.hpNum.Visible = cfg.hpNum
	if cfg.hpNum then
		o.hpNum.Text = tostring(d.hpn)
		local px, py
		if compact then px, py = r + 24, cy - 7
		elseif pos == "Left" then px, py = (armor and ax or bx) - 11, bot - 12
		elseif pos == "Right" then px, py = (armor and ax or bx) + th + 11, bot - 12
		else px, py = r + 12, by - 5 end
		o.hpNum.Position = Vector2.new(px, py)
	end

	for i = 1, MAXB do
		local b = (cfg.skeleton and not compact and d.bones) and d.bones[i]
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

		if not (hum and root and head) then
			hideObj(o)
			continue
		end

		local dist = lpRoot and math.floor((lpRoot.Position - root.Position).Magnitude) or 0
		if dist > cfg.maxDist then
			hideObj(o)
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

		renderObj(o, {
			top = top, bot = bot, cx = (hp.X + fp.X) / 2, hw = (bot - top) * 0.275,
			hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1),
			hpn = math.floor(hum.Health), dist = dist, name = p.DisplayName, bones = bl, armor = getArmor(char),
		})
	end
end)

----------------------------------------------------------------- CROSSHAIR
local crosshairGui, crosshairImg = nil, nil
local CROSSHAIR_IDS = {"rbxassetid://10213989924", "rbxassetid://7831350554", "rbxassetid://7831350554"}
-- ^^ Custom 1, 2, 3 — замени на свои айди

local _chEnabled = false
local _chStyle = 1
local _chSize = 14
local _chOpacity = 100

local function updateCrosshair()
	if crosshairGui then crosshairGui:Destroy(); crosshairGui = nil; crosshairImg = nil end
	if not _chEnabled then return end
	if _chStyle == 1 then return end
	local id = CROSSHAIR_IDS[_chStyle - 1]
	if not id or id == "" then return end
	crosshairGui = Instance.new("ScreenGui", lp:WaitForChild("PlayerGui"))
	crosshairGui.Name = "DramaCrosshair"
	crosshairGui.ResetOnSpawn = false
	crosshairGui.DisplayOrder = 999
	crosshairGui.IgnoreGuiInset = true
	crosshairImg = Instance.new("ImageLabel", crosshairGui)
	crosshairImg.BackgroundTransparency = 1
	crosshairImg.Image = id
	crosshairImg.AnchorPoint = Vector2.new(.5, .5)
	crosshairImg.Position = UDim2.fromScale(.5, .5)
	crosshairImg.Size = UDim2.fromOffset(_chSize * 4, _chSize * 4)
	crosshairImg.ImageTransparency = 1 - (_chOpacity / 100)
end

----------------------------------------------------------------- AMBIENT
local Lighting = game:GetService("Lighting")

local function getOrCreate(class)
	return Lighting:FindFirstChildOfClass(class) or Instance.new(class, Lighting)
end

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
	ru = {["Skeleton"]="Скелет",["HP position"]="Позиция HP",["Left"]="Слева",["Right"]="Справа",["Top"]="Сверху",["Bottom"]="Снизу",["Corners"]="Углы",["Corners + skeleton"]="Углы + скелет",["ESP preview"]="Предпросмотр ESP",["Armor bar"]="Броня"},
	uk = {["Skeleton"]="Скелет",["HP position"]="Позиція HP",["Left"]="Ліворуч",["Right"]="Праворуч",["Top"]="Зверху",["Bottom"]="Знизу",["Corners"]="Кути",["Corners + skeleton"]="Кути + скелет",["ESP preview"]="Попередній перегляд ESP",["Armor bar"]="Броня"},
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
		local ok, list = pcall(function() return root:GetDescendants() end)
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

local function resolveLang(v)
	if type(v) == "number" then return langMap[math.floor(v)] or "en" end
	if type(v) == "string" then return LANG_ALIAS[v] or LANG_ALIAS[v:lower()] or "en" end
	return "en"
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

-- Aim tab labels
do
	local ADD = {
		ru = {["Silent aim"]="Silent aim",["Aimbot"]="Аимбот",["Wall check"]="Проверка стен",["Target part"]="Часть тела",
			["Target snapline"]="Линия к цели",["Whitelist"]="Белый список",["FOV settings"]="Настройки FOV",["Show circle"]="Показать круг",
			["Radius"]="Радиус",["Closest"]="Ближайшая",["Head"]="Голова",["Torso"]="Торс",
			["Bullet mods"]="Модификации пуль",["Wallbang"]="Wallbang",["Instant hit"]="Мгновенный хит",["Touch button"]="Кнопка для телефона",["Auto"]="Авто",
			["Dead check"]="Проверка смерти",["Team check"]="Проверка команды",["Target priority"]="Приоритет цели",["Health"]="Здоровье",["Hit chance"]="Шанс попадания",["Prediction"]="Упреждение",["Sticky target"]="Липкая цель",["Triggerbot"]="Триггербот",["Delay"]="Задержка",["Target info"]="Инфо о цели",["Position"]="Позиция",["Top"]="Сверху",["Right"]="Справа",["Bottom"]="Снизу",
			["Auto prediction"]="Авто-упреждение",["Weapon profiles"]="Профили оружия",["Override"]="Переопределить",["Revolver"]="Револьвер",["Shotgun"]="Дробовик",["Rifle"]="Винтовка",["Hit sound"]="Звук попадания",["Hit"]="Попадание",["Knock"]="Нокаут",["Spectate"]="Наблюдение",["Off"]="Выкл"},
		uk = {["Silent aim"]="Silent aim",["Aimbot"]="Аімбот",["Wall check"]="Перевірка стін",["Target part"]="Частина тіла",
			["Target snapline"]="Лінія до цілі",["Whitelist"]="Білий список",["FOV settings"]="Налаштування FOV",["Show circle"]="Показати коло",
			["Radius"]="Радіус",["Closest"]="Найближча",["Head"]="Голова",["Torso"]="Торс",
			["Bullet mods"]="Модифікації куль",["Wallbang"]="Wallbang",["Instant hit"]="Миттєвий хіт",["Touch button"]="Кнопка для телефона",["Auto"]="Авто",
			["Dead check"]="Перевірка смерті",["Team check"]="Перевірка команди",["Target priority"]="Пріоритет цілі",["Health"]="Здоров'я",["Hit chance"]="Шанс влучання",["Prediction"]="Упередження",["Sticky target"]="Липка ціль",["Triggerbot"]="Тригербот",["Delay"]="Затримка",["Target info"]="Інфо про ціль",["Position"]="Позиція",["Top"]="Зверху",["Right"]="Справа",["Bottom"]="Знизу",
			["Auto prediction"]="Авто-упередження",["Weapon profiles"]="Профілі зброї",["Override"]="Перевизначити",["Revolver"]="Револьвер",["Shotgun"]="Дробовик",["Rifle"]="Гвинтівка",["Hit sound"]="Звук влучання",["Hit"]="Влучання",["Knock"]="Нокаут",["Spectate"]="Спостереження",["Off"]="Вимк"},
	}
	for code, add in pairs(ADD) do
		LANG[code] = LANG[code] or {}
		for k, v in pairs(add) do
			if LANG[code][k] == nil then LANG[code][k] = v end
		end
	end
end

local function applyLang(idx, TABS)
	local dict = LANG[langMap[idx] or "en"] or {}
	for _, tab in ipairs(TABS) do
		tab._origName = tab._origName or tab.name
		tab._origGroup = tab._origGroup or tab.group
		tab.name = dict[tab._origName] or tab._origName
		tab.group = dict[tab._origGroup] or tab._origGroup
		if tab.cards then
			for _, card in ipairs(tab.cards) do
				card._origTitle = card._origTitle or card.title
				card.title = dict[card._origTitle] or card._origTitle
				if card.rows then
					local function patchRows(rows)
						for _, r in ipairs(rows) do
							r._origL = r._origL or r.l
							r.l = dict[r._origL] or r._origL
							if r.t == "g" and r.rows then patchRows(r.rows) end
						end
					end
					patchRows(card.rows)
				end
			end
		end
	end
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
panel.Size = UDim2.fromOffset(PW, 480)
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

local TOGGLES = {{"Box","box"},{"HpBar","hpBar"},{"hpNum","hpNum"},{"Distance","distance"},{"Nickname","nickname"},{"Skeleton","skeleton"}}
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
	})
end)

----------------------------------------------------------------- AIM
-- Silent aim + Aimbot (вкладка Aim). Состояние читается прямо из UI (DramaTABS).
do
	local ACCENT = Color3.fromHex("E5312B")

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

	----------------------------------------------------------- shared state (переживает повторный запуск)
	local S = getgenv().DramaAimState
	if type(S) ~= "table" then S = {}; getgenv().DramaAimState = S end
	S.on, S.pos, S.part, S.cam, S.camPos = false, nil, nil, nil, nil
	S.firing, S.lastFire, S.roll = false, -10, true

	local WL = getgenv().DramaWhitelist
	if type(WL) ~= "table" then WL = {}; getgenv().DramaWhitelist = WL end
	local WL_FILE = "DramaWhitelist.json"
	local function saveWL()
		if type(writefile) ~= "function" then return end
		local names = {}
		for n in pairs(WL) do names[#names + 1] = n end
		pcall(function() writefile(WL_FILE, game:GetService("HttpService"):JSONEncode(names)) end)
	end
	do
		if type(isfile) == "function" and type(readfile) == "function" then
			pcall(function()
				if isfile(WL_FILE) then
					local names = game:GetService("HttpService"):JSONDecode(readfile(WL_FILE))
					if type(names) == "table" then
						for _, n in ipairs(names) do
							if type(n) == "string" then WL[n] = true end
						end
					end
				end
			end)
		end
	end

	----------------------------------------------------------- drawing
	local prevDraw = getgenv().DramaAimDraw
	if type(prevDraw) == "table" then
		for _, d in pairs(prevDraw) do pcall(function() d:Remove() end) end
	end
	local draw = {}
	getgenv().DramaAimDraw = draw
	local function mkDraw(class, props)
		local ok, d = pcall(function() return Drawing.new(class) end)
		if not ok or not d then return nil end
		for k, v in pairs(props) do pcall(function() d[k] = v end) end
		draw[#draw + 1] = d
		return d
	end
	local fovCircle = mkDraw("Circle", {Visible = false, Thickness = 1, NumSides = 64, Filled = false, Color = ACCENT, Transparency = 1})
	local silentCircle = mkDraw("Circle", {Visible = false, Thickness = 1, NumSides = 64, Filled = false, Color = Color3.fromHex("22D3EE"), Transparency = 1})
	local snapLine = mkDraw("Line", {Visible = false, Thickness = 1.5, Color = ACCENT, Transparency = 1})

	----------------------------------------------------------- target selection
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

	-- мёртв / нокнут (Da Hood: BodyEffects["K.O"] / ["Dead"])
	local function isDead(ch, hum)
		if hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then return true end
		local be = ch:FindFirstChild("BodyEffects")
		if be then
			local ko = be:FindFirstChild("K.O")
			if ko and ko.Value == true then return true end
			local dd = be:FindFirstChild("Dead")
			if dd and dd.Value == true then return true end
		end
		return false
	end

	local function candidates(ch, mode)
		local out = {}
		local function add(x) if x and x:IsA("BasePart") then out[#out + 1] = x end end
		local head = ch:FindFirstChild("Head")
		local torso = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("HumanoidRootPart")
		if mode == 1 then
			add(head)
		elseif mode == 2 then
			add(torso)
		else
			add(head); add(torso); add(ch:FindFirstChild("HumanoidRootPart"))
		end
		return out
	end

	-- o: {dist, mode (1 Head/2 Torso/3 Closest), prio (1 Crosshair/2 Distance/3 Health), wall, fov, dead, team, pred (ms), only}
	local function pick(cam, center, o)
		local origin = cam.CFrame.Position
		local best, bestScore
		for _, p in ipairs(Players:GetPlayers()) do
			local ch = p.Character
			if p ~= lp and ch and not WL[p.Name] and (not o.only or ch == o.only)
				and not (o.team and lp.Team and p.Team == lp.Team) then
				local hum = ch:FindFirstChildOfClass("Humanoid")
				if hum and (not o.dead or not isDead(ch, hum)) then
					for _, part in ipairs(candidates(ch, o.mode)) do
						local wd = (part.Position - origin).Magnitude
						if wd <= o.dist then
							local sp, vis = cam:WorldToViewportPoint(part.Position)
							if vis then
								local scr = Vector2.new(sp.X, sp.Y)
								local d = (scr - center).Magnitude
								if not o.fov or d <= o.fov then
									local score = d
									if o.prio == 2 then score = wd elseif o.prio == 3 then score = hum.Health end
									if (not bestScore or score < bestScore) and (not o.wall or visible(part, ch, origin)) then
										local pos = part.Position
										if o.pred and o.pred > 0 then
											local root = ch:FindFirstChild("HumanoidRootPart")
											if root then pos = pos + root.AssemblyLinearVelocity * (o.pred / 1000) end
										end
										best = {part = part, pos = pos, screen = scr, char = ch}
										bestScore = score
									end
								end
							end
						end
					end
				end
			end
		end
		return best
	end

	-- Sticky: проверка уже захваченной цели БЕЗ FOV, стен и экрана. Цель теряется только если она
	-- мертва, вышла за Distance, попала в whitelist/команду или пропала.
	local function lockOn(cam, center, ch, o)
		if not ch or not ch.Parent then return nil end
		local plr = Players:GetPlayerFromCharacter(ch)
		if not plr or plr == lp or WL[plr.Name] then return nil end
		if o.team and lp.Team and plr.Team == lp.Team then return nil end
		local hum = ch:FindFirstChildOfClass("Humanoid")
		if not hum then return nil end
		if o.dead and isDead(ch, hum) then return nil end
		local origin = cam.CFrame.Position
		local best, bestD
		for _, part in ipairs(candidates(ch, o.mode)) do
			if (part.Position - origin).Magnitude <= o.dist then
				local sp = cam:WorldToViewportPoint(part.Position)
				local scr = Vector2.new(sp.X, sp.Y)
				local d = (scr - center).Magnitude
				if not bestD or d < bestD then
					local pos = part.Position
					if o.pred and o.pred > 0 then
						local root = ch:FindFirstChild("HumanoidRootPart")
						if root then pos = pos + root.AssemblyLinearVelocity * (o.pred / 1000) end
					end
					best = {part = part, pos = pos, screen = scr, char = ch}
					bestD = d
				end
			end
		end
		return best
	end

	-- Triggerbot: авто-выстрел, когда в центре экрана живой враг
	local trp = RaycastParams.new()
	trp.FilterType = Enum.RaycastFilterType.Exclude
	trp.IgnoreWater = true
	local lastTrig = 0
	local rollT = 0
	local function rollHit()
		S.roll = math.random(1, 100) <= V("Aim/Silent aim/Hit chance", 100)
		rollT = os.clock()
	end
	local function trigger(cam, center)
		if not ON("Aim/Triggerbot") then return end
		local mine = lp.Character
		trp.FilterDescendantsInstances = mine and {mine} or {}
		local ray = cam:ViewportPointToRay(center.X, center.Y)
		local res = workspace:Raycast(ray.Origin, ray.Direction * V("Aim/Triggerbot/Distance", 300), trp)
		if not res then return end
		local model = res.Instance:FindFirstAncestorOfClass("Model")
		local p = model and Players:GetPlayerFromCharacter(model)
		if not p or p == lp or WL[p.Name] then return end
		if V("Aim/Triggerbot/Team check", true) and lp.Team and p.Team == lp.Team then return end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		if V("Aim/Triggerbot/Dead check", true) and isDead(model, hum) then return end
		local now = os.clock()
		if now - lastTrig < V("Aim/Triggerbot/Delay", 50) / 1000 then return end
		lastTrig = now
		S.lastFire = now
		rollHit()
		if type(mouse1click) == "function" then
			pcall(mouse1click)
		else
			local tool = mine and mine:FindFirstChildOfClass("Tool")
			if tool then tool:Activate() end
		end
	end

	----------------------------------------------------------- whitelist (dropdown со списком игроков)
	local wlNames = {}
	local WL_KEYS = {"Aim/Silent aim/Whitelist", "Aim/Aimbot/Whitelist"}
	local function refreshWL()
		local names = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= lp and p.Parent == Players then names[#names + 1] = p.Name end
		end
		table.sort(names)
		local o = {"Whitelist"}
		wlNames = {false}
		for _, n in ipairs(names) do
			o[#o + 1] = (WL[n] and "+ " or "") .. n
			wlNames[#o] = n
		end
		for _, k in ipairs(WL_KEYS) do
			local r = ROWS[k]
			if r then r.o = o end
		end
	end
	getgenv().DramaAimWLPick = function(v)
		if type(v) ~= "number" then return end
		local n = wlNames[v]
		if n then WL[n] = (not WL[n]) or nil end
		for _, k in ipairs(WL_KEYS) do
			local r = ROWS[k]
			if r then r.val = 1 end
		end
		saveWL()
		refreshWL()
	end
	Players.PlayerAdded:Connect(function() pcall(refreshWL) end)
	Players.PlayerRemoving:Connect(function() task.defer(function() pcall(refreshWL) end) end)

	----------------------------------------------------------- silent aim hooks (ставятся один раз)
	local HAS = type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" and type(checkcaller) == "function"
	if not HAS then
		warn("[Drama/Aim] executor не поддерживает hookmetamethod/getnamecallmethod/checkcaller: Silent aim не работает")
	elseif getgenv().DramaAimHooked ~= 2 then
		getgenv().DramaAimHooked = 2
		local newcc = (type(newcclosure) == "function") and newcclosure or function(f) return f end
		local mouse = lp:GetMouse()
		local RAY = {FindPartOnRay = true, FindPartOnRayWithIgnoreList = true, FindPartOnRayWithWhitelist = true}
		local VPR = {ScreenPointToRay = true, ViewportPointToRay = true}

		local oldNC
		oldNC = hookmetamethod(game, "__namecall", newcc(function(self, ...)
			local method = getnamecallmethod()
			if S.on and (S.firing or os.clock() - S.lastFire < 0.25) and not checkcaller() then
				local cp = S.camPos
				if self == workspace then
					if method == "Raycast" then
						local o, d = ...
						if typeof(o) == "Vector3" and typeof(d) == "Vector3" and d.Magnitude >= 30 and cp and (o - cp).Magnitude < 60 then
							local args = table.pack(...)
							local changed = false
							if S.on and S.pos and S.roll then
								local v = S.pos - o
								if v.Magnitude > 0.001 then args[2] = v.Unit * d.Magnitude; changed = true end
							end
							if changed then return oldNC(self, table.unpack(args, 1, args.n)) end
						end
					elseif RAY[method] then
						local r = ...
						if typeof(r) == "Ray" and r.Direction.Magnitude >= 30 and cp and (r.Origin - cp).Magnitude < 60 then
							local args = table.pack(...)
							local changed = false
							if S.on and S.pos and S.roll then
								local v = S.pos - r.Origin
								if v.Magnitude > 0.001 then args[1] = Ray.new(r.Origin, v.Unit * r.Direction.Magnitude); changed = true end
							end
							if changed then return oldNC(self, table.unpack(args, 1, args.n)) end
						end
					end
				elseif VPR[method] and S.on and S.pos and S.roll and cp and self == S.cam then
					local v = S.pos - cp
					if v.Magnitude > 0.001 then return Ray.new(cp, v.Unit) end
				end
			end
			return oldNC(self, ...)
		end))

		local oldIdx
		oldIdx = hookmetamethod(game, "__index", newcc(function(self, key)
			if self == mouse and (key == "Hit" or key == "Target" or key == "UnitRay") and S.on and S.pos and S.roll
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

	----------------------------------------------------------- touch button (телефон): Pill, перетаскивается
	local touchOn = false
	local tbGui, tbApply, tbShown
	local ICON_IDLE = Color3.fromHex("C4C4C9")
	local KNOB_IDLE = Color3.fromHex("D0D0D4")
	local WHITE = Color3.new(1, 1, 1)

	local function buildTouch()
		tbGui, tbApply, tbShown = newGui("DramaAimTouch", 1001), nil, nil
		if not tbGui then return end
		local TweenService = game:GetService("TweenService")
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
		b.Position = UDim2.fromScale(.84, .6)
		b.Size = UDim2.fromOffset(94, 42)
		b.BackgroundColor3 = Color3.fromHex("121214")
		b.BackgroundTransparency = 0.4
		b.BorderSizePixel = 0
		b.Parent = tbGui
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(1, 0)
		bc.Parent = b
		local st = Instance.new("UIStroke")
		st.Thickness = 1
		st.Color = WHITE
		st.Transparency = 0.86
		st.Parent = b

		-- иконка прицела
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

		-- переключатель
		local track = frame(b, {AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -9, .5, 0),
			Size = UDim2.fromOffset(36, 22), BackgroundColor3 = WHITE, BackgroundTransparency = 0.86}, true)
		local knob = frame(track, {AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 3, .5, 0),
			Size = UDim2.fromOffset(16, 16), BackgroundColor3 = KNOB_IDLE}, true)

		local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		tbApply = function(on)
			local c = on and ACCENT or ICON_IDLE
			TweenService:Create(rs, ti, {Color = c}):Play()
			for _, p in ipairs(parts) do TweenService:Create(p, ti, {BackgroundColor3 = c}):Play() end
			TweenService:Create(st, ti, {Color = on and ACCENT or WHITE, Transparency = on and 0.4 or 0.86}):Play()
			TweenService:Create(track, ti, {BackgroundColor3 = on and ACCENT or WHITE, BackgroundTransparency = on and 0.65 or 0.86}):Play()
			TweenService:Create(knob, ti, {Position = UDim2.new(0, on and 17 or 3, .5, 0), BackgroundColor3 = on and ACCENT or KNOB_IDLE}):Play()
		end

		-- перетаскивание (тап = вкл/выкл, движение пальцем > 10px = перенос)
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
			touchOn = not touchOn
		end)
	end

	-- авто-детект: кнопка только на телефоне/планшете без клавиатуры
	local function touchWanted()
		return UIS.TouchEnabled and not UIS.KeyboardEnabled
	end

	----------------------------------------------------------- input
	local aimHeld = false
	UIS.InputBegan:Connect(function(input, gp)
		local ut = input.UserInputType
		if ut == Enum.UserInputType.Touch or (ut == Enum.UserInputType.MouseButton1 and not gp) then
			S.firing = true
			S.lastFire = os.clock()
			rollHit()
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

	----------------------------------------------------------- loop
	----------------------------------------------------------- target info (карточка цели)
	local inGui, inUI
	local function buildInfo()
		inGui, inUI = newGui("DramaTargetInfo", 1002), nil
		if not inGui then return end
		local function mk(class, parent, props)
			local o = Instance.new(class)
			for k, v in pairs(props) do o[k] = v end
			o.Parent = parent
			return o
		end
		local function label(parent, props)
			props.BackgroundTransparency = 1
			props.Font = Enum.Font.GothamMedium
			props.TextSize = 12
			props.TextColor3 = Color3.fromHex("9A9AA1")
			props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
			props.TextTruncate = Enum.TextTruncate.AtEnd
			return mk("TextLabel", parent, props)
		end
		local f = mk("Frame", inGui, {Size = UDim2.fromOffset(210, 70), BackgroundColor3 = Color3.fromHex("121214"),
			BackgroundTransparency = 0.4, BorderSizePixel = 0})
		mk("UICorner", f, {CornerRadius = UDim.new(0, 12)})
		mk("UIStroke", f, {Thickness = 1, Color = WHITE, Transparency = 0.87})
		local name = label(f, {Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -86, 0, 16), TextSize = 13,
			TextColor3 = Color3.fromHex("F2F2F2"), Text = ""})
		local dist = label(f, {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 11), Size = UDim2.fromOffset(64, 14),
			TextXAlignment = Enum.TextXAlignment.Right, Text = ""})
		local back = mk("Frame", f, {Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 4),
			BackgroundColor3 = WHITE, BackgroundTransparency = 0.88, BorderSizePixel = 0})
		mk("UICorner", back, {CornerRadius = UDim.new(1, 0)})
		local fill = mk("Frame", back, {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromHex("4ADE80"), BorderSizePixel = 0})
		mk("UICorner", fill, {CornerRadius = UDim.new(1, 0)})
		local part = label(f, {Position = UDim2.fromOffset(12, 46), Size = UDim2.fromOffset(100, 14), Text = ""})
		local hpl = label(f, {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 46), Size = UDim2.fromOffset(80, 14),
			TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromHex("F2F2F2"), Text = ""})
		inUI = {f = f, name = name, dist = dist, fill = fill, part = part, hp = hpl}
	end
	local function updInfo(cam, t)
		local ch = t and t.char
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if not ON("Aim/Target info") or not hum then
			if inGui then inGui.Enabled = false end
			return
		end
		if not inGui or not inGui.Parent or not inUI then buildInfo() end
		if not inGui or not inUI then return end
		inGui.Enabled = true
		local pos = V("Aim/Target info/Position", 1)
		local f = inUI.f
		if pos == 2 then
			f.AnchorPoint, f.Position = Vector2.new(1, .5), UDim2.new(1, -16, .35, 0)
		elseif pos == 3 then
			f.AnchorPoint, f.Position = Vector2.new(.5, 1), UDim2.new(.5, 0, 1, -24)
		else
			f.AnchorPoint, f.Position = Vector2.new(.5, 0), UDim2.new(.5, 0, 0, 12)
		end
		local p = Players:GetPlayerFromCharacter(ch)
		local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		inUI.name.Text = p and p.Name or ch.Name
		inUI.dist.Text = math.floor((t.part.Position - cam.CFrame.Position).Magnitude + 0.5) .. " st"
		inUI.part.Text = (t.part.Name == "Head") and "Head" or "Torso"
		inUI.hp.Text = math.max(0, math.floor(hum.Health + 0.5)) .. " HP"
		inUI.fill.Size = UDim2.fromScale(frac, 1)
		inUI.fill.BackgroundColor3 = Color3.fromHSV(frac / 3, 0.75, 0.9)
	end

	----------------------------------------------------------- авто-prediction по пингу
	local Stats = game:GetService("Stats")
	local pingMs = 0
	local function updPing(dt)
		local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		if ok and type(v) == "number" then
			if pingMs == 0 then pingMs = v else pingMs = pingMs + (v - pingMs) * math.min(1, dt * 2) end
		end
	end
	-- base: значение слайдера Prediction (мс); при Auto prediction к нему добавляется пинг
	local function predOf(base, auto)
		local p = base or 0
		if auto then p = p + pingMs end
		return math.clamp(p, 0, 600)
	end

	----------------------------------------------------------- профили оружия (Da Hood)
	local function weaponClass(tool)
		if not tool then return nil end
		local n = (tool.Name:lower():gsub("[%[%]%s%-_]", ""))
		if n:find("revolver", 1, true) then return "Revolver" end
		if n:find("shotgun", 1, true) or n:find("doublebarrel", 1, true) then return "Shotgun" end
		if n == "smg" or n == "silencer" or n == "p90" or n == "glock" or n == "uzi" then return "SMG" end
		if n == "ar" or n == "ak47" or n == "aug" or n == "lmg" or n == "rifle" or n == "drumgun" then return "Rifle" end
		return nil
	end

	----------------------------------------------------------- hit sound
	local SoundService = game:GetService("SoundService")
	local Debris = game:GetService("Debris")
	local SND = {
		"rbxasset://sounds/electronicpingshort.wav",
		"rbxasset://sounds/button.wav",
		"rbxasset://sounds/snap.mp3",
		"rbxasset://sounds/bass.wav",
	}
	-- Custom (5): файлы DramaHit.mp3 / DramaKnock.mp3 в папке workspace executor'а
	local function soundId(idx, kind)
		if idx == 5 then
			local f = (kind == "knock") and "DramaKnock.mp3" or "DramaHit.mp3"
			if type(isfile) == "function" and type(getcustomasset) == "function" then
				local ok, id = pcall(function() if isfile(f) then return getcustomasset(f) end end)
				if ok and id then return id end
			end
			return nil
		end
		return SND[idx]
	end
	local lastSnd = 0
	local function playHit(knock)
		if not ON("Aim/Hit sound") then return end
		local now = os.clock()
		if now - lastSnd < 0.04 then return end
		lastSnd = now
		local vol = V("Aim/Hit sound/Volume", 60) / 100
		if vol <= 0 then return end
		local id = soundId(V(knock and "Aim/Hit sound/Knock" or "Aim/Hit sound/Hit", knock and 4 or 1), knock and "knock" or "hit")
		if not id then return end
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = vol
		s.Parent = SoundService
		s:Play()
		Debris:AddItem(s, 4)
	end

	local lastHit, lastKnock = setmetatable({}, {__mode = "k"}), setmetatable({}, {__mode = "k"})
	local function nearCenter(ch)
		local root = ch:FindFirstChild("HumanoidRootPart")
		local cam = workspace.CurrentCamera
		if not root or not cam then return true end
		local v, vis = cam:WorldToViewportPoint(root.Position)
		if not vis then return false end
		return (Vector2.new(v.X, v.Y) - cam.ViewportSize / 2).Magnitude < cam.ViewportSize.Y * 0.45
	end
	local function knockSound(ch)
		local now = os.clock()
		if now - (lastKnock[ch] or -10) < 1.5 then return end
		if now - (lastHit[ch] or -10) < 2.5 then
			lastKnock[ch] = now
			playHit(true)
		end
	end
	local function watchChar(ch)
		local hum = ch:WaitForChild("Humanoid", 5)
		if not hum then return end
		local last = hum.Health
		local function damaged()
			if (S.firing or os.clock() - S.lastFire < 0.6) and (S.tchar == ch or nearCenter(ch)) then
				lastHit[ch] = os.clock()
				playHit(false)
				return true
			end
			return false
		end
		hum.HealthChanged:Connect(function(h)
			local d = last - h
			last = h
			if d > 0 then
				if damaged() and h <= 0 then knockSound(ch) end
			end
		end)
		local be = ch:WaitForChild("BodyEffects", 5)
		if be then
			local ko = be:FindFirstChild("K.O")
			if ko then
				ko:GetPropertyChangedSignal("Value"):Connect(function()
					if ko.Value == true then knockSound(ch) end
				end)
			end
			local armor = be:FindFirstChild("Armor")
			if armor and armor:IsA("ValueBase") then
				local la = armor.Value
				armor:GetPropertyChangedSignal("Value"):Connect(function()
					local d = la - armor.Value
					la = armor.Value
					if d > 0 then damaged() end
				end)
			end
		end
	end
	local function watchPlayer(p)
		if p == lp then return end
		if p.Character then task.spawn(watchChar, p.Character) end
		p.CharacterAdded:Connect(function(ch) task.spawn(watchChar, ch) end)
	end
	for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
	Players.PlayerAdded:Connect(watchPlayer)

	----------------------------------------------------------- spectate
	local specName, specActive = nil, false
	local specNames = {false}
	local SPEC_KEY = "Aim/Spectate/Player"
	local function refreshSpec()
		local names = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= lp and p.Parent == Players then names[#names + 1] = p.Name end
		end
		table.sort(names)
		local o = {"Off"}
		specNames = {false}
		local sel = 1
		for _, n in ipairs(names) do
			o[#o + 1] = n
			specNames[#o] = n
			if n == specName then sel = #o end
		end
		if sel == 1 then specName = nil end
		local r = ROWS[SPEC_KEY]
		if r then r.o = o; r.val = sel end
	end
	getgenv().DramaAimSpecPick = function(v)
		if type(v) ~= "number" then return end
		specName = (v >= 2) and specNames[v] or nil
	end
	Players.PlayerAdded:Connect(function() pcall(refreshSpec) end)
	Players.PlayerRemoving:Connect(function() task.defer(function() pcall(refreshSpec) end) end)
	-- возвращает true, пока камера наблюдает за игроком (аим в это время отключён)
	local function specUpdate(cam)
		local want
		if ON("Aim/Spectate") and specName then
			local p = Players:FindFirstChild(specName)
			local hum = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if hum then want = hum end
		end
		if want then
			specActive = true
			if cam.CameraSubject ~= want then cam.CameraSubject = want end
			return true
		end
		if specActive then
			specActive = false
			local mine = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
			if mine then cam.CameraSubject = mine end
		end
		return false
	end

	local indexed = false
	local stickyChar
	local function update(dt)
		if not indexed then
			reindex()
			if next(ROWS) then indexed = true; refreshWL(); refreshSpec() end
		end
		local cam = workspace.CurrentCamera
		if not cam then return end
		S.cam, S.camPos = cam, cam.CFrame.Position
		local vp = cam.ViewportSize
		local center = Vector2.new(vp.X / 2, vp.Y / 2)
		if S.firing and os.clock() - rollT > 0.25 then rollHit() end
		updPing(dt)
		local spec = specUpdate(cam)
		local wclass = weaponClass(lp.Character and lp.Character:FindFirstChildOfClass("Tool"))
		local prof
		if wclass and ON("Aim/Weapon profiles") and V("Aim/Weapon profiles/" .. wclass .. "/Override", false) then
			local b = "Aim/Weapon profiles/" .. wclass .. "/"
			prof = {fov = V(b .. "FOV", 150), smooth = V(b .. "Smoothing", 25), pred = V(b .. "Prediction", 0)}
		end

		-- Aimbot
		local abOn = ON("Aim/Aimbot") and not spec
		local abFov = prof and prof.fov or V("Aim/Aimbot/FOV settings/Radius", 150)
		local infoT
		if fovCircle then
			if abOn and V("Aim/Aimbot/FOV settings/Show circle", true) then
				fovCircle.Position = center
				fovCircle.Radius = abFov
				fovCircle.Visible = true
			else
				fovCircle.Visible = false
			end
		end
		if abOn and touchWanted() then
			if not tbGui or not tbGui.Parent or not tbApply then buildTouch() end
			if tbGui and tbApply then
				tbGui.Enabled = true
				if tbShown ~= touchOn then tbShown = touchOn; tbApply(touchOn) end
			end
		else
			touchOn = false
			if tbGui then tbGui.Enabled = false end
		end
		if not abOn then aimHeld = false; touchOn = false end
		if abOn and (aimHeld or touchOn) then
			local o = {
				dist = V("Aim/Aimbot/Distance", 500),
				mode = V("Aim/Aimbot/Target part", 1),
				prio = V("Aim/Aimbot/Target priority", 1),
				wall = V("Aim/Aimbot/Wall check", true),
				fov = abFov,
				dead = V("Aim/Aimbot/Dead check", true),
				team = V("Aim/Aimbot/Team check", false),
				pred = predOf(prof and prof.pred or V("Aim/Aimbot/Prediction", 0), V("Aim/Aimbot/Auto prediction", false)),
			}
			local sticky = V("Aim/Aimbot/Sticky target", false)
			local t
			if sticky and stickyChar then t = lockOn(cam, center, stickyChar, o) end
			if not t then t = pick(cam, center, o) end
			stickyChar = t and t.char or nil
			infoT = t
			-- липкая цель за стеной: камеру не двигаем, но и на другого не переключаемся
			if t and sticky and o.wall and not visible(t.part, t.char, cam.CFrame.Position) then t = nil end
			if t then
				local cf = cam.CFrame
				local s = math.clamp(prof and prof.smooth or V("Aim/Aimbot/Smoothing", 25), 0, 95) / 100
				local alpha = math.clamp(1 - s ^ (dt * 60), 0, 1)
				cam.CFrame = cf:Lerp(CFrame.lookAt(cf.Position, t.pos), alpha)
			end
		else
			stickyChar = nil
		end

		-- Silent aim
		local sOn = ON("Aim/Silent aim") and not spec
		local sFov = prof and prof.fov or V("Aim/Silent aim/FOV settings/Radius", 300)
		if silentCircle then
			if sOn and V("Aim/Silent aim/FOV settings/Show circle", false) then
				silentCircle.Position = center
				silentCircle.Radius = sFov
				silentCircle.Visible = true
			else
				silentCircle.Visible = false
			end
		end
		if sOn then
			local t = pick(cam, center, {
				dist = V("Aim/Silent aim/Distance", 500),
				mode = V("Aim/Silent aim/Target part", 1),
				prio = V("Aim/Silent aim/Target priority", 1),
				wall = V("Aim/Silent aim/Wall check", true),
				fov = sFov,
				dead = V("Aim/Silent aim/Dead check", true),
				team = V("Aim/Silent aim/Team check", false),
				pred = predOf(prof and prof.pred or V("Aim/Silent aim/Prediction", 0), V("Aim/Silent aim/Auto prediction", false)),
			})
			S.on = true
			if not infoT then infoT = t end
			if t then
				S.pos, S.part = t.pos, t.part
				if snapLine then
					if V("Aim/Silent aim/Target snapline", true) then
						snapLine.From = center
						snapLine.To = t.screen
						snapLine.Visible = true
					else
						snapLine.Visible = false
					end
				end
			else
				S.pos, S.part = nil, nil
				if snapLine then snapLine.Visible = false end
			end
		else
			S.on, S.pos, S.part = false, nil, nil
			if snapLine then snapLine.Visible = false end
		end

		S.tchar = infoT and infoT.char or nil
		updInfo(cam, infoT)

		if not spec then trigger(cam, center) end
	end

	local warned = false
	pcall(function() RunService:UnbindFromRenderStep("DramaAim") end)
	pcall(function() RunService:UnbindFromRenderStep("DramaAimSens") end)
	pcall(function() RunService:UnbindFromRenderStep("DramaAimView") end)
	RunService:BindToRenderStep("DramaAim", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local ok, err = pcall(update, dt)
		if not ok and not warned then
			warned = true
			warn("[Drama/Aim] " .. tostring(err))
		end
	end)
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
	["Visual/ESP/Max distance"] = function(v) cfg.maxDist = v end,
	["Visual/ESP/Skeleton"] = function(v) setCfg("skeleton", v) end,
	["Visual/ESP/HP position"] = function(v) setCfg("hpPos", resolveHpPos(v)) end,
	["Visual/ESP/Preview"] = function(v) setPreview(v) end,
	-- Crosshair
	["Visual/Crosshair"] = function(on) _chEnabled = on; updateCrosshair() end,
	["Visual/Crosshair/Enabled"] = function(v) _chEnabled = v; updateCrosshair() end,
	["Visual/Crosshair/Style"] = function(v) _chStyle = v; updateCrosshair() end,
	["Visual/Crosshair/Size"] = function(v)
		_chSize = v
		if crosshairImg then crosshairImg.Size = UDim2.fromOffset(v*4, v*4) end
	end,
	["Visual/Crosshair/Opacity"] = function(v)
		_chOpacity = v
		if crosshairImg then crosshairImg.ImageTransparency = 1-(v/100) end
	end,
	-- Aim (whitelist)
	["Aim/Silent aim/Whitelist"] = function(v) local f = getgenv().DramaAimWLPick; if f then f(v) end end,
	["Aim/Aimbot/Whitelist"] = function(v) local f = getgenv().DramaAimWLPick; if f then f(v) end end,
	["Aim/Spectate/Player"] = function(v) local f = getgenv().DramaAimSpecPick; if f then f(v) end end,
	-- Ambient / Time
	["Ambient/Time/Time of day"] = function(v)
		if v == 1 then return end
		local hours = {6,12,18,0}
		Lighting.TimeOfDay = string.format("%02d:00:00", hours[v-1] or 12)
	end,
	["Ambient/Time/Clock hour"] = function(v)
		Lighting.TimeOfDay = string.format("%02d:00:00", math.floor(v)%24)
	end,
	-- Ambient / Fog (fog = свойства Lighting, не Instance)
	["Ambient/Fog"] = function(v)
		Lighting.FogEnd = v and 500 or 100000
		Lighting.FogStart = v and 0 or 0
	end,
	["Ambient/Fog/Enable fog"] = function(v)
		Lighting.FogEnd = v and 500 or 100000
	end,
	["Ambient/Fog/Fog start"] = function(v) Lighting.FogStart = v end,
	["Ambient/Fog/Fog end"] = function(v) Lighting.FogEnd = v end,
	-- Ambient / Lighting
	["Ambient/Lighting"] = function(v) end,
	["Ambient/Lighting/Brightness"] = function(v) Lighting.Brightness = v/100*2 end,
	["Ambient/Lighting/Ambient"] = function(v)
		local c = v/100*255; Lighting.Ambient = Color3.fromRGB(c,c,c)
	end,
	["Ambient/Lighting/Shadows"] = function(v) Lighting.GlobalShadows = v end,
	-- Ambient / Effects
	["Ambient/Effects"] = function(v) end,
	["Ambient/Effects/Bloom"] = function(v)
		local b = Lighting:FindFirstChildOfClass("BloomEffect")
		if not b then b = Instance.new("BloomEffect"); b.Parent = Lighting end
		b.Enabled = v
	end,
	["Ambient/Effects/Bloom intensity"] = function(v)
		local b = Lighting:FindFirstChildOfClass("BloomEffect")
		if b then b.Intensity = v/10 end
	end,
	["Ambient/Effects/Blur"] = function(v)
		local bl = Lighting:FindFirstChildOfClass("BlurEffect")
		if not bl then bl = Instance.new("BlurEffect"); bl.Parent = Lighting end
		bl.Enabled = v
	end,
	["Ambient/Effects/Blur size"] = function(v)
		local bl = Lighting:FindFirstChildOfClass("BlurEffect")
		if bl then bl.Size = v end
	end,
	["Ambient/Effects/Color correction"] = function(v)
		local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
		if not cc then cc = Instance.new("ColorCorrectionEffect"); cc.Parent = Lighting end
		cc.Enabled = v
	end,
	["Ambient/Effects/Saturation"] = function(v)
		local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
		if cc then cc.Saturation = v/100 end
	end,
	["Ambient/Effects/Contrast"] = function(v)
		local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
		if cc then cc.Contrast = v/100 end
	end,
	["Miscellaneous/Language/Language"] = function(v) setLang(v) end,
}

----------------------------------------------------------------- LOAD UI
loadstring(game:HttpGet("https://raw.githubusercontent.com/Gasantr12k/Ui-Drama/main/Drama_Client.client"))()

task.delay(0.5, function() setLang(2) end)
task.delay(2.5, function() setLang(2) end)
