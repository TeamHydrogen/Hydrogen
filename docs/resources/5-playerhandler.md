# PlayerHandler

PlayerHandler manages player data — loading defaults, updating values, and notifying
you when data changes.

::: danger Coming from before 0.5.0?
Please read the migration notice at the bottom of this page to be fully up to date. If you're starting at or after 0.5.0, you don't need to worry.
:::

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

## Migrating Data To 0.5.0

As of 0.5.0, Data uses a new key format from {PlayerName}-{UserId} to just UserID. This is for reasons related to Right to Be Forgotten requests, and also general username changing.

Data will be automatically migrated for you when a player joins, but if a player is missing data the function has been exposed for you

```lua
Hydrogen.PlayerHandler.MigrateOldData(Player)
```
