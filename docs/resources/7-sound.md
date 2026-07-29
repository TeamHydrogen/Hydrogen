# SoundHandler

SoundHandler plays sounds across the server and client without you needing to
manually manage Sound instances, replication, or cleanup.

## Setup

Start SoundHandler in **both** `init.server.luau` and `init.client.luau`, passing
a folder containing your sounds:

```lua
Hydrogen.SoundHandler.Start(SoundsFolder)
```

::: warning
`SoundsFolder` must contain the sounds you plan to play by name. If a sound can't
be found inside it, `PlaySound` will fail and log an error.
:::

::: tip
We recommend setting `SoundFolder` to `SoundService`, as this is an already created place to put your sounds.
:::

## Playing Sounds

```lua
Hydrogen.SoundHandler.PlaySound(Sound, Player, PlayLength, CF, Props)
```

| Parameter    | Type               | Required | Description                                                                                            |
| ------------ | ------------------ | :------: | ------------------------------------------------------------------------------------------------------ |
| `Sound`      | `string`           |    ✅    | Name of the sound to play                                                                              |
| `Player`     | `Player?`          |    ❌    | Server-only — who hears the sound. Omit to play for everyone                                           |
| `PlayLength` | `number?`          |    ❌    | Seconds before the sound is stopped and cleaned up. Omit to clean up automatically when the sound ends |
| `CF`         | `CFrame?`          |    ❌    | Plays the sound positionally at this CFrame instead of globally                                        |
| `Props`      | `{[string]: any}?` |    ❌    | Extra properties applied to the sound instance (e.g. `Volume`, `PlaybackSpeed`)                        |

Calling `PlaySound` on the client always plays locally. Calling it on the server replicates to the given `Player`, or to everyone if `Player` is omitted.

::: tip
`PlaySound` will return the Sound object if played on the client. Note it won't return on the server.
:::

## Examples

Play a sound for everyone:

```lua
Hydrogen.SoundHandler.PlaySound("Explosion")
```

Play a sound for one player only:

```lua
Hydrogen.SoundHandler.PlaySound("LevelUp", Player)
```

Play a positional sound for 3 seconds:

```lua
Hydrogen.SoundHandler.PlaySound("Footstep", nil, 3, HitPart.CFrame)
```

Play a sound with custom properties:

```lua
Hydrogen.SoundHandler.PlaySound("Ambient", nil, nil, nil, { Volume = 0.5, Looped = true })
```

::: warning
If `Looped = true` and no `PlayLength` is given, the sound will never clean itself
up on its own — it only stops when `Ended` fires, which won't happen for looped sounds.
Always pass `PlayLength` when looping.

This matters most on the server, since `PlaySound` doesn't return anything there —
you have no handle to stop the sound yourself. On the client, `PlaySound` returns
the `Sound` object, so you can still destroy it manually if needed.
:::
