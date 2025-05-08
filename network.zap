opt client_output = "src/_PRIVATE_HYDROGEN_network/client.luau"
opt server_output = "src/_PRIVATE_HYDROGEN_network/server.luau"
opt remote_folder = "HydrogenNetwork"

funct GetPlayerData = {
    call: Async,
    rets: unknown
}

event PlaySoundOnClient = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: (Sound: string, CFrame: CFrame?)
}

event PlaySoundToAll = {
	from: Client,
	type: Reliable,
	call: ManyAsync,
	data: (Sound: string, CFrame: CFrame?)
}