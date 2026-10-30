local EspManager = {
	Library = nil,
	ESP = nil,
	Tab = nil,
	Prefix = "ESP_",
	CategoryTitle = "World ESP",
	CategoryGroupbox = nil,
	Categories = {},
	Pending = {},
}

local FontNames = {"UI", "System", "Plex", "Monospace"}

function EspManager:SetLibrary(library)
	self.Library = library
	if library.OnUnload then
		library:OnUnload(function()
			if self.ESP and not self.ESP.Unloaded then
				self.ESP:Unload()
			end
		end)
	end
end

function EspManager:SetESP(esp)
	self.ESP = esp
end

function EspManager:SetPrefix(prefix)
	self.Prefix = prefix
end

function EspManager:BindToggle(groupbox, key, text, tooltip)
	local esp = self.ESP
	return groupbox:AddToggle(self.Prefix .. key, {
		Text = text,
		Default = esp[key] and true or false,
		Tooltip = tooltip,
		Callback = function(value)
			esp[key] = value
		end,
	})
end

function EspManager:BindSlider(groupbox, key, text, min, max, rounding, toValue, fromValue)
	local esp = self.ESP
	return groupbox:AddSlider(self.Prefix .. key, {
		Text = text,
		Default = fromValue and fromValue(esp[key]) or esp[key],
		Min = min,
		Max = max,
		Rounding = rounding,
		Callback = function(value)
			esp[key] = toValue and toValue(value) or value
		end,
	})
end

function EspManager:BuildMain(groupbox)
	local esp = self.ESP

	groupbox:AddToggle(self.Prefix .. "Enabled", {
		Text = "Enabled",
		Default = esp.Enabled,
		Callback = function(value)
			esp:Toggle(value)
		end,
	}):AddColorPicker(self.Prefix .. "Color", {
		Default = esp.Color,
		Title = "ESP Color",
		Callback = function(value)
			esp.Color = value
		end,
	})

	self:BindToggle(groupbox, "Boxes", "Boxes")
	self:BindToggle(groupbox, "Names", "Names")
	self:BindToggle(groupbox, "Distance", "Distance")
	self:BindToggle(groupbox, "HealthBars", "Health Bars")
	self:BindToggle(groupbox, "Tracers", "Tracers")
	self:BindToggle(groupbox, "Chams", "Chams", "Uses Highlights; Roblox only renders 31 at once")

	groupbox:AddDivider()

	self:BindToggle(groupbox, "Players", "Show Players")
	self:BindToggle(groupbox, "TeamMates", "Show Teammates")
	self:BindToggle(groupbox, "TeamColor", "Use Team Color")
end

function EspManager:BuildSettings(groupbox)
	local esp = self.ESP

	groupbox:AddDropdown(self.Prefix .. "BoxType", {
		Text = "Box Type",
		Values = {"2D", "Quad"},
		Default = esp.BoxType,
		Multi = false,
		Callback = function(value)
			esp.BoxType = value
		end,
	})

	groupbox:AddDropdown(self.Prefix .. "TracerOrigin", {
		Text = "Tracer Origin",
		Values = {"Bottom", "Center", "Top", "Mouse"},
		Default = esp.TracerOrigin,
		Multi = false,
		Callback = function(value)
			esp.TracerOrigin = value
		end,
	})

	groupbox:AddDropdown(self.Prefix .. "Font", {
		Text = "Font",
		Values = FontNames,
		Default = FontNames[(esp.Font or 2) + 1] or "Plex",
		Multi = false,
		Callback = function(value)
			esp.Font = (table.find(FontNames, value) or 3) - 1
		end,
	})

	self:BindToggle(groupbox, "BoxOutline", "Box Outline")
	self:BindToggle(groupbox, "FaceCamera", "Face Camera", "Only affects Quad boxes")
	self:BindToggle(groupbox, "UseDisplayName", "Display Names", "Applies to players who spawn after changing it")

	self:BindSlider(groupbox, "MaxDistance", "Max Distance", 50, 10000, 0,
		function(v) return v >= 10000 and math.huge or v end,
		function(v) return math.min(v, 10000) end)
	self:BindSlider(groupbox, "TextSize", "Text Size", 10, 24, 0)
	self:BindSlider(groupbox, "Thickness", "Thickness", 1, 5, 0)
	self:BindSlider(groupbox, "ChamsFillTransparency", "Chams Fill", 0, 1, 2)
	self:BindSlider(groupbox, "ChamsOutlineTransparency", "Chams Outline", 0, 1, 2)
end

function EspManager:GetCategoryGroupbox()
	if not self.CategoryGroupbox and self.Tab then
		self.CategoryGroupbox = self.Tab:AddRightGroupbox(self.CategoryTitle)
	end
	return self.CategoryGroupbox
end

function EspManager:BuildCategory(category)
	local groupbox = category.Groupbox or self:GetCategoryGroupbox()
	if not groupbox then
		table.insert(self.Pending, category)
		return
	end

	local esp = self.ESP
	local toggle = groupbox:AddToggle(category.Flag, {
		Text = category.Name,
		Default = category.Enabled,
		Tooltip = category.Tooltip,
		Callback = function(value)
			category.Enabled = value
			esp[category.Flag] = value
		end,
	})

	if category.HasPicker then
		toggle:AddColorPicker(category.Flag .. "_Color", {
			Default = category.Color,
			Title = category.Name .. " Color",
			Callback = function(value)
				category.Color = value
			end,
		})
	end
end

function EspManager:AddCategory(name, options)
	assert(self.ESP, "EspManager: call SetESP before AddCategory")
	assert(options and options.Parent, "EspManager: AddCategory needs a Parent")

	local esp = self.ESP
	local flag = self.Prefix .. "Cat_" .. name:gsub("%W", "")

	if self.Categories[name] then
		self:RemoveCategory(name)
	end

	local category = {
		Name = name,
		Flag = flag,
		Enabled = options.Default and true or false,
		Color = type(options.Color) == "userdata" and options.Color or esp.Color,
		HasPicker = type(options.Color) ~= "function",
		Groupbox = options.Groupbox,
		Tooltip = options.Tooltip,
		Connections = {},
	}
	esp[flag] = category.Enabled
	self.Categories[name] = category

	local listener = {}
	for k, v in pairs(options) do
		listener[k] = v
	end
	listener.Parent = nil
	listener.Default = nil
	listener.Groupbox = nil
	listener.Tooltip = nil
	listener.IsEnabled = flag
	if category.HasPicker then
		listener.Color = nil
		listener.ColorDynamic = function()
			return category.Color
		end
	end

	local parents = typeof(options.Parent) == "Instance" and {options.Parent} or options.Parent
	for _, parent in ipairs(parents) do
		table.insert(category.Connections, esp:AddObjectListener(parent, listener))
	end

	self:BuildCategory(category)
	return category
end

function EspManager:RemoveCategory(name)
	local category = self.Categories[name]
	if not category then
		return
	end
	for _, conn in ipairs(category.Connections) do
		conn:Disconnect()
	end
	for _, box in pairs(self.ESP.Objects) do
		if box.IsEnabled == category.Flag then
			box:Remove()
		end
	end
	self.ESP[category.Flag] = nil
	self.Categories[name] = nil
end

function EspManager:ApplyToTab(tab)
	assert(self.Library, "EspManager: call SetLibrary before ApplyToTab")
	assert(self.ESP, "EspManager: call SetESP before ApplyToTab")

	self.Tab = tab
	self:BuildMain(tab:AddLeftGroupbox("ESP"))
	self:BuildSettings(tab:AddRightGroupbox("ESP Settings"))

	local pending = self.Pending
	self.Pending = {}
	for _, category in ipairs(pending) do
		self:BuildCategory(category)
	end
end

return EspManager