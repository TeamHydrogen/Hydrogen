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

function SoundHandler._BackendSound(Sound: string, PlayLength: number?, CF: CFrame?, CustomProps: { [string]: any }?)
	if not SoundHandler.Sounds then
		return
	end

	local OriginalSound: Sound = FunctionLib:FindFirstDescendant(SoundHandler.Sounds, Sound) :: Sound

	local NewSound: Sound = OriginalSound:Clone()
	NewSound.Parent = workspace

	if CustomProps then
		for PropName, Property in CustomProps do
			NewSound[PropName] = Property
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

	if PlayLength then
		task.wait(PlayLength)

		NewSound:Destroy()

		if NewPart then
			NewPart:Destroy()
		end

		return
	end

	NewSound.Ended:Wait()

	NewSound:Destroy()

	if NewPart then
		NewPart:Destroy()
	end
end

function SoundHandler.PlaySound(
	Sound: string,
	Player: Player?,
	PlayLength: number?,
	CF: CFrame?,
	Props: { [string]: any }?
)
	if not CheckSound(Sound) then
		error(`Sound {Sound} doesn't exist!`)
		return
	end

	if RunService:IsClient() then
		task.spawn(function()
			SoundHandler._BackendSound(Sound, PlayLength, CF, Props)
		end)

		return
	end

	if Player then
		Network.PlaySoundOnClient.Fire(Player, Sound, CF)
	else
		Network.PlaySoundOnClient.FireAll(Sound, CF)
	end
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
