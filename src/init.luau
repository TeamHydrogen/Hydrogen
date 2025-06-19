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
	Server = { ModuleNames = {}, RequiredModules = {} } :: {
		RunLifecycles: boolean? | typeof(PossibleServerCycles)?,
		ModuleNames: {},
		RequiredModules: {},
	},
	Client = { ModuleNames = {}, RequiredModules = {} } :: {
		RunLifecycles: boolean? | typeof(PossibleClientCycles)?,
		ModuleNames: {},
		RequiredModules: {},
	},
}

Hydrogen.PlayerHandler = require(script.Player)
Hydrogen.FunctionLib = require(script.Util.FunctionLib)
Hydrogen.SoundHandler = require(script.Sound)
Hydrogen.Logging = require(script.Logging)
Hydrogen.Lifecycles = require(script.Lifecycles)

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

		if table.find(Hydrogen[Runtime].ModuleNames, Descendant.Name) then
			error("Hydrogen failed to load " .. Descendant.Name .. " as there is already a module named that loaded!")
		end

		task.spawn(function()
			local _RequiredDescendant = require(Descendant) :: any
			table.insert(Hydrogen[Runtime].ModuleNames, Descendant.Name)
			table.insert(Hydrogen[Runtime].RequiredModules, Descendant)

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

	Lifecycles.Run(Hydrogen[Runtime].RequiredModules, Hydrogen[Runtime].RunLifecycles)
end

return Hydrogen
