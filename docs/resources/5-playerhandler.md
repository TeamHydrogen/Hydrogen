# PlayerHandler

PlayerHandler manages player data — loading defaults, updating values, and notifying
you when data changes.

## Setup

Start PlayerHandler in `init.server.luau`, passing a table of default data:

```lua
Hydrogen.PlayerHandler.Start({
    Cash = 0,
    Level = 1,
})
```

Every player will receive this shape by default.

## Detecting Data Changes

Use `SetDataSetCallback` to run code whenever a player's data updates:

```lua
Hydrogen.PlayerHandler.SetDataSetCallback(function(Data)
    -- fires on every data update
end)
```

::: tip
Fire a RemoteEvent inside this callback to notify clients their data has changed.
:::

## Getting Player Data

`GetPlayerData` returns a [Future](https://github.com/red-blox/Util/blob/main/libs/Future/), so call `:Await()` to get the value.

| Context | Usage                                                                             |
| ------- | --------------------------------------------------------------------------------- |
| Server  | `Hydrogen.PlayerHandler:GetPlayerData(Player):Await()`                            |
| Client  | `Hydrogen.PlayerHandler:GetPlayerData():Await()` — returns the LocalPlayer's data |

## Setting Player Data

`SetPlayerData` is **server-only**. It takes the player to update, and a table that's
merged into their existing data.

```lua
Hydrogen.PlayerHandler:SetPlayerData(Player, { Cash = 100 })
```

::: warning
This merges into existing data — it doesn't replace it. Only include the keys you
want to change.
:::

## Example: Updating Cash

```lua
local Data = Hydrogen.PlayerHandler:GetPlayerData(Player):Await()
Hydrogen.PlayerHandler:SetPlayerData(Player, { Cash = Data.Cash + 100 })
```
