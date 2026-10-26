local httpService = game:GetService('HttpService')
local ThemeManager = {} do
	ThemeManager.Folder = 'LinoriaLibSettings'

	ThemeManager.Library = nil
	ThemeManager.BuiltInThemes = {
		['Default']         = { 1, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"0055ff","BackgroundColor":"141414","OutlineColor":"323232"}') },
		['BBot']            = { 2, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}') },
		['Fatality']        = { 3, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}') },
		['Jester']          = { 4, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Mint']            = { 5, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Tokyo Night']     = { 6, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') },
		['Ubuntu']          = { 7, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}') },
		['Kiriot Hub']      = { 8, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"30333b","AccentColor":"ffaa00","BackgroundColor":"1a1c20","OutlineColor":"141414"}') },
		['Dracula']         = { 9, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232533","AccentColor":"6271a5","BackgroundColor":"1b1c27","OutlineColor":"7c82a7"}') },
		['Solarized Dark']  = { 10, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"002b36","AccentColor":"b58900","BackgroundColor":"073642","OutlineColor":"586e75"}') },
		['Cyberpunk']       = { 11, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"2a0034","AccentColor":"ff0090","BackgroundColor":"1a001f","OutlineColor":"3a0044"}') },
		['Monokai']         = { 12, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"272822","AccentColor":"f92672","BackgroundColor":"1e1e1e","OutlineColor":"75715e"}') },
		['Nord']            = { 13, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3b4252","AccentColor":"88c0d0","BackgroundColor":"2e3440","OutlineColor":"4c566a"}') },
		['Rose Pine']       = { 14, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232136","AccentColor":"eb6f92","BackgroundColor":"191724","OutlineColor":"31748f"}') },
		['Hacker']          = { 15, httpService:JSONDecode('{"FontColor":"00ff00","MainColor":"101010","AccentColor":"00cc00","BackgroundColor":"080808","OutlineColor":"222222"}') },
		['Lavender']        = { 16, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3d2a4d","AccentColor":"c792ea","BackgroundColor":"2a1e37","OutlineColor":"4b3a5a"}') },
		['Void Runner']     = { 17, httpService:JSONDecode('{"FontColor":"d2d2ff","MainColor":"0c001a","AccentColor":"7d00ff","BackgroundColor":"00000a","OutlineColor":"1a0033"}') },
		['Circuit Core']    = { 18, httpService:JSONDecode('{"FontColor":"00ffcc","MainColor":"001a1a","AccentColor":"00ffaa","BackgroundColor":"000f0f","OutlineColor":"005555"}') },
		['Moss & Stone']    = { 19, httpService:JSONDecode('{"FontColor":"d4e157","MainColor":"2e342e","AccentColor":"a2c523","BackgroundColor":"1c1f1c","OutlineColor":"4c584c"}') },
		['Noir Film']       = { 20, httpService:JSONDecode('{"FontColor":"eeeeee","MainColor":"111111","AccentColor":"888888","BackgroundColor":"000000","OutlineColor":"2a2a2a"}') },
		['Glass UI']        = { 21, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1a1a1a","AccentColor":"80dfff","BackgroundColor":"0a0a0a","OutlineColor":"80dfff"}') },
		['Arcade Wave']     = { 22, httpService:JSONDecode('{"FontColor":"ffff99","MainColor":"331144","AccentColor":"ff3399","BackgroundColor":"1a0022","OutlineColor":"661177"}') },
		['Storm Cloud']     = { 23, httpService:JSONDecode('{"FontColor":"dfe6e9","MainColor":"2d3436","AccentColor":"74b9ff","BackgroundColor":"1e272e","OutlineColor":"636e72"}') },
		['Inkdrop']         = { 24, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0f0f14","AccentColor":"2e2e91","BackgroundColor":"06060a","OutlineColor":"1c1c3a"}') },
		['Tundra Bloom']    = { 25, httpService:JSONDecode('{"FontColor":"eaf6ff","MainColor":"5e81ac","AccentColor":"a3be8c","BackgroundColor":"2e3440","OutlineColor":"4c566a"}') },
		['Molten Core']     = { 26, httpService:JSONDecode('{"FontColor":"ffeaa7","MainColor":"2d0900","AccentColor":"ff6f00","BackgroundColor":"120400","OutlineColor":"3e1300"}') },
		['Bioluminescent']  = { 27, httpService:JSONDecode('{"FontColor":"ccffe6","MainColor":"003322","AccentColor":"00ff99","BackgroundColor":"001a12","OutlineColor":"00664d"}') },
		['Mechanical Soul'] = { 28, httpService:JSONDecode('{"FontColor":"e0e0e0","MainColor":"3b3b3b","AccentColor":"d4af37","BackgroundColor":"1c1c1c","OutlineColor":"5e5e5e"}') },
		['Abyssal']         = { 29, httpService:JSONDecode('{"FontColor":"ade4ff","MainColor":"0a0f1d","AccentColor":"0077be","BackgroundColor":"02050a","OutlineColor":"1a2a45"}') },
		['Coffee']          = { 30, httpService:JSONDecode('{"FontColor":"fdf0d5","MainColor":"3c2f2f","AccentColor":"be9b7b","BackgroundColor":"251e1e","OutlineColor":"4b3832"}') },
		['Frost']           = { 31, httpService:JSONDecode('{"FontColor":"e0fbff","MainColor":"22333b","AccentColor":"c9f2c7","BackgroundColor":"0a100d","OutlineColor":"3d5a80"}') },
		['Crimson']         = { 32, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1a0a0a","AccentColor":"ff0000","BackgroundColor":"0d0505","OutlineColor":"3d1414"}') },
		['Sunset']          = { 33, httpService:JSONDecode('{"FontColor":"ffe9dc","MainColor":"2b1b2e","AccentColor":"ff7a45","BackgroundColor":"1c121f","OutlineColor":"4a2c4f"}') },
		['Copper Teal']     = { 34, httpService:JSONDecode('{"FontColor":"e6f2f0","MainColor":"13262b","AccentColor":"e08a4f","BackgroundColor":"0b1a1e","OutlineColor":"24434a"}') },
		['Royal']           = { 35, httpService:JSONDecode('{"FontColor":"f0f2ff","MainColor":"141a33","AccentColor":"ffcc4d","BackgroundColor":"0c1024","OutlineColor":"2a3361"}') },
		['Toxic']           = { 36, httpService:JSONDecode('{"FontColor":"f4ffd6","MainColor":"171717","AccentColor":"ccff00","BackgroundColor":"0e0e0e","OutlineColor":"2b2b2b"}') },
	}

	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]
		if not data then return end

		for idx, col in next, customThemeData or data[2] do
			local success, result = pcall(Color3.fromHex, col)
			if success then
				self.Library[idx] = result
				if Options[idx] then
					Options[idx]:SetValueRGB(result)
				end
			end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		local options = { 'FontColor', 'MainColor', 'AccentColor', 'BackgroundColor', 'OutlineColor' }
		for _, field in next, options do
			if Options and Options[field] and Options[field].Value ~= nil then
				self.Library[field] = Options[field].Value
			end
		end

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor);
		self.Library:UpdateColorsUsingRegistry()
	end

	function ThemeManager:LoadDefault()		
		local theme = 'Default'
		local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')

		local isDefault = true
		if content then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
				isDefault = false;
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
		 	theme = self.DefaultTheme
		end

		if isDefault then
			Options.ThemeManager_ThemeList:SetValue(theme)
		else
			self:ApplyTheme(theme)
		end
	end

	ThemeManager.Fonts = {
		'Code', 'RobotoMono', 'Ubuntu', 'Gotham', 'GothamMedium', 'BuilderSans', 'BuilderSansMedium',
		'SourceSansSemibold', 'Roboto', 'Nunito', 'TitilliumWeb', 'Jura', 'Michroma', 'FredokaOne', 'Arcade', 'SciFi',
	}

	function ThemeManager:GetFonts()
		local out = {}
		for _, name in ipairs(self.Fonts) do
			local ok = pcall(function()
				return Enum.Font[name]
			end)
			if ok then
				table.insert(out, name)
			end
		end
		return out
	end

	function ThemeManager:GetSavedFont()
		local path = self.Folder .. '/themes/font.txt'
		if isfile and isfile(path) then
			local name = readfile(path)
			if table.find(self:GetFonts(), name) then
				return name
			end
		end
		return 'Code'
	end

	function ThemeManager:SaveFont(name)
		if writefile then
			pcall(writefile, self.Folder .. '/themes/font.txt', name)
		end
	end

	ThemeManager.RainbowParts = {
		{ Name = 'Accent', Field = 'AccentColor', Brightness = 1 },
		{ Name = 'Font', Field = 'FontColor', Brightness = 1 },
		{ Name = 'Outline', Field = 'OutlineColor', Brightness = 0.6 },
		{ Name = 'Main', Field = 'MainColor', Brightness = 0.3 },
		{ Name = 'Background', Field = 'BackgroundColor', Brightness = 0.2 },
	}

	function ThemeManager:GetSavedRainbow()
		local path = self.Folder .. '/themes/rainbow.txt'
		local legacy = self.Folder .. '/themes/rainbow.json'
		if isfile and isfile(legacy) then
			if not isfile(path) and writefile then
				pcall(writefile, path, readfile(legacy))
			end
			if delfile then
				pcall(delfile, legacy)
			end
		end
		if isfile and isfile(path) then
			local ok, data = pcall(httpService.JSONDecode, httpService, readfile(path))
			if ok and type(data) == 'table' then
				return type(data.parts) == 'table' and data.parts or {}, tonumber(data.speed) or 5
			end
		end
		return {}, 5
	end

	function ThemeManager:SaveRainbow()
		if not writefile or not Options.ThemeManager_Rainbow then
			return
		end
		local parts = {}
		for name, enabled in next, Options.ThemeManager_Rainbow.Value do
			if enabled then
				table.insert(parts, name)
			end
		end
		local data = { parts = parts, speed = Options.ThemeManager_RainbowSpeed.Value }
		pcall(writefile, self.Folder .. '/themes/rainbow.txt', httpService:JSONEncode(data))
	end

	function ThemeManager:StartRainbow()
		if self.RainbowConnection then
			return
		end
		local function onFrame()
			local selected = Options.ThemeManager_Rainbow and Options.ThemeManager_Rainbow.Value
			if type(selected) ~= 'table' or not next(selected) then
				return
			end

			local speed = Options.ThemeManager_RainbowSpeed and Options.ThemeManager_RainbowSpeed.Value or 5
			local hue = (os.clock() * speed / 20) % 1
			local changed = false

			for _, part in ipairs(self.RainbowParts) do
				if selected[part.Name] then
					self.Library[part.Field] = Color3.fromHSV(hue, 0.8, part.Brightness)
					changed = true
				end
			end

			if changed then
				self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
				self.Library:UpdateColorsUsingRegistry()
			end
		end

		local signal = game:GetService('RunService').RenderStepped
		if self.Library.Connect then
			self.RainbowConnection = self.Library:Connect(signal, onFrame)
		else
			self.RainbowConnection = signal:Connect(onFrame)
			if self.Library.GiveSignal then
				self.Library:GiveSignal(self.RainbowConnection)
			end
		end
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. '/themes/default.txt', theme)
	end

	function ThemeManager:Delete(name)
		if (not name) then
			return false, 'no config file is selected'
		end
		
		local file = self.Folder .. '/themes/' .. name .. '.json'
		if not isfile(file) then return false, 'invalid file' end

		local success, decoded = pcall(delfile, file)
		if not success then return false, 'delete file error' end
		
		return true
	end
	
	function ThemeManager:CreateThemeManager(groupbox)
		groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor });
		groupbox:AddLabel('Main color')	:AddColorPicker('MainColor', { Default = self.Library.MainColor });
		groupbox:AddLabel('Accent color'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor });
		groupbox:AddLabel('Outline color'):AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor });
		groupbox:AddLabel('Font color')	:AddColorPicker('FontColor', { Default = self.Library.FontColor });

		groupbox:AddDropdown('ThemeManager_Font', { Text = 'Font', Values = self:GetFonts(), Default = self:GetSavedFont() })
		Options.ThemeManager_Font:OnChanged(function()
			local name = Options.ThemeManager_Font.Value
			if name and self.Library.SetFont and self.Library:SetFont(name) then
				self:SaveFont(name)
			end
		end)

		local rainbowNames = {}
		for _, part in ipairs(self.RainbowParts) do
			table.insert(rainbowNames, part.Name)
		end
		local savedParts, savedSpeed = self:GetSavedRainbow()

		groupbox:AddDropdown('ThemeManager_Rainbow', { Text = 'Rainbow', Values = rainbowNames, Default = savedParts, Multi = true, AllowNull = true })
		groupbox:AddSlider('ThemeManager_RainbowSpeed', { Text = 'Rainbow speed', Default = math.clamp(savedSpeed, 1, 10), Min = 1, Max = 10, Rounding = 0, Compact = true })

		local rainbowReady = false
		Options.ThemeManager_Rainbow:OnChanged(function()
			if not rainbowReady then
				return
			end
			self:ThemeUpdate()
			self:SaveRainbow()
		end)
		Options.ThemeManager_RainbowSpeed:OnChanged(function()
			if rainbowReady then
				self:SaveRainbow()
			end
		end)
		rainbowReady = true
		self:StartRainbow()
		
		local ThemesArray = {}
		for Name, Theme in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end

		table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

		groupbox:AddDivider()

		groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = ThemesArray, Default = 1 })
		groupbox:AddButton('Set as default', function()
			self:SaveDefault(Options.ThemeManager_ThemeList.Value)
			self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_ThemeList.Value))
		end)

		Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
		end)

		groupbox:AddDivider()

		groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })
		groupbox:AddButton('Create theme', function() 
			local name = Options.ThemeManager_CustomThemeName.Value
			if name:gsub(' ', '') == '' then
				return self.Library:Notify('Invalid file name for theme (empty)', 3)
			end

			self:SaveCustomTheme(name)

			local newThemes = self:ReloadCustomThemes()
			Options.ThemeManager_CustomThemeList:SetValues(newThemes)
			
			Options.ThemeManager_CustomThemeList:SetValue(name)
		end)

		groupbox:AddDivider()

		groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
		groupbox:AddButton('Load theme', function() 
			local name = Options.ThemeManager_CustomThemeList.Value
			if name and name ~= '' then
				self:ApplyTheme(name)
				self.Library:Notify(string.format('Loaded theme %q', name), 3)
			else
				self.Library:Notify('Please select a theme from the list!', 3)
			end
		end)
		groupbox:AddButton('Overwrite theme', function()
			local name = Options.ThemeManager_CustomThemeList.Value
			if name and name ~= '' then
				self:SaveCustomTheme(name)
			else
				self.Library:Notify('Please select a theme from the list to overwrite!', 3)
			end
		end):AddButton('Delete theme', function()
			local name = Options.ThemeManager_CustomThemeList.Value

			if not name or name == '' then
				return self.Library:Notify('Please select a theme to delete', 3)
			end

			local success, err = self:Delete(name)
			if not success then
				return self.Library:Notify('Failed to delete theme: ' .. err)
			end

			self.Library:Notify(string.format('Deleted theme %q', name))
			
			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)
		groupbox:AddButton('Refresh list', function()
			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)
		groupbox:AddButton('Set as default', function()
			if Options.ThemeManager_CustomThemeList.Value ~= nil and Options.ThemeManager_CustomThemeList.Value ~= '' then
				self:SaveDefault(Options.ThemeManager_CustomThemeList.Value)
				self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_CustomThemeList.Value))
			end
		end)
		groupbox:AddButton('Reset default', function()
			local success = pcall(delfile, self.Folder .. '/themes/default.txt')
			if not success then 
				return self.Library:Notify('Failed to reset default: delete file error')
			end
				
			self.Library:Notify('Set default theme to nothing')
			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		ThemeManager:LoadDefault()

		local function UpdateTheme()
			self:ThemeUpdate()
		end

		Options.BackgroundColor:OnChanged(UpdateTheme)
		Options.MainColor:OnChanged(UpdateTheme)
		Options.AccentColor:OnChanged(UpdateTheme)
		Options.OutlineColor:OnChanged(UpdateTheme)
		Options.FontColor:OnChanged(UpdateTheme)
	end

	function ThemeManager:GetCustomTheme(file)
		local fileName = file
		if not fileName:find('%.json$') then
			fileName = fileName .. '.json'
		end
		
		local path = self.Folder .. '/themes/' .. fileName
		if not isfile(path) then return nil end

		local data = readfile(path)
		local success, decoded = pcall(httpService.JSONDecode, httpService, data)
		
		return success and decoded or nil
	end

	function ThemeManager:SaveCustomTheme(file)
		if file:gsub(' ', '') == '' then
			return self.Library:Notify('Invalid file name for theme (empty)', 3)
		end

		local theme = {}
		local fields = { 'FontColor', 'MainColor', 'AccentColor', 'BackgroundColor', 'OutlineColor' }

		for _, field in next, fields do
			if Options[field] then
				theme[field] = Options[field].Value:ToHex()
			end
		end

		file = file:gsub('[\\/:*?"<>|]', '')
		writefile(self.Folder .. '/themes/' .. file .. '.json', httpService:JSONEncode(theme))
		self.Library:Notify(string.format('Saved custom theme %q', file), 3)
	end

	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder .. '/themes')
		local out = {}

		for i = 1, #list do
			local file = list[i]
			-- This grabs everything after the last slash and before .json
			local name = file:match('([^\\/]+)%.json$')
			if name then
				table.insert(out, name)
			end
		end

		return out
	end
	
	function ThemeManager:SetLibrary(lib)
		self.Library = lib
	end

	function ThemeManager:BuildFolderTree()
		local paths = {}

		-- build the entire tree if a path is like some-hub/phantom-forces
		-- makefolder builds the entire tree on Synapse X but not other exploits

		local parts = self.Folder:split('/')
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx)
		end

		table.insert(paths, self.Folder .. '/themes')

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder:gsub('/+$', '')
		self:BuildFolderTree()
	end

	function ThemeManager:CreateGroupBox(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		return tab:AddLeftGroupbox('Themes')
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		local groupbox = self:CreateGroupBox(tab)
		self:CreateThemeManager(groupbox)
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end

return ThemeManager