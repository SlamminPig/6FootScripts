-- Credits to Kiriot22 for the base source

local cloneref = cloneref or function(c) return c end
local Service = setmetatable({}, {__index = function(_, x) return cloneref(game:GetService(x)) end})

local LocalPlayer = Service.Players.LocalPlayer
while not LocalPlayer do
	Service.Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Service.Players.LocalPlayer
end

local Vector2new = Vector2.new
local Vector3new = Vector3.new
local CFramenew = CFrame.new
local mathfloor, mathmin, mathmax, mathclamp, mathtan, mathrad = math.floor, math.min, math.max, math.clamp, math.tan, math.rad
local WTVP = Instance.new("Camera").WorldToViewportPoint

local Black = Color3.new(0, 0, 0)
local HealthLow = Color3.fromRGB(255, 60, 60)
local HealthHigh = Color3.fromRGB(80, 255, 80)

local HighlightParent do
	local ok, hui = pcall(function() return gethui() end)
	HighlightParent = ok and hui or Service.CoreGui
end

local ESP = {
	Credits = "Based on Kiriot22's ESP library",
	Enabled = false,

	Boxes = true,
	BoxType = "2D",
	BoxOutline = true,
	BoxShift = CFramenew(0, -1.5, 0),
	BoxSize = Vector3new(4, 6, 0),
	FaceCamera = false,

	Names = true,
	UseDisplayName = true,
	Distance = true,
	DistanceFormat = "[%d]",
	HealthBars = false,
	Tracers = false,
	TracerOrigin = "Bottom",

	Chams = false,
	ChamsFillTransparency = 0.5,
	ChamsOutlineTransparency = 0,

	Color = Color3.fromRGB(255, 170, 0),
	HighlightColor = Color3.fromRGB(255, 255, 255),
	TeamColor = true,
	TeamMates = true,
	Players = true,

	Thickness = 1,
	TextSize = 14,
	Font = (Drawing.Fonts and Drawing.Fonts.Plex) or 2,
	MaxDistance = math.huge,
	AutoRemove = true,

	Objects = {},
	Overrides = {},
	Connections = {},
	PlayerConnections = {},
}

local Definitions = {
	BoxOutline = {"Square", {Color = Black, Thickness = 3, Filled = false, Transparency = 1, Visible = false, ZIndex = 1}},
	Box = {"Square", {Thickness = 1, Filled = false, Transparency = 1, Visible = false, ZIndex = 2}},
	QuadOutline = {"Quad", {Color = Black, Thickness = 3, Filled = false, Transparency = 1, Visible = false, ZIndex = 1}},
	Quad = {"Quad", {Thickness = 1, Filled = false, Transparency = 1, Visible = false, ZIndex = 2}},
	HealthOutline = {"Square", {Color = Black, Filled = true, Transparency = 1, Visible = false, ZIndex = 1}},
	HealthBar = {"Square", {Filled = true, Transparency = 1, Visible = false, ZIndex = 2}},
	Name = {"Text", {Center = true, Outline = true, Transparency = 1, Visible = false, ZIndex = 3}},
	Distance = {"Text", {Center = true, Outline = true, Transparency = 1, Visible = false, ZIndex = 3}},
	Tracer = {"Line", {Thickness = 1, Transparency = 1, Visible = false, ZIndex = 2}},
}

local function Draw(class, props)
	local obj = Drawing.new(class)
	for k, v in pairs(props) do
		obj[k] = v
	end
	return obj
end

local function NewComponents(state)
	return setmetatable({}, {__index = function(t, name)
		local def = Definitions[name]
		if not def then
			return nil
		end
		local obj = Draw(def[1], def[2])
		state[name] = {Visible = false}
		rawset(t, name, obj)
		return obj
	end})
end

local function Get(box, name)
	local obj = box.Components[name]
	return obj, box.State[name]
end

local function Set(obj, state, prop, value)
	if state[prop] ~= value then
		obj[prop] = value
		state[prop] = value
	end
end

local function Off(box, name)
	local obj = rawget(box.Components, name)
	if obj then
		Set(obj, box.State[name], "Visible", false)
	end
end

local function Connect(list, signal, fn)
	local conn = signal:Connect(fn)
	table.insert(list, conn)
	return conn
end

function ESP:GetTeam(p)
	local ov = self.Overrides.GetTeam
	if ov then
		return ov(p)
	end
	return p and p.Team
end

function ESP:IsTeamMate(p)
	local ov = self.Overrides.IsTeamMate
	if ov then
		return ov(p)
	end
	return self:GetTeam(p) == self:GetTeam(LocalPlayer)
end

function ESP:GetPlrFromChar(char)
	local ov = self.Overrides.GetPlrFromChar
	if ov then
		return ov(char)
	end
	return Service.Players:GetPlayerFromCharacter(char)
end

function ESP:GetColor(obj)
	local ov = self.Overrides.GetColor
	if ov then
		return ov(obj)
	end
	local p = self:GetPlrFromChar(obj)
	return p and self.TeamColor and p.Team and p.Team.TeamColor.Color or self.Color
end

local DefaultGetColor = ESP.GetColor

function ESP:GetHealth(box)
	local ov = self.Overrides.GetHealth
	if ov then
		return ov(box)
	end
	local hum = box.Humanoid
	if hum and hum.Parent then
		return hum.Health, hum.MaxHealth
	end
end

function ESP:GetBox(obj)
	return self.Objects[obj]
end

function ESP:HideAll()
	for _, box in pairs(self.Objects) do
		box:Hide()
	end
end

function ESP:Toggle(bool)
	self.Enabled = bool
	if not bool then
		for _, box in pairs(self.Objects) do
			if box.Temporary then
				box:Remove()
			else
				box:Hide()
			end
		end
	end
end

local Box = {}
Box.__index = Box

function Box:Hide()
	if self.Hidden then
		return
	end
	self.Hidden = true
	local state = self.State
	for name, d in pairs(self.Components) do
		d.Visible = false
		state[name].Visible = false
	end
	if self.Highlight then
		self.Highlight.Enabled = false
		self.ChamsOn = false
	end
end

function Box:Remove()
	if self.Removed then
		return
	end
	self.Removed = true
	if ESP.Objects[self.Object] == self then
		ESP.Objects[self.Object] = nil
	end
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	table.clear(self.Connections)
	setmetatable(self.Components, nil)
	for _, d in pairs(self.Components) do
		pcall(function()
			d.Visible = false
			d:Remove()
		end)
	end
	table.clear(self.Components)
	if self.Highlight then
		self.Highlight:Destroy()
		self.Highlight = nil
	end
end

function Box:GetColor()
	if ESP.Highlighted == self.Object then
		return ESP.HighlightColor
	end
	if self.Color then
		return self.Color
	end
	if self.ColorDynamic then
		local dynamic = self:ColorDynamic()
		if dynamic then
			return dynamic
		end
	end
	if ESP.GetColor ~= DefaultGetColor or ESP.Overrides.GetColor or ESP.Overrides.GetPlrFromChar then
		return ESP:GetColor(self.Object) or ESP.Color
	end
	local p = self.Player
	if p and ESP.TeamColor then
		local team = p.Team
		if team then
			return team.TeamColor.Color
		end
	end
	return ESP.Color
end

function Box:IsAllowed()
	local ov = ESP.Overrides.UpdateAllow
	if ov and not ov(self) then
		return false
	end
	local p = self.Player
	if p then
		if not ESP.Players then
			return false
		end
		if not ESP.TeamMates and ESP:IsTeamMate(p) then
			return false
		end
	end
	local en = self.IsEnabled
	if en then
		if type(en) == "string" and not ESP[en] then
			return false
		elseif type(en) == "function" and not en(self) then
			return false
		end
	end
	if not self.RenderInNil and not self.PrimaryPart:IsDescendantOf(workspace) then
		return false
	end
	return true
end

function Box:UpdateChams(color)
	local hl = self.Highlight
	if not ESP.Chams then
		if hl and self.ChamsOn then
			hl.Enabled = false
			self.ChamsOn = false
		end
		return
	end
	if not hl then
		local obj = self.Object
		if not (obj:IsA("Model") or obj:IsA("BasePart")) then
			return
		end
		hl = Instance.new("Highlight")
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee = obj
		hl.Enabled = false
		hl.Parent = HighlightParent
		self.Highlight = hl
		self.ChamsOn = false
	end
	if self.ChamsColor ~= color then
		self.ChamsColor = color
		hl.FillColor = color
		hl.OutlineColor = color
	end
	local fill, outline = ESP.ChamsFillTransparency, ESP.ChamsOutlineTransparency
	if self.ChamsFill ~= fill then
		self.ChamsFill = fill
		hl.FillTransparency = fill
	end
	if self.ChamsOutline ~= outline then
		self.ChamsOutline = outline
		hl.OutlineTransparency = outline
	end
	if not self.ChamsOn then
		self.ChamsOn = true
		hl.Enabled = true
	end
end

function Box:Update(cam, viewport, tanHalfFov, origin)
	if self.Removed then
		return
	end
	local part = self.PrimaryPart
	if not part then
		return self:Remove()
	end
	if not self:IsAllowed() then
		return self:Hide()
	end

	local camPos = cam.CFrame.Position
	local cf = part.CFrame
	local distance = (camPos - cf.Position).Magnitude
	if distance > ESP.MaxDistance then
		return self:Hide()
	end

	if ESP.FaceCamera then
		cf = CFramenew(cf.Position, camPos)
	end
	cf = cf * ESP.BoxShift

	local size = self.Size or ESP.BoxSize
	local isQuad = ESP.BoxType == "Quad"
	local minX, minY, maxX, maxY, pA, pB, pC, pD

	if isQuad then
		local hx, hy = size.X / 2, size.Y / 2
		local a = WTVP(cam, cf:PointToWorldSpace(Vector3new(-hx, hy, 0)))
		local b = WTVP(cam, cf:PointToWorldSpace(Vector3new(hx, hy, 0)))
		local c = WTVP(cam, cf:PointToWorldSpace(Vector3new(hx, -hy, 0)))
		local d = WTVP(cam, cf:PointToWorldSpace(Vector3new(-hx, -hy, 0)))
		if a.Z <= 0 or b.Z <= 0 or c.Z <= 0 or d.Z <= 0 then
			return self:Hide()
		end
		pA, pB, pC, pD = Vector2new(a.X, a.Y), Vector2new(b.X, b.Y), Vector2new(c.X, c.Y), Vector2new(d.X, d.Y)
		minX, maxX = mathmin(a.X, b.X, c.X, d.X), mathmax(a.X, b.X, c.X, d.X)
		minY, maxY = mathmin(a.Y, b.Y, c.Y, d.Y), mathmax(a.Y, b.Y, c.Y, d.Y)
	else
		local center = WTVP(cam, cf.Position)
		if center.Z <= 0 then
			return self:Hide()
		end
		local scale = viewport.Y / (2 * center.Z * tanHalfFov)
		local w, h = size.X * scale, size.Y * scale
		minX, minY = mathfloor(center.X - w / 2), mathfloor(center.Y - h / 2)
		maxX, maxY = mathfloor(minX + w), mathfloor(minY + h)
	end

	if maxX < 0 or minX > viewport.X or maxY < 0 or minY > viewport.Y then
		return self:Hide()
	end

	self.Hidden = false

	local color = self:GetColor()
	local thickness = ESP.Thickness
	local centerX = (minX + maxX) / 2

	self:UpdateChams(color)

	if ESP.Boxes and isQuad then
		local q, qs = Get(self, "Quad")
		Set(q, qs, "PointA", pA)
		Set(q, qs, "PointB", pB)
		Set(q, qs, "PointC", pC)
		Set(q, qs, "PointD", pD)
		Set(q, qs, "Color", color)
		Set(q, qs, "Thickness", thickness)
		Set(q, qs, "Visible", true)
		if ESP.BoxOutline then
			local qo, qos = Get(self, "QuadOutline")
			Set(qo, qos, "PointA", pA)
			Set(qo, qos, "PointB", pB)
			Set(qo, qos, "PointC", pC)
			Set(qo, qos, "PointD", pD)
			Set(qo, qos, "Thickness", thickness + 2)
			Set(qo, qos, "Visible", true)
		else
			Off(self, "QuadOutline")
		end
		Off(self, "Box")
		Off(self, "BoxOutline")
	elseif ESP.Boxes then
		local pos = Vector2new(minX, minY)
		local sz = Vector2new(maxX - minX, maxY - minY)
		local bx, bs = Get(self, "Box")
		Set(bx, bs, "Position", pos)
		Set(bx, bs, "Size", sz)
		Set(bx, bs, "Color", color)
		Set(bx, bs, "Thickness", thickness)
		Set(bx, bs, "Visible", true)
		if ESP.BoxOutline then
			local bo, bos = Get(self, "BoxOutline")
			Set(bo, bos, "Position", pos)
			Set(bo, bos, "Size", sz)
			Set(bo, bos, "Thickness", thickness + 2)
			Set(bo, bos, "Visible", true)
		else
			Off(self, "BoxOutline")
		end
		Off(self, "Quad")
		Off(self, "QuadOutline")
	else
		Off(self, "Box")
		Off(self, "BoxOutline")
		Off(self, "Quad")
		Off(self, "QuadOutline")
	end

	local textSize, font = ESP.TextSize, ESP.Font

	if ESP.Names then
		local name, ns = Get(self, "Name")
		Set(name, ns, "Text", self.Name)
		Set(name, ns, "Size", textSize)
		Set(name, ns, "Font", font)
		Set(name, ns, "Color", color)
		Set(name, ns, "Position", Vector2new(centerX, minY - textSize - 3))
		Set(name, ns, "Visible", true)
	else
		Off(self, "Name")
	end

	if ESP.Distance then
		local dist, ds = Get(self, "Distance")
		local whole, format = mathfloor(distance), ESP.DistanceFormat
		if self.DistanceValue ~= whole or self.DistanceFormat ~= format then
			self.DistanceValue = whole
			self.DistanceFormat = format
			self.DistanceText = string.format(format, whole)
		end
		Set(dist, ds, "Text", self.DistanceText)
		Set(dist, ds, "Size", textSize)
		Set(dist, ds, "Font", font)
		Set(dist, ds, "Color", color)
		Set(dist, ds, "Position", Vector2new(centerX, maxY + 2))
		Set(dist, ds, "Visible", true)
	else
		Off(self, "Distance")
	end

	local health, maxHealth
	if ESP.HealthBars then
		health, maxHealth = ESP:GetHealth(self)
	end
	if health and maxHealth and maxHealth > 0 then
		local pct = mathclamp(health / maxHealth, 0, 1)
		local barHeight = maxY - minY
		local ho, hos = Get(self, "HealthOutline")
		local hb, hbs = Get(self, "HealthBar")
		Set(ho, hos, "Position", Vector2new(minX - 6, minY - 1))
		Set(ho, hos, "Size", Vector2new(4, barHeight + 2))
		Set(ho, hos, "Visible", true)
		Set(hb, hbs, "Position", Vector2new(minX - 5, minY + barHeight * (1 - pct)))
		Set(hb, hbs, "Size", Vector2new(2, barHeight * pct))
		Set(hb, hbs, "Color", HealthLow:Lerp(HealthHigh, pct))
		Set(hb, hbs, "Visible", true)
	else
		Off(self, "HealthBar")
		Off(self, "HealthOutline")
	end

	if ESP.Tracers then
		local tracer, ts = Get(self, "Tracer")
		Set(tracer, ts, "From", origin)
		Set(tracer, ts, "To", Vector2new(centerX, maxY))
		Set(tracer, ts, "Color", color)
		Set(tracer, ts, "Thickness", thickness)
		Set(tracer, ts, "Visible", true)
	else
		Off(self, "Tracer")
	end
end

function ESP:Add(obj, options)
	if self.Unloaded then
		return
	end
	options = options or {}
	if not obj.Parent and not options.RenderInNil then
		return warn("[ESP]", obj, "has no parent")
	end

	local existing = self.Objects[obj]
	if existing then
		existing:Remove()
	end

	local primary = options.PrimaryPart
	if not primary then
		if obj:IsA("Model") then
			primary = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
		elseif obj:IsA("BasePart") then
			primary = obj
		end
	end

	local state = {}
	local box = setmetatable({
		Name = options.Name or obj.Name,
		Type = "Box",
		Color = options.Color,
		ColorDynamic = options.ColorDynamic,
		Size = options.Size,
		Object = obj,
		Player = options.Player or self:GetPlrFromChar(obj),
		PrimaryPart = primary,
		Humanoid = options.Humanoid or obj:FindFirstChildOfClass("Humanoid"),
		IsEnabled = options.IsEnabled,
		Temporary = options.Temporary,
		RenderInNil = options.RenderInNil,
		Components = NewComponents(state),
		State = state,
		Connections = {},
		Hidden = true,
	}, Box)

	self.Objects[obj] = box

	Connect(box.Connections, obj.AncestryChanged, function(_, parent)
		if not parent and self.AutoRemove ~= false and not box.RenderInNil then
			box:Remove()
		end
	end)

	if box.Humanoid then
		Connect(box.Connections, box.Humanoid.Died, function()
			if self.AutoRemove ~= false then
				box:Remove()
			end
		end)
	end

	return box
end

function ESP:AddObjectListener(parent, options)
	local function Matches(c)
		if type(options.Type) == "string" and not c:IsA(options.Type) then
			return false
		end
		if type(options.Name) == "string" and c.Name ~= options.Name then
			return false
		end
		if options.Validator and not options.Validator(c) then
			return false
		end
		return true
	end

	local function OnAdded(c)
		if not Matches(c) then
			return
		end

		local primary = options.PrimaryPart
		if type(primary) == "string" then
			primary = c:WaitForChild(primary, options.Timeout or 10)
			if not primary then
				return
			end
		elseif type(primary) == "function" then
			primary = primary(c)
		end

		local box = self:Add(c, {
			PrimaryPart = primary,
			Color = type(options.Color) == "function" and options.Color(c) or options.Color,
			ColorDynamic = options.ColorDynamic,
			Name = type(options.CustomName) == "function" and options.CustomName(c) or options.CustomName,
			Size = options.Size,
			Humanoid = options.Humanoid,
			IsEnabled = options.IsEnabled,
			RenderInNil = options.RenderInNil,
			Temporary = options.Temporary,
		})

		if box and options.OnAdded then
			task.spawn(options.OnAdded, box)
		end
	end

	local signal = options.Recursive and parent.DescendantAdded or parent.ChildAdded
	local conn = Connect(self.Connections, signal, function(c)
		task.spawn(OnAdded, c)
	end)

	for _, c in ipairs(options.Recursive and parent:GetDescendants() or parent:GetChildren()) do
		task.spawn(OnAdded, c)
	end

	return conn
end

function ESP:AddCharacter(player, char)
	local root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 10)
	if not root or not char.Parent then
		return
	end
	return self:Add(char, {
		Name = self.UseDisplayName and player.DisplayName or player.Name,
		Player = player,
		PrimaryPart = root,
	})
end

function ESP:TrackPlayer(player)
	if player == LocalPlayer or self.PlayerConnections[player] then
		return
	end
	self.PlayerConnections[player] = player.CharacterAdded:Connect(function(char)
		task.spawn(self.AddCharacter, self, player, char)
	end)
	if player.Character then
		task.spawn(self.AddCharacter, self, player, player.Character)
	end
end

function ESP:TrackPlayers()
	if self.TrackingPlayers then
		return
	end
	self.TrackingPlayers = true
	Connect(self.Connections, Service.Players.PlayerAdded, function(p)
		self:TrackPlayer(p)
	end)
	Connect(self.Connections, Service.Players.PlayerRemoving, function(p)
		local conn = self.PlayerConnections[p]
		if conn then
			conn:Disconnect()
			self.PlayerConnections[p] = nil
		end
	end)
	for _, p in ipairs(Service.Players:GetPlayers()) do
		self:TrackPlayer(p)
	end
end

function ESP:Unload()
	self.Enabled = false
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	table.clear(self.Connections)
	for _, conn in pairs(self.PlayerConnections) do
		conn:Disconnect()
	end
	table.clear(self.PlayerConnections)
	for _, box in pairs(self.Objects) do
		box:Remove()
	end
	table.clear(self.Objects)
	self.TrackingPlayers = false
	self.Unloaded = true
end

local WasEnabled = false

Connect(ESP.Connections, Service.RunService.RenderStepped, function()
	if not ESP.Enabled then
		if WasEnabled then
			WasEnabled = false
			ESP:HideAll()
		end
		return
	end
	WasEnabled = true

	local cam = workspace.CurrentCamera
	if not cam then
		return
	end

	local viewport = cam.ViewportSize
	local tanHalfFov = mathtan(mathrad(cam.FieldOfView) / 2)
	local originType = ESP.TracerOrigin
	local origin
	if originType == "Mouse" then
		origin = Service.UserInputService:GetMouseLocation()
	elseif originType == "Center" then
		origin = viewport / 2
	elseif originType == "Top" then
		origin = Vector2new(viewport.X / 2, 0)
	else
		origin = Vector2new(viewport.X / 2, viewport.Y)
	end

	for obj, box in pairs(ESP.Objects) do
		local ok, err = pcall(box.Update, box, cam, viewport, tanHalfFov, origin)
		if not ok then
			if box.LastError ~= err then
				box.LastError = err
				warn("[ESP]", err, typeof(obj) == "Instance" and obj:GetFullName() or obj)
			end
			box:Hide()
		end
	end
end)

ESP:TrackPlayers()

return ESP
