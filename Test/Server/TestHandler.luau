local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hydrogen = require(ReplicatedStorage.Hydrogen)
local Lifecycles = require(ReplicatedStorage.Hydrogen.Lifecycles)

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

function module.ReplicatedAdded(Child)
	print("Object added to RS")
	print(Child.Name)
end

do
	print("alright")

	task.spawn(function()
		task.wait(5)

		local part = Instance.new("Part")
		part.Name = "TestPart"
		part.Size = Vector3.new(4, 1, 2)
		part.Anchored = true
		part.Parent = ReplicatedStorage
	end)
end

return module
