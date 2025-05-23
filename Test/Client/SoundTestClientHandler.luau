local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hydrogen = require(ReplicatedStorage.Hydrogen)

local SoundHandler = Hydrogen.SoundHandler
SoundHandler.Start(ReplicatedStorage.Sounds)

local TestClientHandler = {}

function TestClientHandler.RenderStepped()
	print("Step!")
end

do
	print("--------------------------")
	print("CLIENT SOUND TEST")
	print("")
	print("TESTING GUNSHOT IN 3")
	task.wait(3)
	SoundHandler.PlaySound("Shot1")
end

return TestClientHandler
