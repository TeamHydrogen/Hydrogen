--!strict
--!native
--!optimize 2
local RunService = game:GetService("RunService")

--// Services

--// Modules

local Packages = script.Parent.Parent.Parent["roblox_packages"]

local Lapis

if RunService:IsServer() then
	Lapis = require(Packages.Lapis)
end

local Migrations = {}

--// Table

local PlayerClass = {}
PlayerClass.__index = PlayerClass

PlayerClass.DefaultData = {}

local DataCollection

export type PlayerClassType = typeof(setmetatable(
	{} :: {
		Player: Player,
		Data: typeof(PlayerClass.DefaultData),
		Document: any,
		CustomData: { any },
		Destroy: (self: PlayerClassType) -> (),
	},
	PlayerClass
))

function PlayerClass.Start(CollectionName: string?)
	if RunService:IsClient() then
		return
	end

	if game.PlaceId == 0 then
		return
	end

	DataCollection = Lapis.createCollection(
		CollectionName and CollectionName or "PlayerData",
		{ migrations = Migrations, defaultData = PlayerClass.DefaultData }
	)
end

function PlayerClass.new(Player: Player): PlayerClassType
	if RunService:IsClient() then
		error("PlayerClass cannot be ran on client!")
	end

	local self = {}

	self.Player = Player
	self.Data = PlayerClass.DefaultData
	self.Document = nil :: any
	self.CustomData = {}

	if game.PlaceId ~= 0 then
		DataCollection:load(`Player-{self.Player.Name}-{self.Player.UserId}`, { self.Player.UserId })
			:andThen(function(Document)
				if not self.Player.Parent then
					Document:close():catch(warn)
					return
				end

				self.Document = Document
				self.Data = self.Document:read()
			end)
			:catch(function(Message)
				self.Player:Kick("Hey there! Unfortunately your data failed to load! No data has been lost")
				warn(Message)
			end)
	end

	return setmetatable(self, PlayerClass) :: PlayerClassType
end

function PlayerClass.SetDefaultData(Data: { any })
	PlayerClass.DefaultData = Data
end

function PlayerClass.SetMigrations(pMigrations: { { migrate: ({ any }) -> { any }, backwardsCompatible: boolean? } })
	Migrations = pMigrations
end

function PlayerClass.Destroy(self: PlayerClassType)
	if self.Document then
		local Document = self.Document :: any

		Document:close():catch(warn)
	end
end

return PlayerClass
