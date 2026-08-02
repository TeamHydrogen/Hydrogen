--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Logging = require(script.Parent.Parent.Logging)
local Future = require(script.Parent.Parent.Packages.Future)
local ProfileStore

local Store = nil :: any

--// Table

local PlayerClass = {}
PlayerClass.__index = PlayerClass

PlayerClass.DefaultData = {} :: { [string]: any }

export type PlayerClassType = typeof(setmetatable(
	{} :: {
		Player: Player,
		Data: typeof(PlayerClass.DefaultData),
		DataStore: any,
		SessionEnd: RBXScriptConnection,
		CustomData: { any },
		Destroy: (self: PlayerClassType) -> (),
	},
	PlayerClass
))

function PlayerClass.new(Player: Player): Future.Future<PlayerClassType>?
	if RunService:IsClient() then
		Logging.Message({
			LogCat = "Hydrogen Framework PlayerClass",
			Message = "You cannot run PlayerClass on the client.",
			Level = "WARN",
		})
		return nil
	end

	return Future.new(function(): PlayerClassType
		local self = {}

		self.Player = Player :: Player
		self.Data = PlayerClass.DefaultData
		self.CustomData = {} :: { any }
		self.SessionEnd = nil :: any
		self.DataStore = nil :: any

		self.DataStore = Store:StartSessionAsync(`{Player.UserId}`, {
			Cancel = function()
				return Player.Parent ~= Players
			end,
		})

		if not self.DataStore then
			Logging.Message({
				Level = "FATAL",
				Message = `Player {Player.Name} (UID: {Player.UserId})'s data failed to load!`,
				LogCat = "HYDROGEN: PlayerClass",
			})
			Player:Kick("Hey, unfortunately your data failed to load! Please try again later!")
		end

		self.DataStore:AddUserId(Player.UserId)
		self.DataStore:Reconcile()
		self.SessionEnd = self.DataStore.OnSessionEnd:Connect(function()
			Player:Kick(`Profile session end - Please rejoin`)
		end)

		self.Data = self.DataStore.Value

		return setmetatable(self, PlayerClass) :: PlayerClassType
	end)
end

function PlayerClass.Init()
	if RunService:IsServer() then
		ProfileStore = require(script.Parent.Parent.Packages.ProfileStore)
	end
end

function PlayerClass.SetDefaultData(Data: { [string]: any })
	PlayerClass.DefaultData = Data

	if RunService:IsServer() and ProfileStore then
		Store = RunService:IsStudio() and ProfileStore.New("Data", PlayerClass.DefaultData :: any).Mock
			or ProfileStore.New("Data", PlayerClass.DefaultData :: any)
	end
end

function PlayerClass.Destroy(self: PlayerClassType)
	if self.DataStore then
		self.DataStore:EndSession()
	end
end

return PlayerClass
