# Hydrogen

## A Framework for Roblox designed to handle things that you would rather not.

---

## WARNING: Hey There! Please note that Hydrogen is NOT finished and contains MANY issues and no official documentation

## These will come with due time after the project has been battle-tested, however feel free to use Hydrogen if you figure it out!

## Install

### With pesde

```sh
pesde add teamhydrogen/hydrogen
pesde install
```

### In File

pesde.toml:

```toml
[dependencies]
hydrogen = { name = "teamhydrogen/hydrogen", version = "^0.2.0"}
```

## Usage:

These documents will be very brief as it is just a readme

```lua
Hydrogen.Start(Config: {
	ModuleDirectory: any,
	ModuleSuffix: string?,
	RunLifecycles: boolean? | { "PlayerAdded" | "PlayerRemoving" | "CharacterAdded" | "Heartbeat" | "RenderStepped" }?,
})
```

ModuleDirectory: Where your modules are stored on Server and Client
ModuleSuffix: What your modules end in, Defaults to "Handler"
RunLifecycles: True for all, select what you can use automatically as a function without needing extra connections

This will load your modules and other Hydrogen aspects like lifecycles and sound, Players will need to be sorted yourself.

## Lifecycles

Lifecycles set in Hydrogen.Start can be ran with the following

```lua
local Module = {}

function Module.CONNECTION(Args)
end

return Module
```

For example:

```lua
local Module = {}

function Module.PlayerAdded(Player: Player)
end

return Module
```

This will run every time a player is added

## PlayerHandler

This handles player data and saving, being a wrapper for [ProfileStore](https://devforum.roblox.com/t/profilestore-save-your-player-data-easy-datastore-module/3190543) allowing you to set, get and even handle custom functions when data is updated

This will go more in-depth in the real documentation, however for a README I want to keep it short.

The basics are that you set data with

```lua
PlayerHandler:SetPlayerData(Player, {DATA})
```

Data is a table with a key and what you want to set the key to

```lua
PlayerHandler:SetPlayerData(Player, {Coins = 300}) -- Sets coins to 300
```

You get data with

```lua
PlayerHandler:GetPlayerData(Player):expect() -- Returns a promise, expect being most likely what you would want
```

## SoundHandler

Plays sounds on Server and/or Client, tries to make sounds completely handled by Client.
