local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hydrogen = require(ReplicatedStorage.Hydrogen)

Hydrogen.Start({ ModuleDirectory = script, RunLifecycles = true })

print("-------------")
print(Hydrogen.PlayerHandler:GetPlayerData())
