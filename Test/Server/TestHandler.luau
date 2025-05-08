local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hydrogen = require(ReplicatedStorage.Hydrogen)

local module = {}

function module.PlayerAdded(Player: Player)
	print("hi")
	local data = Hydrogen.PlayerHandler:GetPlayerData(Player)

	print("MODULE TEST")
	print(data)
end

do
	print("alright")
end

return module
