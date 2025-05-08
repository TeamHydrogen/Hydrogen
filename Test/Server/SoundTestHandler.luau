local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hydrogen = require(ReplicatedStorage.Hydrogen)

local SoundHandler = Hydrogen.SoundHandler
SoundHandler.Start(ReplicatedStorage.Sounds)

do
	task.wait(5)
	print("--------------------------")
	print("SERVER SOUND TEST")
	print("")
	print("TESTING GUNSHOT IN 3")
	task.wait(3)
	SoundHandler.PlaySound("Shot1")
end

return {}
