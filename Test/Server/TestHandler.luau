local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hydrogen = require(ReplicatedStorage.Hydrogen)

local module = {}

function module.PlayerAdded(Player: Player)
	local data = Hydrogen.PlayerHandler:GetPlayerData(Player):expect()

	print("MODULE TEST")
	print(data)

	task.wait(5)

	Hydrogen.PlayerHandler:SetPlayerData(Player, {
		Coins = data.Coins + 300,
	})

	print(Hydrogen.PlayerHandler:GetPlayerData(Player):expect())
end

do
	print("alright")
end

return module
