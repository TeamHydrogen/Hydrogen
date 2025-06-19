--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Network

if RunService:IsServer() then
	Network = require(script.Parent["_PRIVATE_HYDROGEN_network"].server) :: any
else
	Network = require(script.Parent["_PRIVATE_HYDROGEN_network"].client) :: any
end

local Promise = require(script.Parent.Packages.Promise)
local FunctionLib = require(script.Parent.Util.FunctionLib)
local PlayerClass = require(script.PlayerClass)

local PlayerHandler = {}
PlayerHandler.Players = {} :: { [Player]: PlayerClass.PlayerClassType }
PlayerHandler.DataSetCallback = nil :: (Player: Player, Data: { any }) -> ()?
type Handler = typeof(PlayerHandler)

function PlayerHandler.SetDataSetCallback(Callback: (Player: Player, Data: { [string]: any }) -> ())
	PlayerHandler.DataSetCallback = Callback :: any
end

function PlayerHandler.PlayerAdded(self: Handler, Player: Player)
	PlayerClass.new(Player)
		:andThen(function(Object)
			self.Players[Player] = Object
			return self.Players[Player]
		end)
		:catch(warn)
end

function PlayerHandler.SetCustomData(self: Handler, Player: Player, NewData: { any })
	local Data = self.Players[Player].CustomData
	local NewDictionary = FunctionLib:MergeDictionary(Data, NewData)

	self.Players[Player].CustomData = NewDictionary
end

PlayerHandler.onPlayerRemoving = function(self: Handler, Player: Player)
	self.Players[Player]:Destroy()
	self.Players[Player] = nil
end

PlayerHandler.GetPlayerData = function(self: Handler, Player: Player?)
	return Promise.new(function(Resolve, _, Cancel)
		Cancel(function()
			Resolve({})
			return true
		end)

		if RunService:IsClient() then
			local Data = Network.GetPlayerData.Call()

			Resolve(Data)
			return
		end

		if not Player then
			error("On server player must not be nil!")
			return true
		end

		repeat
			task.wait(0.1)
		until self.Players[Player]

		local success, err = pcall(function()
			repeat
				task.wait(0.1)
			until self.Players[Player]["DataStore"] ~= nil

			return true
		end)

		if not success and err then
			warn(err)
			Resolve({})
			return
		end

		Resolve(self.Players[Player]["DataStore"].Data :: typeof(self.Players[Player].DataStore.Data))
	end):catch(warn)
end

PlayerHandler.SetPlayerData = function(self: typeof(PlayerHandler), Player: Player, NewData: {})
	assert(RunService:IsServer(), "SetPlayerData Must be ran from the server!")

	local Data = self:GetPlayerData(Player):expect() :: any

	local NewDictionary = FunctionLib:MergeDictionary(Data, NewData)

	if PlayerHandler.DataSetCallback then
		PlayerHandler.DataSetCallback(Player, NewDictionary)
	end

	if self.Players[Player]["DataStore"] then
		for Key, Value in NewDictionary do
			self.Players[Player]["DataStore"].Data[Key] = Value
		end
	end

	self.Players[Player]["Data"] = NewDictionary

	return NewDictionary
end

function PlayerHandler.Start(Config: {
	DefaultData: {},
})
	if RunService:IsClient() then
		return
	end

	Network.GetPlayerData.SetCallback(function(Player: Player)
		local PlayerObject = PlayerHandler.Players[Player]
		if not PlayerObject or not PlayerObject.DataStore then
			return {}
		end
		local ClonedTable = FunctionLib:CopyDeep(PlayerObject.DataStore.Data)
		return ClonedTable
	end)

	PlayerClass.SetDefaultData(Config.DefaultData)

	for _, Player in Players:GetPlayers() do
		PlayerHandler:PlayerAdded(Player)
	end

	Players.PlayerAdded:Connect(function(Player)
		PlayerHandler:PlayerAdded(Player)
	end)

	Players.PlayerRemoving:Connect(function(Player)
		PlayerHandler:onPlayerRemoving(Player)
	end)
end

return PlayerHandler
