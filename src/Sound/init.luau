--!strict

local RunService = game:GetService("RunService")
local FunctionLib = require(script.Parent.Util.FunctionLib)
local Network

if RunService:IsServer() then
	Network = require(script.Parent["_PRIVATE_HYDROGEN_network"].server) :: any
else
	Network = require(script.Parent["_PRIVATE_HYDROGEN_network"].client) :: any
end

local SoundHandler = {
	Sounds = nil :: Folder?,
}

local function CheckSound(Sound: string): boolean
	if not SoundHandler.Sounds then
		return false
	end

	if not FunctionLib:FindFirstDescendant(SoundHandler.Sounds, Sound) then
		return false
	end

	return true
end

function SoundHandler._BackendSound(
	Sound: string,
	PlayLength: number?,
	CF: CFrame?,
	CustomProps: { [string]: any }?
): Sound?
	if not SoundHandler.Sounds then
		return
	end

	local OriginalSound: Sound = FunctionLib:FindFirstDescendant(SoundHandler.Sounds, Sound) :: Sound

	local NewSound: Sound = OriginalSound:Clone()
	NewSound.Parent = workspace

	if CustomProps then
		for PropName, Property in CustomProps do
			NewSound[PropName] = Property -- yes i know the lsp errors here. i'm not doing anything about it though because it should error if it doesnt exist or we're doing something dumb.
		end
	end

	local NewPart

	if CF then
		NewPart = Instance.new("Part")
		NewPart.Transparency = 1
		NewPart.Anchored = true
		NewPart.CanCollide = false
		NewPart.Size = Vector3.new(1, 1, 1)
		NewPart.CFrame = CF
		NewPart.Parent = workspace

		NewSound.Parent = NewPart
	end

	NewSound:Play()

	task.spawn(function()
		if PlayLength then
			task.wait(PlayLength)

			NewSound:Destroy()

			if NewPart then
				NewPart:Destroy()
			end

			return
		end

		NewSound.Ended:Wait()

		if NewSound then
			NewSound:Destroy()
		end

		if NewPart then
			NewPart:Destroy()
		end
	end)

	return NewSound
end

function SoundHandler.PlaySound(
	Sound: string,
	Player: Player?,
	PlayLength: number?,
	CF: CFrame?,
	Props: { [string]: any }?
): Sound?
	if not CheckSound(Sound) then
		error(`Sound {Sound} doesn't exist!`)
		return
	end

	if RunService:IsClient() then
		return SoundHandler._BackendSound(Sound, PlayLength, CF, Props)
	end

	if Player then
		Network.PlaySoundOnClient.Fire(Player, Sound, CF)
	else
		Network.PlaySoundOnClient.FireAll(Sound, CF)
	end

	return
end

function SoundHandler.Start(Sounds: Folder)
	assert(Sounds, "Hydrogen SoundHandler: Sounds Must be set to a folder")
	SoundHandler.Sounds = Sounds

	if RunService:IsServer() then
		return
	end

	Network.PlaySoundOnClient.On(function(Sound: string, CFrame: CFrame?)
		SoundHandler._BackendSound(Sound, nil, CFrame)
	end)
end

return SoundHandler
