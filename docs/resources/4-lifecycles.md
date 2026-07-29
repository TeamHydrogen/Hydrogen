# Lifecycles

Lifecycles are Hydrogen's way of automatically wiring your modules up to common events —
without you having to manually connect them yourself.

Think of a lifecycle like `Players.PlayerAdded`. Normally, you'd write:

```lua
Players.PlayerAdded:Connect(function(Player: Player)
    -- do something
end)
```

With Hydrogen, you don't connect anything manually. If any of your handlers have a matching function, Hydrogen will call it automatically:

```lua
function Handler.PlayerAdded(Player: Player)
    -- do something
end
```

As soon as `Players.PlayerAdded` fires, **every** loaded module with a `PlayerAdded`
function will have it called — no `:Connect()`, no manual event wiring, no boilerplate.

::: tip
This means you can split logic for the same event across multiple modules. A
`CombatHandler` and an `InventoryHandler` can both define their own `PlayerAdded`
function, and both will run independently when a player joins.
:::

## Default lifecycles

Hydrogen comes with a list of default lifecycles on the Server and Client.

| Lifecycle         | Server | Client |
| ----------------- | :----: | :----: |
| PlayerAdded       |   ✅   |   ✅   |
| PlayerRemoving    |   ✅   |   ✅   |
| Heartbeat         |   ✅   |   ✅   |
| PostSimulation    |   ✅   |   ✅   |
| PreSimulation     |   ✅   |   ✅   |
| PreAnimation      |   ✅   |   ✅   |
| PreRender         |   ❌   |   ✅   |
| RenderStepped     |   ❌   |   ✅   |
| CharacterAdded    |   ❌   |   ✅   |
| CharacterRemoving |   ❌   |   ✅   |

These come pre-shipped with Hydrogen.

::: warning

`RenderStepped` is here for backwards compatibility. For new works, use `PreRender`. In future versions of Hydrogen, RenderStepped may be removed.

:::

### Running Lifecycles

Lifecycles are ran in the way mentioned in [Loader Setup](./3-setup).

## Custom Lifecycles

If Hydrogen is missing any lifecycles that you want or you want to make any of your own, it's incredibly simple!

```lua
Hydrogen.Lifecycles.new(LifecycleName: string, Lifecycle: RBXScriptConnection)
```

LifecycleName is what you call in your function, Lifecycle is the signal.

::: tip
We recommend setting `LifecycleName` to be the same as the Lifecycle itself for consistency
:::

::: tip
Lifecycles can also be generic signals from signal libraries. As long as they have a connect function, they work fine!
:::
