--!strict

local RunService = game:GetService("RunService")
local Suphi = require(script.Parent.Parent.Packages.Suphi)

--// Table

local PlayerClass = {}
PlayerClass.__index = PlayerClass

PlayerClass.DefaultData = {}

export type PlayerClassType = typeof(setmetatable(
	{} :: {
		Player: Player,
		Data: typeof(PlayerClass.DefaultData),
		DataStore: any,
		CustomData: { any },
		Destroy: (self: PlayerClassType) -> (),
	},
	PlayerClass
))

local function StateChanged(_state, dataStore)
	while dataStore.State == false do -- Keep trying to re-open if the state is closed
		if dataStore:Open(PlayerClass.DefaultData) ~= "Success" then
			task.wait(6)
		end
	end
end

function PlayerClass.new(Player: Player, CollectionName: string): PlayerClassType
	if RunService:IsClient() then
		error("PlayerClass cannot be ran on client!")
	end

	local self = {}

	self.Player = Player :: Player
	self.Data = PlayerClass.DefaultData
	self.CustomData = {}

	if game.PlaceId ~= 0 then
		self.DataStore = Suphi.new(CollectionName, "PlayerData", `Player-{self.Player.Name}-{self.Player.UserId}`)
		self.DataStore:Reconcile(PlayerClass.DefaultData)
		self.DataStore.StateChanged:Connect(StateChanged)
	end

	return setmetatable(self, PlayerClass) :: PlayerClassType
end

function PlayerClass.SetDefaultData(Data: { any })
	PlayerClass.DefaultData = Data
end

function PlayerClass.Destroy(self: PlayerClassType, CollectionName: string)
	local dataStore = Suphi.find(CollectionName, "PlayerData", `Player-{self.Player.Name}-{self.Player.UserId}`)
	if dataStore ~= nil then
		dataStore:Destroy()
	end
end

return PlayerClass
