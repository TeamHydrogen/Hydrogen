local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Lifecycles = {}

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

function Lifecycles.Run(
	Modules: { any },
	PossibleLifecycles: {
		"PlayerAdded"
		| "PlayerRemoving"
		| "CharacterAdded"
		| "Heartbeat"
		| "PostSimulation"
		| "RenderStepped"
	}?
)
	if not PossibleLifecycles then
		return
	end

	if table.find(PossibleLifecycles, "PlayerAdded") then
		Players.PlayerAdded:Connect(function(Player)
			RunCycles(Modules, "PlayerAdded", Player)

			if table.find(PossibleLifecycles, "CharacterAdded") then
				Player.CharacterAdded:Connect(function(Character)
					RunCycles(Modules, "CharacterAdded", Character)
				end)
			end
		end)
	end

	if table.find(PossibleLifecycles, "PlayerRemoving") then
		Players.PlayerRemoving:Connect(function(Player)
			RunCycles(Modules, "PlayerRemoving", Player)
		end)
	end

	if table.find(PossibleLifecycles, "Heartbeat") then
		RunService.Heartbeat:Connect(function(Delta)
			RunCycles(Modules, "Heartbeat", Delta)
		end)
	end

	if table.find(PossibleLifecycles, "PostSimulation") then
		RunService.PostSimulation:Connect(function(Delta)
			RunCycles(Modules, "PostSimulation", Delta)
		end)
	end

	if table.find(PossibleLifecycles, "RenderStepped") then
		RunService.RenderStepped:Connect(function(Delta)
			RunCycles(Modules, "RenderStepped", Delta)
		end)
	end
end

return Lifecycles
