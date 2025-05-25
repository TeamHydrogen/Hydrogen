-- Variables
local Proxy = require(script.Proxy)
local Signal = require(script.Signal)
local SynchronousTaskManager = require(script.SynchronousTaskManager)
local dataStoreService, memoryStoreService, httpService =
	game:GetService("DataStoreService"), game:GetService("MemoryStoreService"), game:GetService("HttpService")
local Constructor, DataStore = {}, {}
local OpenTask, ReadTask, LockTask, SaveTask, CloseTask, DestroyTask, Lock, Unlock, Load, Save, StartSaveTimer, StopSaveTimer, SaveTimerEnded, StartLockTimer, StopLockTimer, LockTimerEnded, ProcessQueue, SignalConnected, Clone, Reconcile, Compress, Decompress, Encode, Decode, BindToClose
local dataStores, bindToClose, active = {}, {}, true
local characters = {
	[0] = "0",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"a",
	"b",
	"c",
	"d",
	"e",
	"f",
	"g",
	"h",
	"i",
	"j",
	"k",
	"l",
	"m",
	"n",
	"o",
	"p",
	"q",
	"r",
	"s",
	"t",
	"u",
	"v",
	"w",
	"x",
	"y",
	"z",
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I",
	"J",
	"K",
	"L",
	"M",
	"N",
	"O",
	"P",
	"Q",
	"R",
	"S",
	"T",
	"U",
	"V",
	"W",
	"X",
	"Y",
	"Z",
	"!",
	"$",
	"%",
	"&",
	"'",
	",",
	".",
	"/",
	":",
	";",
	"=",
	"?",
	"@",
	"[",
	"]",
	"^",
	"_",
	"`",
	"{",
	"}",
	"~",
}
local bytes = {}
for i = 0, #characters do
	bytes[string.byte(characters[i])] = i
end
local base = #characters + 1

-- Types
export type Constructor = {
	new: (name: string, scope: string, key: string?) -> DataStore,
	hidden: (name: string, scope: string, key: string?) -> DataStore,
	find: (name: string, scope: string, key: string?) -> DataStore?,
	Response: { Success: string, Saved: string, Locked: string, State: string, Error: string },
}

export type DataStore = {
	[any]: any,
	Value: any,
	Metadata: { [string]: any },
	UserIds: { any },
	SaveInterval: number,
	SaveDelay: number,
	LockInterval: number,
	LockAttempts: number,
	SaveOnClose: boolean,
	Id: string,
	UniqueId: string,
	Key: string,
	State: boolean?,
	Hidden: boolean,
	AttemptsRemaining: number,
	CreatedTime: number,
	UpdatedTime: number,
	Version: string,
	CompressedValue: string,
	StateChanged: Signal.Signal,
	Saving: Signal.Signal,
	Saved: Signal.Signal,
	AttemptsChanged: Signal.Signal,
	ProcessQueue: Signal.Signal,
	Open: (self: DataStore, template: any?) -> (string, any),
	Read: (self: DataStore, template: any?) -> (string, any),
	Save: (self: DataStore) -> (string, any),
	Close: (self: DataStore) -> (string, any),
	Destroy: (self: DataStore) -> (string, any),
	Queue: (self: DataStore, value: any, expiration: number?, priority: number?) -> (string, any),
	Remove: (self: DataStore, id: string) -> (string, any),
	Clone: (self: DataStore) -> any,
	Reconcile: (self: DataStore, template: any) -> (),
	Usage: (self: DataStore) -> (number, number),
}

-- Constructor
Constructor.new = function(name, scope, key)
	if key == nil then
		key, scope = scope, "global"
	end
	local id = name .. "/" .. scope .. "/" .. key
	if dataStores[id] ~= nil then
		return dataStores[id]
	end
	local proxy, dataStore = Proxy.new(DataStore, {
		Metadata = {},
		UserIds = {},
		SaveInterval = 30,
		SaveDelay = 0,
		LockInterval = 60,
		LockAttempts = 5,
		SaveOnClose = true,
		Id = id,
		UniqueId = httpService:GenerateGUID(false),
		Key = key,
		State = false,
		Hidden = false,
		AttemptsRemaining = 0,
		CreatedTime = 0,
		UpdatedTime = 0,
		Version = "",
		CompressedValue = "",
		StateChanged = Signal.new(),
		Saving = Signal.new(),
		Saved = Signal.new(),
		AttemptsChanged = Signal.new(),
		ProcessQueue = Signal.new(),
	})
	dataStore.TaskManager = SynchronousTaskManager.new()
	dataStore.LockTime = -math.huge
	dataStore.SaveTime = -math.huge
	dataStore.ActiveLockInterval = 0
	dataStore.ProcessingQueue = false
	dataStore.DataStore = dataStoreService:GetDataStore(name, scope)
	dataStore.MemoryStore = memoryStoreService:GetSortedMap(id)
	dataStore.Queue = memoryStoreService:GetQueue(id)
	dataStore.Options = Instance.new("DataStoreSetOptions")
	dataStore.__public.ProcessQueue.DataStore = proxy
	dataStore.__public.ProcessQueue.Connected = SignalConnected
	dataStores[id] = proxy
	if active == true then
		bindToClose[dataStore.__public.UniqueId] = proxy
	end
	return proxy
end

Constructor.hidden = function(name, scope, key)
	if key == nil then
		key, scope = scope, "global"
	end
	local id = name .. "/" .. scope .. "/" .. key
	local proxy, dataStore = Proxy.new(DataStore, {
		Metadata = {},
		UserIds = {},
		SaveInterval = 30,
		SaveDelay = 0,
		LockInterval = 60,
		LockAttempts = 5,
		SaveOnClose = true,
		Id = id,
		UniqueId = httpService:GenerateGUID(false),
		Key = key,
		State = false,
		Hidden = true,
		AttemptsRemaining = 0,
		CreatedTime = 0,
		UpdatedTime = 0,
		Version = "",
		CompressedValue = "",
		StateChanged = Signal.new(),
		Saving = Signal.new(),
		Saved = Signal.new(),
		AttemptsChanged = Signal.new(),
		ProcessQueue = Signal.new(),
	})
	dataStore.TaskManager = SynchronousTaskManager.new()
	dataStore.LockTime = -math.huge
	dataStore.SaveTime = -math.huge
	dataStore.ActiveLockInterval = 0
	dataStore.ProcessingQueue = false
	dataStore.DataStore = dataStoreService:GetDataStore(name, scope)
	dataStore.MemoryStore = memoryStoreService:GetSortedMap(id)
	dataStore.Queue = memoryStoreService:GetQueue(id)
	dataStore.Options = Instance.new("DataStoreSetOptions")
	dataStore.__public.ProcessQueue.DataStore = proxy
	dataStore.__public.ProcessQueue.Connected = SignalConnected
	if active == true then
		bindToClose[dataStore.__public.UniqueId] = proxy
	end
	return proxy
end

Constructor.find = function(name, scope, key)
	if key == nil then
		key, scope = scope, "global"
	end
	local id = name .. "/" .. scope .. "/" .. key
	return dataStores[id]
end

Constructor.Response = { Success = "Success", Saved = "Saved", Locked = "Locked", State = "State", Error = "Error" }

-- DataStore
DataStore.__tostring = function(proxy)
	return "DataStore"
end

DataStore.__shared = {
	Open = function(proxy, template)
		local dataStore = getmetatable(proxy)
		if type(dataStore) ~= "table" or dataStore.__shared ~= DataStore.__shared then
			error("Attempt to Open failed: Passed value is not a DataStore", 3)
		end
		if dataStore.__public.State == nil then
			return "State", "Destroyed"
		end
		local synchronousTask = dataStore.TaskManager:FindFirst(OpenTask)
		if synchronousTask ~= nil then
			return synchronousTask:Wait(template)
		end
		if dataStore.TaskManager:FindLast(DestroyTask) ~= nil then
			return "State", "Destroying"
		end
		if dataStore.__public.State == true and dataStore.TaskManager:FindLast(CloseTask) == nil then
			if dataStore.__public.Value == nil then
				dataStore.__public.Value = Clone(template)
			elseif type(dataStore.__public.Value) == "table" and type(template) == "table" then
				Reconcile(dataStore.__public.Value, template)
			end
			return "Success"
		end
		return dataStore.TaskManager:InsertBack(OpenTask, proxy):Wait(template)
	end,
	Read = function(proxy, template)
		local dataStore = getmetatable(proxy)
		if type(dataStore) ~= "table" or dataStore.__shared ~= DataStore.__shared then
			error("Attempt to Read failed: Passed value is not a DataStore", 3)
		end
		local synchronousTask = dataStore.TaskManager:FindFirst(ReadTask)
		if synchronousTask ~= nil then
			return synchronousTask:Wait(template)
		end
		if dataStore.__public.State == true and dataStore.TaskManager:FindLast(CloseTask) == nil then
			return "State", "Open"
		end
		return dataStore.TaskManager:InsertBack(ReadTask, proxy):Wait(template)
	end,
	Save = function(proxy)
		local dataStore = getmetatable(proxy)
		if type(dataStore) ~= "table" or dataStore.__shared ~= DataStore.__shared then
			error("Attempt to Save failed: Passed value is not a DataStore", 3)
		end
		if dataStore.__public.State == false then
			return "State", "Closed"
		end
		if dataStore.__public.State == nil then
			return "State", "Destroyed"
		end
		local synchronousTask = dataStore.TaskManager:FindFirst(SaveTask)
		if synchronousTask ~= nil then
			return synchronousTask:Wait()
		end
		if dataStore.TaskManager:FindLast(CloseTask) ~= nil then
			return "State", "Closing"
		end
		if dataStore.TaskManager:FindLast(DestroyTask) ~= nil then
			return "State", "Destroying"
		end
		return dataStore.TaskManager:InsertBack(SaveTask, proxy):Wait()
	end,
	Close = function(proxy)
		local dataStore = getmetatable(proxy)
		if type(dataStore) ~= "table" or dataStore.__shared ~= DataStore.__shared then
			error("Attempt to Close failed: Passed value is not a DataStore", 3)
		end
		if dataStore.__public.State == nil then
			return "Success"
		end
		local synchronousTask = dataStore.TaskManager:FindFirst(CloseTask)
		if synchronousTask ~= nil then
			return synchronousTask:Wait()
		end
		if dataStore.__public.State == false and dataStore.TaskManager:FindLast(OpenTask) == nil then
			return "Success"
		end
		local synchronousTask = dataStore.TaskManager:FindFirst(DestroyTask)
		if synchronousTask ~= nil then
			return synchronousTask:Wait()
		end
		StopLockTimer(dataStore)
		StopSaveTimer(dataStore)
		return dataStore.TaskManager:InsertBack(CloseTask, proxy):Wait()
	end,
	Destroy = function(proxy)
		local dataStore = getmetatable(proxy)
		if type(dataStore) ~= "table" or dataStore.__shared ~= DataStore.__shared then
			error("Attempt to Destroy failed: Passed value is not a DataStore", 3)
		end
		if dataStore.__public.State == nil then
			return "Success"
		end
		dataStores[dataStore.__public.Id] = nil
		StopLockTimer(dataStore)
		StopSaveTimer(dataStore)
		return (dataStore.TaskManager:FindFirst(DestroyTask) or dataStore.TaskManager:InsertBack(DestroyTask, proxy)):Wait()
	end,
	Queue = function(proxy, value, expiration, priority)
		local dataStore = getmetatable(proxy)
		if type(dataStore) ~= "table" or dataStore.__shared ~= DataStore.__shared then
			error("Attempt to Queue failed: Passed value is not a DataStore", 3)
		end
		if expiration ~= nil and type(expiration) ~= "number" then
			error("Attempt to Queue failed: Passed value is not nil or number", 3)
		end
		if priority ~= nil and type(priority) ~= "number" then
			error("Attempt to Queue failed: Passed value is not nil or number", 3)
		end
		local success, errorMessage
		for i = 1, 3 do
			if i > 1 then
				task.wait(1)
			end
			success, errorMessage =
				pcall(dataStore.Queue.AddAsync, dataStore.Queue, value, expiration or 604800, priority)
			if success == true then
				return "Success"
			end
		end
		return "Error", errorMessage
	end,
	Remove = function(proxy, id)
		local dataStore = getmetatable(proxy)
		if type(dataStore) ~= "table" or dataStore.__shared ~= DataStore.__shared then
			error("Attempt to Remove failed: Passed value is not a DataStore", 3)
		end
		if type(id) ~= "string" then
			error("Attempt to RemoveQueue failed: Passed value is not a string", 3)
		end
		local success, errorMessage
		for i = 1, 3 do
			if i > 1 then
				task.wait(1)
			end
			success, errorMessage = pcall(dataStore.Queue.RemoveAsync, dataStore.Queue, id)
			if success == true then
				return "Success"
			end
		end
		return "Error", errorMessage
	end,
	Clone = function(proxy)
		local dataStore = getmetatable(proxy)
		if type(dataStore) ~= "table" or dataStore.__shared ~= DataStore.__shared then
			error("Attempt to Clone failed: Passed value is not a DataStore", 3)
		end
		return Clone(dataStore.__public.Value)
	end,
	Reconcile = function(proxy, template)
		local dataStore = getmetatable(proxy)
		if type(dataStore) ~= "table" or dataStore.__shared ~= DataStore.__shared then
			error("Attempt to Reconcile failed: Passed value is not a DataStore", 3)
		end
		if dataStore.__public.Value == nil then
			dataStore.__public.Value = Clone(template)
		elseif type(dataStore.__public.Value) == "table" and type(template) == "table" then
			Reconcile(dataStore.__public.Value, template)
		end
	end,
	Usage = function(proxy)
		local dataStore = getmetatable(proxy)
		if type(dataStore) ~= "table" or dataStore.__shared ~= DataStore.__shared then
			error("Attempt to Usage failed: Passed value is not a DataStore", 3)
		end
		if dataStore.__public.Value == nil then
			return 0, 0
		end
		if type(dataStore.__public.Metadata.Compress) ~= "table" then
			local characters = #httpService:JSONEncode(dataStore.__public.Value)
			return characters, characters / 4194303
		else
			local level = dataStore.__public.Metadata.Compress.Level or 2
			local decimals = 10 ^ (dataStore.__public.Metadata.Compress.Decimals or 3)
			local safety = if dataStore.__public.Metadata.Compress.Safety == nil
				then true
				else dataStore.__public.Metadata.Compress.Safety
			dataStore.__public.CompressedValue = Compress(dataStore.__public.Value, level, decimals, safety)
			local characters = #httpService:JSONEncode(dataStore.__public.CompressedValue)
			return characters, characters / 4194303
		end
	end,
}

DataStore.__set = {
	Metadata = function(proxy, dataStore, value)
		if type(value) ~= "table" then
			error("Attempt to set Metadata failed: Passed value is not a table", 3)
		end
		dataStore.__public.Metadata = value
	end,
	UserIds = function(proxy, dataStore, value)
		if type(value) ~= "table" then
			error("Attempt to set UserIds failed: Passed value is not a table", 3)
		end
		dataStore.__public.UserIds = value
	end,
	SaveInterval = function(proxy, dataStore, value)
		if type(value) ~= "number" then
			error("Attempt to set SaveInterval failed: Passed value is not a number", 3)
		end
		if value < 10 and value ~= 0 then
			error("Attempt to set SaveInterval failed: Passed value is less then 10 and not 0", 3)
		end
		if value > 1000 then
			error("Attempt to set SaveInterval failed: Passed value is more then 1000", 3)
		end
		if value == dataStore.__public.SaveInterval then
			return
		end
		dataStore.__public.SaveInterval = value
		if dataStore.__public.State ~= true then
			return
		end
		if value == 0 then
			StopSaveTimer(dataStore)
		elseif
			dataStore.TaskManager:FindLast(CloseTask) == nil and dataStore.TaskManager:FindLast(DestroyTask) == nil
		then
			StartSaveTimer(proxy)
		end
	end,
	SaveDelay = function(_proxy, dataStore, value)
		if type(value) ~= "number" then
			error("Attempt to set SaveDelay failed: Passed value is not a number", 3)
		end
		if value < 0 then
			error("Attempt to set SaveDelay failed: Passed value is less then 0", 3)
		end
		if value > 10 then
			error("Attempt to set SaveDelay failed: Passed value is more then 10", 3)
		end
		dataStore.__public.SaveDelay = value
	end,
	LockInterval = function(_proxy, dataStore, value)
		if type(value) ~= "number" then
			error("Attempt to set LockInterval failed: Passed value is not a number", 3)
		end
		if value < 10 then
			error("Attempt to set LockInterval failed: Passed value is less then 10", 3)
		end
		if value > 1000 then
			error("Attempt to set LockInterval failed: Passed value is more then 1000", 3)
		end
		dataStore.__public.LockInterval = value
	end,
	LockAttempts = function(proxy, dataStore, value)
		if type(value) ~= "number" then
			error("Attempt to set LockAttempts failed: Passed value is not a number", 3)
		end
		if value < 1 then
			error("Attempt to set LockAttempts failed: Passed value is less then 1", 3)
		end
		if value > 100 then
			error("Attempt to set LockAttempts failed: Passed value is more then 100", 3)
		end
		dataStore.__public.LockAttempts = value
	end,
	SaveOnClose = function(proxy, dataStore, value)
		if type(value) ~= "boolean" then
			error("Attempt to set SaveOnClose failed: Passed value is not a boolean", 3)
		end
		dataStore.__public.SaveOnClose = value
	end,
	Id = false,
	UniqueId = false,
	Key = false,
	State = false,
	Hidden = false,
	AttemptsRemaining = false,
	CreatedTime = false,
	UpdatedTime = false,
	Version = false,
	CompressedValue = false,
	StateChanged = false,
	Saving = false,
	Saved = false,
	AttemptsChanged = false,
	ProcessQueue = false,
}

-- Functions
OpenTask = function(runningTask, proxy)
	local dataStore = getmetatable(proxy)
	local response, responseData = Lock(dataStore, 3)
	if response ~= "Success" then
		for thread in runningTask:Iterate() do
			task.defer(thread, response, responseData)
		end
		return
	end
	local response, responseData = Load(dataStore, 3)
	if response ~= "Success" then
		Unlock(dataStore, 3)
		for thread in runningTask:Iterate() do
			task.defer(thread, response, responseData)
		end
		return
	end
	dataStore.__public.State = true
	if dataStore.TaskManager:FindLast(CloseTask) == nil and dataStore.TaskManager:FindLast(DestroyTask) == nil then
		StartSaveTimer(proxy)
		StartLockTimer(proxy)
	end
	for thread, template in runningTask:Iterate() do
		if dataStore.__public.Value == nil then
			dataStore.__public.Value = Clone(template)
		elseif type(dataStore.__public.Value) == "table" and type(template) == "table" then
			Reconcile(dataStore.__public.Value, template)
		end
		task.defer(thread, response)
	end
	if dataStore.ProcessingQueue == false and dataStore.__public.ProcessQueue.Connections > 0 then
		task.defer(ProcessQueue, proxy)
	end
	dataStore.__public.StateChanged:Fire(true, proxy)
end

ReadTask = function(runningTask, proxy)
	local dataStore = getmetatable(proxy)
	if dataStore.__public.State == true then
		for thread in runningTask:Iterate() do
			task.defer(thread, "State", "Open")
		end
		return
	end
	local response, responseData = Load(dataStore, 3)
	if response ~= "Success" then
		for thread in runningTask:Iterate() do
			task.defer(thread, response, responseData)
		end
		return
	end
	for thread, template in runningTask:Iterate() do
		if dataStore.__public.Value == nil then
			dataStore.__public.Value = Clone(template)
		elseif type(dataStore.__public.Value) == "table" and type(template) == "table" then
			Reconcile(dataStore.__public.Value, template)
		end
		task.defer(thread, response)
	end
end

LockTask = function(runningTask, proxy)
	local dataStore = getmetatable(proxy)
	local attemptsRemaining = dataStore.__public.AttemptsRemaining
	local response, responseData = Lock(dataStore, 3)
	if response ~= "Success" then
		dataStore.__public.AttemptsRemaining -= 1
	end
	if dataStore.__public.AttemptsRemaining ~= attemptsRemaining then
		dataStore.__public.AttemptsChanged:Fire(dataStore.__public.AttemptsRemaining, proxy)
	end
	if dataStore.__public.AttemptsRemaining > 0 then
		if dataStore.TaskManager:FindLast(CloseTask) == nil and dataStore.TaskManager:FindLast(DestroyTask) == nil then
			StartLockTimer(proxy)
		end
	else
		dataStore.__public.State = false
		StopLockTimer(dataStore)
		StopSaveTimer(dataStore)
		if dataStore.__public.SaveOnClose == true then
			Save(proxy, 3)
		end
		Unlock(dataStore, 3)
		dataStore.__public.StateChanged:Fire(false, proxy)
	end
	for thread in runningTask:Iterate() do
		task.defer(thread, response, responseData)
	end
end

SaveTask = function(runningTask, proxy)
	local dataStore = getmetatable(proxy)
	if dataStore.__public.State == false then
		for thread in runningTask:Iterate() do
			task.defer(thread, "State", "Closed")
		end
		return
	end
	StopSaveTimer(dataStore)
	runningTask:End()
	local response, responseData = Save(proxy, 3)
	if dataStore.TaskManager:FindLast(CloseTask) == nil and dataStore.TaskManager:FindLast(DestroyTask) == nil then
		StartSaveTimer(proxy)
	end
	for thread in runningTask:Iterate() do
		task.defer(thread, response, responseData)
	end
end

CloseTask = function(runningTask, proxy)
	local dataStore = getmetatable(proxy)
	if dataStore.__public.State == false then
		for thread in runningTask:Iterate() do
			task.defer(thread, "Success")
		end
		return
	end
	dataStore.__public.State = false
	local response, responseData = nil, nil
	if dataStore.__public.SaveOnClose == true then
		response, responseData = Save(proxy, 3)
	end
	Unlock(dataStore, 3)
	dataStore.__public.StateChanged:Fire(false, proxy)
	if response == "Saved" then
		for thread in runningTask:Iterate() do
			task.defer(thread, response, responseData)
		end
	else
		for thread in runningTask:Iterate() do
			task.defer(thread, "Success")
		end
	end
end

DestroyTask = function(runningTask, proxy)
	local dataStore = getmetatable(proxy)
	local response, responseData = nil, nil
	if dataStore.__public.State == false then
		dataStore.__public.State = nil
	else
		dataStore.__public.State = nil
		if dataStore.__public.SaveOnClose == true then
			response, responseData = Save(proxy, 3)
		end
		Unlock(dataStore, 3)
	end
	dataStore.__public.StateChanged:Fire(nil, proxy)
	dataStore.__public.StateChanged:DisconnectAll()
	dataStore.__public.Saving:DisconnectAll()
	dataStore.__public.Saved:DisconnectAll()
	dataStore.__public.AttemptsChanged:DisconnectAll()
	dataStore.__public.ProcessQueue:DisconnectAll()
	bindToClose[dataStore.__public.UniqueId] = nil
	if response == "Saved" then
		for thread in runningTask:Iterate() do
			task.defer(thread, response, responseData)
		end
	else
		for thread in runningTask:Iterate() do
			task.defer(thread, "Success")
		end
	end
end

Lock = function(dataStore, attempts)
	local success, value, id, lockTime, lockInterval, lockAttempts =
		nil, nil, nil, nil, dataStore.__public.LockInterval, dataStore.__public.LockAttempts
	for i = 1, attempts do
		if i > 1 then
			task.wait(1)
		end
		lockTime = os.clock()
		success, value = pcall(dataStore.MemoryStore.UpdateAsync, dataStore.MemoryStore, "Id", function(value)
			id = value
			return if id == nil or id == dataStore.__public.UniqueId then dataStore.__public.UniqueId else nil
		end, lockInterval * lockAttempts + 30)
		if success == true then
			break
		end
	end
	if success == false then
		return "Error", value
	end
	if value == nil then
		return "Locked", id
	end
	dataStore.LockTime = lockTime + lockInterval * lockAttempts
	dataStore.ActiveLockInterval = lockInterval
	dataStore.__public.AttemptsRemaining = lockAttempts
	return "Success"
end

Unlock = function(dataStore, attempts)
	local success, value, id = nil, nil, nil
	for i = 1, attempts do
		if i > 1 then
			task.wait(1)
		end
		success, value = pcall(dataStore.MemoryStore.UpdateAsync, dataStore.MemoryStore, "Id", function(value)
			id = value
			return if id == dataStore.__public.UniqueId then dataStore.__public.UniqueId else nil
		end, 0)
		if success == true then
			break
		end
	end
	if success == false then
		return "Error", value
	end
	if value == nil and id ~= nil then
		return "Locked", id
	end
	return "Success"
end

Load = function(dataStore, attempts)
	local success, value, info = nil, nil, nil
	for i = 1, attempts do
		if i > 1 then
			task.wait(1)
		end
		success, value, info = pcall(dataStore.DataStore.GetAsync, dataStore.DataStore, dataStore.__public.Key)
		if success == true then
			break
		end
	end
	if success == false then
		return "Error", value
	end
	if info == nil then
		dataStore.__public.Metadata, dataStore.__public.UserIds, dataStore.__public.CreatedTime, dataStore.__public.UpdatedTime, dataStore.__public.Version =
			{}, {}, 0, 0, ""
	else
		dataStore.__public.Metadata, dataStore.__public.UserIds, dataStore.__public.CreatedTime, dataStore.__public.UpdatedTime, dataStore.__public.Version =
			info:GetMetadata(), info:GetUserIds(), info.CreatedTime, info.UpdatedTime, info.Version
	end
	if type(dataStore.__public.Metadata.Compress) ~= "table" then
		dataStore.__public.Value = value
	else
		dataStore.__public.CompressedValue = value
		local decimals = 10 ^ (dataStore.__public.Metadata.Compress.Decimals or 3)
		dataStore.__public.Value = Decompress(dataStore.__public.CompressedValue, decimals)
	end
	return "Success"
end

Save = function(proxy, attempts)
	local dataStore = getmetatable(proxy)
	local deltaTime = os.clock() - dataStore.SaveTime
	if deltaTime < dataStore.__public.SaveDelay then
		task.wait(dataStore.__public.SaveDelay - deltaTime)
	end
	dataStore.__public.Saving:Fire(dataStore.__public.Value, proxy)
	local success, value, info = nil, nil, nil
	if dataStore.__public.Value == nil then
		for i = 1, attempts do
			if i > 1 then
				task.wait(1)
			end
			success, value, info = pcall(dataStore.DataStore.RemoveAsync, dataStore.DataStore, dataStore.__public.Key)
			if success == true then
				break
			end
		end
		if success == false then
			dataStore.__public.Saved:Fire("Error", value, proxy)
			return "Error", value
		end
		dataStore.__public.Metadata, dataStore.__public.UserIds, dataStore.__public.CreatedTime, dataStore.__public.UpdatedTime, dataStore.__public.Version =
			{}, {}, 0, 0, ""
	elseif type(dataStore.__public.Metadata.Compress) ~= "table" then
		dataStore.Options:SetMetadata(dataStore.__public.Metadata)
		for i = 1, attempts do
			if i > 1 then
				task.wait(1)
			end
			success, value = pcall(
				dataStore.DataStore.SetAsync,
				dataStore.DataStore,
				dataStore.__public.Key,
				dataStore.__public.Value,
				dataStore.__public.UserIds,
				dataStore.Options
			)
			if success == true then
				break
			end
		end
		if success == false then
			dataStore.__public.Saved:Fire("Error", value, proxy)
			return "Error", value
		end
		dataStore.__public.Version = value
	else
		local level = dataStore.__public.Metadata.Compress.Level or 2
		local decimals = 10 ^ (dataStore.__public.Metadata.Compress.Decimals or 3)
		local safety = if dataStore.__public.Metadata.Compress.Safety == nil
			then true
			else dataStore.__public.Metadata.Compress.Safety
		dataStore.__public.CompressedValue = Compress(dataStore.__public.Value, level, decimals, safety)
		dataStore.Options:SetMetadata(dataStore.__public.Metadata)
		for i = 1, attempts do
			if i > 1 then
				task.wait(1)
			end
			success, value = pcall(
				dataStore.DataStore.SetAsync,
				dataStore.DataStore,
				dataStore.__public.Key,
				dataStore.__public.CompressedValue,
				dataStore.__public.UserIds,
				dataStore.Options
			)
			if success == true then
				break
			end
		end
		if success == false then
			dataStore.__public.Saved:Fire("Error", value, proxy)
			return "Error", value
		end
		dataStore.Version = value
	end
	dataStore.SaveTime = os.clock()
	dataStore.__public.Saved:Fire("Saved", dataStore.__public.Value, proxy)
	return "Saved", dataStore.__public.Value
end

StartSaveTimer = function(proxy)
	local dataStore = getmetatable(proxy)
	if dataStore.SaveThread ~= nil then
		task.cancel(dataStore.SaveThread)
	end
	if dataStore.__public.SaveInterval == 0 then
		return
	end
	dataStore.SaveThread = task.delay(dataStore.__public.SaveInterval, SaveTimerEnded, proxy)
end

StopSaveTimer = function(dataStore)
	if dataStore.SaveThread == nil then
		return
	end
	task.cancel(dataStore.SaveThread)
	dataStore.SaveThread = nil
end

SaveTimerEnded = function(proxy)
	local dataStore = getmetatable(proxy)
	dataStore.SaveThread = nil
	if dataStore.TaskManager:FindLast(SaveTask) ~= nil then
		return
	end
	dataStore.TaskManager:InsertBack(SaveTask, proxy)
end

StartLockTimer = function(proxy)
	local dataStore = getmetatable(proxy)
	if dataStore.LockThread ~= nil then
		task.cancel(dataStore.LockThread)
	end
	local startTime = dataStore.LockTime - dataStore.__public.AttemptsRemaining * dataStore.ActiveLockInterval
	dataStore.LockThread = task.delay(startTime - os.clock() + dataStore.ActiveLockInterval, LockTimerEnded, proxy)
end

StopLockTimer = function(dataStore)
	if dataStore.LockThread == nil then
		return
	end
	task.cancel(dataStore.LockThread)
	dataStore.LockThread = nil
end

LockTimerEnded = function(proxy)
	local dataStore = getmetatable(proxy)
	dataStore.LockThread = nil
	if dataStore.TaskManager:FindFirst(LockTask) ~= nil then
		return
	end
	dataStore.TaskManager:InsertBack(LockTask, proxy)
end

ProcessQueue = function(proxy)
	local dataStore = getmetatable(proxy)
	if dataStore.__public.State ~= true then
		return
	end
	if dataStore.__public.ProcessQueue.Connections == 0 then
		return
	end
	if dataStore.ProcessingQueue == true then
		return
	end
	dataStore.ProcessingQueue = true
	while true do
		local success, values, id = pcall(dataStore.Queue.ReadAsync, dataStore.Queue, 100, false, 30)
		if dataStore.__public.State ~= true then
			break
		end
		if dataStore.__public.ProcessQueue.Connections == 0 then
			break
		end
		if success == true and id ~= nil then
			dataStore.__public.ProcessQueue:Fire(id, values, proxy)
		end
	end
	dataStore.ProcessingQueue = false
end

SignalConnected = function(connected, signal)
	if connected == false then
		return
	end
	ProcessQueue(signal.DataStore)
end

Clone = function(original)
	if type(original) ~= "table" then
		return original
	end
	local clone = {}
	for index, value in original do
		clone[index] = Clone(value)
	end
	return clone
end

Reconcile = function(target, template)
	for index, value in template do
		if type(index) == "number" then
			continue
		end
		if target[index] == nil then
			target[index] = Clone(value)
		elseif type(target[index]) == "table" and type(value) == "table" then
			Reconcile(target[index], value)
		end
	end
end

Compress = function(value, level, decimals, safety)
	local data = {}
	if type(value) == "boolean" then
		table.insert(data, if value == false then "-" else "+")
	elseif type(value) == "number" then
		if value % 1 == 0 then
			table.insert(data, if value < 0 then "<" .. Encode(-value) else ">" .. Encode(value))
		else
			table.insert(
				data,
				if value < 0
					then "(" .. Encode(math.round(-value * decimals))
					else ")" .. Encode(math.round(value * decimals))
			)
		end
	elseif type(value) == "string" then
		if safety == true then
			value = value:gsub("", " ")
		end
		table.insert(data, "#" .. value .. "")
	elseif type(value) == "table" then
		if #value > 0 and level == 2 then
			table.insert(data, "|")
			for i = 1, #value do
				table.insert(data, Compress(value[i], level, decimals, safety))
			end
			table.insert(data, "")
		else
			table.insert(data, "*")
			for key, tableValue in value do
				table.insert(data, Compress(key, level, decimals, safety))
				table.insert(data, Compress(tableValue, level, decimals, safety))
			end
			table.insert(data, "")
		end
	end
	return table.concat(data)
end

Decompress = function(value, decimals, index)
	local i1, i2, dataType, data = value:find("([-+<>()#|*])", index or 1)
	if dataType == "-" then
		return false, i2
	elseif dataType == "+" then
		return true, i2
	elseif dataType == "<" then
		i1, i2, data = value:find("([^-+<>()#|*]*)", i2 + 1)
		return -Decode(data), i2
	elseif dataType == ">" then
		i1, i2, data = value:find("([^-+<>()#|*]*)", i2 + 1)
		return Decode(data), i2
	elseif dataType == "(" then
		i1, i2, data = value:find("([^-+<>()#|*]*)", i2 + 1)
		return -Decode(data) / decimals, i2
	elseif dataType == ")" then
		i1, i2, data = value:find("([^-+<>()#|*]*)", i2 + 1)
		return Decode(data) / decimals, i2
	elseif dataType == "#" then
		i1, i2, data = value:find("(.-)", i2 + 1)
		return data, i2
	elseif dataType == "|" then
		local array = {}
		while true do
			data, i2 = Decompress(value, decimals, i2 + 1)
			if data == nil then
				break
			end
			table.insert(array, data)
		end
		return array, i2
	elseif dataType == "*" then
		local dictionary, key = {}, nil
		while true do
			key, i2 = Decompress(value, decimals, i2 + 1)
			if key == nil then
				break
			end
			data, i2 = Decompress(value, decimals, i2 + 1)
			dictionary[key] = data
		end
		return dictionary, i2
	end
	return nil, i2
end

Encode = function(value)
	if value == 0 then
		return "0"
	end
	local data = {}
	while value > 0 do
		table.insert(data, characters[value % base])
		value = math.floor(value / base)
	end
	return table.concat(data)
end

Decode = function(value)
	local number, power, data = 0, 1, { string.byte(value, 1, #value) }
	for i, code in data do
		number += bytes[code] * power
		power *= base
	end
	return number
end

BindToClose = function()
	active = false
	for _uniqueId, proxy in bindToClose do
		local dataStore = getmetatable(proxy)
		if dataStore.__public.State == nil then
			continue
		end
		dataStores[dataStore.__public.Id] = nil
		StopLockTimer(dataStore)
		StopSaveTimer(dataStore)
		if dataStore.TaskManager:FindFirst(DestroyTask) == nil then
			dataStore.TaskManager:InsertBack(DestroyTask, proxy)
		end
	end
	while next(bindToClose) ~= nil do
		task.wait()
	end
end

-- Events
game:BindToClose(BindToClose)

return table.freeze(Constructor) :: Constructor
