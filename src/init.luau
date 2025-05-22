--!strict

local RunService = game:GetService("RunService")

--[[

Sophie B 2025 MIT

]]

local Lifecycles = require(script.Lifecycles)

local PossibleClientCycles = {
	"PlayerAdded",
	"PlayerRemoving",
	"Heartbeat",
	"CharacterAdded",
	"CharacterRemoving",
	"RenderStepped",
	"PostSimulation",
}

local PossibleServerCycles = {
	"PlayerAdded",
	"PlayerRemoving",
	"Heartbeat",
	"PostSimulation",
}

local Hydrogen = {
	Server = { Modules = {} } :: {
		RunLifecycles: boolean? | typeof(PossibleServerCycles)?,
		Modules: {},
	},
	Client = { Modules = {} } :: {
		RunLifecycles: boolean? | typeof(PossibleClientCycles)?,
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
	RunLifecycles: boolean? | typeof(PossibleClientCycles)?,
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
			Hydrogen[Runtime].RunLifecycles = PossibleClientCycles
		else
			Hydrogen[Runtime].RunLifecycles = PossibleServerCycles
		end
	end

	Lifecycles.Run(Hydrogen[Runtime].Modules, Hydrogen[Runtime].RunLifecycles)
end

return Hydrogen
