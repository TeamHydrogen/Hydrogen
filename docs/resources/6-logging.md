# Logging

A logging utility with configurable levels, automatic tracebacks, and cleaned-up
script references. Written by railworks2, used with permission.

::: warning
This has a steeper learning curve than the rest of Hydrogen — config is
mostly for tuning behavior per level, and most day-to-day usage only needs
`Hydrogen.Logging.Message` and `Hydrogen.Logging.assert`.
:::

## Log Levels

| Level   | Enabled                                                                                      | Traceback | Output  |
| ------- | -------------------------------------------------------------------------------------------- | --------- | ------- |
| `DEBUG` | [RunMode](https://create.roblox.com/docs/reference/engine/classes/RunService#IsRunMode) only | ✅        | `print` |
| `INFO`  | ✅                                                                                           | ❌        | `print` |
| `WARN`  | ✅                                                                                           | ✅        | `warn`  |
| `ERROR` | ✅                                                                                           | ✅        | `warn`  |
| `FATAL` | ✅                                                                                           | ❌        | `error` |

::: danger
`FATAL` terminates code execution. Only use it for unrecoverable errors.
:::

Each level's behavior lives in `Log.Config` and can be overridden if needed.

## Logging.Message

Logs a message at a given level.

```lua
Logging.Message({
    Level = "INFO",
    LogCat = "Combat",
    Message = "Player dealt damage",
})
```

**Parameters**

| Field            | Type       | Required | Description                                                       |
| ---------------- | ---------- | :------: | ----------------------------------------------------------------- |
| `Level`          | `LogLevel` |    ✅    | `"INFO"` \| `"DEBUG"` \| `"WARN"` \| `"ERROR"` \| `"FATAL"`       |
| `LogCat`         | `string`   |    ✅    | Category tag shown in the log output                              |
| `Message`        | `string`   |    ✅    | The message to log                                                |
| `LogRef`         | `string?`  |    ❌    | Optional ID shown in the log, useful for tracing a specific event |
| `ForceTraceback` | `boolean?` |    ❌    | Forces a traceback even if the level doesn't normally include one |

You can also pass extra data as additional arguments — it'll be appended to the
log output:

```lua
Logging.Message({ Level = "DEBUG", LogCat = "Shop", Message = "Purchase failed" }, purchaseData)
```

**Example output:**

```
[INFO][LOG] This is an example logging message - Shared.Log:111 - Client

[ERROR][LOAD][ID: NotActive] Failed to start module TestModule due to the Active flag not being enabled - Shared.Log:111 - Server
Data: {"testData"}
Traceback: Shared.UILoad:62
Server.Load:152
```

## Logging.assert

Same idea as Lua's `assert`, but logs an `ERROR` instead of throwing.

```lua
Hydrogen.Logging.assert(Player.Character, {
    LogCat = "Combat",
    Message = "Expected character to exist",
})
```

If `value` is falsy, it logs the error and returns `false`. Otherwise, it returns
`value` unchanged.

::: warning
Unlike Lua's `assert`, this does **not** halt execution — code continues running
after a failed assertion. Use `FATAL` in `Log.Message` instead if you need a hard stop.
:::
