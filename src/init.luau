--!strict

local RunService = game:GetService("RunService")

--[[

Sophie B 2025 MIT

]]

local Lifecycles = require(script.Lifecycles)

local Hydrogen = {
	Server = { Modules = {} } :: {
		RunLifecycles: boolean?
			| { "PlayerAdded" | "PlayerRemoving" | "CharacterAdded" | "Heartbeat" | "PostSimulation" }?,
		Modules: {},
	},
	Client = { Modules = {} } :: {
		RunLifecycles: boolean? | {
			"PlayerAdded"
			| "PlayerRemoving"
			| "Heartbeat"
			| "CharacterAdded"
			| "RenderStepped"
			| "PostSimulation"
		}?,
		Modules: {},
	},
}

Hydrogen.PlayerHandler = require(script.Player)
Hydrogen.FunctionLib = require(script.Util.FunctionLib)
Hydrogen.SoundHandler = require(script.Sound)

function Hydrogen.GetRuntime(): "Server" | "Client"
	return RunService:IsServer() and "Server" :: "Server" or "Client"
end

function Hydrogen.Start(Config: {
	ModuleDirectory: any,
	ModuleSuffix: string?,
	RunLifecycles: boolean? | {
		"PlayerAdded"
		| "PlayerRemoving"
		| "CharacterAdded"
		| "Heartbeat"
		| "RenderStepped"
		| "PostSimulation"
		| "PreSimulation"
		| "CharacterRemoving"
	}?,
})
	local Runtime = Hydrogen.GetRuntime()

	if not Config.ModuleDirectory then
		if RunService:IsClient() then
			Config.ModuleDirectory = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts") :: Folder
		else
			Config.ModuleDirectory = game:GetService("ServerScriptService") :: any
		end
	end

	if not Config.ModuleSuffix then
		Config.ModuleSuffix = "Handler$"
	end

	for _, Descendant in Config.ModuleDirectory:GetDescendants() do
		if not Descendant:IsA("ModuleScript") then
			continue
		end

		local Name = Descendant.Name :: string

		if not Name:match(`{Config.ModuleSuffix}` :: string) then
			continue
		end

		if table.find(Hydrogen[Runtime].Modules, Descendant.Name) then
			error("Hydrogen failed to load " .. Descendant.Name .. " as there is already a module named that loaded!")
		end

		task.spawn(function()
			local _RequiredDescendant = require(Descendant) :: any
			table.insert(Hydrogen[Runtime].Modules, Descendant.Name)

			debug.setmemorycategory(Descendant.Name)
		end)
	end

	if Config.RunLifecycles == true then
		if Runtime == "Client" then
			Hydrogen[Runtime].RunLifecycles =
				{ "PlayerAdded", "PlayerRemoving", "Heartbeat", "CharacterAdded", "RenderStepped", "PostSimulation" }
		else
			Hydrogen[Runtime].RunLifecycles =
				{ "PlayerAdded", "PlayerRemoving", "CharacterAdded", "Heartbeat", "PostSimulation" }
		end
	end

	Lifecycles.Run(Hydrogen[Runtime].Modules, Hydrogen[Runtime].RunLifecycles)
end

return Hydrogen
