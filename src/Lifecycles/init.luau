local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Logging = require(script.Parent.Logging)
local FunctionLib = require(script.Parent.Util.FunctionLib)

local Lifecycles = {}
local CustomCycles = {
	Server = {},
	Client = {},
}

local LifecyclesEvents = {
	PlayerAdded = Players.PlayerAdded,
	PlayerRemoving = Players.PlayerRemoving,
	Heartbeat = RunService.Heartbeat,
	PostSimulation = RunService.PostSimulation,
	PreSimulation = RunService.PreSimulation,
}

local function RunCycles(Modules, Callback, ...)
	for _, Module in Modules do
		local Args = ...

		task.spawn(function()
			if require(Module)[Callback] then
				require(Module)[Callback](Args)
			end
		end)
	end
end

function Lifecycles.Run(Modules: { any }, PossibleLifecycles: { typeof(LifecyclesEvents) }?)
	if not PossibleLifecycles then
		return
	end

	local TotalLifecycles = LifecyclesEvents

	local CycleNamesServer = {}
	local CycleNamesClient = {}

	for Name, _ in CustomCycles.Client do
		table.insert(CycleNamesServer, Name)
	end

	if RunService:IsServer() then
		TotalLifecycles = FunctionLib:MergeDictionary(TotalLifecycles, CustomCycles.Server)

		for Name, _ in CustomCycles.Server do
			table.insert(CycleNamesServer, Name)
		end

		PossibleLifecycles = FunctionLib:MergeDictionary(PossibleLifecycles, CycleNamesServer)
	end

	if RunService:IsClient() then
		local ClientCycles = {
			CharacterAdded = Players.LocalPlayer.CharacterAdded,
			CharacterRemoving = Players.LocalPlayer.CharacterRemoving,
			RenderStepped = RunService.RenderStepped,
		}

		TotalLifecycles = FunctionLib:MergeDictionary(TotalLifecycles, ClientCycles)
		TotalLifecycles = FunctionLib:MergeDictionary(TotalLifecycles, CustomCycles.Client)

		for Name, _ in CustomCycles.Client do
			table.insert(CycleNamesClient, Name)
		end

		PossibleLifecycles = FunctionLib:MergeDictionary(PossibleLifecycles, CycleNamesClient)
	end

	for _, Lifecycle in PossibleLifecycles do
		if TotalLifecycles[Lifecycle] then
			TotalLifecycles[Lifecycle]:Connect(function(...)
				RunCycles(Modules, Lifecycle, ...)
			end)
		end
	end
end

function Lifecycles.New(Name: string, Connection: RBXScriptSignal)
	local CustomLifecycleTable = CustomCycles[RunService:IsServer() and "Server" or "Client"]

	if CustomLifecycleTable[Name] then
		Logging.Message({
			Message = `Lifecycle {Name} already exists, overriding.`,
			Level = "WARN",
			LogCat = "Hydrogen Framework Lifecycle Handler",
		})
	end

	CustomLifecycleTable[Name] = Connection
end

function Lifecycles.Chain(NewLifecycles: { [string]: RBXScriptSignal })
	for Name, Connection in NewLifecycles do
		Lifecycles.New(Name, Connection)
	end
end

return Lifecycles
