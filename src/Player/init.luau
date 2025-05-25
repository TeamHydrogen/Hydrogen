--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Network

if RunService:IsServer() then
	Network = require(script.Parent["_PRIVATE_HYDROGEN_network"].server) :: any
else
	Network = require(script.Parent["_PRIVATE_HYDROGEN_network"].client) :: any
end

local FunctionLib = require(script.Parent.Util.FunctionLib)
local PlayerClass = require(script.PlayerClass)

local PlayerHandler = {}
PlayerHandler.Players = {} :: { [Player]: PlayerClass.PlayerClassType }
PlayerHandler.DataSetCallback = nil :: (Player: Player, Data: { any }) -> ()?
type Handler = typeof(PlayerHandler)

function PlayerHandler.SetDataSetCallback(Callback: (Player: Player, Data: { [string]: any }) -> ())
	PlayerHandler.DataSetCallback = Callback :: any
end

function PlayerHandler.onPlayerAdded(self: Handler, Player: Player, CollectionName: string)
	local NewPlayerObject = PlayerClass.new(Player, CollectionName)
	self.Players[Player] = NewPlayerObject

	local Data = self:GetPlayerData(Player)

	if not Data then
		Player:Kick("Sorry, data loading has failed. However, your data is safe! Please rejoin.")
		return
	end
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
	if RunService:IsClient() then
		return Network.GetPlayerData.Call()
	end

	if game.PlaceId == 0 then
		return PlayerClass.DefaultData
	end

	if not Player then
		error("On server player must not be nil!")
	end

	if not self.Players[Player] then
		repeat
			task.wait()
		until self.Players[Player]
	end

	local success, err = pcall(function()
		repeat
			task.wait(0.1)
		until self.Players[Player]["DataStore"] ~= nil

		return true
	end)

	if not success and err then
		warn(err)
		error("Data failed to be obtained!")
	end

	return self.Players[Player]["DataStore"].Value :: typeof(self.Players[Player].Data)
end

PlayerHandler.SetPlayerData = function(self: typeof(PlayerHandler), Player: Player, NewData: {})
	assert(RunService:IsServer(), "SetPlayerData Must be ran from the server!")

	if game.PlaceId == 0 then
		return
	end

	if not self.Players[Player]["DataStore"] then
		return
	end

	local Data = self:GetPlayerData(Player)
	local NewDictionary = FunctionLib:MergeDictionary(Data, NewData)

	if PlayerHandler.DataSetCallback then
		PlayerHandler.DataSetCallback(Player, NewDictionary)
	end

	for Key, Value in NewDictionary do
		self.Players[Player]["DataStore"].Value[Key] = Value
	end

	return NewDictionary
end

function PlayerHandler.Start(Config: {
	CollectionName: string?,
	DefaultData: {},
})
	if RunService:IsServer() then
		Network.GetPlayerData.SetCallback(function(Player: Player)
			local ClonedTable = FunctionLib:CopyDeep(PlayerHandler:GetPlayerData(Player))

			return ClonedTable :: any
		end)

		PlayerClass.SetDefaultData(Config.DefaultData)

		for _, Player in Players:GetPlayers() do
			PlayerHandler:onPlayerAdded(Player, Config.CollectionName or "Data")
		end

		Players.PlayerAdded:Connect(function(Player)
			PlayerHandler:onPlayerAdded(Player, Config.CollectionName or "Data")
		end)

		Players.PlayerRemoving:Connect(function(Player)
			PlayerHandler:onPlayerRemoving(Player)
		end)
	end
end

return PlayerHandler
