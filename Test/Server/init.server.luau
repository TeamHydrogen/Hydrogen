local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hydrogen = require(ReplicatedStorage.Hydrogen)

Hydrogen.PlayerHandler.Start({ DefaultData = { Coins = 20 } })

Hydrogen.Lifecycles.new("ReplicatedAdded", ReplicatedStorage.ChildAdded):expect()

Hydrogen.Start({ ModuleDirectory = script, ModuleSuffix = "Handler$", RunLifecycles = true })
