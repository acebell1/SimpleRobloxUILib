local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local SimpleUILib = {}

-- ============================================================ утилиты

local function New(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	inst.Parent = parent
	return inst
end

local function Merge(defaults, props)
	for k, v in pairs(props) do
		defaults[k] = v
	end
	return defaults
end

local function Label(props, children)
	return New("TextLabel", Merge({
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.new(1, 1, 1),
	}, props), children)
end

local function Button(props, children)
	return New("TextButton", Merge({
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
	}, props), children)
end

local function Corner(radius)
	return New("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function Stroke(color, thickness, transparency)
	return New("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function Padding(l, t, r, b)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0),
		PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0),
	})
end

local function Tween(inst, props, time, style)
	local tween = TweenService:Create(
		inst,
		TweenInfo.new(time or 0.15, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props
	)
	tween:Play()
	return tween
end

local function Safe(callback, ...)
	if typeof(callback) ~= "function" then
		return
	end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(callback, table.unpack(args, 1, args.n))
		if not ok then
			warn("[RealUI] ошибка в callback: " .. tostring(err))
		end
	end)
end

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

local DefaultTheme = {
	Background = Color3.fromRGB(20, 20, 26),
	Topbar = Color3.fromRGB(26, 26, 34),
	Sidebar = Color3.fromRGB(24, 24, 31),
	Element = Color3.fromRGB(32, 32, 42),
	ElementHover = Color3.fromRGB(42, 42, 54),
	Stroke = Color3.fromRGB(52, 52, 66),
	Text = Color3.fromRGB(235, 235, 245),
	SubText = Color3.fromRGB(150, 150, 172),
	Accent = Color3.fromRGB(110, 120, 255),
}

-- ============================================================ классы

local Window = {}
Window.__index = Window

local Container = {}
Container.__index = Container

local Tab = setmetatable({}, { __index = Container })
Tab.__index = Tab

local SubTab = setmetatable({}, { __index = Container })
SubTab.__index = SubTab

-- ============================================================ окно

function Window:_connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(self._connections, c)
	return c
end

function Window:_accent(inst, prop)
	table.insert(self._accents, { inst, prop })
	inst[prop] = self.Theme.Accent
end

function Window:SetAccent(color)
	self.Theme.Accent = color
	for i = #self._accents, 1, -1 do
		local entry = self._accents[i]
		if entry[1] and entry[1].Parent then
			entry[1][entry[2]] = color
		else
			table.remove(self._accents, i)
		end
	end
end

function Window:SetToggleKey(keyCode)
	self.ToggleKey = keyCode
end

function Window:Toggle(state)
	if state == nil then
		state = not self.Main.Visible
	end
	self.Main.Visible = state
end

function Window:Destroy()
	for _, c in ipairs(self._connections) do
		c:Disconnect()
	end
	table.clear(self._connections)
	if self.Gui then
		self.Gui:Destroy()
	end
end

function Window:Notify(cfg)
	cfg = cfg or {}
	local T = self.Theme
	local duration = cfg.Duration or 4

	local wrap = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = self.NotifyHolder,
	})
	local card = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(320, 0),
		BackgroundColor3 = T.Topbar,
		BorderSizePixel = 0,
		Parent = wrap,
	}, {
		Corner(8),
		Stroke(T.Stroke, 1, 0.2),
		Padding(12, 10, 12, 10),
		New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	Label({
		Text = cfg.Title or "Уведомление",
		Font = Enum.Font.GothamBold,
		TextColor3 = T.Text,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 1,
		Parent = card,
	})
	if cfg.Content then
		Label({
			Text = cfg.Content,
			TextSize = 12,
			TextColor3 = T.SubText,
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			Parent = card,
		})
	end
	local bar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = T.ElementHover,
		BorderSizePixel = 0,
		LayoutOrder = 3,
		Parent = card,
	}, { Corner(2) })
	local fill = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Parent = bar,
	}, { Corner(2) })
	self:_accent(fill, "BackgroundColor3")

	Tween(card, { Position = UDim2.fromOffset(0, 0) }, 0.3, Enum.EasingStyle.Back)
	Tween(fill, { Size = UDim2.fromScale(0, 1) }, duration, Enum.EasingStyle.Linear)

	task.delay(duration, function()
		if card.Parent then
			Tween(card, { Position = UDim2.fromOffset(320, 0) }, 0.25)
			task.wait(0.3)
			wrap:Destroy()
		end
	end)
end

function Window:SelectTab(tab)
	for _, t in ipairs(self.Tabs) do
		t:_setActive(t == tab)
	end
	self.ActiveTab = tab
end

function Window:CreateTab(name, icon)
	local T = self.Theme
	local tab = setmetatable({
		Window = self,
		Name = name,
		SubTabs = {},
		_order = 0,
	}, Tab)

	-- кнопка в сайдбаре
	local btn = Button({
		Name = name,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = T.Element,
		LayoutOrder = #self.Tabs + 1,
		Parent = self.TabList,
	}, { Corner(6) })

	local indicator = New("Frame", {
		Size = UDim2.fromOffset(3, 16),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = btn,
	}, { Corner(2) })
	self:_accent(indicator, "BackgroundColor3")

	local textX = 12
	if icon then
		tab.Icon = New("ImageLabel", {
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.new(0, 12, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Image = icon,
			ImageColor3 = T.SubText,
			Parent = btn,
		})
		textX = 36
	end
	tab.Label = Label({
		Text = name,
		TextColor3 = T.SubText,
		Position = UDim2.fromOffset(textX, 0),
		Size = UDim2.new(1, -textX - 6, 1, 0),
		Parent = btn,
	})
	tab.Button, tab.Indicator = btn, indicator

	-- страница вкладки
	tab.Frame = New("Frame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = self.Content,
	})
	tab.SubBar = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		Visible = false,
		Parent = tab.Frame,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	tab.Body = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = tab.Frame,
	})
	tab.Page = self:_newPage(tab.Body)
	tab.Page.Visible = true

	btn.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)
	btn.MouseEnter:Connect(function()
		if not tab.Active then
			Tween(btn, { BackgroundTransparency = 0.6 }, 0.1)
		end
	end)
	btn.MouseLeave:Connect(function()
		if not tab.Active then
			Tween(btn, { BackgroundTransparency = 1 }, 0.1)
		end
	end)

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then
		self:SelectTab(tab)
	end
	return tab
end

function Window:_newPage(parent)
	local T = self.Theme
	return New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = parent,
	}, {
		New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		Padding(0, 2, 8, 8),
	})
end

-- ============================================================ вкладки

function Tab:_setActive(active)
	local T = self.Window.Theme
	self.Active = active
	self.Frame.Visible = active
	Tween(self.Button, { BackgroundTransparency = active and 0 or 1 }, 0.15)
	Tween(self.Indicator, { BackgroundTransparency = active and 0 or 1 }, 0.15)
	Tween(self.Label, { TextColor3 = active and T.Text or T.SubText }, 0.15)
	if self.Icon then
		Tween(self.Icon, { ImageColor3 = active and T.Text or T.SubText }, 0.15)
	end
end

function Tab:SelectSubTab(sub)
	local T = self.Window.Theme
	for _, s in ipairs(self.SubTabs) do
		local active = s == sub
		s.Page.Visible = active
		Tween(s.Button, { BackgroundTransparency = active and 0 or 1 }, 0.15)
		Tween(s.Button, { TextColor3 = active and T.Text or T.SubText }, 0.15)
		Tween(s.Underline, { BackgroundTransparency = active and 0 or 1 }, 0.15)
	end
	self.ActiveSub = sub
end

function Tab:CreateSubTab(name)
	local W = self.Window
	local T = W.Theme
	local sub = setmetatable({ Window = W, Tab = self, Name = name, _order = 0 }, SubTab)

	if #self.SubTabs == 0 then
		self.SubBar.Visible = true
		self.Body.Position = UDim2.fromOffset(0, 34)
		self.Body.Size = UDim2.new(1, 0, 1, -34)
		self.Page.Visible = false
	end

	sub.Button = Button({
		Size = UDim2.new(0, 0, 1, -4),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Element,
		Text = name,
		TextColor3 = T.SubText,
		LayoutOrder = #self.SubTabs + 1,
		Parent = self.SubBar,
	}, { Corner(6), Padding(12, 0, 12, 0) })

	sub.Underline = New("Frame", {
		Size = UDim2.new(1, -16, 0, 2),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -2),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = sub.Button,
	}, { Corner(1) })
	W:_accent(sub.Underline, "BackgroundColor3")

	sub.Page = W:_newPage(self.Body)
	table.insert(self.SubTabs, sub)

	sub.Button.MouseButton1Click:Connect(function()
		self:SelectSubTab(sub)
	end)

	if #self.SubTabs == 1 then
		self:SelectSubTab(sub)
	end
	return sub
end

-- ============================================================ элементы

function Container:_next()
	self._order += 1
	return self._order
end

function Container:_reg(cfg, obj)
	if cfg.Flag then
		self.Window.Options[cfg.Flag] = obj
	end
	return obj
end

function Container:_card(height, clickable)
	local T = self.Window.Theme
	local props = {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = T.Element,
		BorderSizePixel = 0,
		LayoutOrder = self:_next(),
		Parent = self.Page,
	}
	local children = { Corner(6), Stroke(T.Stroke, 1, 0.5) }
	if clickable then
		return Button(Merge(props, { BackgroundTransparency = 0 }), children)
	end
	return New("Frame", props, children)
end

local function NameLabel(parent, text, T, size)
	return Label({
		Text = text,
		TextColor3 = T.Text,
		Position = UDim2.fromOffset(12, 0),
		Size = size or UDim2.new(1, -24, 0, 34),
		Parent = parent,
	})
end

local function HoverCard(card, T)
	card.MouseEnter:Connect(function()
		Tween(card, { BackgroundColor3 = T.ElementHover }, 0.12)
	end)
	card.MouseLeave:Connect(function()
		Tween(card, { BackgroundColor3 = T.Element }, 0.12)
	end)
end

function Container:AddSection(text)
	local W = self.Window
	local frame = New("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = self:_next(),
		Parent = self.Page,
	})
	local lbl = Label({
		Text = string.upper(text or "Section"),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		Position = UDim2.fromOffset(2, 4),
		Size = UDim2.new(1, 0, 1, -4),
		Parent = frame,
	})
	W:_accent(lbl, "TextColor3")
	return {
		SetText = function(_, t)
			lbl.Text = string.upper(t)
		end,
	}
end

function Container:AddLabel(text)
	local T = self.Window.Theme
	local lbl = Label({
		Text = text or "",
		TextSize = 12,
		TextColor3 = T.SubText,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 18),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self:_next(),
		Parent = self.Page,
	})
	return {
		Set = function(_, t)
			lbl.Text = t
		end,
	}
end

function Container:AddButton(cfg)
	if type(cfg) == "string" then
		cfg = { Name = cfg }
	end
	cfg = cfg or {}
	local W = self.Window
	local T = W.Theme
	local card = self:_card(34, true)
	local name = NameLabel(card, cfg.Name or "Button", T)
	local arrow = Label({
		Text = "»",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 0),
		Size = UDim2.fromOffset(20, 34),
		Parent = card,
	})
	W:_accent(arrow, "TextColor3")
	HoverCard(card, T)

	-- ============ ПЛАШКА ДЛЯ БИНДА ============
	local bindLabel = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 6, 0.5, 0),
		Size = UDim2.fromOffset(70, 22),
		BackgroundColor3 = Color3.fromRGB(10, 10, 15),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = card,
	}, { Corner(4), Padding(6, 0, 6, 0) })
	local bindText = Label({
		Text = "",
		TextSize = 11,
		TextColor3 = T.SubText,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 6,
		Parent = bindLabel,
	})

	local obj = { Type = "Button", BoundKey = nil, _bindListening = false }

	function obj:Fire()
		Safe(cfg.Callback)
	end

	function obj:SetText(t)
		name.Text = t
	end

	-- Пересчёт положения плашки и текста кнопки
	function obj:_layoutBind()
		if self.BoundKey and self.BoundKey ~= "" then
			bindText.Text = "Bind: " .. self.BoundKey
			local w = math.max(bindText.TextBounds.X + 16, 70)
			bindLabel.Size = UDim2.fromOffset(w, 22)
			bindLabel.BackgroundTransparency = 0
			name.Position = UDim2.fromOffset(w + 10, 0)
			name.Size = UDim2.new(1, -(w + 30), 0, 34)
		else
			bindText.Text = ""
			bindLabel.BackgroundTransparency = 1
			name.Position = UDim2.fromOffset(12, 0)
			name.Size = UDim2.new(1, -24, 0, 34)
		end
	end

	-- Установить бинд (передай nil, чтобы снять)
	function obj:SetBind(keyName)
		if keyName == nil or keyName == "" or keyName == "None" then
			self.BoundKey = nil
		else
			self.BoundKey = tostring(keyName)
		end
		self:_layoutBind()
	end

	-- Обычный клик ЛКМ — срабатывает кнопка
	card.MouseButton1Click:Connect(function()
		card.BackgroundColor3 = T.Accent
		Tween(card, { BackgroundColor3 = T.ElementHover }, 0.3)
		obj:Fire()
	end)

	-- MMB — начать бинд
	card.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton3 then
			return
		end
		if obj._bindListening then
			return
		end
		obj._bindListening = true
		W.Listening = true

		-- показать плашку "Bind: ..."
		bindLabel.BackgroundTransparency = 0
		bindLabel.Size = UDim2.fromOffset(70, 22)
		bindText.Text = "Bind: ..."
		name.Position = UDim2.fromOffset(80, 0)
		name.Size = UDim2.new(1, -100, 0, 34)

		local conn
		conn = UIS.InputBegan:Connect(function(inp)
			if inp.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end
			conn:Disconnect()

			if inp.KeyCode == Enum.KeyCode.Backspace then
				-- снять бинд
				obj:SetBind(nil)
			elseif inp.KeyCode == Enum.KeyCode.Delete then
				-- отмена — оставить старый бинд
				obj:_layoutBind()
			else
				-- поставить новый бинд
				obj:SetBind(inp.KeyCode.Name)
			end

			obj._bindListening = false
			task.delay(0.1, function()
				W.Listening = false
			end)
		end)
		table.insert(W._connections, conn)
	end)

	-- Глобальный обработчик: нажатие привязанной клавиши = нажатие кнопки
	W:_connect(UIS.InputBegan, function(input, processed)
		if processed or W.Listening then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if obj.BoundKey and input.KeyCode.Name == obj.BoundKey then
			obj:Fire()
		end
	end)

	return obj
end

function Container:AddToggle(cfg)
	cfg = cfg or {}
	local W = self.Window
	local T = W.Theme
	local card = self:_card(34, true)
	NameLabel(card, cfg.Name or "Toggle", T)
	HoverCard(card, T)

	local track = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = T.ElementHover,
		BorderSizePixel = 0,
		Parent = card,
	}, { Corner(10), Stroke(T.Stroke, 1, 0.3) })
	local fill = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = track,
	}, { Corner(10) })
	W:_accent(fill, "BackgroundColor3")
	local knob = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = track,
	}, { Corner(7) })

	local obj = { Type = "Toggle", Value = false }
	function obj:Set(v, silent)
		self.Value = v and true or false
		if cfg.Flag then
			W.Flags[cfg.Flag] = self.Value
		end
		Tween(fill, { BackgroundTransparency = self.Value and 0 or 1 }, 0.15)
		Tween(knob, { Position = self.Value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, 0.15)
		if not silent then
			Safe(cfg.Callback, self.Value)
		end
	end

	card.MouseButton1Click:Connect(function()
		obj:Set(not obj.Value)
	end)
	obj:Set(cfg.Default or false, not cfg.CallOnLoad)
	return self:_reg(cfg, obj)
end

function Container:AddSlider(cfg)
	cfg = cfg or {}
	local W = self.Window
	local T = W.Theme
	local min, max = cfg.Min or 0, cfg.Max or 100
	local inc = cfg.Increment or 1
	local suffix = cfg.Suffix or ""

	local card = self:_card(50)
	NameLabel(card, cfg.Name or "Slider", T, UDim2.new(0.6, -12, 0, 30))
	local valueLabel = Label({
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = T.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 0),
		Size = UDim2.new(0.4, -12, 0, 30),
		Parent = card,
	})
	local bar = New("Frame", {
		Position = UDim2.new(0, 12, 0, 34),
		Size = UDim2.new(1, -24, 0, 6),
		BackgroundColor3 = T.ElementHover,
		BorderSizePixel = 0,
		Parent = card,
	}, { Corner(3) })
	local fill = New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = bar,
	}, { Corner(3) })
	W:_accent(fill, "BackgroundColor3")
	local knob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = bar,
	}, { Corner(6) })
	local hit = Button({
		Position = UDim2.new(0, 12, 0, 26),
		Size = UDim2.new(1, -24, 0, 22),
		Parent = card,
	})

	local obj = { Type = "Slider" }
	function obj:Set(v, silent)
		v = tonumber(v) or min
		v = math.floor((v - min) / inc + 0.5) * inc + min
		v = math.clamp(tonumber(string.format("%.4f", v)), min, max)
		local changed = v ~= self.Value
		self.Value = v
		local pct = (max == min) and 0 or (v - min) / (max - min)
		fill.Size = UDim2.fromScale(pct, 1)
		knob.Position = UDim2.fromScale(pct, 0.5)
		valueLabel.Text = tostring(v) .. suffix
		if cfg.Flag then
			W.Flags[cfg.Flag] = v
		end
		if changed and not silent then
			Safe(cfg.Callback, v)
		end
	end

	local dragging = false
	local function update(x)
		local pct = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		obj:Set(min + (max - min) * pct)
	end
	hit.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragging = true
			update(input.Position.X)
		end
	end)
	W:_connect(UIS.InputChanged, function(input)
		if dragging and isMove(input) then
			update(input.Position.X)
		end
	end)
	W:_connect(UIS.InputEnded, function(input)
		if isPointer(input) then
			dragging = false
		end
	end)

	obj:Set(cfg.Default or min, not cfg.CallOnLoad)
	return self:_reg(cfg, obj)
end

function Container:AddDropdown(cfg)
	cfg = cfg or {}
	local W = self.Window
	local T = W.Theme
	local multi = cfg.Multi == true
	local options = cfg.Options or {}
	local HEADER, ITEM = 34, 26

	local obj = { Type = "Dropdown", Value = multi and {} or nil, Open = false }

	local card = New("Frame", {
		Size = UDim2.new(1, 0, 0, HEADER),
		BackgroundColor3 = T.Element,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = self:_next(),
		Parent = self.Page,
	}, { Corner(6), Stroke(T.Stroke, 1, 0.5) })

	local header = Button({ Size = UDim2.new(1, 0, 0, HEADER), Parent = card })
	NameLabel(header, cfg.Name or "Dropdown", T, UDim2.new(0.5, -12, 0, HEADER))
	local valueLabel = Label({
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = T.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -30, 0, 0),
		Size = UDim2.new(0.5, -36, 0, HEADER),
		Parent = header,
	})
	local arrow = Label({
		Text = "▼",
		TextSize = 9,
		TextColor3 = T.SubText,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -16, 0, HEADER / 2),
		Size = UDim2.fromOffset(14, 14),
		Parent = header,
	})
	local list = New("ScrollingFrame", {
		Position = UDim2.new(0, 6, 0, HEADER + 2),
		Size = UDim2.new(1, -12, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = card,
	}, { New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })

	header.MouseEnter:Connect(function()
		Tween(card, { BackgroundColor3 = T.ElementHover }, 0.12)
	end)
	header.MouseLeave:Connect(function()
		Tween(card, { BackgroundColor3 = T.Element }, 0.12)
	end)

	local items = {}

	local function isSelected(opt)
		if multi then
			return table.find(obj.Value, opt) ~= nil
		end
		return obj.Value == opt
	end

	local function visuals()
		for opt, it in pairs(items) do
			local on = isSelected(opt)
			Tween(it.Ind, { BackgroundTransparency = on and 0 or 1 }, 0.12)
			Tween(it.Label, { TextColor3 = on and T.Text or T.SubText }, 0.12)
		end
		if multi then
			valueLabel.Text = #obj.Value > 0 and table.concat(obj.Value, ", ") or "None"
		else
			valueLabel.Text = obj.Value ~= nil and tostring(obj.Value) or "None"
		end
	end

	local function listHeight()
		local n = math.min(#options, 5)
		return n * ITEM + math.max(n - 1, 0) * 2
	end
	local function openHeight()
		return HEADER + 2 + listHeight() + 8
	end

	function obj:Set(v, silent)
		if multi then
			local new = {}
			if type(v) == "table" then
				for _, x in ipairs(v) do
					table.insert(new, tostring(x))
				end
			end
			self.Value = new
		else
			self.Value = (v ~= nil) and tostring(v) or nil
		end
		if cfg.Flag then
			W.Flags[cfg.Flag] = self.Value
		end
		visuals()
		if not silent then
			Safe(cfg.Callback, self.Value)
		end
	end

	function obj:Toggle(state)
		if state == nil then
			state = not self.Open
		end
		self.Open = state
		Tween(card, { Size = UDim2.new(1, 0, 0, state and openHeight() or HEADER) }, 0.18)
		Tween(arrow, { Rotation = state and 180 or 0 }, 0.18)
	end

	local function build()
		for _, it in pairs(items) do
			it.Button:Destroy()
		end
		table.clear(items)
		for i, raw in ipairs(options) do
			local opt = tostring(raw)
			local b = Button({
				Size = UDim2.new(1, 0, 0, ITEM),
				BackgroundColor3 = T.ElementHover,
				LayoutOrder = i,
				Parent = list,
			}, { Corner(5) })
			local ind = New("Frame", {
				Size = UDim2.fromOffset(3, 12),
				Position = UDim2.new(0, 4, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = b,
			}, { Corner(2) })
			W:_accent(ind, "BackgroundColor3")
			local lbl = Label({
				Text = opt,
				TextSize = 12,
				TextColor3 = T.SubText,
				Position = UDim2.fromOffset(14, 0),
				Size = UDim2.new(1, -18, 1, 0),
				Parent = b,
			})
			b.MouseEnter:Connect(function()
				Tween(b, { BackgroundTransparency = 0.5 }, 0.1)
			end)
			b.MouseLeave:Connect(function()
				Tween(b, { BackgroundTransparency = 1 }, 0.1)
			end)
			b.MouseButton1Click:Connect(function()
				if multi then
					local new = table.clone(obj.Value)
					local idx = table.find(new, opt)
					if idx then
						table.remove(new, idx)
					else
						table.insert(new, opt)
					end
					obj:Set(new)
				else
					obj:Set(opt)
					obj:Toggle(false)
				end
			end)
			items[opt] = { Button = b, Ind = ind, Label = lbl }
		end
		list.Size = UDim2.new(1, -12, 0, listHeight())
		if obj.Open then
			card.Size = UDim2.new(1, 0, 0, openHeight())
		end
		visuals()
	end

	function obj:Refresh(newOptions)
		options = newOptions or {}
		local lookup = {}
		for _, o in ipairs(options) do
			lookup[tostring(o)] = true
		end
		if multi then
			local kept = {}
			for _, v in ipairs(self.Value) do
				if lookup[v] then
					table.insert(kept, v)
				end
			end
			self.Value = kept
		elseif self.Value ~= nil and not lookup[self.Value] then
			self.Value = nil
		end
		if cfg.Flag then
			W.Flags[cfg.Flag] = self.Value
		end
		build()
	end

	header.MouseButton1Click:Connect(function()
		obj:Toggle()
	end)

	build()
	obj:Set(cfg.Default, not cfg.CallOnLoad)
	return self:_reg(cfg, obj)
end

function Container:AddTextbox(cfg)
	cfg = cfg or {}
	local W = self.Window
	local T = W.Theme
	local card = self:_card(34)
	NameLabel(card, cfg.Name or "Textbox", T, UDim2.new(0.5, -12, 0, 34))
	local box = New("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0.5, -8, 0, 24),
		BackgroundColor3 = T.ElementHover,
		BorderSizePixel = 0,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = T.Text,
		PlaceholderText = cfg.Placeholder or "...",
		PlaceholderColor3 = T.SubText,
		ClearTextOnFocus = false,
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	}, { Corner(5), Padding(6, 0, 6, 0) })

	local obj = { Type = "Textbox", Value = "" }
	function obj:Set(v, silent)
		self.Value = tostring(v or "")
		box.Text = self.Value
		if cfg.Flag then
			W.Flags[cfg.Flag] = self.Value
		end
		if not silent then
			Safe(cfg.Callback, self.Value)
		end
	end
	box.FocusLost:Connect(function()
		obj:Set(box.Text)
	end)
	obj:Set(cfg.Default or "", not cfg.CallOnLoad)
	return self:_reg(cfg, obj)
end

function Container:AddKeybind(cfg)
	cfg = cfg or {}
	local W = self.Window
	local T = W.Theme
	local card = self:_card(34)
	NameLabel(card, cfg.Name or "Keybind", T, UDim2.new(1, -110, 0, 34))
	local btn = Button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(90, 24),
		BackgroundTransparency = 0,
		BackgroundColor3 = T.ElementHover,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = T.Text,
		Text = "None",
		Parent = card,
	}, { Corner(5) })

	local obj = { Type = "Keybind", Value = "None", Listening = false }
	function obj:Set(v, silent)
		local name = "None"
		if typeof(v) == "EnumItem" then
			name = v.Name
		elseif type(v) == "string" and v ~= "" then
			name = v
		end
		local keyCode
		if name ~= "None" then
			local ok, kc = pcall(function()
				return Enum.KeyCode[name]
			end)
			if ok then
				keyCode = kc
			else
				name = "None"
			end
		end
		self.Value = name
		btn.Text = name
		if cfg.Flag then
			W.Flags[cfg.Flag] = name
		end
		if not silent then
			Safe(cfg.OnChanged, name, keyCode)
		end
	end

	btn.MouseButton1Click:Connect(function()
		if obj.Listening then
			return
		end
		obj.Listening = true
		W.Listening = true
		btn.Text = "..."
		local conn
		conn = UIS.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end
			conn:Disconnect()
			if input.KeyCode == Enum.KeyCode.Escape then
				obj:Set(obj.Value, true) -- отмена
			elseif input.KeyCode == Enum.KeyCode.Backspace then
				obj:Set("None")
			else
				obj:Set(input.KeyCode)
			end
			obj.Listening = false
			task.delay(0.1, function()
				W.Listening = false
			end)
		end)
		table.insert(W._connections, conn)
	end)

	W:_connect(UIS.InputBegan, function(input, processed)
		if processed or W.Listening or obj.Value == "None" then
			return
		end
		if input.KeyCode.Name == obj.Value then
			Safe(cfg.Callback)
		end
	end)

	obj:Set(cfg.Default or "None", true)
	return self:_reg(cfg, obj)
end

-- ============================================================ конфиги

function Window:SaveConfig(name)
	if not (writefile and isfolder and makefolder) then
		return false, "файловое API недоступно"
	end
	local data = {}
	for flag, opt in pairs(self.Options) do
		data[flag] = opt.Value
	end
	return pcall(function()
		if not isfolder("RealUI") then
			makefolder("RealUI")
		end
		writefile("RealUI/" .. name .. ".json", HttpService:JSONEncode(data))
	end)
end

function Window:LoadConfig(name)
	if not (readfile and isfile) then
		return false, "файловое API недоступно"
	end
	local path = "RealUI/" .. name .. ".json"
	if not isfile(path) then
		return false, "конфиг не найден"
	end
	return pcall(function()
		local data = HttpService:JSONDecode(readfile(path))
		for flag, value in pairs(data) do
			local opt = self.Options[flag]
			if opt then
				opt:Set(value)
			end
		end
	end)
end

-- ============================================================ вкладка настроек

local AccentPresets = {
	{ "Indigo", Color3.fromRGB(110, 120, 255) },
	{ "Purple", Color3.fromRGB(165, 105, 255) },
	{ "Pink", Color3.fromRGB(255, 105, 180) },
	{ "Red", Color3.fromRGB(255, 90, 90) },
	{ "Orange", Color3.fromRGB(255, 160, 70) },
	{ "Green", Color3.fromRGB(80, 220, 130) },
	{ "Cyan", Color3.fromRGB(70, 200, 240) },
}

function Window:CreateSettingsTab(name)
	local tab = self:CreateTab(name or "Settings")

	tab:AddSection("Menu")
	tab:AddKeybind({
		Name = "Toggle menu key",
		Default = self.ToggleKey,
		OnChanged = function(_, keyCode)
			if keyCode then
				self:SetToggleKey(keyCode)
			end
		end,
	})
	tab:AddSlider({
		Name = "UI scale",
		Min = 70,
		Max = 130,
		Default = 100,
		Increment = 5,
		Suffix = "%",
		Callback = function(v)
			self.Scale.Scale = v / 100
		end,
	})
	local names, colors = {}, {}
	for _, preset in ipairs(AccentPresets) do
		table.insert(names, preset[1])
		colors[preset[1]] = preset[2]
	end
	tab:AddDropdown({
		Name = "Accent color",
		Options = names,
		Default = "Indigo",
		Callback = function(n)
			if n and colors[n] then
				self:SetAccent(colors[n])
			end
		end,
	})

	tab:AddSection("Config")
	local cfgName = "default"
	tab:AddTextbox({
		Name = "Config name",
		Default = cfgName,
		Callback = function(v)
			if v ~= "" then
				cfgName = v
			end
		end,
	})
	tab:AddButton({
		Name = "Save config",
		Callback = function()
			local ok, err = self:SaveConfig(cfgName)
			self:Notify({
				Title = ok and "Конфиг сохранён" or "Ошибка сохранения",
				Content = ok and cfgName or tostring(err),
			})
		end,
	})
	tab:AddButton({
		Name = "Load config",
		Callback = function()
			local ok, err = self:LoadConfig(cfgName)
			self:Notify({
				Title = ok and "Конфиг загружен" or "Ошибка загрузки",
				Content = ok and cfgName or tostring(err),
			})
		end,
	})

	tab:AddSection("Other")
	tab:AddButton({
		Name = "Unload UI",
		Callback = function()
			self:Destroy()
		end,
	})
	return tab
end

-- ============================================================ создание окна

function SimpleUILib:CreateWindow(config)
	config = config or {}
	local self = setmetatable({}, Window)

	self.Theme = {}
	for k, v in pairs(DefaultTheme) do
		self.Theme[k] = v
	end
	if config.Accent then
		self.Theme.Accent = config.Accent
	end
	local T = self.Theme

	self.Flags, self.Options, self.Tabs = {}, {}, {}
	self.ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift
	self.Listening = false
	self._connections, self._accents = {}, {}

	local size = config.Size or Vector2.new(580, 380)
	local TOPBAR, SIDEBAR = 38, 140

	-- ScreenGui
	local gui = New("ScreenGui", {
		Name = "RealUI_" .. math.random(100000, 999999),
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local ok = pcall(function()
		gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not ok or not gui.Parent then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	self.Gui = gui

	-- главное окно
	local main = New("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = T.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = gui,
	}, { Corner(10), Stroke(T.Stroke, 1, 0.2) })
	self.Main = main
	self.Scale = New("UIScale", { Parent = main })

	-- верхняя панель
	local topbar = New("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, TOPBAR),
		BackgroundColor3 = T.Topbar,
		BorderSizePixel = 0,
		Parent = main,
	}, { Corner(10) })
	New("Frame", { -- заполнитель нижних углов
		Position = UDim2.new(0, 0, 1, -10),
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = T.Topbar,
		BorderSizePixel = 0,
		Parent = topbar,
	})
	local dot = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(8, 8),
		BorderSizePixel = 0,
		Parent = topbar,
	}, { Corner(4) })
	self:_accent(dot, "BackgroundColor3")
	Label({
		Text = config.Title or "Real UI",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = T.Text,
		Position = UDim2.fromOffset(30, 0),
		Size = UDim2.new(1, -100, 1, 0),
		Parent = topbar,
	})

	local function topButton(text, offset)
		local b = Button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8 - offset, 0.5, 0),
			Size = UDim2.fromOffset(26, 26),
			BackgroundColor3 = T.Element,
			Text = text,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = T.SubText,
			Parent = topbar,
		}, { Corner(6) })
		b.MouseEnter:Connect(function()
			Tween(b, { BackgroundTransparency = 0, TextColor3 = T.Text }, 0.1)
		end)
		b.MouseLeave:Connect(function()
			Tween(b, { BackgroundTransparency = 1, TextColor3 = T.SubText }, 0.1)
		end)
		return b
	end
	topButton("×", 0).MouseButton1Click:Connect(function()
		self:Destroy()
	end)
	topButton("–", 32).MouseButton1Click:Connect(function()
		self:Toggle(false)
		self:Notify({ Title = "Меню скрыто", Content = "Нажми " .. self.ToggleKey.Name .. ", чтобы открыть", Duration = 3 })
	end)

	-- сайдбар
	local sidebar = New("Frame", {
		Name = "Sidebar",
		Position = UDim2.fromOffset(0, TOPBAR),
		Size = UDim2.new(0, SIDEBAR, 1, -TOPBAR),
		BackgroundColor3 = T.Sidebar,
		BorderSizePixel = 0,
		Parent = main,
	}, { Corner(10) })
	New("Frame", { -- верх
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = T.Sidebar,
		BorderSizePixel = 0,
		Parent = sidebar,
	})
	New("Frame", { -- правая сторона
		Position = UDim2.new(1, -10, 0, 0),
		Size = UDim2.new(0, 10, 1, 0),
		BackgroundColor3 = T.Sidebar,
		BorderSizePixel = 0,
		Parent = sidebar,
	})
	self.TabList = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebar,
	}, {
		New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		Padding(8, 10, 8, 8),
	})

	-- область содержимого
	self.Content = New("Frame", {
		Name = "Content",
		Position = UDim2.new(0, SIDEBAR + 8, 0, TOPBAR + 8),
		Size = UDim2.new(1, -(SIDEBAR + 16), 1, -(TOPBAR + 16)),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = main,
	})

	-- уведомления
	self.NotifyHolder = New("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 280, 1, -32),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
		}),
	})

	-- перетаскивание за верхнюю панель
	local dragging, dragStart, startPos = false, nil, nil
	topbar.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					c:Disconnect()
				end
			end)
		end
	end)
	self:_connect(UIS.InputChanged, function(input)
		if dragging and isMove(input) then
			local d = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)

	self:_connect(UIS.InputBegan, function(input, processed)
		if processed or self.Listening then
			return
		end
		if input.KeyCode == self.ToggleKey then
			self:Toggle()
		end
	end)

	return self
end

return SimpleUILib
