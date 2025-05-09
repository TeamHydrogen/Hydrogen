local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Lifecycles = {}

local LifecyclesEvents = {
	PlayerAdded = Players.PlayerAdded,
	PlayerRemoving = Players.PlayerRemoving,
	Heartbeat = RunService.Heartbeat,
	PostSimulation = RunService.PostSimulation,
	PreSimulation = RunService.PreSimulation,
}

if RunService:Client() then
	LifecyclesEvents["CharacterAdded"] = Players.LocalPlayer.CharacterAdded
	LifecyclesEvents["CharacterRemoving"] = Players.LocalPlayer.CharacterRemoving
	LifecyclesEvents["RenderStepped"] = RunService.RenderStepped
end

local function RunCycles(Modules, Callback, ...)
	for _, Module in Modules do
		local Args = ...

		task.spawn(function()
			if Module[Callback] then
				Module[Callback](Args)
			end
		end)
	end
end

function Lifecycles.Run(Modules: { any }, PossibleLifecycles: { typeof(LifecyclesEvents) }?)
	if not PossibleLifecycles then
		return
	end

	for _, Lifecycle in PossibleLifecycles do
		if LifecyclesEvents[Lifecycle] then
			LifecyclesEvents[Lifecycle]:Connect(function(...)
				RunCycles(Modules, Lifecycle, ...)
			end)
		end
	end
end

return Lifecycles
