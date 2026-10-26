local httpService = game:GetService('HttpService')

local SaveManager = {} do
	SaveManager.Folder = 'LinoriaLibSettings'
	SaveManager.Ignore = {}
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object) 
				return { type = 'Toggle', idx = idx, value = object.Value } 
			end,
			Load = function(idx, data)
				if Toggles[idx] then 
					Toggles[idx]:SetValue(data.value)
				end
			end,
		},
		Slider = {
			Save = function(idx, object)
				return { type = 'Slider', idx = idx, value = tostring(object.Value) }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValue(data.value)
				end
			end,
		},
		Dropdown = {
			Save = function(idx, object)
				return { type = 'Dropdown', idx = idx, value = object.Value, multi = object.Multi }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValue(data.value)
				end
			end,
		},
		ColorPicker = {
			Save = function(idx, object)
				return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
				end
			end,
		},
		KeyPicker = {
			Save = function(idx, object)
				return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValue({ data.key, data.mode })
				end
			end,
		},

		Input = {
			Save = function(idx, object)
				return { type = 'Input', idx = idx, text = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] and type(data.text) == 'string' then
					Options[idx]:SetValue(data.text)
				end
			end,
		},
	}

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder:gsub('/+$', '')
		self:BuildFolderTree()
	end

	function SaveManager:Export()
		local data = {
			game = game.GameId,
			objects = {}
		}

		for idx, toggle in next, Toggles do
			if self.Ignore[idx] then continue end
			if not self.Parser[toggle.Type] then continue end

			table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
		end

		for idx, option in next, Options do
			if not self.Parser[option.Type] then continue end
			if self.Ignore[idx] then continue end

			table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
		end

		local success, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not success then
			return nil, 'failed to encode data'
		end
		return encoded
	end

	function SaveManager:Import(json)
		if type(json) ~= 'string' or json:gsub('%s', '') == '' then
			return false, 'nothing to import'
		end

		local success, decoded = pcall(httpService.JSONDecode, httpService, json)
		if not success or type(decoded) ~= 'table' or type(decoded.objects) ~= 'table' then
			return false, 'decode error'
		end

		if decoded.game ~= nil and decoded.game ~= game.GameId then
			return false, 'config is for a different game'
		end

		for _, option in next, decoded.objects do
			if type(option) == 'table' and self.Parser[option.type] and not self.Ignore[option.idx] then
				task.spawn(function() self.Parser[option.type].Load(option.idx, option) end)
			end
		end

		return true
	end

	function SaveManager:Save(name)
		if (not name) then
			return false, 'no config file is selected'
		end

		name = name:gsub('[\\/:*?"<>|]', '')
		local fullPath = self.Folder .. '/settings/' .. name .. '.json'

		local encoded, err = self:Export()
		if not encoded then
			return false, err
		end

		writefile(fullPath, encoded)
		return true
	end

	function SaveManager:Load(name)
		if (not name) then
			return false, 'no config file is selected'
		end

		local file = self.Folder .. '/settings/' .. name .. '.json'
		if not isfile(file) then return false, 'invalid file' end

		return self:Import(readfile(file))
	end

	function SaveManager:Delete(name)
		if (not name) then
			return false, 'no config file is selected'
		end
		
		local file = self.Folder .. '/settings/' .. name .. '.json'
		if not isfile(file) then return false, 'invalid file' end

		local success, decoded = pcall(delfile, file)
		if not success then return false, 'delete file error' end
		
		return true
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({ 
			"BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor", -- themes
			"ThemeManager_ThemeList", 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName', 'ThemeManager_Font', 'ThemeManager_Rainbow', 'ThemeManager_RainbowSpeed', -- themes
		})
	end

	function SaveManager:BuildFolderTree()
		local paths = {}
		local parts = self.Folder:split('/')
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx)
		end
		paths[#paths + 1] = self.Folder .. '/themes'
		paths[#paths + 1] = self.Folder .. '/settings'

		for i = 1, #paths do
			if not isfolder(paths[i]) then
				makefolder(paths[i])
			end
		end
	end

	function SaveManager:RefreshConfigList()
		local list = listfiles(self.Folder .. '/settings')
		local out = {}

		for i = 1, #list do
			local name = list[i]:match('([^\\/]+)%.json$')
			if name then
				table.insert(out, name)
			end
		end

		return out
	end

	function SaveManager:SetLibrary(library)
		self.Library = library
	end

	function SaveManager:LoadAutoloadConfig()
		if isfile(self.Folder .. '/settings/autoload.txt') then
			local name = readfile(self.Folder .. '/settings/autoload.txt')

			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('Failed to load autoload config: ' .. err)
			end

			self.Library:Notify(string.format('Auto loaded config %q', name))
		end
	end


	function SaveManager:BuildConfigSection(tab)
		assert(self.Library, 'Must set SaveManager.Library')

		local section = tab:AddRightGroupbox('Configuration')

		section:AddInput('SaveManager_ConfigName',    { Text = 'Config name' })
		section:AddButton('Create config', function()
			local name = Options.SaveManager_ConfigName.Value

			if name:gsub(' ', '') == '' then 
				return self.Library:Notify('Invalid config name (empty)', 2)
			end

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('Failed to create config: ' .. err)
			end

			self.Library:Notify(string.format('Created config %q', name))

			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			Options.SaveManager_ConfigList:SetValue(nil)
		end)

		section:AddDivider()

		section:AddDropdown('SaveManager_ConfigList', { Text = 'Config list', Values = self:RefreshConfigList(), AllowNull = true })
		section:AddButton('Load config', function()
			local name = Options.SaveManager_ConfigList.Value

			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('Failed to load config: ' .. err)
			end

			self.Library:Notify(string.format('Loaded config %q', name))
		end)
		section:AddButton('Overwrite config', function()
			local name = Options.SaveManager_ConfigList.Value

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('Failed to overwrite config: ' .. err)
			end

			self.Library:Notify(string.format('Overwrote config %q', name))
		end):AddButton({
			Text = 'Delete config',
			Func = function()
				local name = Options.SaveManager_ConfigList.Value

				local success, err = self:Delete(name)
				if not success then
					return self.Library:Notify('Failed to delete config: ' .. err)
				end

				self.Library:Notify(string.format('Deleted config %q', name))
				Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
				Options.SaveManager_ConfigList:SetValue(nil)
			end,
			DoubleClick = true
		})
		section:AddButton('Refresh list', function()
			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			Options.SaveManager_ConfigList:SetValue(nil)
		end)

		section:AddButton('Set as autoload', function()
			local name = Options.SaveManager_ConfigList.Value
			if not name then
				return self.Library:Notify('Select a config first', 2)
			end
			writefile(self.Folder .. '/settings/autoload.txt', name)
			SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
			self.Library:Notify(string.format('Set %q to auto load', name))
		end)
		section:AddButton('Reset autoload', function()
			local success = pcall(delfile, self.Folder .. '/settings/autoload.txt')
			if not success then 
				return self.Library:Notify('Failed to reset autoload: delete file error')
			end
				
			self.Library:Notify('Set autoload to none')
			SaveManager.AutoloadLabel:SetText('Current autoload config: none')
		end)

		SaveManager.AutoloadLabel = section:AddLabel('Current autoload config: none', true)

		section:AddDivider()

		section:AddButton('Copy config', function()
			local clipboard = setclipboard or toclipboard
			if not clipboard then
				return self.Library:Notify('Your executor does not support copying to clipboard', 3)
			end

			local encoded, err = self:Export()
			if not encoded then
				return self.Library:Notify('Failed to copy config: ' .. err)
			end

			clipboard(encoded)
			self.Library:Notify('Copied current settings to clipboard')
		end)

		section:AddInput('SaveManager_ImportText', { Text = 'Paste config', Placeholder = 'Paste a copied config here', ClearTextOnFocus = false })
		section:AddButton('Import config', function()
			local success, err = self:Import(Options.SaveManager_ImportText.Value)
			if not success then
				return self.Library:Notify('Failed to import config: ' .. err)
			end

			Options.SaveManager_ImportText:SetValue('')
			self.Library:Notify('Imported config')
		end)

		if isfile(self.Folder .. '/settings/autoload.txt') then
			local name = readfile(self.Folder .. '/settings/autoload.txt')
			SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
		end

		SaveManager:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName', 'SaveManager_ImportText' })
	end

	SaveManager:BuildFolderTree()
end

return SaveManager
