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

PlayerClass.DefaultData = {} :: any

if RunService:IsServer() then
	ProfileStore = require(script.Parent.Parent.Packages.ProfileStore)
end

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
		error("PlayerClass cannot be ran on client!")
		return
	end

	return Future.new(function(): PlayerClassType
		local self = {}

		self.Player = Player :: Player
		self.Data = PlayerClass.DefaultData
		self.CustomData = {}
		self.SessionEnd = nil :: any
		self.DataStore = nil :: any

		self.DataStore = Store:StartSessionAsync(`{Player.Name}-{Player.UserId}`, {
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

function PlayerClass.SetDefaultData<T>(Data: T)
	PlayerClass.DefaultData = Data

	if RunService:IsServer() then
		Store = RunService:IsStudio() and ProfileStore.New("Data", PlayerClass.DefaultData).Mock
			or ProfileStore.New("Data", PlayerClass.DefaultData)
	end
end

function PlayerClass.Destroy(self: PlayerClassType)
	if self.DataStore then
		self.DataStore:EndSession()
	end
end

return PlayerClass
