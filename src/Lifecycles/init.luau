local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local FunctionLib = require(script.Parent.Util.FunctionLib)

local Lifecycles = {}

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

	if RunService:IsClient() then
		local ClientCycles = {
			CharacterAdded = Players.LocalPlayer.CharacterAdded,
			CharacterRemoving = Players.LocalPlayer.CharacterRemoving,
			RenderStepped = RunService.RenderStepped,
		}

		TotalLifecycles = FunctionLib:MergeDictionary(TotalLifecycles, ClientCycles)
	end

	for _, Lifecycle in PossibleLifecycles do
		if TotalLifecycles[Lifecycle] then
			TotalLifecycles[Lifecycle]:Connect(function(...)
				RunCycles(Modules, Lifecycle, ...)
			end)
		end
	end
end

return Lifecycles
