local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hydrogen = require(ReplicatedStorage.Hydrogen)

Hydrogen.Start({ ModuleDirectory = script, RunLifecycles = { "CharacterAdded" } })

print("-------------")
print(Hydrogen.PlayerHandler:GetPlayerData())
