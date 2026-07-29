# Loader Setup

Hydrogen is designed to be simple to set up — most features are optional.

```lua
Hydrogen.Start({ ModuleDirectory = script, ModuleSuffix = "Handler$", RunLifecycles = true })
```

Call this once on the server and once on the client to start the module loader.

::: warning Important
For best results, call this at the end of your `init.server.luau` or `init.client.luau` file.
:::

## Parameters

### `ModuleDirectory`

This is where your modules go. A common pattern is to call `Hydrogen.Start` from
an `init.server.luau` file, with all other modules nested inside it.

### `ModuleSuffix`

The suffix Hydrogen uses to identify which modules to load.

::: tip Recommended naming

- **Server:** `Handler`
- **Client:** `ClientHandler`

Another common pattern is `Service` (server) / `Controller` (client).
:::

::: info
For the rest of the documentation, `Handler` will refer to a loaded module on the server and `Client Handler` will refer to one on the client.
:::

### `RunLifecycles`

Whether to run Hydrogen's [lifecycles](/4-lifecycles). Accepts either:

| Type               | Behavior                                               |
| ------------------ | ------------------------------------------------------ |
| `boolean`          | `true` runs all default and extra lifecycles           |
| `table of strings` | Fine-grained control over exactly which lifecycles run |

::: tip
We recommend `true` for peace of mind unless you need fine-grained control.
:::
