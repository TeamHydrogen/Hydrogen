--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Network

if RunService:IsServer() then
	Network = require(script.Parent["_PRIVATE_HYDROGEN_network"].server) :: any
else
	Network = require(script.Parent["_PRIVATE_HYDROGEN_network"].client) :: any
end

local Logging = require(script.Parent.Logging)
local Future = require(script.Parent.Packages.Future)
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
	local Object = PlayerClass.new(Player)

	if Object then
		self.Players[Player] = Object:Await()
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

function PlayerHandler.GetPlayerData(self: Handler, Player: Player): Future.Future<{ any }>
	return Future.new(function()
		if RunService:IsClient() then
			local Data = Network.GetPlayerData.Call()

			return Data
		end

		if not Player then
			Logging.Message({
				Level = "ERROR",
				LogCat = "Hydrogen Framework Data Handler",
				Message = "Argument 'Player' missing or nil. Hint: Did you forget to pass Player in?",
			})
			return {}
		end

		while not self.Players[Player] do -- Yield, we use a while loop as if it's loaded then why wait a frame using a repeat statement?
			task.wait()
		end

		local Attempts = 0

		if not self.Players[Player]["DataStore"] then -- Throw it in an if statement so that we don't start yielding for data that we already have.
			repeat
				task.wait(0.1) -- Yield every 0.1 seconds, it's fast enough.
			until self.Players[Player]["DataStore"] ~= nil or Attempts >= 50 -- Make sure we have the data loaded or not. Data loading should not take longer than 5 seconds.

			if Attempts >= 50 then
				Logging.Message({
					Level = "FATAL",
					LogCat = "Hydrogen Framework Data Handler",
					Message = "We failed to load ",
				})
				return {}
			end
		end

		return self.Players[Player]["DataStore"].Data
	end)
end

PlayerHandler.SetPlayerData = function(self: typeof(PlayerHandler), Player: Player, NewData: {})
	return Future.new(function()
		if not RunService:IsServer() then
			Logging.Message({
				Level = "WARN",
				LogCat = "Hydrogen Framework Data Handler",
				Message = "Data cannot be set on the client. No data saved. Hint: Run this on the server.",
			})
			return self:GetPlayerData(Player):Await()
		end

		local Data = self:GetPlayerData(Player):Await()

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
	end)
end

function PlayerHandler.Start(Config: {
	DefaultData: { any },
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
