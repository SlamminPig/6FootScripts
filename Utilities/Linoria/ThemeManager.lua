local httpService = game:GetService('HttpService')
local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local getassetfunc = getcustomasset or getsynasset
local ThemeManager = {} do
	ThemeManager.Folder = 'LinoriaLibSettings'
	-- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end

	ThemeManager.Library = nil
	ThemeManager.BuiltInThemes = {
		['Default'] 		= { 1, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"0055ff","BackgroundColor":"141414","OutlineColor":"323232"}') },
		['BBot'] 			= { 2, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}') },
		['Fatality']		= { 3, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}') },
		['Jester'] 			= { 4, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Mint'] 			= { 5, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Tokyo Night'] 	= { 6, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') },
		['Ubuntu'] 			= { 7, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3e3e3e","VAccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}') },
		['Quartz'] 			= { 8, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}') },
		['Kiriot Hub'] 		= { 9, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"30333b","AccentColor":"ffaa00","BackgroundColor":"1a1c20","OutlineColor":"141414"}') },
		['Green'] 			= { 10, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"141414","AccentColor":"00ff8b","BackgroundColor":"1c1c1c","OutlineColor":"3c3c3c"}') },
		['Dracula'] 		= { 11, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232533","AccentColor":"6271a5","BackgroundColor":"1b1c27","OutlineColor":"7c82a7"}') },
	
		['Solarized Dark'] 	= { 12, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"002b36","AccentColor":"b58900","BackgroundColor":"073642","OutlineColor":"586e75"}') },
		['Cyberpunk'] 		= { 13, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"2a0034","AccentColor":"ff0090","BackgroundColor":"1a001f","OutlineColor":"3a0044"}') },
		['Monokai'] 		= { 14, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"272822","AccentColor":"f92672","BackgroundColor":"1e1e1e","OutlineColor":"75715e"}') },
		['Nord'] 			= { 15, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3b4252","AccentColor":"88c0d0","BackgroundColor":"2e3440","OutlineColor":"4c566a"}') },
		['Oceanic'] 		= { 16, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1b2b34","AccentColor":"6699cc","BackgroundColor":"0f1924","OutlineColor":"4f5b66"}') },
		['Rose Pine'] 		= { 17, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232136","AccentColor":"eb6f92","BackgroundColor":"191724","OutlineColor":"31748f"}') },
		['Hacker'] 			= { 18, httpService:JSONDecode('{"FontColor":"00ff00","MainColor":"101010","AccentColor":"00cc00","BackgroundColor":"080808","OutlineColor":"222222"}') },
		['Midnight'] 		= { 19, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"121212","AccentColor":"304ffe","BackgroundColor":"0a0a0a","OutlineColor":"252525"}') },
		['Lavender'] 		= { 20, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3d2a4d","AccentColor":"c792ea","BackgroundColor":"2a1e37","OutlineColor":"4b3a5a"}') },

		['Void Runner'] 	 = { 21, httpService:JSONDecode('{"FontColor":"d2d2ff","MainColor":"0c001a","AccentColor":"7d00ff","BackgroundColor":"00000a","OutlineColor":"1a0033"}') },
		['Circuit Core'] 	 = { 22, httpService:JSONDecode('{"FontColor":"00ffcc","MainColor":"001a1a","AccentColor":"00ffaa","BackgroundColor":"000f0f","OutlineColor":"005555"}') },
		['Dream Pop'] 		 = { 23, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"ffb5e8","AccentColor":"c7ceea","BackgroundColor":"ffdac1","OutlineColor":"e0bbe4"}') },
		['Moss & Stone'] 	 = { 24, httpService:JSONDecode('{"FontColor":"d4e157","MainColor":"2e342e","AccentColor":"a2c523","BackgroundColor":"1c1f1c","OutlineColor":"4c584c"}') },
		['Noir Film'] 		 = { 25, httpService:JSONDecode('{"FontColor":"eeeeee","MainColor":"111111","AccentColor":"888888","BackgroundColor":"000000","OutlineColor":"2a2a2a"}') },
		['Glass UI'] 		 = { 26, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1a1a1a","AccentColor":"80dfff","BackgroundColor":"0a0a0a","OutlineColor":"80dfff"}') },
		['Arcade Wave'] 	 = { 27, httpService:JSONDecode('{"FontColor":"ffff99","MainColor":"331144","AccentColor":"ff3399","BackgroundColor":"1a0022","OutlineColor":"661177"}') },
		['Storm Cloud'] 	 = { 28, httpService:JSONDecode('{"FontColor":"dfe6e9","MainColor":"2d3436","AccentColor":"74b9ff","BackgroundColor":"1e272e","OutlineColor":"636e72"}') },
		['Duskwood'] 		 = { 29, httpService:JSONDecode('{"FontColor":"e8e6e3","MainColor":"2c2b27","AccentColor":"c0a97a","BackgroundColor":"1a1917","OutlineColor":"3b3a36"}') },
		['Inkdrop'] 		 = { 30, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0f0f14","AccentColor":"2e2e91","BackgroundColor":"06060a","OutlineColor":"1c1c3a"}') },
		['Tundra Bloom'] 	 = { 31, httpService:JSONDecode('{"FontColor":"eaf6ff","MainColor":"5e81ac","AccentColor":"a3be8c","BackgroundColor":"2e3440","OutlineColor":"4c566a"}') },
		['Molten Core'] 	 = { 32, httpService:JSONDecode('{"FontColor":"ffeaa7","MainColor":"2d0900","AccentColor":"ff6f00","BackgroundColor":"120400","OutlineColor":"3e1300"}') },
		['Bioluminescent'] 	 = { 33, httpService:JSONDecode('{"FontColor":"ccffe6","MainColor":"003322","AccentColor":"00ff99","BackgroundColor":"001a12","OutlineColor":"00664d"}') },
		['Mechanical Soul']  = { 34, httpService:JSONDecode('{"FontColor":"e0e0e0","MainColor":"3b3b3b","AccentColor":"d4af37","BackgroundColor":"1c1c1c","OutlineColor":"5e5e5e"}') },
	
		['Abyssal'] 		 = { 35, httpService:JSONDecode('{"FontColor":"ade4ff","MainColor":"0a0f1d","AccentColor":"0077be","BackgroundColor":"02050a","OutlineColor":"1a2a45"}') },
		['Coffee'] 			 = { 36, httpService:JSONDecode('{"FontColor":"fdf0d5","MainColor":"3c2f2f","AccentColor":"be9b7b","BackgroundColor":"251e1e","OutlineColor":"4b3832"}') },
		['Frost'] 			 = { 37, httpService:JSONDecode('{"FontColor":"e0fbff","MainColor":"22333b","AccentColor":"c9f2c7","BackgroundColor":"0a100d","OutlineColor":"3d5a80"}') },
		['Crimson'] 		 = { 38, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1a0a0a","AccentColor":"ff0000","BackgroundColor":"0d0505","OutlineColor":"3d1414"}') },
	}

	function ApplyBackgroundVideo(webmLink)
		if writefile == nil then return end;if readfile == nil then return end;if isfile == nil then return end
		if ThemeManager.Library == nil then return end
		if ThemeManager.Library.InnerVideoBackground == nil then return end

		if string.sub(tostring(webmLink), -5) == ".webm" then
			local CurrentSaved = ""
			if isfile(ThemeManager.Folder .. '/themes/currentVideoLink.txt') then
				 CurrentSaved = readfile(ThemeManager.Folder .. '/themes/currentVideoLink.txt')
			end
			local VideoData = nil;
			if CurrentSaved == tostring(webmLink) then
				VideoData = {
					Success = true,
					Body = nil
				}
			else
				VideoData = httprequest({
					Url = tostring(webmLink),
					Method = 'GET'
				})
			end
			
			if (VideoData.Success) then
				VideoData = VideoData.Body
				if (isfile(ThemeManager.Folder .. '/themes/currentVideo.webm') == false and VideoData ~= nil) or VideoData ~= nil then
					writefile(ThemeManager.Folder .. '/themes/currentVideo.webm', VideoData)
					writefile(ThemeManager.Folder .. '/themes/currentVideoLink.txt', tostring(webmLink))
				end
				
				local Video = getassetfunc(ThemeManager.Folder .. '/themes/currentVideo.webm')
				ThemeManager.Library.InnerVideoBackground.Video = Video
				ThemeManager.Library.InnerVideoBackground.Visible = true
				ThemeManager.Library.InnerVideoBackground:Play()
			end
		end
	end
	
	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]

		if not data then return end

		-- custom themes are just regular dictionaries instead of an array with { index, dictionary }
		if self.Library.InnerVideoBackground ~= nil then
			self.Library.InnerVideoBackground.Visible = false
		end
		
		local scheme = data[2]
		-- for idx, col in next, customThemeData or scheme do
			-- if idx ~= "VideoLink" then
				-- self.Library[idx] = Color3.fromHex(col)
				
				-- if Options[idx] then
					-- Options[idx]:SetValueRGB(Color3.fromHex(col))
				-- end
			-- else
				-- self.Library[idx] = col
				
				-- if Options[idx] then
					-- Options[idx]:SetValue(col)
				-- end
				
				-- --ApplyBackgroundVideo(col)
			-- end
		-- end
		
		for idx, col in next, customThemeData or scheme do
			if idx ~= 'VideoLink' then
				local success, result = pcall(Color3.fromHex, col)
				if success then
					self.Library[idx] = result
					if Options[idx] then
						Options[idx]:SetValueRGB(result)
					end
				end
			else
				self.Library[idx] = col
				if Options[idx] then
					Options[idx]:SetValue(col)
				end
			end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		-- This allows us to force apply themes without loading the themes tab :)
		if self.Library.InnerVideoBackground ~= nil then
			self.Library.InnerVideoBackground.Visible = false
		end
		
		local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor", "VideoLink" }
		for i, field in next, options do
			if Options and Options[field] then
				self.Library[field] = Options[field].Value
				-- if field == "VideoLink" then
					-- ApplyBackgroundVideo(Options[field].Value)
				-- end
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
		--groupbox:AddInput('VideoLink', { Text = '¬_¬', Default = self.Library.VideoLink });
		
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
			self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)

			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		groupbox:AddDivider()

		groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
		groupbox:AddButton('Load theme', function() 
			local name = Options.ThemeManager_CustomThemeList.Value
			if name and name ~= '' then
				self:ApplyTheme(name)
			else
				self.Library:Notify('Please select a theme from the list!', 3)
			end
		end)
		groupbox:AddButton('Overwrite theme', function()
			self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)
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
		if not file:find('%.json$') then
			file = file .. '.json'
		end
		
		local path = self.Folder .. '/themes/' .. file
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
		local fields = { 'FontColor', 'MainColor', 'AccentColor', 'BackgroundColor', 'OutlineColor', 'VideoLink' }

		for _, field in next, fields do
			-- Check if the option exists in the Options table before indexing .Value
			if Options[field] then
				if field == 'VideoLink' then
					theme[field] = Options[field].Value
				else
					theme[field] = Options[field].Value:ToHex()
				end
			end
		end

		writefile(self.Folder .. '/themes/' .. file .. '.json', httpService:JSONEncode(theme))
		self.Library:Notify(string.format('Saved custom theme %q', file), 3)
	end

	-- function ThemeManager:ReloadCustomThemes()
		-- local list = listfiles(self.Folder .. '/themes')

		-- local out = {}
		-- for i = 1, #list do
			-- local file = list[i]
			-- if file:sub(-5) == '.json' then
				-- -- i hate this but it has to be done ...

				-- local pos = file:find('.json', 1, true)
				-- local char = file:sub(pos, pos)

				-- while char ~= '/' and char ~= '\\' and char ~= '' do
					-- pos = pos - 1
					-- char = file:sub(pos, pos)
				-- end

				-- if char == '/' or char == '\\' then
					-- table.insert(out, file:sub(pos + 1))
				-- end
			-- end
		-- end

		-- return out
	-- end

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
		self.Folder = folder
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
