local cloneref = cloneref or function(o) return o end
local InputService: UserInputService = cloneref(game:GetService('UserInputService'));
local TextService: TextService = cloneref(game:GetService('TextService'));
local CoreGui: CoreGui = cloneref(game:GetService('CoreGui'));
local Teams: Teams = cloneref(game:GetService('Teams'));
local Players: Players = cloneref(game:GetService('Players'));
local RunService: RunService = cloneref(game:GetService('RunService'));
local TweenService: TweenService = cloneref(game:GetService('TweenService'));
local GuiService: GuiService = cloneref(game:GetService('GuiService'));
local HttpService: HttpService = cloneref(game:GetService('HttpService'));
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);
local GetHUI = gethui or (function() return CoreGui end);

local function Elevate()
	if setthreadidentity then
		pcall(setthreadidentity, 8);
	end;
end;

local OldLibrary = getgenv().Library;
if type(OldLibrary) == 'table' and type(OldLibrary.Unload) == 'function' and not OldLibrary.Unloaded then
	pcall(OldLibrary.Unload, OldLibrary);
end;

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = GetHUI();

local Toggles = {};
local Options = {};

getgenv().Linoria = { 
	Toggles = Toggles,
	Options = Options
}

getgenv().Toggles = Toggles; 
getgenv().Options = Options;

local LibraryMainOuterFrame = nil;
local Library = {
	Registry = {};
	RegistryMap = {};

	HudRegistry = {};

	FontColor = Color3.fromRGB(255, 255, 255);
	MainColor = Color3.fromRGB(28, 28, 28);
	BackgroundColor = Color3.fromRGB(20, 20, 20);
	AccentColor = Color3.fromRGB(0, 85, 255);
	OutlineColor = Color3.fromRGB(50, 50, 50);
	RiskColor = Color3.fromRGB(255, 50, 50),

	Black = Color3.new(0, 0, 0);
	Font = Enum.Font.Code,

	OpenedFrames = {};
	DependencyBoxes = {};

	Signals = {};
	ScreenGui = ScreenGui;

	ActiveTab = nil;
	Toggled = false;

	MinSize = Vector2.new(550, 300);
	IsMobile = false;
	DevicePlatform = Enum.Platform.None;
	CanDrag = true;
	CantDragForced = false;
	ShowCustomCursor = false; 
	TotalTabs = 0;
};

pcall(function() Library.DevicePlatform = InputService:GetPlatform(); end); 
Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS);
Library.ElementHeight = Library.IsMobile and 26 or 20;
Library.ToggleSize = Library.IsMobile and 17 or 13;

if Library.IsMobile then
	Library.MinSize = Vector2.new(550, 200); 
end

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
	RainbowStep = RainbowStep + Delta

	if RainbowStep >= (1 / 60) then
		RainbowStep = 0;

		Hue = Hue + (1 / 400);

		if Hue > 1 then
			Hue = 0;
		end;

		Library.CurrentRainbowHue = Hue;
		Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
	end;
end));

local function GetPlayersString()
	local PlayerList = Players:GetPlayers();

	for i = 1, #PlayerList do
		PlayerList[i] = PlayerList[i].Name;
	end;

	table.sort(PlayerList, function(str1, str2) return str1 < str2 end);

	return PlayerList;
end;

local function GetTeamsString()
	local TeamList = Teams:GetTeams();

	for i = 1, #TeamList do
		TeamList[i] = TeamList[i].Name;
	end;

	table.sort(TeamList, function(str1, str2) return str1 < str2 end);

	return TeamList;
end;

local function AddListener(Object, Field, Func)
	assert(type(Func) == 'function', 'OnChanged: expected a function');

	local ListField = '_' .. Field .. 'Listeners';
	local List = rawget(Object, ListField);
	if not List then
		List = {};
		rawset(Object, ListField, List);
		rawset(Object, Field, function(...)
			for _, Listener in ipairs(table.clone(List)) do
				if Library.NotifyOnError then
					Library:SafeCallback(Listener, ...);
				else
					local Success, Error = pcall(Listener, ...);
					if not Success then
						task.spawn(error, Error, 0);
					end;
				end;
			end;
		end);
	end;

	table.insert(List, Func);

	local Connection = { Connected = true };
	function Connection:Disconnect()
		if not self.Connected then
			return;
		end;
		self.Connected = false;
		local Index = table.find(List, Func);
		if Index then
			table.remove(List, Index);
		end;
	end;
	Connection.Destroy = Connection.Disconnect;

	return Connection;
end;

function Library:SafeCallback(f, ...)
	if (not f) then
		return;
	end;

	Elevate();

	if not Library.NotifyOnError then
		local Results = table.pack(f(...));
		Elevate();
		return table.unpack(Results, 1, Results.n);
	end;

	local success, event = pcall(f, ...);
	Elevate();

	if not success then
		local _, i = event:find(":%d+: ");

		if not i then
			return Library:Notify(event);
		end;

		return Library:Notify(event:sub(i + 1), 3);
	end;
end;

function Library:AttemptSave()
	if Library.SaveManager then
		Library.SaveManager:Save();
	end;
end;

function Library:Create(Class, Properties)
	local _Instance = Class;

	if type(Class) == 'string' then
		_Instance = Instance.new(Class);
	end;

	for Property, Value in next, Properties do
		_Instance[Property] = Value;
	end;

	return _Instance;
end;

function Library:ApplyTextStroke(Inst)
	Inst.TextStrokeTransparency = 1;

	Library:Create('UIStroke', {
		Color = Color3.new(0, 0, 0);
		Thickness = 1;
		LineJoinMode = Enum.LineJoinMode.Miter;
		Parent = Inst;
	});
end;

function Library:CreateLabel(Properties, IsHud)
	local _Instance = Library:Create('TextLabel', {
		BackgroundTransparency = 1;
		Font = Library.Font;
		TextColor3 = Library.FontColor;
		TextSize = 16;
		TextStrokeTransparency = 0;
	});

	Library:ApplyTextStroke(_Instance);

	Library:AddToRegistry(_Instance, {
		TextColor3 = 'FontColor';
	}, IsHud);

	return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff)
	Instance.Active = true;

	Instance.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			local ObjPos = Vector2.new(
				Mouse.X - Instance.AbsolutePosition.X,
				Mouse.Y - Instance.AbsolutePosition.Y
			);

			if ObjPos.Y > (Cutoff or 40) then
				return;
			end;

			while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				Instance.Position = UDim2.new(
					0,
					Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
					0,
					Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
				);

				RenderStepped:Wait();
			end;
		end;
	end);

	if Library.IsMobile then
		local Dragging, DraggingInput, DraggingStart, StartPosition;

		InputService.TouchStarted:Connect(function(Input)
			if Library.CantDragForced == true then
				Dragging = false
				return;
			end
			if not Dragging and Library:MouseIsOverFrame(Instance, Input) and Library.Window.Holder.Visible == true then
				DraggingInput = Input;
				DraggingStart = Input.Position;
				StartPosition = Instance.Position;

				local OffsetPos = Input.Position - DraggingStart;
				if OffsetPos.Y > (Cutoff or 40) then
					Dragging = false;
					return;
				end;

				Dragging = true;
			end;
		end);
		InputService.TouchMoved:Connect(function(Input)
			if Library.CantDragForced == true then
				Dragging = false;
				return;
			end
			if Input == DraggingInput and Dragging and Library.CanDrag == true and Library.Window.Holder.Visible == true then
				local OffsetPos = Input.Position - DraggingStart;

				Instance.Position = UDim2.new(
					StartPosition.X.Scale,
					StartPosition.X.Offset + OffsetPos.X,
					StartPosition.Y.Scale,
					StartPosition.Y.Offset + OffsetPos.Y
				);
			end;
		end);
		InputService.TouchEnded:Connect(function(Input)
			if Input == DraggingInput then 
				Dragging = false;
			end;
		end);
	end;
end;

function Library:MakeResizable(Instance, MinSize)
	if Library.IsMobile then
		return;
	end;

	Instance.Active = true;

	local ResizerImage_Size = 25;
	local ResizerImage_HoverTransparency = 0.5;

	local Resizer = Library:Create('Frame', {
		SizeConstraint = Enum.SizeConstraint.RelativeXX;
		BackgroundColor3 = Color3.new(0, 0, 0);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Size = UDim2.new(0, 30, 0, 30);
		Position = UDim2.new(1, -30, 1, -30);
		Visible = true;
		ClipsDescendants = true;
		ZIndex = 1;
		Parent = Instance;
	});

	local ResizerImage = Library:Create('ImageButton', {
		BackgroundColor3 = Library.AccentColor;
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Size = UDim2.new(2, 0, 2, 0);
		Position = UDim2.new(1, -30, 1, -30);
		ZIndex = 2;
		Parent = Resizer;
	});

	local ResizerImageUICorner = Library:Create('UICorner', {
		CornerRadius = UDim.new(0.5, 0);
		Parent = ResizerImage;
	});

	Library:AddToRegistry(ResizerImage, { BackgroundColor3 = 'AccentColor'; });

	Resizer.Size = UDim2.fromOffset(ResizerImage_Size, ResizerImage_Size);
	Resizer.Position = UDim2.new(1, -ResizerImage_Size, 1, -ResizerImage_Size);
	MinSize = MinSize or Library.MinSize;

	local OffsetPos;
	Resizer.Parent = Instance;

	local function FinishResize(Transparency)
		ResizerImage.Position = UDim2.new();
		ResizerImage.Size = UDim2.new(2, 0, 2, 0);
		ResizerImage.Parent = Resizer;
		ResizerImage.BackgroundTransparency = Transparency;
		ResizerImageUICorner.Parent = ResizerImage;
		OffsetPos = nil;
	end;

	ResizerImage.MouseButton1Down:Connect(function()
		if not OffsetPos then
			OffsetPos = Vector2.new(Mouse.X - (Instance.AbsolutePosition.X + Instance.AbsoluteSize.X), Mouse.Y - (Instance.AbsolutePosition.Y + Instance.AbsoluteSize.Y));

			ResizerImage.BackgroundTransparency = 1
			ResizerImage.Size = UDim2.fromOffset(Library.ScreenGui.AbsoluteSize.X, Library.ScreenGui.AbsoluteSize.Y);
			ResizerImage.Position = UDim2.new();
			ResizerImageUICorner.Parent = nil;
			ResizerImage.Parent = Library.ScreenGui;
		end;
	end);

	ResizerImage.MouseMoved:Connect(function()
		if OffsetPos then		
			local MousePos = Vector2.new(Mouse.X - OffsetPos.X, Mouse.Y - OffsetPos.Y);
			local FinalSize = Vector2.new(math.clamp(MousePos.X - Instance.AbsolutePosition.X, MinSize.X, math.huge), math.clamp(MousePos.Y - Instance.AbsolutePosition.Y, MinSize.Y, math.huge));
			Instance.Size = UDim2.fromOffset(FinalSize.X, FinalSize.Y);
		end;
	end);

	ResizerImage.MouseEnter:Connect(function()
		FinishResize(ResizerImage_HoverTransparency);		
	end);

	ResizerImage.MouseLeave:Connect(function() 
		FinishResize(1);
	end);

	ResizerImage.MouseButton1Up:Connect(function()
		FinishResize(ResizerImage_HoverTransparency);
	end);
end;

function Library:AddToolTip(InfoStr, HoverInstance)
	local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14);
	local Tooltip = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,

		Size = UDim2.fromOffset(X + 5, Y + 4),
		ZIndex = 100,
		Parent = Library.ScreenGui,

		Visible = false,
	});

	local Label = Library:CreateLabel({
		Position = UDim2.fromOffset(3, 1),
		Size = UDim2.fromOffset(X, Y);
		TextSize = 14;
		Text = InfoStr,
		TextColor3 = Library.FontColor,
		TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = Tooltip.ZIndex + 1,

		Parent = Tooltip;
	});

	Library:AddToRegistry(Tooltip, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	});

	Library:AddToRegistry(Label, {
		TextColor3 = 'FontColor',
	});

	local IsHovering = false
	local TouchShown = false

	HoverInstance.MouseEnter:Connect(function()
		if TouchShown or Library.PickerOpen or Library:MouseIsOverOpenedFrame() then
			return
		end

		if InputService:GetLastInputType() == Enum.UserInputType.Touch then
			return
		end

		IsHovering = true

		Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
		Tooltip.Visible = true

		while IsHovering do
			RunService.Heartbeat:Wait()
			if Library.PickerOpen then
				IsHovering = false
				Tooltip.Visible = false
				break
			end
			Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
		end
	end)

	HoverInstance.MouseLeave:Connect(function()
		IsHovering = false
		if not TouchShown then
			Tooltip.Visible = false
		end
	end)

	local function HideTouchTooltip()
		if TouchShown then
			TouchShown = false
			Tooltip.Visible = false
		end
	end

	local function ShowTouchTooltip()
		local Screen = Library.ScreenGui.AbsoluteSize
		local Position, Size = HoverInstance.AbsolutePosition, HoverInstance.AbsoluteSize
		local Width, Height = Tooltip.AbsoluteSize.X, Tooltip.AbsoluteSize.Y

		local X = math.clamp(Position.X, 4, math.max(4, Screen.X - Width - 4))
		local Y = Position.Y - Height - 8
		if Y < 4 then
			Y = Position.Y + Size.Y + 8
		end

		IsHovering = false
		TouchShown = true
		Tooltip.Position = UDim2.fromOffset(X, Y)
		Tooltip.Visible = true

		local Connection
		Connection = InputService.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Connection:Disconnect()
				HideTouchTooltip()
			end
		end)

	end

	HoverInstance.InputBegan:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.Touch or Library.PickerOpen or Library:MouseIsOverOpenedFrame(Input) then
			return
		end

		local Start = Input.Position

		task.delay(0.45, function()
			if Input.UserInputState == Enum.UserInputState.End or Input.UserInputState == Enum.UserInputState.Cancel then
				return
			end

			if (Input.Position - Start).Magnitude > 10 or Library.PickerOpen then
				return
			end

			Library.LongPressInput = Input

			if Library.CancelPendingTap then
				Library.CancelPendingTap()
			end

			ShowTouchTooltip()
		end)
	end)

	if LibraryMainOuterFrame then
		LibraryMainOuterFrame:GetPropertyChangedSignal("Visible"):Connect(function() 
			if LibraryMainOuterFrame.Visible == false then
				IsHovering = false
				TouchShown = false
				Tooltip.Visible = false
			end
		end)
	end
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault, condition)
	local function undoHighlight()
		local Reg = Library.RegistryMap[Instance];

		for Property, ColorIdx in next, PropertiesDefault do
			Instance[Property] = Library[ColorIdx] or ColorIdx;

			if Reg and Reg.Properties[Property] then
				Reg.Properties[Property] = ColorIdx;
			end;
		end;
	end
	local function IsCovered()
		if Library.PickerOpen then
			return true;
		end;

		for Frame in next, Library.OpenedFrames do
			if Frame.Visible and not HighlightInstance:IsDescendantOf(Frame) and Library:MouseIsOverFrame(Frame) then
				return true;
			end;
		end;

		return false;
	end

	local function doHighlight()
		if IsCovered() or (condition and not condition()) then undoHighlight() return end
		local Reg = Library.RegistryMap[Instance];

		for Property, ColorIdx in next, Properties do
			Instance[Property] = Library[ColorIdx] or ColorIdx;

			if Reg and Reg.Properties[Property] then
				Reg.Properties[Property] = ColorIdx;
			end;
		end;
	end

	HighlightInstance.MouseEnter:Connect(function()
		doHighlight()
	end)
	HighlightInstance.MouseMoved:Connect(function()
		doHighlight()
	end)
	HighlightInstance.MouseLeave:Connect(function()
		undoHighlight()
	end)
end;

function Library:MouseIsOverOpenedFrame(Input)
	local Pos = Mouse;
	if Library.IsMobile and Input then 
		Pos = Input.Position;
	end;
	for Frame, _ in next, Library.OpenedFrames do
		local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

		if Pos.X >= AbsPos.X and Pos.X <= AbsPos.X + AbsSize.X
			and Pos.Y >= AbsPos.Y and Pos.Y <= AbsPos.Y + AbsSize.Y then

			return true;
		end;
	end;
end;

function Library:MouseIsOverFrame(Frame, Input)
	local Pos = Mouse;
	if Library.IsMobile and Input then 
		Pos = Input.Position;
	end;
	local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

	if Pos.X >= AbsPos.X and Pos.X <= AbsPos.X + AbsSize.X
		and Pos.Y >= AbsPos.Y and Pos.Y <= AbsPos.Y + AbsSize.Y then

		return true;
	end;
end;

function Library:UpdateDependencyBoxes()
	Elevate();
	for _, Depbox in next, Library.DependencyBoxes do
		Depbox:Update();
	end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
	return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
	local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
	return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
	local H, S, V = Color3.toHSV(Color);
	return Color3.fromHSV(H, S, V / 1.5);
end;
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
	local Idx = #Library.Registry + 1;
	local Data = {
		Instance = Instance;
		Properties = Properties;
		Idx = Idx;
	};

	table.insert(Library.Registry, Data);
	Library.RegistryMap[Instance] = Data;

	if IsHud then
		table.insert(Library.HudRegistry, Data);
	end;
end;

function Library:RemoveFromRegistry(Instance)
	local Data = Library.RegistryMap[Instance];

	if Data then
		for Idx = #Library.Registry, 1, -1 do
			if Library.Registry[Idx] == Data then
				table.remove(Library.Registry, Idx);
			end;
		end;

		for Idx = #Library.HudRegistry, 1, -1 do
			if Library.HudRegistry[Idx] == Data then
				table.remove(Library.HudRegistry, Idx);
			end;
		end;

		Library.RegistryMap[Instance] = nil;
	end;
end;

function Library:UpdateColorsUsingRegistry()

	for Idx, Object in next, Library.Registry do
		for Property, ColorIdx in next, Object.Properties do
			if type(ColorIdx) == 'string' then
				Object.Instance[Property] = Library[ColorIdx];
			elseif type(ColorIdx) == 'function' then
				Object.Instance[Property] = ColorIdx()
			end
		end;
	end;
end;

function Library:GiveSignal(Signal)

	table.insert(Library.Signals, Signal)
end

function Library:Unload()
	if Library.Unloaded then
		return
	end
	Library.Unloaded = true

	for _, Callback in ipairs(Library.UnloadCallbacks) do
		local Success, Error = pcall(Callback)
		if not Success then
			warn(Error)
		end
	end
	table.clear(Library.UnloadCallbacks)

	for Idx = #Library.Signals, 1, -1 do
		local Connection = table.remove(Library.Signals, Idx)
		pcall(Connection.Disconnect, Connection)
	end

	local Current = coroutine.running()
	for _, Thread in ipairs(Library.Threads) do
		if Thread ~= Current then
			pcall(task.cancel, Thread)
		end
	end
	table.clear(Library.Threads)

	ScreenGui:Destroy()

	if getgenv().Library == Library then
		getgenv().Library = nil
	end
end

Library.UnloadCallbacks = {}
Library.Threads = {}

function Library:Connect(Signal, Callback)
	local Connection = Signal:Connect(Callback)
	if Library.Unloaded then
		Connection:Disconnect()
		return Connection
	end
	table.insert(Library.Signals, Connection)
	return Connection
end

function Library:Spawn(Callback, ...)
	local Thread = task.spawn(Callback, ...)
	if Library.Unloaded then
		pcall(task.cancel, Thread)
		return Thread
	end
	for Idx = #Library.Threads, 1, -1 do
		if coroutine.status(Library.Threads[Idx]) == 'dead' then
			table.remove(Library.Threads, Idx)
		end
	end
	table.insert(Library.Threads, Thread)
	return Thread
end

function Library:Loop(Interval, Callback)
	return Library:Spawn(function()
		while not Library.Unloaded do
			Elevate()
			local Success, Error = pcall(Callback)
			if not Success then
				warn(Error)
			end
			task.wait(Interval)
		end
	end)
end

function Library:OnUnload(Callback)
	table.insert(Library.UnloadCallbacks, Callback)
end

local function CleanTask(Task)
	local Kind = typeof(Task)
	if Kind == 'RBXScriptConnection' then
		Task:Disconnect()
	elseif Kind == 'function' then
		Task()
	elseif Kind == 'thread' then
		local Cancelled = false
		if coroutine.running() ~= Task then
			Cancelled = pcall(task.cancel, Task)
		end
		if not Cancelled then
			task.defer(function()
				pcall(task.cancel, Task)
			end)
		end
	elseif Kind == 'Instance' then
		Task:Destroy()
	elseif type(Task) == 'table' then
		if type(Task.Destroy) == 'function' then
			Task:Destroy()
		elseif type(Task.Disconnect) == 'function' then
			Task:Disconnect()
		end
	end
end

local function SafeCleanTask(Task)
	local Success, Error = pcall(CleanTask, Task)
	if not Success then
		warn('[Maid] Cleanup error: ' .. tostring(Error))
	end
end

local function IsValidTask(Task)
	local Kind = typeof(Task)
	return Kind == 'function' or Kind == 'thread' or Kind == 'RBXScriptConnection' or Kind == 'Instance'
		or (Kind == 'table' and (type(Task.Destroy) == 'function' or type(Task.Disconnect) == 'function'))
end

local ActiveMaids = {}
local MaidTasks = setmetatable({}, { __mode = 'k' })

local Maid = {}
Maid.ClassName = 'Maid'

function Maid.new()
	local self = setmetatable({}, Maid)
	MaidTasks[self] = {}
	return self
end

function Maid.isMaid(Value)
	return type(Value) == 'table' and getmetatable(Value) == Maid
end

function Maid.__index(self, Key)
	if Maid[Key] ~= nil then
		return Maid[Key]
	end
	return MaidTasks[self][Key]
end

function Maid.__newindex(self, Key, NewTask)
	if Maid[Key] ~= nil then
		error(string.format("Cannot use '%s' as a Maid key", tostring(Key)), 2)
	end

	local Tasks = MaidTasks[self]
	local Old = Tasks[Key]
	if Old == NewTask then
		return
	end

	if NewTask ~= nil and Library.Unloaded then
		Tasks[Key] = nil
		SafeCleanTask(NewTask)
	else
		Tasks[Key] = NewTask
		if NewTask ~= nil then
			ActiveMaids[self] = true
		elseif next(Tasks) == nil then
			ActiveMaids[self] = nil
		end
	end

	if Old ~= nil then
		SafeCleanTask(Old)
	end
end

function Maid:GiveTask(Task)
	if not Task then
		error('Task cannot be false or nil', 2)
	end
	if not IsValidTask(Task) then
		warn('[Maid.GiveTask] Task of type ' .. typeof(Task) .. ' has no Destroy or Disconnect and will be ignored on cleanup\n' .. debug.traceback())
	end

	local Index = #MaidTasks[self] + 1
	self[Index] = Task
	return Index
end

function Maid:Add(Task)
	self:GiveTask(Task)
	return Task
end

function Maid:DoCleaning()
	local Tasks = MaidTasks[self]

	for Key, Task in pairs(Tasks) do
		if typeof(Task) == 'RBXScriptConnection' then
			Tasks[Key] = nil
			Task:Disconnect()
		end
	end

	local Key, Task = next(Tasks)
	while Task ~= nil do
		Tasks[Key] = nil
		SafeCleanTask(Task)
		Key, Task = next(Tasks)
	end

	ActiveMaids[self] = nil
end

Maid.Destroy = Maid.DoCleaning

Library.Maid = setmetatable({
	new = Maid.new,
	isMaid = Maid.isMaid,
	ClassName = 'Maid',
}, {
	__call = function()
		return Maid.new()
	end,
})

function Library:OnCharacter(Callback)
	assert(type(Callback) == 'function', 'OnCharacter: expected a function');

	local Watcher = Library.Maid.new();
	local CurrentCharacter = nil;

	local function Setup(Character)
		CurrentCharacter = Character;
		local CharacterMaid = Library.Maid.new();
		Watcher.Character = CharacterMaid;

		CharacterMaid:GiveTask(task.spawn(function()
			local Humanoid = Character:WaitForChild('Humanoid', 10);
			Callback(Character, CharacterMaid, Humanoid);
		end));
	end;

	Watcher:GiveTask(LocalPlayer.CharacterAdded:Connect(Setup));
	Watcher:GiveTask(LocalPlayer.CharacterRemoving:Connect(function(Character)
		if Character == CurrentCharacter then
			CurrentCharacter = nil;
			Watcher.Character = nil;
		end;
	end));

	if LocalPlayer.Character then
		Setup(LocalPlayer.Character);
	end;

	return Watcher;
end;

function Library:Throttle(Interval, Callback, Config)
	assert(type(Interval) == 'number', 'Throttle: expected a number interval');
	assert(type(Callback) == 'function', 'Throttle: expected a function');

	Config = Config or {};
	local Leading = Config.Leading ~= false;
	local Trailing = Config.Trailing ~= false;

	local NextAllowed = 0;
	local PendingArgs = nil;
	local Scheduled = false;

	local function Run(...)
		if Library.Unloaded then
			return;
		end;
		NextAllowed = os.clock() + Interval;
		Callback(...);
	end;

	local function ScheduleTrailing(Delay)
		if Scheduled then
			return;
		end;
		Scheduled = true;
		Library:Spawn(function()
			task.wait(Delay);
			Scheduled = false;
			if PendingArgs then
				local Args = PendingArgs;
				PendingArgs = nil;
				Run(table.unpack(Args, 1, Args.n));
			end;
		end);
	end;

	return function(...)
		local Now = os.clock();
		if Now >= NextAllowed and not Scheduled then
			if Leading then
				Run(...);
			elseif Trailing then
				PendingArgs = table.pack(...);
				NextAllowed = Now + Interval;
				ScheduleTrailing(Interval);
			end;
			return;
		end;

		if Trailing then
			PendingArgs = table.pack(...);
			ScheduleTrailing(math.max(0, NextAllowed - Now));
		end;
	end;
end;

function Library:Debounce(Delay, Callback)
	assert(type(Delay) == 'number', 'Debounce: expected a number delay');
	assert(type(Callback) == 'function', 'Debounce: expected a function');

	local Version = 0;

	return function(...)
		Version = Version + 1;
		local MyVersion = Version;
		local Args = table.pack(...);

		Library:Spawn(function()
			task.wait(Delay);
			if MyVersion == Version and not Library.Unloaded then
				Callback(table.unpack(Args, 1, Args.n));
			end;
		end);
	end;
end;

local EveryTimestamps = {};

function Library:Every(Key, Interval)
	local Now = os.clock();
	if Now - (EveryTimestamps[Key] or -math.huge) >= Interval then
		EveryTimestamps[Key] = Now;
		return true;
	end;
	return false;
end;

--[[
	Fuzzy matching below is adapted from fzy-lua (https://github.com/swarn/fzy-lua),
	as included in NevermoreEngine (https://github.com/Quenty/NevermoreEngine).

	The MIT License (MIT)

	Copyright (c) 2020 Seth Warn

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
]]

local FUZZY_GAP_LEADING = -0.005;
local FUZZY_GAP_TRAILING = -0.005;
local FUZZY_GAP_INNER = -0.01;
local FUZZY_CONSECUTIVE = 1.0;
local FUZZY_SLASH = 0.9;
local FUZZY_WORD = 0.8;
local FUZZY_CAPITAL = 0.7;
local FUZZY_DOT = 0.6;
local FUZZY_MAX_LENGTH = 1024;

local function FuzzyBonuses(Haystack)
	local Bonuses = {};
	local Last = '/';
	for Index = 1, #Haystack do
		local Char = Haystack:sub(Index, Index);
		if Last == '/' or Last == '\\' then
			Bonuses[Index] = FUZZY_SLASH;
		elseif Last == '-' or Last == '_' or Last == ' ' then
			Bonuses[Index] = FUZZY_WORD;
		elseif Last == '.' then
			Bonuses[Index] = FUZZY_DOT;
		elseif Last:match('%l') and Char:match('%u') then
			Bonuses[Index] = FUZZY_CAPITAL;
		else
			Bonuses[Index] = 0;
		end;
		Last = Char;
	end;
	return Bonuses;
end;

function Library:FuzzyScore(Needle, Haystack)
	Needle, Haystack = tostring(Needle), tostring(Haystack);
	local NeedleLength, HaystackLength = #Needle, #Haystack;
	if NeedleLength == 0 or NeedleLength > HaystackLength or HaystackLength > FUZZY_MAX_LENGTH then
		return nil;
	end;

	local LowerNeedle, LowerHaystack = Needle:lower(), Haystack:lower();
	if LowerNeedle == LowerHaystack then
		return math.huge;
	end;

	local SearchFrom = 1;
	for Index = 1, NeedleLength do
		SearchFrom = LowerHaystack:find(LowerNeedle:sub(Index, Index), SearchFrom, true);
		if not SearchFrom then
			return nil;
		end;
		SearchFrom = SearchFrom + 1;
	end;

	local Bonuses = FuzzyBonuses(Haystack);
	local HaystackChars = {};
	for Index = 1, HaystackLength do
		HaystackChars[Index] = LowerHaystack:sub(Index, Index);
	end;

	local PreviousD, PreviousM = nil, nil;
	for Row = 1, NeedleLength do
		local D, M = {}, {};
		local Best = -math.huge;
		local Gap = Row == NeedleLength and FUZZY_GAP_TRAILING or FUZZY_GAP_INNER;
		local NeedleChar = LowerNeedle:sub(Row, Row);

		for Column = 1, HaystackLength do
			if NeedleChar == HaystackChars[Column] then
				local Score = -math.huge;
				if Row == 1 then
					Score = (Column - 1) * FUZZY_GAP_LEADING + Bonuses[Column];
				elseif Column > 1 then
					Score = math.max(PreviousM[Column - 1] + Bonuses[Column], PreviousD[Column - 1] + FUZZY_CONSECUTIVE);
				end;
				D[Column] = Score;
				Best = math.max(Score, Best + Gap);
			else
				D[Column] = -math.huge;
				Best = Best + Gap;
			end;
			M[Column] = Best;
		end;

		PreviousD, PreviousM = D, M;
	end;

	return PreviousM[HaystackLength];
end;

function Library:FuzzyFilter(Needle, Values)
	local Results = {};
	for Index, Value in ipairs(Values) do
		local Score = Library:FuzzyScore(Needle, Value);
		if Score then
			table.insert(Results, { Value = Value, Score = Score, Index = Index });
		end;
	end;

	table.sort(Results, function(A, B)
		if A.Score ~= B.Score then
			return A.Score > B.Score;
		end;
		return A.Index < B.Index;
	end);

	local Sorted = {};
	for Index, Result in ipairs(Results) do
		Sorted[Index] = Result.Value;
	end;
	return Sorted;
end;

Library:OnUnload(function()
	local Key = next(ActiveMaids)
	while Key ~= nil do
		ActiveMaids[Key] = nil
		local Success, Error = pcall(Maid.DoCleaning, Key)
		if not Success then
			warn('[Maid] Cleanup error: ' .. tostring(Error))
		end
		Key = next(ActiveMaids)
	end
end)

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
	if Library.RegistryMap[Instance] then
		Library:RemoveFromRegistry(Instance);
	end;
end))

local TapTracker = nil;

function Library.CancelPendingTap()
	TapTracker = nil;
end;

local function TrackTap(Input, Scroller, Callback)
	TapTracker = {
		Start = Input.Position;
		Scroller = Scroller;
		Canvas = Scroller and Scroller.CanvasPosition;
		Callback = Callback;
	};
end;

Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
	if Input.UserInputType ~= Enum.UserInputType.Touch or not TapTracker then
		return;
	end;

	local Tap = TapTracker;
	TapTracker = nil;

	if (Input.Position - Tap.Start).Magnitude > 10 then
		return;
	end;

	if Tap.Scroller and (Tap.Scroller.CanvasPosition - Tap.Canvas).Magnitude > 2 then
		return;
	end;

	Tap.Callback();
end));

local BaseAddons = {};

do
	local Funcs = {};

	function Funcs:AddColorPicker(Idx, Info)
		local ParentObj = self
		local ToggleLabel = self.TextLabel;

		assert(Info.Default, 'AddColorPicker: Missing default value.');

		local ColorPicker = {
			Value = Info.Default;
			Transparency = Info.Transparency or 0;
			Type = 'ColorPicker';
			Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
			Callback = Info.Callback or function(Color) end;
		};

		function ColorPicker:SetHSVFromRGB(Color)
			local H, S, V = Color3.toHSV(Color);

			ColorPicker.Hue = H;
			ColorPicker.Sat = S;
			ColorPicker.Vib = V;
		end;

		ColorPicker:SetHSVFromRGB(ColorPicker.Value);

		local DisplayFrame = Library:Create('Frame', {
			BackgroundColor3 = ColorPicker.Value;
			BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(0, 28, 0, 14);
			ZIndex = 6;
			Parent = ToggleLabel;
		});

		local CheckerFrame = Library:Create('ImageLabel', {
			BorderSizePixel = 0;
			Size = UDim2.new(0, 27, 0, 13);
			ZIndex = 5;
			Image = 'http://www.roblox.com/asset/?id=12977615774';
			Visible = not not Info.Transparency;
			Parent = DisplayFrame;
		});

		local PickerFrameOuter = Library:Create('Frame', {
			Name = 'Color';
			BackgroundColor3 = Color3.new(1, 1, 1);
			BorderColor3 = Color3.new(0, 0, 0);
			Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
			Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
			Visible = false;
			ZIndex = 15;
			Parent = ScreenGui,
		});

		DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
			PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
		end)

		local PickerFrameInner = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 16;
			Parent = PickerFrameOuter;
		});

		local Highlight = Library:Create('Frame', {
			BackgroundColor3 = Library.AccentColor;
			BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 0, 2);
			ZIndex = 17;
			Parent = PickerFrameInner;
		});

		local SatVibMapOuter = Library:Create('Frame', {
			BorderColor3 = Color3.new(0, 0, 0);
			Position = UDim2.new(0, 4, 0, 25);
			Size = UDim2.new(0, 200, 0, 200);
			ZIndex = 17;
			Parent = PickerFrameInner;
		});

		local SatVibMapInner = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 18;
			Parent = SatVibMapOuter;
		});

		local SatVibMap = Library:Create('ImageLabel', {
			BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 18;
			Image = 'rbxassetid://4155801252';
			Parent = SatVibMapInner;
		});

		local CursorOuter = Library:Create('ImageLabel', {
			AnchorPoint = Vector2.new(0.5, 0.5);
			Size = UDim2.new(0, 6, 0, 6);
			BackgroundTransparency = 1;
			Image = 'http://www.roblox.com/asset/?id=9619665977';
			ImageColor3 = Color3.new(0, 0, 0);
			ZIndex = 19;
			Parent = SatVibMap;
		});

		local CursorInner = Library:Create('ImageLabel', {
			Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
			Position = UDim2.new(0, 1, 0, 1);
			BackgroundTransparency = 1;
			Image = 'http://www.roblox.com/asset/?id=9619665977';
			ZIndex = 20;
			Parent = CursorOuter;
		})

		local HueSelectorOuter = Library:Create('Frame', {
			BorderColor3 = Color3.new(0, 0, 0);
			Position = UDim2.new(0, 208, 0, 25);
			Size = UDim2.new(0, 15, 0, 200);
			ZIndex = 17;
			Parent = PickerFrameInner;
		});

		local HueSelectorInner = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(1, 1, 1);
			BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 18;
			Parent = HueSelectorOuter;
		});

		local HueCursor = Library:Create('Frame', { 
			BackgroundColor3 = Color3.new(1, 1, 1);
			AnchorPoint = Vector2.new(0, 0.5);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(1, 0, 0, 1);
			ZIndex = 18;
			Parent = HueSelectorInner;
		});

		local HueBoxOuter = Library:Create('Frame', {
			BorderColor3 = Color3.new(0, 0, 0);
			Position = UDim2.fromOffset(4, 228),
			Size = UDim2.new(0.5, -6, 0, 20),
			ZIndex = 18,
			Parent = PickerFrameInner;
		});

		local HueBoxInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 18,
			Parent = HueBoxOuter;
		});

		Library:Create('UIGradient', {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
			});
			Rotation = 90;
			Parent = HueBoxInner;
		});

		local HueBox = Library:Create('TextBox', {
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 5, 0, 0);
			Size = UDim2.new(1, -5, 1, 0);
			Font = Library.Font;
			PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
			PlaceholderText = 'Hex color',
			Text = '#FFFFFF',
			TextColor3 = Library.FontColor;
			TextSize = 14;
			TextStrokeTransparency = 0;
			TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 20,
			Parent = HueBoxInner;
		});

		Library:ApplyTextStroke(HueBox);

		local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
			Position = UDim2.new(0.5, 2, 0, 228),
			Size = UDim2.new(0.5, -6, 0, 20),
			Parent = PickerFrameInner
		});

		local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
			Text = '255, 255, 255',
			PlaceholderText = 'RGB color',
			TextColor3 = Library.FontColor
		});

		local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor;

		if Info.Transparency then 
			TransparencyBoxOuter = Library:Create('Frame', {
				BorderColor3 = Color3.new(0, 0, 0);
				Position = UDim2.fromOffset(4, 251);
				Size = UDim2.new(1, -8, 0, 15);
				ZIndex = 19;
				Parent = PickerFrameInner;
			});

			TransparencyBoxInner = Library:Create('Frame', {
				BackgroundColor3 = ColorPicker.Value;
				BorderColor3 = Library.OutlineColor;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 1, 0);
				ZIndex = 19;
				Parent = TransparencyBoxOuter;
			});

			Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });

			Library:Create('ImageLabel', {
				BackgroundTransparency = 1;
				Size = UDim2.new(1, 0, 1, 0);
				Image = 'http://www.roblox.com/asset/?id=12978095818';
				ZIndex = 20;
				Parent = TransparencyBoxInner;
			});

			TransparencyCursor = Library:Create('Frame', { 
				BackgroundColor3 = Color3.new(1, 1, 1);
				AnchorPoint = Vector2.new(0.5, 0);
				BorderColor3 = Color3.new(0, 0, 0);
				Size = UDim2.new(0, 1, 1, 0);
				ZIndex = 21;
				Parent = TransparencyBoxInner;
			});
		end;

		local DisplayLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 0, 14);
			Position = UDim2.fromOffset(5, 5);
			TextXAlignment = Enum.TextXAlignment.Left;
			TextSize = 14;
			Text = ColorPicker.Title,
			TextWrapped = false;
			ZIndex = 16;
			Parent = PickerFrameInner;
		});

		local ContextMenu = {}
		do
			ContextMenu.Options = {}
			ContextMenu.Container = Library:Create('Frame', {
				BorderColor3 = Color3.new(),
				ZIndex = 14,

				Visible = false,
				Parent = ScreenGui
			})

			ContextMenu.Inner = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Library.OutlineColor;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.fromScale(1, 1);
				ZIndex = 15;
				Parent = ContextMenu.Container;
			});

			Library:Create('UIListLayout', {
				Name = 'Layout',
				FillDirection = Enum.FillDirection.Vertical;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Parent = ContextMenu.Inner;
			});

			Library:Create('UIPadding', {
				Name = 'Padding',
				PaddingLeft = UDim.new(0, 4),
				Parent = ContextMenu.Inner,
			});

			local function updateMenuPosition()
				ContextMenu.Container.Position = UDim2.fromOffset(
					(DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
					DisplayFrame.AbsolutePosition.Y + 1
				)
			end

			local function updateMenuSize()
				local menuWidth = 60
				for i, label in next, ContextMenu.Inner:GetChildren() do
					if label:IsA('TextLabel') then
						menuWidth = math.max(menuWidth, label.TextBounds.X)
					end
				end

				ContextMenu.Container.Size = UDim2.fromOffset(
					menuWidth + 8,
					ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
				)
			end

			DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
			ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)

			task.spawn(updateMenuPosition)
			task.spawn(updateMenuSize)

			Library:AddToRegistry(ContextMenu.Inner, {
				BackgroundColor3 = 'BackgroundColor';
				BorderColor3 = 'OutlineColor';
			});

			function ContextMenu:Show()
				if Library.IsMobile then
					Library.CanDrag = false;
				end;

				self.Container.Visible = true;
			end

			function ContextMenu:Hide()
				if Library.IsMobile then
					Library.CanDrag = true;
				end;

				self.Container.Visible = false;
			end

			function ContextMenu:AddOption(Str, Callback)
				if type(Callback) ~= 'function' then
					Callback = function() end
				end

				local Button = Library:CreateLabel({
					Active = false;
					Size = UDim2.new(1, 0, 0, 15);
					TextSize = 13;
					Text = Str;
					ZIndex = 16;
					Parent = self.Inner;
					TextXAlignment = Enum.TextXAlignment.Left,
				});

				Library:OnHighlight(Button, Button, 
					{ TextColor3 = 'AccentColor' },
					{ TextColor3 = 'FontColor' }
				);

				Button.InputBegan:Connect(function(Input)
					if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end

					self:Hide()
					Callback()
				end)
			end

			ContextMenu:AddOption('Copy color', function()
				Library.ColorClipboard = ColorPicker.Value
				Library:Notify('Copied color!', 2)
			end)

			ContextMenu:AddOption('Paste color', function()
				if not Library.ColorClipboard then
					return Library:Notify('You have not copied a color!', 2)
				end
				ColorPicker:SetValueRGB(Library.ColorClipboard)
				Library:AttemptSave()
			end)

			ContextMenu:AddOption('Copy HEX', function()
				pcall(setclipboard, ColorPicker.Value:ToHex())
				Library:Notify('Copied hex code to clipboard!', 2)
			end)

			ContextMenu:AddOption('Copy RGB', function()
				pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '))
				Library:Notify('Copied RGB values to clipboard!', 2)
			end)

		end

		Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
		Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });
		Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });

		Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
		Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
		Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor', });
		Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor', });

		local SequenceTable = {};

		for Hue = 0, 1, 0.1 do
			table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
		end;

		local HueSelectorGradient = Library:Create('UIGradient', {
			Color = ColorSequence.new(SequenceTable);
			Rotation = 90;
			Parent = HueSelectorInner;
		});

		HueBox.FocusLost:Connect(function(enter)
			if enter then
				local success, result = pcall(Color3.fromHex, HueBox.Text)
				if success and typeof(result) == 'Color3' then
					ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
				end
			end

			ColorPicker:Display()
		end)

		RgbBox.FocusLost:Connect(function(enter)
			if enter then
				local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
				if r and g and b then
					ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
				end
			end

			ColorPicker:Display()
		end)

		function ColorPicker:Display()
			ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
			SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

			Library:Create(DisplayFrame, {
				BackgroundColor3 = ColorPicker.Value;
				BackgroundTransparency = ColorPicker.Transparency;
				BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
			});

			if TransparencyBoxInner then
				TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value;
				TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0);
			end;

			CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
			HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0);

			HueBox.Text = '#' .. ColorPicker.Value:ToHex()
			RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

			Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
			Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value);
		end;

		function ColorPicker:OnChanged(Func)
			local Connection = AddListener(ColorPicker, 'Changed', Func);
			Func(ColorPicker.Value);
			return Connection;
		end;

		if ParentObj.Addons then
			table.insert(ParentObj.Addons, ColorPicker)
		end

		function ColorPicker:Show()
			for Frame, Val in next, Library.OpenedFrames do
				if Frame.Name == 'Color' then
					Frame.Visible = false;
					Library.OpenedFrames[Frame] = nil;
				end;
			end;

			PickerFrameOuter.Visible = true;
			Library.OpenedFrames[PickerFrameOuter] = true;
		end;

		function ColorPicker:Hide()
			PickerFrameOuter.Visible = false;
			Library.OpenedFrames[PickerFrameOuter] = nil;
		end;

		function ColorPicker:SetValue(HSV, Transparency)
			local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);

			ColorPicker.Transparency = Transparency or 0;
			ColorPicker:SetHSVFromRGB(Color);
			ColorPicker:Display();
		end;

		function ColorPicker:SetValueRGB(Color, Transparency)
			ColorPicker.Transparency = Transparency or 0;
			ColorPicker:SetHSVFromRGB(Color);
			ColorPicker:Display();
		end;

		SatVibMap.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1 or Enum.UserInputType.Touch) do
					local MinX = SatVibMap.AbsolutePosition.X;
					local MaxX = MinX + SatVibMap.AbsoluteSize.X;
					local MouseX = math.clamp(Mouse.X, MinX, MaxX);

					local MinY = SatVibMap.AbsolutePosition.Y;
					local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
					local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

					ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
					ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
					ColorPicker:Display();

					RenderStepped:Wait();
				end;

				Library:AttemptSave();
			end;
		end);

		HueSelectorInner.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1 or Enum.UserInputType.Touch) do
					local MinY = HueSelectorInner.AbsolutePosition.Y;
					local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
					local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

					ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
					ColorPicker:Display();

					RenderStepped:Wait();
				end;

				Library:AttemptSave();
			end;
		end);

		DisplayFrame.InputBegan:Connect(function(Input)
			if Library:MouseIsOverOpenedFrame() then
				return;
			end;

			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if PickerFrameOuter.Visible then
					ColorPicker:Hide()
				else
					ContextMenu:Hide()
					ColorPicker:Show()
				end;
			elseif Input.UserInputType == Enum.UserInputType.Touch then
				local Start = Input.Position;

				task.delay(0.45, function()
					if Input.UserInputState == Enum.UserInputState.End or Input.UserInputState == Enum.UserInputState.Cancel then
						return;
					end;

					if (Input.Position - Start).Magnitude > 10 then
						return;
					end;

					Library.CancelPendingTap();
					ColorPicker:Hide();
					ContextMenu:Show();
				end);

				TrackTap(Input, DisplayFrame:FindFirstAncestorWhichIsA('ScrollingFrame'), function()
					if PickerFrameOuter.Visible then
						ColorPicker:Hide()
					else
						ContextMenu:Hide()
						ColorPicker:Show()
					end;
				end);
			elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
				ContextMenu:Show()
				ColorPicker:Hide()
			end
		end);

		if TransparencyBoxInner then
			TransparencyBoxInner.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1 or Enum.UserInputType.Touch) do
						local MinX = TransparencyBoxInner.AbsolutePosition.X;
						local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X;
						local MouseX = math.clamp(Mouse.X, MinX, MaxX);

						ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX));

						ColorPicker:Display();

						RenderStepped:Wait();
					end;

					Library:AttemptSave();
				end;
			end);
		end;

		Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;

				if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
					or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

					ColorPicker:Hide();
				end;

				if not Library:MouseIsOverFrame(ContextMenu.Container, Input) then
					ContextMenu:Hide()
				end
			end;

			if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
				if not Library:MouseIsOverFrame(ContextMenu.Container, Input) and not Library:MouseIsOverFrame(DisplayFrame, Input) then
					ContextMenu:Hide()
				end
			end
		end))

		ColorPicker:Display();
		ColorPicker.DisplayFrame = DisplayFrame

		Options[Idx] = ColorPicker;

		return self;
	end;

	function Funcs:AddKeyPicker(Idx, Info)
		local ParentObj = self;
		local ToggleLabel = self.TextLabel;
		local Container = self.Container;

		assert(Info.Default, 'AddKeyPicker: Missing default value.');

		local KeyPicker = {
			Value = Info.Default;
			Toggled = false;
			Mode = Info.Mode or 'Toggle'; 
			Type = 'KeyPicker';
			Callback = Info.Callback or function(Value) end;
			ChangedCallback = Info.ChangedCallback or function(New) end;
			SyncToggleState = Info.SyncToggleState or false;
		};

		if KeyPicker.SyncToggleState then
			Info.Modes = { 'Toggle' }
			Info.Mode = 'Toggle'
		end

		local PickOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(0, 28, 0, 15);
			ZIndex = 6;
			Parent = ToggleLabel;
		});

		local PickInner = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 7;
			Parent = PickOuter;
		});

		Library:AddToRegistry(PickInner, {
			BackgroundColor3 = 'BackgroundColor';
			BorderColor3 = 'OutlineColor';
		});

		local DisplayLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 1, 0);
			TextSize = 13;
			Text = Info.Default;
			TextWrapped = true;
			ZIndex = 8;
			Parent = PickInner;
		});

		local ModeSelectOuter = Library:Create('Frame', {
			BorderColor3 = Color3.new(0, 0, 0);
			Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
			Size = UDim2.new(0, 60, 0, 45 + 2);
			Visible = false;
			ZIndex = 14;
			Parent = ScreenGui;
		});

		ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
			ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
		end);

		local ModeSelectInner = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 15;
			Parent = ModeSelectOuter;
		});

		Library:AddToRegistry(ModeSelectInner, {
			BackgroundColor3 = 'BackgroundColor';
			BorderColor3 = 'OutlineColor';
		});

		Library:Create('UIListLayout', {
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = ModeSelectInner;
		});

		local ContainerLabel = Library:CreateLabel({
			TextXAlignment = Enum.TextXAlignment.Left;
			Size = UDim2.new(1, 0, 0, 18);
			TextSize = 13;
			Visible = false;
			ZIndex = 110;
			Parent = Library.KeybindContainer;
		},  true);

		local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
		local ModeButtons = {};

		for Idx, Mode in next, Modes do
			local ModeButton = {};

			local Label = Library:CreateLabel({
				Active = false;
				Size = UDim2.new(1, 0, 0, 15);
				TextSize = 13;
				Text = Mode;
				ZIndex = 16;
				Parent = ModeSelectInner;
			});

			function ModeButton:Select()
				for _, Button in next, ModeButtons do
					Button:Deselect();
				end;

				KeyPicker.Mode = Mode;

				Label.TextColor3 = Library.AccentColor;
				Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

				ModeSelectOuter.Visible = false;
			end;

			function ModeButton:Deselect()
				KeyPicker.Mode = nil;

				Label.TextColor3 = Library.FontColor;
				Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
			end;

			Label.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					ModeButton:Select();
					Library:AttemptSave();
				end;
			end);

			if Mode == KeyPicker.Mode then
				ModeButton:Select();
			end;

			ModeButtons[Mode] = ModeButton;
		end;

		function KeyPicker:Update()
			if Info.NoUI then
				return;
			end;

			local State = KeyPicker:GetState();

			ContainerLabel.Text = string.format('[%s] %s (%s)', KeyPicker.Value, Info.Text, KeyPicker.Mode);

			ContainerLabel.Visible = true;
			ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;

			Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';

			local YSize = 0
			local XSize = 0

			for _, Label in next, Library.KeybindContainer:GetChildren() do
				if Label:IsA('TextLabel') and Label.Visible then
					YSize = YSize + 18;
					if (Label.TextBounds.X > XSize) then
						XSize = Label.TextBounds.X
					end
				end;
			end;

			Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10, 210), 0, YSize + 23)
		end;

		function KeyPicker:GetState()
			if KeyPicker.Mode == 'Always' then
				return true;
			elseif KeyPicker.Mode == 'Hold' then
				if KeyPicker.Value == 'None' then
					return false;
				end

				local Key = KeyPicker.Value;

				if Key == 'MB1' or Key == 'MB2' then
					return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
						or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
				else
					return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]);
				end;
			else
				return KeyPicker.Toggled;
			end;
		end;

		function KeyPicker:SetValue(Data)
			local Key, Mode = Data[1], Data[2];
			DisplayLabel.Text = Key;
			KeyPicker.Value = Key;
			if ModeButtons[Mode] then ModeButtons[Mode]:Select(); end
			KeyPicker:Update();
		end;

		function KeyPicker:OnClick(Callback)
			return AddListener(KeyPicker, 'Clicked', Callback)
		end

		function KeyPicker:OnChanged(Callback)
			local Connection = AddListener(KeyPicker, 'Changed', Callback)
			Callback(KeyPicker.Value)
			return Connection
		end

		if ParentObj.Addons then
			table.insert(ParentObj.Addons, KeyPicker)
		end

		function KeyPicker:DoClick()
			if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
				ParentObj:SetValue(not ParentObj.Value)
			end

			Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
			Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
		end

		local Picking = false;

		PickOuter.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				Picking = true;

				DisplayLabel.Text = '';

				local Break;
				local Text = '';

				task.spawn(function()
					while (not Break) do
						if Text == '...' then
							Text = '';
						end;

						Text = Text .. '.';
						DisplayLabel.Text = Text;

						task.wait(0.4);
					end;
				end);

				task.wait(0.2);

				local Event;
				Event = InputService.InputBegan:Connect(function(Input)
					local Key;

					if Input.UserInputType == Enum.UserInputType.Keyboard then
						Key = Input.KeyCode.Name;
					elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Key = 'MB1';
					elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
						Key = 'MB2';
					end;

					Break = true;
					Picking = false;

					DisplayLabel.Text = Key;
					KeyPicker.Value = Key;

					Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
					Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)

					Library:AttemptSave();

					Event:Disconnect();
				end);
			elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
				ModeSelectOuter.Visible = true;
			end;
		end);

		Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
			if KeyPicker.Value == "Unknown" then return end

			if (not Picking) and (not InputService:GetFocusedTextBox()) then
				if KeyPicker.Mode == 'Toggle' then
					local Key = KeyPicker.Value;

					if Key == 'MB1' or Key == 'MB2' then
						if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
						or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2 then
							KeyPicker.Toggled = not KeyPicker.Toggled
							KeyPicker:DoClick()
						end;
					elseif Input.UserInputType == Enum.UserInputType.Keyboard then
						if Input.KeyCode.Name == Key then
							KeyPicker.Toggled = not KeyPicker.Toggled;
							KeyPicker:DoClick()
						end;
					end;
				end;

				KeyPicker:Update();
			end;

			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;

				if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
					or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

					ModeSelectOuter.Visible = false;
				end;
			end;
		end))

		Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
			if (not Picking) then
				KeyPicker:Update();
			end;
		end))

		KeyPicker:Update();
		KeyPicker.DisplayFrame = PickOuter

		Options[Idx] = KeyPicker;

		return self;
	end;

	BaseAddons.__index = Funcs;
	BaseAddons.__namecall = function(Table, Key, ...)
		return Funcs[Key](...);
	end;
end;

local PICKER_ROW_HEIGHT = 34;

local MobilePicker = {
	Owner = nil;
	OnClose = nil;
	SearchText = '';
	Rows = {};
};

function MobilePicker:Build()
	if self.Window then
		return;
	end;

	local Overlay = Library:Create('TextButton', {
		AutoButtonColor = false;
		BackgroundColor3 = Color3.new(0, 0, 0);
		BackgroundTransparency = 0.45;
		BorderSizePixel = 0;
		Position = UDim2.fromOffset(0, -100);
		Size = UDim2.new(1, 0, 1, 100);
		Text = '';
		Visible = false;
		ZIndex = 400;
		Parent = ScreenGui;
	});

	local Window = Library:Create('Frame', {
		Active = true;
		AnchorPoint = Vector2.new(0.5, 0.5);
		BackgroundColor3 = Color3.new(0, 0, 0);
		BorderSizePixel = 0;
		Position = UDim2.fromScale(0.5, 0.5);
		Size = UDim2.fromOffset(320, 360);
		Visible = false;
		ZIndex = 401;
		Parent = ScreenGui;
	});

	local Inner = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.AccentColor;
		BorderMode = Enum.BorderMode.Inset;
		Position = UDim2.fromOffset(1, 1);
		Size = UDim2.new(1, -2, 1, -2);
		ZIndex = 402;
		Parent = Window;
	});

	Library:AddToRegistry(Inner, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'AccentColor';
	});

	local Title = Library:CreateLabel({
		Position = UDim2.fromOffset(8, 0);
		Size = UDim2.new(1, -48, 0, 30);
		Text = '';
		TextSize = 15;
		TextTruncate = Enum.TextTruncate.AtEnd;
		TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 403;
		Parent = Inner;
	});

	local CloseButton = Library:Create('TextButton', {
		AnchorPoint = Vector2.new(1, 0);
		AutoButtonColor = false;
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Library.OutlineColor;
		Font = Library.Font;
		Position = UDim2.new(1, -6, 0, 3);
		Size = UDim2.fromOffset(28, 24);
		Text = 'X';
		TextColor3 = Library.FontColor;
		TextSize = 15;
		ZIndex = 404;
		Parent = Inner;
	});

	Library:ApplyTextStroke(CloseButton);
	Library:AddToRegistry(CloseButton, {
		BackgroundColor3 = 'BackgroundColor';
		BorderColor3 = 'OutlineColor';
		TextColor3 = 'FontColor';
	});

	local SearchOuter = Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Library.OutlineColor;
		Position = UDim2.fromOffset(8, 32);
		Size = UDim2.new(1, -16, 0, 26);
		ZIndex = 403;
		Parent = Inner;
	});

	Library:AddToRegistry(SearchOuter, {
		BackgroundColor3 = 'BackgroundColor';
		BorderColor3 = 'OutlineColor';
	});

	local SearchBox = Library:Create('TextBox', {
		BackgroundTransparency = 1;
		ClearTextOnFocus = false;
		Font = Library.Font;
		PlaceholderColor3 = Color3.fromRGB(150, 150, 150);
		PlaceholderText = 'Search...';
		Position = UDim2.fromOffset(6, 0);
		Size = UDim2.new(1, -12, 1, 0);
		Text = '';
		TextColor3 = Library.FontColor;
		TextSize = 14;
		TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 404;
		Parent = SearchOuter;
	});

	Library:ApplyTextStroke(SearchBox);
	Library:AddToRegistry(SearchBox, {
		TextColor3 = 'FontColor';
	});

	local ListOuter = Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Library.OutlineColor;
		Position = UDim2.fromOffset(8, 64);
		Size = UDim2.new(1, -16, 1, -72);
		ZIndex = 403;
		Parent = Inner;
	});

	Library:AddToRegistry(ListOuter, {
		BackgroundColor3 = 'BackgroundColor';
		BorderColor3 = 'OutlineColor';
	});

	local Scroller = Library:Create('ScrollingFrame', {
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		CanvasSize = UDim2.new(0, 0, 0, 0);
		ScrollingDirection = Enum.ScrollingDirection.Y;
		Size = UDim2.new(1, 0, 1, 0);
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar;
		TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
		BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
		ScrollBarThickness = 12;
		ScrollBarImageColor3 = Library.AccentColor;
		ZIndex = 404;
		Parent = ListOuter;
	});

	Library:AddToRegistry(Scroller, {
		ScrollBarImageColor3 = 'AccentColor';
	});

	Library:Create('UIListLayout', {
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = Scroller;
	});

	local Empty = Library:CreateLabel({
		Size = UDim2.new(1, 0, 0, 30);
		Text = 'No results';
		TextSize = 14;
		Visible = false;
		ZIndex = 405;
		Parent = ListOuter;
	});

	local DoneButton = Library:Create('TextButton', {
		AnchorPoint = Vector2.new(0, 1);
		AutoButtonColor = false;
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Library.AccentColor;
		Font = Library.Font;
		Position = UDim2.new(0, 8, 1, -8);
		Size = UDim2.new(1, -16, 0, 30);
		Text = 'Done';
		TextColor3 = Library.FontColor;
		TextSize = 15;
		Visible = false;
		ZIndex = 404;
		Parent = Inner;
	});

	Library:ApplyTextStroke(DoneButton);
	Library:AddToRegistry(DoneButton, {
		BackgroundColor3 = 'BackgroundColor';
		BorderColor3 = 'AccentColor';
		TextColor3 = 'FontColor';
	});

	local function CreateActionButton(Text, Index)
		local Button = Library:Create('TextButton', {
			AnchorPoint = Vector2.new(0, 1);
			AutoButtonColor = false;
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			Font = Library.Font;
			Position = UDim2.new(Index / 3, 8 + Index * (8 - 32 / 3), 1, -8);
			Size = UDim2.new(1 / 3, -32 / 3, 0, 30);
			Text = Text;
			TextColor3 = Library.FontColor;
			TextSize = 15;
			Visible = false;
			ZIndex = 404;
			Parent = Inner;
		});

		Library:ApplyTextStroke(Button);
		Library:AddToRegistry(Button, {
			BackgroundColor3 = 'BackgroundColor';
			BorderColor3 = 'OutlineColor';
			TextColor3 = 'FontColor';
		});

		return Button;
	end;

	local AllButton = CreateActionButton('All', 0);
	local ClearButton = CreateActionButton('Clear', 1);

	self.Overlay = Overlay;
	self.Window = Window;
	self.Title = Title;
	self.SearchBox = SearchBox;
	self.ListOuter = ListOuter;
	self.Scroller = Scroller;
	self.Empty = Empty;
	self.DoneButton = DoneButton;
	self.AllButton = AllButton;
	self.ClearButton = ClearButton;

	local function IsOutsideWindow(Position)
		local WindowPosition, WindowSize = Window.AbsolutePosition, Window.AbsoluteSize;

		return Position.X < WindowPosition.X or Position.X > WindowPosition.X + WindowSize.X
			or Position.Y < WindowPosition.Y or Position.Y > WindowPosition.Y + WindowSize.Y;
	end;

	Overlay.InputBegan:Connect(function(Input)
		if not IsOutsideWindow(Input.Position) then
			return;
		end;

		if Input.UserInputType == Enum.UserInputType.Touch then
			TrackTap(Input, nil, function()
				MobilePicker:Close();
			end);
		elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
			MobilePicker:Close();
		end;
	end);

	CloseButton.MouseButton1Click:Connect(function()
		MobilePicker:Close();
	end);

	DoneButton.MouseButton1Click:Connect(function()
		MobilePicker:Close();
	end);

	local function ConfirmOnSecondPress(Button, Text, Bool)
		local Armed = 0;

		local function Reset()
			Armed = 0;
			Button.Text = Text;
			Button.TextColor3 = Library.FontColor;
			Library.RegistryMap[Button].Properties.TextColor3 = 'FontColor';
		end;

		Button.MouseButton1Click:Connect(function()
			if os.clock() - Armed < 1 then
				Reset();
				MobilePicker:SetShown(Bool);
				return;
			end;

			local Stamp = os.clock();
			Armed = Stamp;
			Button.Text = 'Sure?';
			Button.TextColor3 = Library.AccentColor;
			Library.RegistryMap[Button].Properties.TextColor3 = 'AccentColor';

			task.delay(1, function()
				if Armed == Stamp then
					Reset();
				end;
			end);
		end);
	end;

	ConfirmOnSecondPress(AllButton, 'All', true);
	ConfirmOnSecondPress(ClearButton, 'Clear', false);

	SearchBox:GetPropertyChangedSignal('Text'):Connect(function()
		if not MobilePicker.Owner or SearchBox.Text == MobilePicker.SearchText then
			return;
		end;

		MobilePicker.SearchText = SearchBox.Text;
		MobilePicker:Refresh();
		Scroller.CanvasPosition = Vector2.zero;
	end);

	ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
		if MobilePicker.Owner then
			MobilePicker:Layout();
		end;
	end);
end;

function MobilePicker:Layout()
	local Screen = ScreenGui.AbsoluteSize;
	local Width = math.clamp(Screen.X - 40, 220, 360);
	local Height = math.clamp(Screen.Y - 40, 200, 440);

	self.Window.Size = UDim2.fromOffset(Width, Height);
	self.ListOuter.Size = UDim2.new(1, -16, 1, -(64 + (self.DoneButton.Visible and 46 or 8)));

	local Multi = self.Owner ~= nil and self.Owner.Multi == true;

	self.AllButton.Visible = Multi;
	self.ClearButton.Visible = Multi;

	if Multi then
		self.DoneButton.Position = UDim2.new(2 / 3, 8 + 2 * (8 - 32 / 3), 1, -8);
		self.DoneButton.Size = UDim2.new(1 / 3, -32 / 3, 0, 30);
	else
		self.DoneButton.Position = UDim2.new(0, 8, 1, -8);
		self.DoneButton.Size = UDim2.new(1, -16, 0, 30);
	end;
end;

function MobilePicker:SetShown(Bool)
	local Owner = self.Owner;

	if not Owner or not Owner.Multi or not self.ShownValues then
		return;
	end;

	Owner:SetMany(self.ShownValues, Bool);

	if self.Owner == Owner then
		self:UpdateRows();
	end;
end;

function MobilePicker:ClearRows()
	for _, Row in next, self.Rows do
		Row.Frame:Destroy();
	end;

	table.clear(self.Rows);
end;

function MobilePicker:UpdateRows()
	local Owner = self.Owner;

	for _, Row in next, self.Rows do
		local Selected = Owner ~= nil and Owner:IsValueSelected(Row.Value);

		Row.Label.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
		Row.Frame.BorderColor3 = Selected and Library.AccentColor or Library.OutlineColor;

		Library.RegistryMap[Row.Label].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
		Library.RegistryMap[Row.Frame].Properties.BorderColor3 = Selected and 'AccentColor' or 'OutlineColor';
	end;
end;

function MobilePicker:Refresh()
	local Owner = self.Owner;

	if not Owner then
		return;
	end;

	self:ClearRows();

	local Values = self.SearchText ~= '' and Library:FuzzyFilter(self.SearchText, Owner.Values) or Owner.Values;
	local Count = 0;

	self.ShownValues = Values;

	for _, Value in next, Values do
		Count = Count + 1;

		local Frame = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			LayoutOrder = Count;
			Size = UDim2.new(1, 0, 0, PICKER_ROW_HEIGHT);
			ZIndex = 405;
			Parent = self.Scroller;
		});

		Library:AddToRegistry(Frame, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		local Label = Library:CreateLabel({
			Position = UDim2.fromOffset(10, 0);
			Size = UDim2.new(1, -14, 1, 0);
			Text = tostring(Value);
			TextSize = 15;
			TextTruncate = Enum.TextTruncate.AtEnd;
			TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 406;
			Parent = Frame;
		});

		Frame.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.Touch then
				TrackTap(Input, MobilePicker.Scroller, function()
					MobilePicker:Choose(Value);
				end);
			elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
				MobilePicker:Choose(Value);
			end;
		end);

		table.insert(self.Rows, { Frame = Frame; Label = Label; Value = Value });
	end;

	self.Scroller.CanvasSize = UDim2.fromOffset(0, Count * PICKER_ROW_HEIGHT);
	self.Empty.Visible = Count == 0;
	self:UpdateRows();
end;

function MobilePicker:ScrollToSelected()
	local Owner = self.Owner;

	if not Owner then
		return;
	end;

	for Index, Row in next, self.Rows do
		if Owner:IsValueSelected(Row.Value) then
			local Y = (Index - 1) * PICKER_ROW_HEIGHT - (self.Scroller.AbsoluteSize.Y - PICKER_ROW_HEIGHT) / 2;
			self.Scroller.CanvasPosition = Vector2.new(0, math.max(0, Y));
			return;
		end;
	end;
end;

function MobilePicker:Choose(Value)
	local Owner = self.Owner;

	if not Owner then
		return;
	end;

	Owner:SelectValue(Value);

	if self.Owner == Owner then
		self:UpdateRows();
	end;
end;

function MobilePicker:Open(Owner, TitleText, OnClose)
	self:Build();

	if self.Owner and self.Owner ~= Owner then
		self:Close();
	end;

	self.Owner = Owner;
	self.OnClose = OnClose;
	self.SearchText = '';
	self.SearchBox.Text = '';
	self.Title.Text = TitleText;
	self.DoneButton.Visible = true;

	self:Layout();

	self.Overlay.Visible = true;
	self.Window.Visible = true;
	Library.OpenedFrames[self.Window] = true;
	Library.PickerOpen = true;
	Library.CanDrag = false;

	self:Refresh();
	self.Scroller.CanvasPosition = Vector2.zero;

	task.defer(function()
		MobilePicker:ScrollToSelected();
	end);
end;

function MobilePicker:Close()
	if not self.Owner then
		return;
	end;

	local OnClose = self.OnClose;

	self.Owner = nil;
	self.OnClose = nil;

	if self.SearchBox:IsFocused() then
		self.SearchBox:ReleaseFocus();
	end;

	self.Overlay.Visible = false;
	self.Window.Visible = false;
	Library.OpenedFrames[self.Window] = nil;
	Library.PickerOpen = false;
	Library.CanDrag = true;

	self:ClearRows();

	if OnClose then
		OnClose();
	end;
end;

local BaseGroupbox = {};

do
	local Funcs = {};

	function Funcs:AddBlank(Size)
		local Groupbox = self;
		local Container = Groupbox.Container;

		Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 0, Size);
			ZIndex = 1;
			Parent = Container;
		});
	end;

	function Funcs:AddLabel(Text, DoesWrap)
		local Label = {};

		local Groupbox = self;
		local Container = Groupbox.Container;

		local TextLabel = Library:CreateLabel({
			Size = UDim2.new(1, -4, 0, 15);
			TextSize = 14;
			Text = Text;
			TextWrapped = DoesWrap or false,
			TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 5;
			Parent = Container;
		});

		if DoesWrap then
			local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
			TextLabel.Size = UDim2.new(1, -4, 0, Y)
		else
			Library:Create('UIListLayout', {
				Padding = UDim.new(0, 4);
				FillDirection = Enum.FillDirection.Horizontal;
				HorizontalAlignment = Enum.HorizontalAlignment.Right;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Parent = TextLabel;
			});
		end

		Label.TextLabel = TextLabel;
		Label.Container = Container;

		function Label:SetText(Text)
			Elevate();
			TextLabel.Text = Text

			if DoesWrap then
				local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
				TextLabel.Size = UDim2.new(1, -4, 0, Y)
			end

			Groupbox:Resize();
		end

		if (not DoesWrap) then
			setmetatable(Label, BaseAddons);
		end

		Groupbox:AddBlank(5);
		Groupbox:Resize();

		return Label;
	end;

	function Funcs:AddButton(...)

		local Button = {};
		local function ProcessButtonParams(Class, Obj, ...)
			local Props = select(1, ...)
			if type(Props) == 'table' then
				Obj.Text = Props.Text
				Obj.Func = Props.Func
				Obj.DoubleClick = Props.DoubleClick
				Obj.Tooltip = Props.Tooltip
			else
				Obj.Text = select(1, ...)
				Obj.Func = select(2, ...)
			end

			assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
		end

		ProcessButtonParams('Button', Button, ...)

		local Groupbox = self;
		local Container = Groupbox.Container;

		local function CreateBaseButton(Button)
			local Outer = Library:Create('Frame', {
				BackgroundColor3 = Color3.new(0, 0, 0);
				BorderColor3 = Color3.new(0, 0, 0);
				Size = UDim2.new(1, -4, 0, Library.ElementHeight);
				ZIndex = 5;
			});

			local Inner = Library:Create('Frame', {
				BackgroundColor3 = Library.MainColor;
				BorderColor3 = Library.OutlineColor;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 1, 0);
				ZIndex = 6;
				Parent = Outer;
			});

			local Label = Library:CreateLabel({
				Size = UDim2.new(1, 0, 1, 0);
				TextSize = 14;
				Text = Button.Text;
				ZIndex = 6;
				Parent = Inner;
			});

			Library:Create('UIGradient', {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
				});
				Rotation = 90;
				Parent = Inner;
			});

			Library:AddToRegistry(Outer, {
				BorderColor3 = 'Black';
			});

			Library:AddToRegistry(Inner, {
				BackgroundColor3 = 'MainColor';
				BorderColor3 = 'OutlineColor';
			});

			Library:OnHighlight(Outer, Outer,
				{ BorderColor3 = 'AccentColor' },
				{ BorderColor3 = 'Black' }
			);

			return Outer, Inner, Label
		end

		local function InitEvents(Button)
			local function WaitForEvent(event, timeout, validator)
				local bindable = Instance.new('BindableEvent')
				local connection = event:Once(function(...)

					if type(validator) == 'function' and validator(...) then
						bindable:Fire(true)
					else
						bindable:Fire(false)
					end
				end)
				task.delay(timeout, function()
					connection:disconnect()
					bindable:Fire(false)
				end)
				return bindable.Event:Wait()
			end

			local function ValidateClick(Input)
				if Library:MouseIsOverOpenedFrame(Input) then
					return false
				end

				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					return true
				elseif Input.UserInputType == Enum.UserInputType.Touch then
					return true
				else
					return false
				end
			end

			local function Press()
				if Button.Locked then return end

				if Button.DoubleClick then
					Library:RemoveFromRegistry(Button.Label)
					Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })

					Button.Label.TextColor3 = Library.AccentColor
					Button.Label.Text = 'Are you sure?'
					Button.Locked = true

					local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

					Library:RemoveFromRegistry(Button.Label)
					Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })

					Button.Label.TextColor3 = Library.FontColor
					Button.Label.Text = Button.Text
					task.defer(rawset, Button, 'Locked', false)

					if clicked then
						Library:SafeCallback(Button.Func)
					end

					return
				end

				Library:SafeCallback(Button.Func);
			end

			Button.Outer.InputBegan:Connect(function(Input)
				if not ValidateClick(Input) then return end

				if Input.UserInputType == Enum.UserInputType.Touch then
					TrackTap(Input, Button.Outer:FindFirstAncestorWhichIsA('ScrollingFrame'), function()
						task.spawn(Press)
					end)
				else
					Press()
				end
			end)
		end

		Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
		Button.Outer.Parent = Container

		InitEvents(Button)

		function Button:AddTooltip(tooltip)
			if type(tooltip) == 'string' then
				Library:AddToolTip(tooltip, self.Outer)
			end
			return self
		end

		function Button:AddButton(...)
			local SubButton = {}

			ProcessButtonParams('SubButton', SubButton, ...)

			self.Outer.Size = UDim2.new(0.5, -2, 0, Library.ElementHeight)

			SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

			SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
			SubButton.Outer.Size = UDim2.new(1, -3, 1, 0)
			SubButton.Outer.Parent = self.Outer

			function SubButton:AddTooltip(tooltip)
				if type(tooltip) == 'string' then
					Library:AddToolTip(tooltip, self.Outer)
				end
				return SubButton
			end

			if type(SubButton.Tooltip) == 'string' then
				SubButton:AddTooltip(SubButton.Tooltip)
			end

			InitEvents(SubButton)
			return SubButton
		end

		if type(Button.Tooltip) == 'string' then
			Button:AddTooltip(Button.Tooltip)
		end

		Groupbox:AddBlank(5);
		Groupbox:Resize();

		return Button;
	end;

	function Funcs:AddDivider()
		local Groupbox = self;
		local Container = self.Container

		local Divider = {
			Type = 'Divider',
		}

		Groupbox:AddBlank(2);
		local DividerOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(1, -4, 0, 5);
			ZIndex = 5;
			Parent = Container;
		});

		local DividerInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Parent = DividerOuter;
		});

		Library:AddToRegistry(DividerOuter, {
			BorderColor3 = 'Black';
		});

		Library:AddToRegistry(DividerInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		Groupbox:AddBlank(9);
		Groupbox:Resize();
	end

	function Funcs:AddInput(Idx, Info)
		assert(Info.Text, 'AddInput: Missing `Text` string.')

		local Textbox = {
			Value = Info.Default or '';
			Numeric = Info.Numeric or false;
			Finished = Info.Finished or false;
			Type = 'Input';
			Callback = Info.Callback or function(Value) end;
		};

		local Groupbox = self;
		local Container = Groupbox.Container;

		local InputLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 0, 15);
			TextSize = 14;
			Text = Info.Text;
			TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 5;
			Parent = Container;
		});

		Groupbox:AddBlank(1);

		local TextBoxOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(1, -4, 0, Library.ElementHeight);
			ZIndex = 5;
			Parent = Container;
		});

		local TextBoxInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Parent = TextBoxOuter;
		});

		Library:AddToRegistry(TextBoxInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		Library:OnHighlight(TextBoxOuter, TextBoxOuter,
			{ BorderColor3 = 'AccentColor' },
			{ BorderColor3 = 'Black' }
		);

		if type(Info.Tooltip) == 'string' then
			Library:AddToolTip(Info.Tooltip, TextBoxOuter)
		end

		Library:Create('UIGradient', {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
			});
			Rotation = 90;
			Parent = TextBoxInner;
		});

		local Container = Library:Create('Frame', {
			BackgroundTransparency = 1;
			ClipsDescendants = true;

			Position = UDim2.new(0, 5, 0, 0);
			Size = UDim2.new(1, -5, 1, 0);

			ZIndex = 7;
			Parent = TextBoxInner;
		})

		local Box = Library:Create('TextBox', {
			BackgroundTransparency = 1;

			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromScale(5, 1),

			Font = Library.Font;
			PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
			PlaceholderText = Info.Placeholder or '';

			Text = Info.Default or '';
			TextColor3 = Library.FontColor;
			TextSize = 14;
			TextStrokeTransparency = 0;
			TextXAlignment = Enum.TextXAlignment.Left;

			ClearTextOnFocus = (typeof(Info.ClearTextOnFocus) ~= "boolean" and true or Info.ClearTextOnFocus);

			ZIndex = 7;
			Parent = Container;
		});

		Library:ApplyTextStroke(Box);

		function Textbox:SetValue(Text)
			if Info.MaxLength and #Text > Info.MaxLength then
				Text = Text:sub(1, Info.MaxLength);
			end;

			if Textbox.Numeric then
				if (not tonumber(Text)) and Text:len() > 0 then
					Text = Textbox.Value
				end
			end

			Textbox.Value = Text;
			Box.Text = Text;

			Library:SafeCallback(Textbox.Callback, Textbox.Value);
			Library:SafeCallback(Textbox.Changed, Textbox.Value);
		end;

		if Textbox.Finished then
			Box.FocusLost:Connect(function(enter)
				if not enter then return end

				Textbox:SetValue(Box.Text);
				Library:AttemptSave();
			end)
		else
			Box:GetPropertyChangedSignal('Text'):Connect(function()
				Textbox:SetValue(Box.Text);
				Library:AttemptSave();
			end);
		end

		local function Update()
			local PADDING = 2
			local reveal = Container.AbsoluteSize.X

			if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then

				Box.Position = UDim2.new(0, PADDING, 0, 0)
			else

				local cursor = Box.CursorPosition
				if cursor ~= -1 then

					local subtext = string.sub(Box.Text, 1, cursor-1)
					local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

					local currentCursorPos = Box.Position.X.Offset + width

					if currentCursorPos < PADDING then
						Box.Position = UDim2.fromOffset(PADDING-width, 0)
					elseif currentCursorPos > reveal - PADDING - 1 then
						Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
					end
				end
			end
		end

		task.spawn(Update)

		Box:GetPropertyChangedSignal('Text'):Connect(Update)
		Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
		Box.FocusLost:Connect(Update)
		Box.Focused:Connect(Update)

		Library:AddToRegistry(Box, {
			TextColor3 = 'FontColor';
		});

		function Textbox:OnChanged(Func)
			local Connection = AddListener(Textbox, 'Changed', Func);
			Func(Textbox.Value);
			return Connection;
		end;

		Groupbox:AddBlank(5);
		Groupbox:Resize();

		Options[Idx] = Textbox;

		return Textbox;
	end;

	function Funcs:AddToggle(Idx, Info)
		assert(Info.Text, 'AddInput: Missing `Text` string.')

		local Toggle = {
			Value = Info.Default or false;
			Type = 'Toggle';

			Callback = Info.Callback or function(Value) end;
			Addons = {},
			Risky = Info.Risky,
		};

		local Groupbox = self;
		local Container = Groupbox.Container;

		local ToggleOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(0, Library.ToggleSize, 0, Library.ToggleSize);
			ZIndex = 5;
			Parent = Container;
		});

		Library:AddToRegistry(ToggleOuter, {
			BorderColor3 = 'Black';
		});

		local ToggleInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Parent = ToggleOuter;
		});

		Library:AddToRegistry(ToggleInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		local ToggleLabel = Library:CreateLabel({
			Size = UDim2.new(0, 216, 1, 0);
			Position = UDim2.new(1, 6, 0, -1);
			TextSize = 14;
			Text = Info.Text;
			TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 6;
			Parent = ToggleInner;
		});

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 4);
			FillDirection = Enum.FillDirection.Horizontal;
			HorizontalAlignment = Enum.HorizontalAlignment.Right;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = ToggleLabel;
		});

		local ToggleRegion = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(0, 170, 1, 0);
			ZIndex = 8;
			Parent = ToggleOuter;
		});

		Library:OnHighlight(ToggleRegion, ToggleOuter,
			{ BorderColor3 = 'AccentColor' },
			{ BorderColor3 = 'Black' },
			function()
				for _, Addon in next, Toggle.Addons do
					if Library:MouseIsOverFrame(Addon.DisplayFrame) then return false end
				end
				return true
			end
		);

		function Toggle:UpdateColors()
			Toggle:Display();
		end;

		if type(Info.Tooltip) == 'string' then
			Library:AddToolTip(Info.Tooltip, ToggleRegion)
		end

		function Toggle:Display()
			ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor;
			ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

			Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
			Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
		end;

		function Toggle:OnChanged(Func)
			local Connection = AddListener(Toggle, 'Changed', Func);
			Func(Toggle.Value);
			return Connection;
		end;

		function Toggle:SetValue(Bool)
			Elevate();
			Bool = (not not Bool);

			Toggle.Value = Bool;
			Toggle:Display();

			for _, Addon in next, Toggle.Addons do
				if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
					Addon.Toggled = Bool
					Addon:Update()
				end
			end

			Library:SafeCallback(Toggle.Callback, Toggle.Value);
			Library:SafeCallback(Toggle.Changed, Toggle.Value);
			Library:UpdateDependencyBoxes();
		end;

		ToggleRegion.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				for _, Addon in next, Toggle.Addons do
					if Library:MouseIsOverFrame(Addon.DisplayFrame) then return end
				end
				Toggle:SetValue(not Toggle.Value)
				Library:AttemptSave();
			elseif Input.UserInputType == Enum.UserInputType.Touch and not Library:MouseIsOverOpenedFrame(Input) then
				for _, Addon in next, Toggle.Addons do
					if Library:MouseIsOverFrame(Addon.DisplayFrame, Input) then return end
				end
				TrackTap(Input, ToggleRegion:FindFirstAncestorWhichIsA('ScrollingFrame'), function()
					Toggle:SetValue(not Toggle.Value)
					Library:AttemptSave();
				end);
			end;
		end);

		if Toggle.Risky then
			Library:RemoveFromRegistry(ToggleLabel)
			ToggleLabel.TextColor3 = Library.RiskColor
			Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
		end

		Toggle:Display();
		Groupbox:AddBlank(Info.BlankSize or (Library.IsMobile and 9 or 7));
		Groupbox:Resize();

		Toggle.TextLabel = ToggleLabel;
		Toggle.Container = Container;
		setmetatable(Toggle, BaseAddons);

		Toggles[Idx] = Toggle;

		Library:UpdateDependencyBoxes();

		return Toggle;
	end;

	function Funcs:AddSlider(Idx, Info)
		assert(Info.Default, 'AddSlider: Missing default value.');
		assert(Info.Text, 'AddSlider: Missing slider text.');
		assert(Info.Min, 'AddSlider: Missing minimum value.');
		assert(Info.Max, 'AddSlider: Missing maximum value.');
		assert(Info.Rounding, 'AddSlider: Missing rounding value.');

		local Slider = {
			Value = Info.Default;
			Min = Info.Min;
			Max = Info.Max;
			Rounding = Info.Rounding;
			MaxSize = 232;
			Type = 'Slider';
			Callback = Info.Callback or function(Value) end;
		};

		local Groupbox = self;
		local Container = Groupbox.Container;

		if not Info.Compact then
			Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 10);
				TextSize = 14;
				Text = Info.Text;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Bottom;
				ZIndex = 5;
				Parent = Container;
			});

			Groupbox:AddBlank(3);
		end

		local SliderOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(1, -4, 0, Library.ToggleSize);
			ZIndex = 5;
			Parent = Container;
		});

		SliderOuter:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
			Slider.MaxSize = SliderOuter.AbsoluteSize.X - 2;
		end);

		Library:AddToRegistry(SliderOuter, {
			BorderColor3 = 'Black';
		});

		local SliderInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Parent = SliderOuter;
		});

		Library:AddToRegistry(SliderInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		local Fill = Library:Create('Frame', {
			BackgroundColor3 = Library.AccentColor;
			BorderColor3 = Library.AccentColorDark;
			Size = UDim2.new(0, 0, 1, 0);
			ZIndex = 7;
			Parent = SliderInner;
		});

		Library:AddToRegistry(Fill, {
			BackgroundColor3 = 'AccentColor';
			BorderColor3 = 'AccentColorDark';
		});

		local HideBorderRight = Library:Create('Frame', {
			BackgroundColor3 = Library.AccentColor;
			BorderSizePixel = 0;
			Position = UDim2.new(1, 0, 0, 0);
			Size = UDim2.new(0, 1, 1, 0);
			ZIndex = 8;
			Parent = Fill;
		});

		Library:AddToRegistry(HideBorderRight, {
			BackgroundColor3 = 'AccentColor';
		});

		local DisplayLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 1, 0);
			TextSize = 14;
			Text = 'Infinite';
			ZIndex = 9;
			Parent = SliderInner;
		});

		Library:OnHighlight(SliderOuter, SliderOuter,
			{ BorderColor3 = 'AccentColor' },
			{ BorderColor3 = 'Black' }
		);

		if type(Info.Tooltip) == 'string' then
			Library:AddToolTip(Info.Tooltip, SliderOuter)
		end

		function Slider:UpdateColors()
			Fill.BackgroundColor3 = Library.AccentColor;
			Fill.BorderColor3 = Library.AccentColorDark;
		end;

		function Slider:Display()
			local Suffix = Info.Suffix or '';

			if Info.Compact then
				DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
			elseif Info.HideMax then
				DisplayLabel.Text = string.format('%s', Slider.Value .. Suffix)
			else
				DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix);
			end

			local X = Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, 1);
			Fill.Size = UDim2.new(X, 0, 1, 0);

			HideBorderRight.Visible = not (X == 1 or X == 0);
		end;

		function Slider:OnChanged(Func)
			local Connection = AddListener(Slider, 'Changed', Func);
			Func(Slider.Value);
			return Connection;
		end;

		local function Round(Value)
			if Slider.Rounding == 0 then
				return math.floor(Value);
			end;

			return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
		end;

		function Slider:GetValueFromXScale(X)
			return Round(Library:MapValue(X, 0, 1, Slider.Min, Slider.Max));
		end;

		function Slider:SetMax(Value)
			assert(Value > Slider.Min, 'Max value cannot be less than the current min value.');

			Slider.Value = math.clamp(Slider.Value, Slider.Min, Value);
			Slider.Max = Value;
			Slider:Display();
		end;

		function Slider:SetMin(Value)
			assert(Value < Slider.Max, 'Min value cannot be greater than the current max value.');

			Slider.Value = math.clamp(Slider.Value, Value, Slider.Max);
			Slider.Min = Value;
			Slider:Display();
		end;

		function Slider:SetValue(Str)
			local Num = tonumber(Str);

			if (not Num) then
				return;
			end;

			Num = math.clamp(Num, Slider.Min, Slider.Max);

			Slider.Value = Num;
			Slider:Display();

			Library:SafeCallback(Slider.Callback, Slider.Value);
			Library:SafeCallback(Slider.Changed, Slider.Value);
		end;

		local function SetFromX(X)
			local Offset = math.clamp(X - Fill.AbsolutePosition.X, 0, Slider.MaxSize);
			local nValue = Slider:GetValueFromXScale(Library:MapValue(Offset, 0, Slider.MaxSize, 0, 1));

			if nValue ~= Slider.Value then
				Slider.Value = nValue;
				Slider:Display();

				Library:SafeCallback(Slider.Callback, Slider.Value);
				Library:SafeCallback(Slider.Changed, Slider.Value);
			end;
		end;

		local function IsTouchActive(Input)
			return Input.UserInputState ~= Enum.UserInputState.End and Input.UserInputState ~= Enum.UserInputState.Cancel;
		end;

		local Editing = false;
		local LastPress = 0;

		local function OpenEditor()
			if Editing or Library.IsMobile and Library.PickerOpen then
				return;
			end;

			Editing = true;

			local Box = Library:Create('TextBox', {
				BackgroundColor3 = Library.MainColor;
				BorderSizePixel = 0;
				ClearTextOnFocus = false;
				Font = Library.Font;
				Size = UDim2.new(1, 0, 1, 0);
				Text = tostring(Slider.Value);
				TextColor3 = Library.FontColor;
				TextSize = 14;
				ZIndex = 10;
				Parent = SliderInner;
			});

			Library:ApplyTextStroke(Box);
			Box:CaptureFocus();

			Box.FocusLost:Connect(function()
				local Number = tonumber(Box.Text);

				Box:Destroy();
				Editing = false;

				if Number then
					Slider:SetValue(Round(math.clamp(Number, Slider.Min, Slider.Max)));
					Library:AttemptSave();
				end;
			end);
		end;

		local function RegisterPress()
			local Now = os.clock();

			if Now - LastPress < 0.35 then
				LastPress = 0;
				OpenEditor();
			else
				LastPress = Now;
			end;
		end;

		local function HandleSliderTouch(Input)
			if Editing then
				return;
			end;

			local Start = Input.Position;
			local Scroller = SliderOuter:FindFirstAncestorWhichIsA('ScrollingFrame');
			local CanvasStart = Scroller and Scroller.CanvasPosition;
			local Dragging = false;

			while IsTouchActive(Input) do
				if Library.LongPressInput == Input then
					return;
				end;

				local Delta = Input.Position - Start;

				if math.abs(Delta.X) > 8 and math.abs(Delta.X) > math.abs(Delta.Y) then
					Dragging = true;
					break;
				end;

				if math.abs(Delta.Y) > 8 then
					return;
				end;

				RenderStepped:Wait();
			end;

			if not Dragging then
				if Library.LongPressInput == Input then
					return;
				end;

				if (Input.Position - Start).Magnitude <= 10 and (not Scroller or (Scroller.CanvasPosition - CanvasStart).Magnitude <= 2) then
					SetFromX(Input.Position.X);
					Library:AttemptSave();
					RegisterPress();
				end;

				return;
			end;

			Library.CanDrag = false;

			if Scroller then
				Scroller.ScrollingEnabled = false;
			end;

			while IsTouchActive(Input) do
				SetFromX(Input.Position.X);
				RenderStepped:Wait();
			end;

			if Scroller then
				Scroller.ScrollingEnabled = true;
			end;

			if not Library.PickerOpen then
				Library.CanDrag = true;
			end;

			Library:AttemptSave();
		end;

		SliderInner.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.Touch then
				if not Library:MouseIsOverOpenedFrame(Input) then
					HandleSliderTouch(Input);
				end;
				return;
			end;

			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				if Library.IsMobile then
					Library.CanDrag = false;
				end;

				local Sides = {};
				if Library.Window then
					Sides = Library.Window.Tabs[Library.ActiveTab]:GetSides();
				end

				for _, Side in pairs(Sides) do
					if typeof(Side) == "Instance" then
						if Side:IsA("ScrollingFrame") then
							Side.ScrollingEnabled = false;
						end
					end;
				end;

				local mPos = Mouse.X;
				local gPos = Fill.AbsoluteSize.X;
				local Diff = mPos - (Fill.AbsolutePosition.X + gPos);

				while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1 or Enum.UserInputType.Touch) do
					local nMPos = Mouse.X;
					local nXOffset = math.clamp(gPos + (nMPos - mPos) + Diff, 0, Slider.MaxSize); 
					local nXScale = Library:MapValue(nXOffset, 0, Slider.MaxSize, 0, 1);

					local nValue = Slider:GetValueFromXScale(nXScale);
					local OldValue = Slider.Value;
					Slider.Value = nValue;

					Slider:Display();

					if nValue ~= OldValue then
						Library:SafeCallback(Slider.Callback, Slider.Value);
						Library:SafeCallback(Slider.Changed, Slider.Value);
					end;

					RenderStepped:Wait();
				end;

				if Library.IsMobile then
					Library.CanDrag = true;
				end;

				for _, Side in pairs(Sides) do
					if typeof(Side) == "Instance" then
						if Side:IsA("ScrollingFrame") then
							Side.ScrollingEnabled = true;
						end
					end;
				end;

				Library:AttemptSave();
				RegisterPress();
			end;
		end);

		Slider:Display();
		Groupbox:AddBlank(Info.BlankSize or 6);
		Groupbox:Resize();

		Options[Idx] = Slider;

		return Slider;
	end;

	function Funcs:AddDropdown(Idx, Info)
		if Info.SpecialType == 'Player' then
			Info.Values = GetPlayersString();
			Info.AllowNull = true;
		elseif Info.SpecialType == 'Team' then
			Info.Values = GetTeamsString();
			Info.AllowNull = true;
		end;

		assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
		assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

		if (not Info.Text) then
			Info.Compact = true;
		end;

		local Dropdown = {
			Values = Info.Values;
			Value = Info.Multi and {};
			Multi = Info.Multi;
			Type = 'Dropdown';
			SpecialType = Info.SpecialType; 
			Callback = Info.Callback or function(Value) end;
		};

		local Groupbox = self;
		local Container = Groupbox.Container;

		local RelativeOffset = 0;

		if not Info.Compact then
			local DropdownLabel = Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 10);
				TextSize = 14;
				Text = Info.Text;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Bottom;
				ZIndex = 5;
				Parent = Container;
			});

			Groupbox:AddBlank(3);
		end

		for _, Element in next, Container:GetChildren() do
			if not Element:IsA('UIListLayout') then
				RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
			end;
		end;

		local DropdownOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(1, -4, 0, Library.ElementHeight);
			ZIndex = 5;
			Parent = Container;
		});

		Library:AddToRegistry(DropdownOuter, {
			BorderColor3 = 'Black';
		});

		local DropdownInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Parent = DropdownOuter;
		});

		Library:AddToRegistry(DropdownInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		Library:Create('UIGradient', {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
			});
			Rotation = 90;
			Parent = DropdownInner;
		});

		local DropdownArrow = Library:Create('ImageLabel', {
			AnchorPoint = Vector2.new(0, 0.5);
			BackgroundTransparency = 1;
			Position = UDim2.new(1, -16, 0.5, 0);
			Size = UDim2.new(0, 12, 0, 12);
			Image = 'http://www.roblox.com/asset/?id=6282522798';
			ZIndex = 8;
			Parent = DropdownInner;
		});

		local ItemList = Library:CreateLabel({
			Position = UDim2.new(0, 5, 0, 0);
			Size = UDim2.new(1, -5, 1, 0);
			TextSize = 14;
			Text = '--';
			TextXAlignment = Enum.TextXAlignment.Left;
			TextWrapped = true;
			ZIndex = 7;
			Parent = DropdownInner;
		});

		Library:OnHighlight(DropdownOuter, DropdownOuter,
			{ BorderColor3 = 'AccentColor' },
			{ BorderColor3 = 'Black' }
		);

		if type(Info.Tooltip) == 'string' then
			Library:AddToolTip(Info.Tooltip, DropdownOuter)
		end

		local MAX_DROPDOWN_ITEMS = 8;
		local ITEM_HEIGHT = Library.IsMobile and 26 or 20;
		local UsePicker = Library.IsMobile and Info.MobilePicker ~= false;
		local CurrentButtons = {};
		local SearchHeight = Info.Searchable and 24 or 0;
		local ActionsHeight = Info.Multi and 22 or 0;
		local HeaderHeight = SearchHeight + ActionsHeight;
		Dropdown.SearchText = '';

		local ListOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			ZIndex = 20;
			Visible = false;
			Parent = ScreenGui;
		});

		local function RecalculateListPosition()
			ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1);
		end;

		local function RecalculateListSize(YSize)
			local Y = YSize or math.clamp(#Dropdown.Values * ITEM_HEIGHT, 0, MAX_DROPDOWN_ITEMS * ITEM_HEIGHT) + 1 + HeaderHeight;
			ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X + 0.5, Y)
		end;

		RecalculateListPosition();
		RecalculateListSize();

		DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);

		local ListInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 21;
			Parent = ListOuter;
		});

		Library:AddToRegistry(ListInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		local Scrolling = Library:Create('ScrollingFrame', {
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			CanvasSize = UDim2.new(0, 0, 0, 0);
			Position = UDim2.fromOffset(0, HeaderHeight);
			Size = UDim2.new(1, 0, 1, -HeaderHeight);
			ZIndex = 21;
			Parent = ListInner;

			TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
			BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

			ScrollBarThickness = Library.IsMobile and 6 or 3, 
			ScrollBarImageColor3 = Library.AccentColor,
		});

		Library:AddToRegistry(Scrolling, {
			ScrollBarImageColor3 = 'AccentColor'
		})

		if Info.Multi then
			local Actions = Library:Create('Frame', {
				BackgroundTransparency = 1;
				Position = UDim2.fromOffset(0, SearchHeight);
				Size = UDim2.new(1, 0, 0, ActionsHeight);
				ZIndex = 22;
				Parent = ListInner;
			});

			local function AddAction(Text, Index, Bool)
				local Label = Library:CreateLabel({
					Position = UDim2.new(Index * 0.5, 0, 0, 0);
					Size = UDim2.new(0.5, 0, 1, 0);
					Text = Text;
					TextSize = 13;
					ZIndex = 23;
					Parent = Actions;
				});

				Library:OnHighlight(Label, Label,
					{ TextColor3 = 'AccentColor' },
					{ TextColor3 = 'FontColor' }
				);

				Label.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Dropdown:SetMany(Dropdown:GetDisplayValues(), Bool);
					elseif Input.UserInputType == Enum.UserInputType.Touch then
						TrackTap(Input, nil, function()
							Dropdown:SetMany(Dropdown:GetDisplayValues(), Bool);
						end);
					end;
				end);
			end;

			AddAction('Select All', 0, true);
			AddAction('Clear', 1, false);
		end;

		local SearchBox;
		if Info.Searchable then
			local SearchOuter = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Library.OutlineColor;
				Position = UDim2.fromOffset(2, 2);
				Size = UDim2.new(1, -4, 0, SearchHeight - 4);
				ZIndex = 22;
				Parent = ListInner;
			});

			Library:AddToRegistry(SearchOuter, {
				BackgroundColor3 = 'BackgroundColor';
				BorderColor3 = 'OutlineColor';
			});

			SearchBox = Library:Create('TextBox', {
				BackgroundTransparency = 1;
				Position = UDim2.fromOffset(4, 0);
				Size = UDim2.new(1, -8, 1, 0);
				Font = Library.Font;
				PlaceholderColor3 = Color3.fromRGB(150, 150, 150);
				PlaceholderText = 'Search...';
				Text = '';
				TextColor3 = Library.FontColor;
				TextSize = 14;
				TextXAlignment = Enum.TextXAlignment.Left;
				ClearTextOnFocus = false;
				ZIndex = 23;
				Parent = SearchOuter;
			});

			Library:ApplyTextStroke(SearchBox);
			Library:AddToRegistry(SearchBox, {
				TextColor3 = 'FontColor';
			});

			SearchBox:GetPropertyChangedSignal('Text'):Connect(function()
				Dropdown.SearchText = SearchBox.Text;
				Dropdown:BuildDropdownList();
				Scrolling.CanvasPosition = Vector2.zero;
			end);

			SearchBox.FocusLost:Connect(function(EnterPressed)
				if not EnterPressed or Info.Multi or Dropdown.SearchText == '' then
					return;
				end;

				local First = Dropdown:GetDisplayValues()[1];
				if First == nil then
					return;
				end;

				Dropdown.Value = First;
				Dropdown:BuildDropdownList();
				Dropdown:Display();

				Library:UpdateDependencyBoxes();
				Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
				Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
				Library:AttemptSave();

				Dropdown:CloseDropdown();
			end);
		end;

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 0);
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = Scrolling;
		});

		function Dropdown:Display()
			local Values = Dropdown.Values;
			local Str = '';

			if Info.Multi then
				for Idx, Value in next, Values do
					if Dropdown.Value[Value] then
						Str = Str .. Value .. ', ';
					end;
				end;

				Str = Str:sub(1, #Str - 2);
			else
				Str = Dropdown.Value or '';
			end;

			ItemList.Text = (Str == '' and '--' or Str);
		end;

		function Dropdown:GetActiveValues()
			if Info.Multi then
				local T = {};

				for Value, Bool in next, Dropdown.Value do
					table.insert(T, Value);
				end;

				return T;
			else
				return Dropdown.Value and 1 or 0;
			end;
		end;

		function Dropdown:GetDisplayValues()
			if SearchBox and Dropdown.SearchText ~= '' then
				return Library:FuzzyFilter(Dropdown.SearchText, Dropdown.Values);
			end;
			return Dropdown.Values;
		end;

		function Dropdown:IsValueSelected(Value)
			if Info.Multi then
				return Dropdown.Value[Value] == true;
			end;

			return Dropdown.Value == Value;
		end;

		local function CommitChange()
			for _, Button in next, CurrentButtons do
				Button:UpdateButton();
			end;

			Dropdown:Display();

			Library:UpdateDependencyBoxes();
			Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
			Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

			Library:AttemptSave();
		end;

		function Dropdown:SetMany(Values, Bool)
			if not Info.Multi then
				return;
			end;

			for _, Value in next, Values do
				Dropdown.Value[Value] = Bool and true or nil;
			end;

			CommitChange();
		end;

		function Dropdown:SelectValue(Value)
			local Try = not Dropdown:IsValueSelected(Value);

			if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
				return;
			end;

			if Info.Multi then
				Dropdown.Value[Value] = Try or nil;
			else
				Dropdown.Value = Try and Value or nil;
			end;

			CommitChange();
		end;

		function Dropdown:BuildDropdownList()
			local Values = Dropdown:GetDisplayValues();
			local Buttons = {};
			CurrentButtons = Buttons;

			for _, Element in next, Scrolling:GetChildren() do
				if not Element:IsA('UIListLayout') then
					Element:Destroy();
				end;
			end;

			local Count = 0;
			for Idx, Value in next, Values do
				local Table = {};

				Count = Count + 1;

				local Button = Library:Create('Frame', {
					BackgroundColor3 = Library.MainColor;
					BorderColor3 = Library.OutlineColor;
					BorderMode = Enum.BorderMode.Middle;
					Size = UDim2.new(1, -1, 0, ITEM_HEIGHT);
					ZIndex = 23;
					Active = true,
					Parent = Scrolling;
				});

				Library:AddToRegistry(Button, {
					BackgroundColor3 = 'MainColor';
					BorderColor3 = 'OutlineColor';
				});

				local ButtonLabel = Library:CreateLabel({
					Active = false;
					Size = UDim2.new(1, -6, 1, 0);
					Position = UDim2.new(0, 6, 0, 0);
					TextSize = 14;
					Text = Value;
					TextXAlignment = Enum.TextXAlignment.Left;
					ZIndex = 25;
					Parent = Button;
				});

				Library:OnHighlight(Button, Button,
					{ BorderColor3 = 'AccentColor', ZIndex = 24 },
					{ BorderColor3 = 'OutlineColor', ZIndex = 23 }
				);

				local Selected;

				if Info.Multi then
					Selected = Dropdown.Value[Value];
				else
					Selected = Dropdown.Value == Value;
				end;

				function Table:UpdateButton()
					if Info.Multi then
						Selected = Dropdown.Value[Value];
					else
						Selected = Dropdown.Value == Value;
					end;

					ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
					Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
				end;

				ButtonLabel.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Dropdown:SelectValue(Value);
					elseif Input.UserInputType == Enum.UserInputType.Touch then
						TrackTap(Input, Scrolling, function()
							if ListOuter.Visible then
								Dropdown:SelectValue(Value);
							end;
						end);
					end;
				end);

				Table:UpdateButton();
				Dropdown:Display();

				Buttons[Button] = Table;
			end;

			Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * ITEM_HEIGHT) + 1);

			Scrolling.Visible = false;
			Scrolling.Visible = true;

			local Y = math.clamp(Count * ITEM_HEIGHT, 0, MAX_DROPDOWN_ITEMS * ITEM_HEIGHT) + 1 + HeaderHeight;
			RecalculateListSize(Y);

			if MobilePicker.Owner == Dropdown then
				MobilePicker:Refresh();
			end;
		end;

		function Dropdown:SetValues(NewValues)
			if NewValues then
				Dropdown.Values = NewValues;
			end;

			Dropdown:BuildDropdownList();
		end;

		function Dropdown:OpenDropdown()
			if UsePicker then
				DropdownArrow.Rotation = 180;
				MobilePicker:Open(Dropdown, Info.Text or tostring(Idx), function()
					DropdownArrow.Rotation = 0;
				end);
				return;
			end;

			if Library.IsMobile then
				Library.CanDrag = false;
			end;

			ListOuter.Visible = true;
			Library.OpenedFrames[ListOuter] = true;
			DropdownArrow.Rotation = 180;

			if SearchBox then
				SearchBox.Text = '';
				Dropdown.SearchText = '';
				if not Library.IsMobile then
					task.defer(function()
						if ListOuter.Visible then
							SearchBox:CaptureFocus();
						end;
					end);
				end;
			end;

			RecalculateListSize();
		end;

		function Dropdown:CloseDropdown()
			if MobilePicker.Owner == Dropdown then
				MobilePicker:Close();
			end;

			if not ListOuter.Visible then
				return;
			end;

			if Library.IsMobile then
				Library.CanDrag = true;
			end;

			ListOuter.Visible = false;
			Library.OpenedFrames[ListOuter] = nil;
			DropdownArrow.Rotation = 0;

			if SearchBox and SearchBox:IsFocused() then
				SearchBox:ReleaseFocus();
			end;
		end;

		function Dropdown:OnChanged(Func)
			local Connection = AddListener(Dropdown, 'Changed', Func);
			Func(Dropdown.Value);
			return Connection;
		end;

		function Dropdown:SetValue(Val)
			if Dropdown.Multi then
				local nTable = {};

				for Value, Bool in next, Val do
					if table.find(Dropdown.Values, Value) then
						nTable[Value] = true
					end;
				end;

				Dropdown.Value = nTable;
			else
				if (not Val) then
					Dropdown.Value = nil;
				elseif table.find(Dropdown.Values, Val) then
					Dropdown.Value = Val;
				end;
			end;

			Dropdown:BuildDropdownList();

			Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
			Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
		end;

		local function ToggleList()
			if ListOuter.Visible or MobilePicker.Owner == Dropdown then
				Dropdown:CloseDropdown();
			else
				Dropdown:OpenDropdown();
			end;
		end;

		DropdownOuter.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				ToggleList();
			elseif Input.UserInputType == Enum.UserInputType.Touch then
				TrackTap(Input, DropdownOuter:FindFirstAncestorWhichIsA('ScrollingFrame'), ToggleList);
			end;
		end);

		InputService.InputBegan:Connect(function(Input)
			if not ListOuter.Visible then
				return;
			end;

			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;

				if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
					or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

					Dropdown:CloseDropdown();
				end;
			end;
		end);

		Dropdown:BuildDropdownList();
		Dropdown:Display();

		local Defaults = {}

		if type(Info.Default) == 'string' then
			local Idx = table.find(Dropdown.Values, Info.Default)
			if Idx then
				table.insert(Defaults, Idx)
			end
		elseif type(Info.Default) == 'table' then
			for _, Value in next, Info.Default do
				local Idx = table.find(Dropdown.Values, Value)
				if Idx then
					table.insert(Defaults, Idx)
				end
			end
		elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
			table.insert(Defaults, Info.Default)
		end

		if next(Defaults) then
			for i = 1, #Defaults do
				local Index = Defaults[i]
				if Info.Multi then
					Dropdown.Value[Dropdown.Values[Index]] = true
				else
					Dropdown.Value = Dropdown.Values[Index];
				end

				if (not Info.Multi) then break end
			end

			Dropdown:BuildDropdownList();
			Dropdown:Display();
		end

		Groupbox:AddBlank(Info.BlankSize or 5);
		Groupbox:Resize();

		Options[Idx] = Dropdown;

		return Dropdown;
	end;

	function Funcs:AddDependencyBox()
		local Depbox = {
			Dependencies = {};
		};

		local Groupbox = self;
		local Container = Groupbox.Container;

		local Holder = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 0, 0);
			Visible = false;
			Parent = Container;
		});

		local Frame = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 1, 0);
			Visible = true;
			Parent = Holder;
		});

		local Layout = Library:Create('UIListLayout', {
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = Frame;
		});

		function Depbox:Resize()
			Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
			Groupbox:Resize();
		end;

		Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			Depbox:Resize();
		end);

		Holder:GetPropertyChangedSignal('Visible'):Connect(function()
			Depbox:Resize();
		end);

		function Depbox:Update()
			for _, Dependency in next, Depbox.Dependencies do
				local Elem = Dependency[1];
				local Value = Dependency[2];

				if if Elem.Multi then not table.find(Elem:GetActiveValues(), Value) else Elem.Value ~= Value then
					Holder.Visible = false;
					Depbox:Resize();
					return;
				end;
			end;

			Holder.Visible = true;
			Depbox:Resize();
		end;

		function Depbox:SetupDependencies(Dependencies)
			for _, Dependency in next, Dependencies do
				assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.');
				assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.');
				assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.');
			end;

			Depbox.Dependencies = Dependencies;
			Depbox:Update();
		end;

		Depbox.Container = Frame;

		setmetatable(Depbox, BaseGroupbox);

		table.insert(Library.DependencyBoxes, Depbox);

		return Depbox;
	end;

	BaseGroupbox.__index = Funcs;
	BaseGroupbox.__namecall = function(Table, Key, ...)
		return Funcs[Key](...);
	end;
end;

do
	Library.NotificationArea = Library:Create('Frame', {
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 0, 0, 40);
		Size = UDim2.new(0, 300, 0, 200);
		ZIndex = 100;
		Parent = ScreenGui;
	});

	Library:Create('UIListLayout', {
		Padding = UDim.new(0, 4);
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = Library.NotificationArea;
	});

	local WatermarkOuter = Library:Create('Frame', {
		AnchorPoint = Vector2.new(0.5, 0);
		BorderColor3 = Color3.new(0, 0, 0);
		Position = UDim2.new(0.5, 0, 0, 10);
		Size = UDim2.new(0, 213, 0, 20);
		ZIndex = 200;
		Visible = false;
		Parent = ScreenGui;
	});

	local WatermarkInner = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.AccentColor;
		BorderMode = Enum.BorderMode.Inset;
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 201;
		Parent = WatermarkOuter;
	});

	Library:AddToRegistry(WatermarkInner, {
		BorderColor3 = 'AccentColor';
	});

	local InnerFrame = Library:Create('Frame', {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BorderSizePixel = 0;
		Position = UDim2.new(0, 1, 0, 1);
		Size = UDim2.new(1, -2, 1, -2);
		ZIndex = 202;
		Parent = WatermarkInner;
	});

	local Gradient = Library:Create('UIGradient', {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
			ColorSequenceKeypoint.new(1, Library.MainColor),
		});
		Rotation = -90;
		Parent = InnerFrame;
	});

	Library:AddToRegistry(Gradient, {
		Color = function()
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
				ColorSequenceKeypoint.new(1, Library.MainColor),
			});
		end
	});

	local WatermarkLabel = Library:CreateLabel({
		Position = UDim2.new(0, 5, 0, 0);
		Size = UDim2.new(1, -4, 1, 0);
		TextSize = 14;
		TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 203;
		Parent = InnerFrame;
	});

	Library.Watermark = WatermarkOuter;
	Library.WatermarkText = WatermarkLabel;
	Library:MakeDraggable(Library.Watermark);

	local KeybindOuter = Library:Create('Frame', {
		AnchorPoint = Vector2.new(0, 0.5);
		BorderColor3 = Color3.new(0, 0, 0);
		Position = UDim2.new(0, 10, 0.5, 0);
		Size = UDim2.new(0, 210, 0, 20);
		Visible = false;
		ZIndex = 100;
		Parent = ScreenGui;
	});

	local KeybindInner = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.OutlineColor;
		BorderMode = Enum.BorderMode.Inset;
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 101;
		Parent = KeybindOuter;
	});

	Library:AddToRegistry(KeybindInner, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	}, true);

	local ColorFrame = Library:Create('Frame', {
		BackgroundColor3 = Library.AccentColor;
		BorderSizePixel = 0;
		Size = UDim2.new(1, 0, 0, 2);
		ZIndex = 102;
		Parent = KeybindInner;
	});

	Library:AddToRegistry(ColorFrame, {
		BackgroundColor3 = 'AccentColor';
	}, true);

	local KeybindLabel = Library:CreateLabel({
		Size = UDim2.new(1, 0, 0, 20);
		Position = UDim2.fromOffset(5, 2),
		TextXAlignment = Enum.TextXAlignment.Left,

		Text = 'Keybinds';
		ZIndex = 104;
		Parent = KeybindInner;
	});
	Library:MakeDraggable(KeybindOuter);

	local KeybindContainer = Library:Create('Frame', {
		BackgroundTransparency = 1;
		Size = UDim2.new(1, 0, 1, -20);
		Position = UDim2.new(0, 0, 0, 20);
		ZIndex = 1;
		Parent = KeybindInner;
	});

	Library:Create('UIListLayout', {
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = KeybindContainer;
	});

	Library:Create('UIPadding', {
		PaddingLeft = UDim.new(0, 5),
		Parent = KeybindContainer,
	})

	Library.KeybindFrame = KeybindOuter;
	Library.KeybindContainer = KeybindContainer;
	Library:MakeDraggable(KeybindOuter);
end;

function Library:SetWatermarkVisibility(Bool)
	Elevate();
	Library.Watermark.Visible = Bool;
end;

Library.NotifyTimestamps = true;
Library.NotifyTimeColor = Color3.fromRGB(200, 200, 200);
Library.NotifyTimeSeparator = ' | ';

local function getTime()
	if getgenv().getTime then
		return getgenv().getTime();
	end;
	local t = os.date('*t');
	local hour = t.hour % 12;
	if hour == 0 then
		hour = 12;
	end;
	return string.format('%d:%02d %s', hour, t.min, t.hour >= 12 and 'PM' or 'AM');
end;

local function escapeRich(Str)
	return (Str:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'));
end;

function Library:Notify(Text, Time, SoundId)
	Text = tostring(Text);
	if Text:lower():find('to hide', 1, true) then
		Library.HideNotified = true;
	end;
	local DisplayText = escapeRich(Text);
	if Library.NotifyTimestamps then
		local Stamp = getTime();
		Stamp = Stamp .. Library.NotifyTimeSeparator;
		Text = Stamp .. Text;
		DisplayText = string.format('<font color="#%s">%s</font>%s', Library.NotifyTimeColor:ToHex(), escapeRich(Stamp), DisplayText);
	end;

	local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14);

	YSize = YSize + 7
	Elevate();
	local NotifyOuter = Library:Create('Frame', {
		BorderColor3 = Color3.new(0, 0, 0);
		Position = UDim2.new(0, 100, 0, 10);
		Size = UDim2.new(0, 0, 0, YSize);
		ClipsDescendants = true;
		ZIndex = 100;
		Parent = Library.NotificationArea;
	});

	local NotifyInner = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.OutlineColor;
		BorderMode = Enum.BorderMode.Inset;
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 101;
		Parent = NotifyOuter;
	});

	Library:AddToRegistry(NotifyInner, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	}, true);

	local InnerFrame = Library:Create('Frame', {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BorderSizePixel = 0;
		Position = UDim2.new(0, 1, 0, 1);
		Size = UDim2.new(1, -2, 1, -2);
		ZIndex = 102;
		Parent = NotifyInner;
	});

	local Gradient = Library:Create('UIGradient', {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
			ColorSequenceKeypoint.new(1, Library.MainColor),
		});
		Rotation = -90;
		Parent = InnerFrame;
	});

	Library:AddToRegistry(Gradient, {
		Color = function()
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
				ColorSequenceKeypoint.new(1, Library.MainColor),
			});
		end
	});

	local NotifyLabel = Library:CreateLabel({
		Position = UDim2.new(0, 4, 0, 0);
		Size = UDim2.new(1, -4, 1, 0);
		Text = DisplayText;
		RichText = true;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextSize = 14;
		ZIndex = 103;
		Parent = InnerFrame;
	});

	local LeftColor = Library:Create('Frame', {
		BackgroundColor3 = Library.AccentColor;
		BorderSizePixel = 0;
		Position = UDim2.new(0, -1, 0, -1);
		Size = UDim2.new(0, 3, 1, 2);
		ZIndex = 104;
		Parent = NotifyOuter;
	});

	Library:AddToRegistry(LeftColor, {
		BackgroundColor3 = 'AccentColor';
	}, true);

	if SoundId then
		Library:Create('Sound', {
			SoundId = "rbxassetid://" .. tostring(SoundId):gsub("rbxassetid://", "");
			Volume = 3;
			PlayOnRemove = true;
			Parent = game:GetService("SoundService");
		}):Destroy();
	end

	pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 8 + 4, 0, YSize), 'Out', 'Quad', 0.4, true);

	local Closed = false;
	local function Close()
		if Closed then
			return;
		end;
		Closed = true;
		Elevate();
		pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.4, true);
		task.delay(0.4, function()
			Elevate();
			NotifyOuter:Destroy();
		end);
	end;

	local Dismiss = Library:Create('TextButton', {
		BackgroundTransparency = 1;
		Text = '';
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 105;
		Parent = NotifyOuter;
	});
	Dismiss.MouseButton1Click:Connect(Close);

	task.spawn(function()
		if typeof(Time) == 'Instance' then
			Time.Destroying:Wait();
		elseif type(Time) == 'number' and Time <= 0 then
			return;
		else
			task.wait(Time or 5);
		end;
		Close();
	end);

	return { Close = Close };
end;

Library.StartTime = os.clock();

local FramesThisSecond = 0;
local CurrentFPS = 0;
local FPSClock = os.clock();
Library:GiveSignal(RunService.RenderStepped:Connect(function()
	FramesThisSecond = FramesThisSecond + 1;
	local Now = os.clock();
	if Now - FPSClock >= 1 then
		CurrentFPS = math.floor(FramesThisSecond / (Now - FPSClock) + 0.5);
		FramesThisSecond = 0;
		FPSClock = Now;
	end;
end));

local function FormatElapsed(Seconds)
	Seconds = math.floor(Seconds);
	local Hours = math.floor(Seconds / 3600);
	local Minutes = math.floor(Seconds % 3600 / 60);
	local Secs = Seconds % 60;
	if Hours > 0 then
		return string.format('%d:%02d:%02d', Hours, Minutes, Secs);
	end;
	return string.format('%d:%02d', Minutes, Secs);
end;

local function GetPing()
	local Success, Ping = pcall(function()
		return LocalPlayer:GetNetworkPing();
	end);
	return Success and math.floor(Ping * 1000 + 0.5) or 0;
end;

Library.WatermarkTokens = {
	time = getTime,
	fps = function()
		return CurrentFPS;
	end,
	ping = GetPing,
	elapsed = function()
		return FormatElapsed(os.clock() - Library.StartTime);
	end,
};

local WatermarkTemplate = nil;

local function ApplyWatermarkText(Text)
	Elevate();
	local X, Y = Library:GetTextBounds(Text, Library.Font, 14);
	Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3);
	Library.WatermarkText.Text = Text;
end;

local function FormatWatermark(Template)
	return (Template:gsub('{(%w+)}', function(Key)
		local Token = Library.WatermarkTokens[Key];
		if not Token then
			return nil;
		end;
		local Success, Value = pcall(Token);
		Elevate();
		return Success and tostring(Value) or '?';
	end));
end;

function Library:SetWatermark(Text)
	Text = tostring(Text);
	if Text:find('{%w+}') then
		WatermarkTemplate = Text;
		ApplyWatermarkText(FormatWatermark(Text));
	else
		WatermarkTemplate = nil;
		ApplyWatermarkText(Text);
	end;
	Library:SetWatermarkVisibility(true);
end;

Library.WatermarkTopOffset = 10;

local WatermarkFile = nil;

local function GetDefaultWatermarkPosition()
	local Success, Inset = pcall(function()
		return GuiService:GetGuiInset();
	end);
	local InsetY = Success and typeof(Inset) == 'Vector2' and Inset.Y or 0;
	return UDim2.new(0.5, 0, 0, Library.WatermarkTopOffset - InsetY);
end;

local function SetWatermarkPosition(Position)
	Library.Watermark.AnchorPoint = Vector2.new(0.5, 0);
	Library.Watermark.Position = Position;
end;

local function SaveWatermarkPosition()
	if not WatermarkFile or not writefile then
		return;
	end;
	local Screen = ScreenGui.AbsoluteSize;
	if Screen.X <= 0 or Screen.Y <= 0 then
		return;
	end;
	local Watermark = Library.Watermark;
	local X = (Watermark.AbsolutePosition.X + Watermark.AbsoluteSize.X * 0.5) / Screen.X;
	local Y = Watermark.AbsolutePosition.Y / Screen.Y;
	pcall(writefile, WatermarkFile, string.format('%.4f,%.4f', X, Y));
end;

local function LoadWatermarkPosition()
	if WatermarkFile and isfile and readfile and isfile(WatermarkFile) then
		local X, Y = readfile(WatermarkFile):match('^(%-?[%d%.]+),(%-?[%d%.]+)$');
		X, Y = tonumber(X), tonumber(Y);
		if X and Y then
			SetWatermarkPosition(UDim2.new(math.clamp(X, 0, 1), 0, math.clamp(Y, -0.1, 0.95), 0));
			return true;
		end;
	end;
	SetWatermarkPosition(GetDefaultWatermarkPosition());
	return false;
end;

local UISettingsFile = nil;
local UISettings = { LockUI = false; SideHidden = false };

local function ApplyUISettings()
	Library.CantDragForced = UISettings.LockUI == true;
	if Library.LockUILabel then
		Library.LockUILabel.Text = Library.CantDragForced and 'Unlock UI' or 'Lock UI';
	end;
	if Library.ApplySideDock then
		Library.ApplySideDock();
	end;
	if Library.MenuKeybindPicker and UISettings.MenuKeybind and Library.MenuKeybindPicker.Value ~= UISettings.MenuKeybind then
		Library.MenuKeybindPicker:SetValue({ UISettings.MenuKeybind, Library.MenuKeybindPicker.Mode or 'Toggle' });
	end;
end;

local function SaveUISettings()
	if not UISettingsFile or not writefile then
		return;
	end;
	local Folder = UISettingsFile:match('^(.*)/[^/]*$');
	if Folder and isfolder and makefolder and not isfolder(Folder) then
		pcall(makefolder, Folder);
	end;
	pcall(writefile, UISettingsFile, HttpService:JSONEncode(UISettings));
end;

function Library:SetUISettingsFile(Path)
	UISettingsFile = Path;
	if Path and isfile and readfile and isfile(Path) then
		local Success, Data = pcall(function()
			return HttpService:JSONDecode(readfile(Path));
		end);
		if Success and type(Data) == 'table' then
			UISettings.LockUI = Data.LockUI == true;
			UISettings.SideHidden = Data.SideHidden == true;
			UISettings.MenuKeybind = type(Data.MenuKeybind) == 'string' and Data.MenuKeybind or nil;
		end;
	end;
	ApplyUISettings();
end;

function Library:AddMenuKeybind(Groupbox, Info)
	if Library.IsMobile then
		return nil;
	end;

	Info = Info or {};

	local Idx = Info.Idx or 'MenuKeybind';

	Groupbox:AddLabel(Info.Text or 'Menu bind'):AddKeyPicker(Idx, {
		Default = UISettings.MenuKeybind or Info.Default or 'RightControl';
		NoUI = true;
		Text = 'Menu keybind';
	});

	local Picker = Options[Idx];

	Library.MenuKeybindPicker = Picker;
	Library.ToggleKeybind = Picker;

	Picker:OnChanged(function()
		if type(Picker.Value) == 'string' and Picker.Value ~= UISettings.MenuKeybind then
			UISettings.MenuKeybind = Picker.Value;
			SaveUISettings();
		end;
	end);

	return Picker;
end;

function Library:GetMenuKeybindText()
	local Picker = type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind;

	if Picker and type(Picker.Value) == 'string' and Picker.Value ~= 'None' and Picker.Value ~= 'Unknown' then
		return Picker.Value;
	end;

	return 'RightCtrl or RightShift';
end;

function Library:SetUILocked(Bool)
	UISettings.LockUI = not not Bool;
	ApplyUISettings();
	SaveUISettings();
end;

function Library:SetWatermarkSaveFile(Path)
	WatermarkFile = Path;
	return LoadWatermarkPosition();
end;

function Library:ResetWatermarkPosition()
	if WatermarkFile and isfile and delfile and isfile(WatermarkFile) then
		pcall(delfile, WatermarkFile);
	end;
	SetWatermarkPosition(GetDefaultWatermarkPosition());
end;

SetWatermarkPosition(GetDefaultWatermarkPosition());

do
	local DragStartPosition = nil;

	Library:GiveSignal(Library.Watermark.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			DragStartPosition = Library.Watermark.Position;
		elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
			Library:ResetWatermarkPosition();
			Library:Notify('Watermark position reset', 2);
		end;
	end));

	Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
		if not DragStartPosition then
			return;
		end;
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			local StartPosition = DragStartPosition;
			DragStartPosition = nil;
			task.delay(0.1, function()
				if Library.Watermark.Position ~= StartPosition then
					SaveWatermarkPosition();
				end;
			end);
		end;
	end));
end;

Library:Loop(1, function()
	if WatermarkTemplate and Library.Watermark and Library.Watermark.Visible then
		ApplyWatermarkText(FormatWatermark(WatermarkTemplate));
	end;
end);

function Library:SetFont(Font)
	if type(Font) == 'string' then
		local Success, Result = pcall(function()
			return Enum.Font[Font];
		end);
		if not Success then
			return false;
		end;
		Font = Result;
	end;
	if typeof(Font) ~= 'EnumItem' then
		return false;
	end;

	Library.Font = Font;
	for _, Object in ipairs(ScreenGui:GetDescendants()) do
		if Object:IsA('TextLabel') or Object:IsA('TextButton') or Object:IsA('TextBox') then
			Object.Font = Font;
		end;
	end;
	return true;
end;

local TabFile = nil;
local PendingTab = nil;

function Library:SetTabSaveFile(Path)
	TabFile = Path;
	PendingTab = nil;

	if not (Path and isfile and readfile and isfile(Path)) then
		return;
	end;

	local Success, Name = pcall(readfile, Path);

	if not Success or type(Name) ~= 'string' or Name == '' then
		return;
	end;

	local Tab = Library.RememberTab and Library.Window and Library.Window.Tabs[Name];

	if Tab then
		Tab:ShowTab();
	else
		PendingTab = Name;
	end;
end;

function Library:CreateWindow(...)
	local Arguments = { ... }
	local Config = { AnchorPoint = Vector2.zero }

	if type(...) == 'table' then
		Config = ...;
	else
		Config.Title = Arguments[1]
		Config.AutoShow = Arguments[2] or false;
	end

	if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
	if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 1 end
	if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end
	if type(Config.ShowCustomCursor) ~= 'boolean' then Library.ShowCustomCursor = false else Library.ShowCustomCursor = Config.ShowCustomCursor end

	if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
	if typeof(Config.Size) ~= 'UDim2' then 
		Config.Size = UDim2.fromOffset(550, 600)
		if Library.IsMobile then
			Config.Size = UDim2.fromOffset(550, 400)
		end
	end

	if Config.RememberTab ~= nil then
		Library.RememberTab = Config.RememberTab == true
	end

	if Config.TabPadding <= 0 then
		Config.TabPadding = 1
	end

	if Config.Center then

		Config.Position = UDim2.new(0.5, -Config.Size.X.Offset/2, 0.5, -Config.Size.Y.Offset/2)
	end

	local Window = {
		Tabs = {};
	};

	local Outer = Library:Create('Frame', {
		AnchorPoint = Config.AnchorPoint;
		BackgroundColor3 = Color3.new(0, 0, 0);
		BorderSizePixel = 0;
		Position = Config.Position;
		Size = Config.Size;
		Visible = false;
		ZIndex = 1;
		Parent = ScreenGui;
	});
	LibraryMainOuterFrame = Outer;
	Library:MakeDraggable(Outer, 25);

	if Config.Resizable then
		Library:MakeResizable(Outer, Library.MinSize);
	end

	local Inner = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.AccentColor;
		BorderMode = Enum.BorderMode.Inset;
		Position = UDim2.new(0, 1, 0, 1);
		Size = UDim2.new(1, -2, 1, -2);
		ZIndex = 1;
		Parent = Outer;
	});

	Library:AddToRegistry(Inner, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'AccentColor';
	});

	local WindowLabel = Library:CreateLabel({
		Position = UDim2.new(0, 7, 0, 0);
		Size = UDim2.new(0, 0, 0, 25);
		Text = Config.Title or '';
		TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 1;
		Parent = Inner;
	});

	local MainSectionOuter = Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Library.OutlineColor;
		Position = UDim2.new(0, 8, 0, 25);
		Size = UDim2.new(1, -16, 1, -33);
		ZIndex = 1;
		Parent = Inner;
	});

	Library:AddToRegistry(MainSectionOuter, {
		BackgroundColor3 = 'BackgroundColor';
		BorderColor3 = 'OutlineColor';
	});

	local MainSectionInner = Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Color3.new(0, 0, 0);
		BorderMode = Enum.BorderMode.Inset;
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 1;
		Parent = MainSectionOuter;
	});

	Library:AddToRegistry(MainSectionInner, {
		BackgroundColor3 = 'BackgroundColor';
	});

	local TabArea = Library:Create('ScrollingFrame', {
		ScrollingDirection = Enum.ScrollingDirection.X;
		CanvasSize = UDim2.new(0, 0, 2, 0);
		HorizontalScrollBarInset = Enum.ScrollBarInset.Always;
		AutomaticCanvasSize = Enum.AutomaticSize.XY;
		ScrollBarThickness = 0;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 8 - Config.TabPadding, 0, 4);
		Size = UDim2.new(1, -10, 0, 26);
		ZIndex = 1;
		Parent = MainSectionInner;
	});

	local TabListLayout = Library:Create('UIListLayout', {
		Padding = UDim.new(0, Config.TabPadding);
		FillDirection = Enum.FillDirection.Horizontal;
		SortOrder = Enum.SortOrder.LayoutOrder;
		VerticalAlignment = Enum.VerticalAlignment.Center;
		Parent = TabArea;
	});

	Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Library.OutlineColor;
		Size = UDim2.new(0, 0, 0, 0);
		LayoutOrder = -1;
		BackgroundTransparency = 1;
		ZIndex = 1;
		Parent = TabArea;
	});
	Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Library.OutlineColor;
		Size = UDim2.new(0, 0, 0, 0);
		LayoutOrder = 9999999;
		BackgroundTransparency = 1;
		ZIndex = 1;
		Parent = TabArea;
	});

	local TabContainer = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.OutlineColor;
		Position = UDim2.new(0, 8, 0, 30);
		Size = UDim2.new(1, -16, 1, -38);
		ZIndex = 2;
		Parent = MainSectionInner;
	});

	Library:AddToRegistry(TabContainer, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	});

	function Window:SetWindowTitle(Title)
		WindowLabel.Text = Title;
	end;

	function Window:AddTab(Name)
		local Tab = {
			Groupboxes = {};
			Tabboxes = {};
		};

		local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 16);

		local TabButton = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			Size = UDim2.new(0, TabButtonWidth + 8 + 4, 0.85, 0);
			ZIndex = 1;
			Parent = TabArea;
		});

		Library:AddToRegistry(TabButton, {
			BackgroundColor3 = 'BackgroundColor';
			BorderColor3 = 'OutlineColor';
		});

		local TabButtonLabel = Library:CreateLabel({
			Position = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(1, 0, 1, -1);
			Text = Name;
			ZIndex = 1;
			Parent = TabButton;
		});

		local Blocker = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderSizePixel = 0;
			Position = UDim2.new(0, 0, 1, 0);
			Size = UDim2.new(1, 0, 0, 1);
			BackgroundTransparency = 1;
			ZIndex = 3;
			Parent = TabButton;
		});

		Library:AddToRegistry(Blocker, {
			BackgroundColor3 = 'MainColor';
		});

		local TabFrame = Library:Create('Frame', {
			Name = 'TabFrame',
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(1, 0, 1, 0);
			Visible = false;
			ZIndex = 2;
			Parent = TabContainer;
		});

		local LeftSide = Library:Create('ScrollingFrame', {
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
			Size = UDim2.new(0.5, -12 + 2, 1, -14);
			CanvasSize = UDim2.new(0, 0, 0, 0);
			BottomImage = '';
			TopImage = '';
			ScrollBarThickness = 0;
			ZIndex = 2;
			Parent = TabFrame;
		});

		local RightSide = Library:Create('ScrollingFrame', {
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
			Size = UDim2.new(0.5, -12 + 2, 1, -14);
			CanvasSize = UDim2.new(0, 0, 0, 0);
			BottomImage = '';
			TopImage = '';
			ScrollBarThickness = 0;
			ZIndex = 2;
			Parent = TabFrame;
		});

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 8);
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			HorizontalAlignment = Enum.HorizontalAlignment.Center;
			Parent = LeftSide;
		});

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 8);
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			HorizontalAlignment = Enum.HorizontalAlignment.Center;
			Parent = RightSide;
		});

		if Library.IsMobile then
			local SidesValues = {
				["Left"] = tick(),
				["Right"] = tick(),
			}

			LeftSide:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
				Library.CanDrag = false;

				local ChangeTick = tick();
				SidesValues.Left = ChangeTick;
				task.wait(0.15);

				if SidesValues.Left == ChangeTick then
					Library.CanDrag = true;
				end
			end);

			RightSide:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
				Library.CanDrag = false;

				local ChangeTick = tick();
				SidesValues.Right = ChangeTick;
				task.wait(0.15);

				if SidesValues.Right == ChangeTick then
					Library.CanDrag = true;
				end
			end);
		end;

		for _, Side in next, { LeftSide, RightSide } do
			Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
				Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y);
			end);
		end;

		function Tab:ShowTab()
			Library.ActiveTab = Name;

			if Library.RememberTab and TabFile and writefile then
				pcall(writefile, TabFile, Name);
			end;

			for _, Tab in next, Window.Tabs do
				Tab:HideTab();
			end;

			Blocker.BackgroundTransparency = 0;
			TabButton.BackgroundColor3 = Library.MainColor;
			Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor';
			TabFrame.Visible = true;
		end;

		function Tab:HideTab()
			Blocker.BackgroundTransparency = 1;
			TabButton.BackgroundColor3 = Library.BackgroundColor;
			Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor';
			TabFrame.Visible = false;
		end;

		function Tab:SetLayoutOrder(Position)
			TabButton.LayoutOrder = Position;
			TabListLayout:ApplyLayout();
		end;

		function Tab:GetSides()
			return { ["Left"] = LeftSide, ["Right"] = RightSide };
		end;

		function Tab:AddGroupbox(Info)
			local Groupbox = {};

			local BoxOuter = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Library.OutlineColor;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 0, 507 + 2);
				ZIndex = 2;
				Parent = Info.Side == 1 and LeftSide or RightSide;
			});

			Library:AddToRegistry(BoxOuter, {
				BackgroundColor3 = 'BackgroundColor';
				BorderColor3 = 'OutlineColor';
			});

			local BoxInner = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Color3.new(0, 0, 0);

				Size = UDim2.new(1, -2, 1, -2);
				Position = UDim2.new(0, 1, 0, 1);
				ZIndex = 4;
				Parent = BoxOuter;
			});

			Library:AddToRegistry(BoxInner, {
				BackgroundColor3 = 'BackgroundColor';
			});

			local Highlight = Library:Create('Frame', {
				BackgroundColor3 = Library.AccentColor;
				BorderSizePixel = 0;
				Size = UDim2.new(1, 0, 0, 2);
				ZIndex = 5;
				Parent = BoxInner;
			});

			Library:AddToRegistry(Highlight, {
				BackgroundColor3 = 'AccentColor';
			});

			local GroupboxLabel = Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 18);
				Position = UDim2.new(0, 4, 0, 2);
				TextSize = 14;
				Text = Info.Name;
				TextXAlignment = Enum.TextXAlignment.Left;
				ZIndex = 5;
				Parent = BoxInner;
			});

			local Container = Library:Create('Frame', {
				BackgroundTransparency = 1;
				Position = UDim2.new(0, 4, 0, 20);
				Size = UDim2.new(1, -4, 1, -20);
				ZIndex = 1;
				Parent = BoxInner;
			});

			Library:Create('UIListLayout', {
				FillDirection = Enum.FillDirection.Vertical;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Parent = Container;
			});

			function Groupbox:Resize()
				local Size = 0;

				for _, Element in next, Groupbox.Container:GetChildren() do
					if (not Element:IsA('UIListLayout')) and Element.Visible then
						Size = Size + Element.Size.Y.Offset;
					end;
				end;

				BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
			end;

			Groupbox.Container = Container;
			setmetatable(Groupbox, BaseGroupbox);

			Groupbox:AddBlank(3);
			Groupbox:Resize();

			Tab.Groupboxes[Info.Name] = Groupbox;

			return Groupbox;
		end;

		function Tab:AddLeftGroupbox(Name)
			return Tab:AddGroupbox({ Side = 1; Name = Name; });
		end;

		function Tab:AddRightGroupbox(Name)
			return Tab:AddGroupbox({ Side = 2; Name = Name; });
		end;

		function Tab:AddTabbox(Info)
			local Tabbox = {
				Tabs = {};
			};

			local BoxOuter = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Library.OutlineColor;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 0, 0);
				ZIndex = 2;
				Parent = Info.Side == 1 and LeftSide or RightSide;
			});

			Library:AddToRegistry(BoxOuter, {
				BackgroundColor3 = 'BackgroundColor';
				BorderColor3 = 'OutlineColor';
			});

			local BoxInner = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Color3.new(0, 0, 0);

				Size = UDim2.new(1, -2, 1, -2);
				Position = UDim2.new(0, 1, 0, 1);
				ZIndex = 4;
				Parent = BoxOuter;
			});

			Library:AddToRegistry(BoxInner, {
				BackgroundColor3 = 'BackgroundColor';
			});

			local Highlight = Library:Create('Frame', {
				BackgroundColor3 = Library.AccentColor;
				BorderSizePixel = 0;
				Size = UDim2.new(1, 0, 0, 2);
				ZIndex = 10;
				Parent = BoxInner;
			});

			Library:AddToRegistry(Highlight, {
				BackgroundColor3 = 'AccentColor';
			});

			local TabboxButtons = Library:Create('Frame', {
				BackgroundTransparency = 1;
				Position = UDim2.new(0, 0, 0, 1);
				Size = UDim2.new(1, 0, 0, 18);
				ZIndex = 5;
				Parent = BoxInner;
			});

			Library:Create('UIListLayout', {
				FillDirection = Enum.FillDirection.Horizontal;
				HorizontalAlignment = Enum.HorizontalAlignment.Left;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Parent = TabboxButtons;
			});

			function Tabbox:AddTab(Name)
				local Tab = {};

				local Button = Library:Create('Frame', {
					BackgroundColor3 = Library.MainColor;
					BorderColor3 = Color3.new(0, 0, 0);
					Size = UDim2.new(0.5, 0, 1, 0);
					ZIndex = 6;
					Parent = TabboxButtons;
				});

				Library:AddToRegistry(Button, {
					BackgroundColor3 = 'MainColor';
				});

				local ButtonLabel = Library:CreateLabel({
					Size = UDim2.new(1, 0, 1, 0);
					TextSize = 14;
					Text = Name;
					TextXAlignment = Enum.TextXAlignment.Center;
					ZIndex = 7;
					Parent = Button;
				});

				local Block = Library:Create('Frame', {
					BackgroundColor3 = Library.BackgroundColor;
					BorderSizePixel = 0;
					Position = UDim2.new(0, 0, 1, 0);
					Size = UDim2.new(1, 0, 0, 1);
					Visible = false;
					ZIndex = 9;
					Parent = Button;
				});

				Library:AddToRegistry(Block, {
					BackgroundColor3 = 'BackgroundColor';
				});

				local Container = Library:Create('Frame', {
					BackgroundTransparency = 1;
					Position = UDim2.new(0, 4, 0, 20);
					Size = UDim2.new(1, -4, 1, -20);
					ZIndex = 1;
					Visible = false;
					Parent = BoxInner;
				});

				Library:Create('UIListLayout', {
					FillDirection = Enum.FillDirection.Vertical;
					SortOrder = Enum.SortOrder.LayoutOrder;
					Parent = Container;
				});

				function Tab:Show()
					for _, Tab in next, Tabbox.Tabs do
						Tab:Hide();
					end;

					Container.Visible = true;
					Block.Visible = true;

					Button.BackgroundColor3 = Library.BackgroundColor;
					Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';

					Tab:Resize();
				end;

				function Tab:Hide()
					Container.Visible = false;
					Block.Visible = false;

					Button.BackgroundColor3 = Library.MainColor;
					Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
				end;

				function Tab:Resize()
					local TabCount = 0;

					for _, Tab in next, Tabbox.Tabs do
						TabCount = TabCount + 1;
					end;

					for _, Button in next, TabboxButtons:GetChildren() do
						if not Button:IsA('UIListLayout') then
							Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
						end;
					end;

					if (not Container.Visible) then
						return;
					end;

					local Size = 0;

					for _, Element in next, Tab.Container:GetChildren() do
						if (not Element:IsA('UIListLayout')) and Element.Visible then
							Size = Size + Element.Size.Y.Offset;
						end;
					end;

					BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
				end;

				Button.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
						Tab:Show();
						Tab:Resize();
					elseif Input.UserInputType == Enum.UserInputType.Touch then
						TrackTap(Input, Button:FindFirstAncestorWhichIsA('ScrollingFrame'), function()
							Tab:Show();
							Tab:Resize();
						end);
					end;
				end);

				Tab.Container = Container;
				Tabbox.Tabs[Name] = Tab;

				setmetatable(Tab, BaseGroupbox);

				Tab:AddBlank(3);
				Tab:Resize();

				if #TabboxButtons:GetChildren() == 2 then
					Tab:Show();
				end;

				return Tab;
			end;

			Tab.Tabboxes[Info.Name or ''] = Tabbox;

			return Tabbox;
		end;

		function Tab:AddLeftTabbox(Name)
			return Tab:AddTabbox({ Name = Name, Side = 1; });
		end;

		function Tab:AddRightTabbox(Name)
			return Tab:AddTabbox({ Name = Name, Side = 2; });
		end;

		TabButton.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Tab:ShowTab();
			elseif Input.UserInputType == Enum.UserInputType.Touch then
				TrackTap(Input, TabArea, function()
					Tab:ShowTab();
				end);
			end;
		end);

	Library.TotalTabs = Library.TotalTabs + 1;
		if Library.TotalTabs == 1 then
			Tab:ShowTab();
		end;

		Window.Tabs[Name] = Tab;

		if Library.RememberTab and PendingTab == Name then
			PendingTab = nil;
			Tab:ShowTab();
		end;

		return Tab;
	end;

	local ModalElement = Library:Create('TextButton', {
		BackgroundTransparency = 1;
		Size = UDim2.new(0, 0, 0, 0);
		Visible = true;
		Text = '';
		Modal = false;
		Parent = ScreenGui;
	});

	local TransparencyCache = {};
	local Toggled = false;
	local Fading = false;

	function Library:Toggle()
		if Fading then
			return;
		end;

		local FadeTime = Config.MenuFadeTime;
		Fading = true;
		Toggled = (not Toggled);
		Library.Toggled = Toggled;
		ModalElement.Modal = Toggled;

		if Toggled then

			Outer.Visible = true;

			if Library.ShowCustomCursor and Drawing then
				local Cursor = Drawing.new("Triangle")
				Cursor.Thickness = 1
				Cursor.Filled = true
				Cursor.Visible = true
				local CursorOutline = Drawing.new("Triangle")
				CursorOutline.Thickness = 1
				CursorOutline.Filled = false
				CursorOutline.Color = Color3.new(0, 0, 0)
				CursorOutline.Visible = true

				local OldMouseIconState = InputService.MouseIconEnabled
				RunService:BindToRenderStep("LinoriaCursor", Enum.RenderPriority.Camera.Value - 1, function()
					InputService.MouseIconEnabled = false
					local mPos = InputService:GetMouseLocation()
					local X, Y = mPos.X, mPos.Y
					Cursor.Color = Library.AccentColor
					Cursor.PointA = Vector2.new(X, Y)
					Cursor.PointB = Vector2.new(X + 16, Y + 6)
					Cursor.PointC = Vector2.new(X + 6, Y + 16)
					CursorOutline.PointA = Cursor.PointA
					CursorOutline.PointB = Cursor.PointB
					CursorOutline.PointC = Cursor.PointC
					if not (Toggled and ScreenGui.Parent and Library.ShowCustomCursor) then
						InputService.MouseIconEnabled = OldMouseIconState
						Cursor:Destroy()
						CursorOutline:Destroy()
						RunService:UnbindFromRenderStep("LinoriaCursor")
					end
				end)
			end
		end;

		for _, Option in Options do
			if Option.Type == 'Dropdown' then
				Option:CloseDropdown()
			end
		end

		for _, Desc in next, Outer:GetDescendants() do
			local Properties = {};

			if Desc:IsA('ImageLabel') then
				table.insert(Properties, 'ImageTransparency');
				table.insert(Properties, 'BackgroundTransparency');
			elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox') then
				table.insert(Properties, 'TextTransparency');
			elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
				table.insert(Properties, 'BackgroundTransparency');
			elseif Desc:IsA('UIStroke') then
				table.insert(Properties, 'Transparency');
			end;

			local Cache = TransparencyCache[Desc];

			if (not Cache) then
				Cache = {};
				TransparencyCache[Desc] = Cache;
			end;

			for _, Prop in next, Properties do
				if not Cache[Prop] then
					Cache[Prop] = Desc[Prop];
				end;

				if Cache[Prop] == 1 then
					continue;
				end;

				TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), { [Prop] = Toggled and Cache[Prop] or 1 }):Play();
			end;
		end;

		task.wait(FadeTime);

		Outer.Visible = Toggled;

		Fading = false;
	end

	Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
		if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
			if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value and not InputService:GetFocusedTextBox() then
				task.spawn(Library.Toggle)
			end
		elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
			task.spawn(Library.Toggle)
		end
	end));

	if Library.IsMobile then
		local Dock = Library:Create('Frame', {
			AutomaticSize = Enum.AutomaticSize.XY;
			BackgroundTransparency = 1;
			Position = UDim2.fromScale(0.008, 0.45);
			Size = UDim2.fromOffset(0, 0);
			ZIndex = 200;
			Parent = ScreenGui;
		});

		Library:Create('UIListLayout', {
			FillDirection = Enum.FillDirection.Vertical;
			Padding = UDim.new(0, 8);
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = Dock;
		});

		local function CreateDockButton(Text, Order, Height)
			local ButtonOuter = Library:Create('Frame', {
				BackgroundColor3 = Color3.new(0, 0, 0);
				BorderColor3 = Color3.new(0, 0, 0);
				LayoutOrder = Order;
				Size = UDim2.fromOffset(100, Height);
				ZIndex = 200;
				Parent = Dock;
			});

			local ButtonInner = Library:Create('Frame', {
				BackgroundColor3 = Library.MainColor;
				BorderColor3 = Library.AccentColor;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 1, 0);
				ZIndex = 201;
				Parent = ButtonOuter;
			});

			Library:AddToRegistry(ButtonInner, {
				BackgroundColor3 = 'MainColor';
				BorderColor3 = 'AccentColor';
			});

			local ButtonFill = Library:Create('Frame', {
				BackgroundColor3 = Color3.new(1, 1, 1);
				BorderSizePixel = 0;
				Position = UDim2.new(0, 1, 0, 1);
				Size = UDim2.new(1, -2, 1, -2);
				ZIndex = 202;
				Parent = ButtonInner;
			});

			local Gradient = Library:Create('UIGradient', {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
					ColorSequenceKeypoint.new(1, Library.MainColor),
				});
				Rotation = -90;
				Parent = ButtonFill;
			});

			Library:AddToRegistry(Gradient, {
				Color = function()
					return ColorSequence.new({
						ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
						ColorSequenceKeypoint.new(1, Library.MainColor),
					});
				end
			});

			local Button = Library:Create('TextButton', {
				AutoButtonColor = false;
				BackgroundTransparency = 1;
				Font = Library.Font;
				Size = UDim2.new(1, 0, 1, 0);
				Text = Text;
				TextColor3 = Library.FontColor;
				TextSize = 15;
				TextStrokeTransparency = 0;
				ZIndex = 203;
				Parent = ButtonFill;
			});

			Library:AddToRegistry(Button, {
				TextColor3 = 'FontColor';
			});

			return ButtonOuter, Button, ButtonInner, ButtonFill;
		end;

		local GripOuter, GripButton, GripInner, GripFill = CreateDockButton('Hide', 1, 26);
		local ToggleUIOuter, ToggleUIButton = CreateDockButton('Toggle UI', 2, 38);
		local LockUIOuter, LockUIButton = CreateDockButton(Library.CantDragForced and 'Unlock UI' or 'Lock UI', 3, 38);

		Library.LockUILabel = LockUIButton;

		ToggleUIButton.MouseButton1Click:Connect(function()
			task.spawn(Library.Toggle);
		end);

		LockUIButton.MouseButton1Click:Connect(function()
			Library:SetUILocked(not Library.CantDragForced);
			Library:Notify(Library.CantDragForced and 'Locked UI' or 'Unlocked UI', 2);
		end);

		local function ClampDock(X, Y)
			local Screen = ScreenGui.AbsoluteSize;
			local Size = Dock.AbsoluteSize;

			return math.clamp(X, 0, math.max(0, Screen.X - Size.X)), math.clamp(Y, 0, math.max(0, Screen.Y - Size.Y));
		end;

		local function PlaceDock(X, Y)
			X, Y = ClampDock(X, Y);

			local Screen = ScreenGui.AbsoluteSize;

			if Screen.X > 0 and Screen.Y > 0 then
				Dock.Position = UDim2.fromScale(X / Screen.X, Y / Screen.Y);
			else
				Dock.Position = UDim2.fromOffset(X, Y);
			end;
		end;

		local function KeepDockOnScreen()
			task.defer(function()
				local Position = Dock.AbsolutePosition;
				PlaceDock(Position.X, Position.Y);
			end);
		end;

		local function SetDockHidden(Hidden, Save)
			ToggleUIOuter.Visible = not Hidden;
			LockUIOuter.Visible = not Hidden;

			GripOuter.Size = Hidden and UDim2.fromOffset(30, 30) or UDim2.fromOffset(100, 26);
			GripButton.Text = Hidden and '+' or 'Hide';
			GripButton.TextTransparency = Hidden and 0.35 or 0;
			GripInner.BackgroundTransparency = Hidden and 0.5 or 0;
			GripFill.BackgroundTransparency = Hidden and 0.5 or 0;
			GripOuter.BackgroundTransparency = Hidden and 0.5 or 0;

			if Save then
				UISettings.SideHidden = Hidden;
				SaveUISettings();
			end;

			KeepDockOnScreen();
		end;

		function Library.ApplySideDock()
			SetDockHidden(UISettings.SideHidden == true, false);
		end;

		local function GetPointer(Input)
			if Input.UserInputType == Enum.UserInputType.Touch then
				return Vector2.new(Input.Position.X, Input.Position.Y);
			end;

			return Vector2.new(Mouse.X, Mouse.Y);
		end;

		local function IsPointerDown(Input)
			if Input.UserInputType == Enum.UserInputType.Touch then
				return Input.UserInputState ~= Enum.UserInputState.End and Input.UserInputState ~= Enum.UserInputState.Cancel;
			end;

			return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1);
		end;

		GripButton.InputBegan:Connect(function(Input)
			if Input.UserInputType ~= Enum.UserInputType.Touch and Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return;
			end;

			local Start = GetPointer(Input);
			local DockStart = Dock.AbsolutePosition;
			local Moved = false;

			while IsPointerDown(Input) do
				local Delta = GetPointer(Input) - Start;

				if not Moved and Delta.Magnitude > 8 then
					Moved = true;
					Library.CanDrag = false;
				end;

				if Moved then
					local X, Y = ClampDock(DockStart.X + Delta.X, DockStart.Y + Delta.Y);
					Dock.Position = UDim2.fromOffset(X, Y);
				end;

				RenderStepped:Wait();
			end;

			if Moved then
				local Position = Dock.AbsolutePosition;
				PlaceDock(Position.X, Position.Y);

				if not Library.PickerOpen then
					Library.CanDrag = true;
				end;
			else
				SetDockHidden(ToggleUIOuter.Visible, true);
			end;
		end);

		ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(KeepDockOnScreen);

		Library.ApplySideDock();
	end

	if Config.AutoShow then task.spawn(Library.Toggle) end

	if Library.IsMobile then
		local BaseSize = nil;

		local function FitWindow()
			local Screen = ScreenGui.AbsoluteSize;

			if Screen.X <= 0 or Screen.Y <= 0 then
				return;
			end;

			local Base = BaseSize or Outer.AbsoluteSize;
			BaseSize = Base;

			local OldWidth, OldHeight = Outer.AbsoluteSize.X, Outer.AbsoluteSize.Y;
			local Width = math.min(Base.X, Screen.X - 16);
			local Height = math.min(Base.Y, Screen.Y - 16);
			local Anchor = Outer.AnchorPoint;
			local Position = Outer.Position;

			local Left = Position.X.Scale * Screen.X + Position.X.Offset - Anchor.X * OldWidth;
			local Top = Position.Y.Scale * Screen.Y + Position.Y.Offset - Anchor.Y * OldHeight;

			Left = math.clamp(Left, 8, math.max(8, Screen.X - Width - 8));
			Top = math.clamp(Top, 8, math.max(8, Screen.Y - Height - 8));

			Outer.Size = UDim2.fromOffset(Width, Height);
			Outer.Position = UDim2.fromOffset(Left + Anchor.X * Width, Top + Anchor.Y * Height);
		end;

		task.defer(FitWindow);
		Library:GiveSignal(ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(FitWindow));
	end;

	if not Library.IsMobile and Config.KeybindNotify ~= false then
		Library:Spawn(function()
			local Started = os.clock();

			while not UISettingsFile and os.clock() - Started < 3 do
				task.wait(0.1);
			end;

			task.wait(1);

			if not Library.Unloaded and not Library.HideNotified then
				Library:Notify(('Press %s to hide the menu'):format(Library:GetMenuKeybindText()), 10);
			end;
		end);
	end;

	Window.Holder = Outer;

	Library.Window = Window;
	return Window;
end;

local function OnPlayerChange()
	local PlayerList = GetPlayersString();

	for _, Value in next, table.clone(Options) do
		if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
			Value:SetValues(PlayerList);
		end;
	end;
end;

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange));
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange));

getgenv().Library = Library
return Library
