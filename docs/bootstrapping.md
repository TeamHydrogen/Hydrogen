# Bootstrapping

Hydrogen has an incredibly simple, but also **powerful** bootstrapper for your modules.
This allows us to create simple Services / Controllers (Or whatever you like to call them!) 
very quickly, without any boilerplate in the modules unlike [other frameworks you 
might be used to.](https://github.com/sleitnick/Knit)

## Starting

The bootstrapper contains one singular function and that is:

```luau
Hydrogen:Start()
```

However, it's not just that. Start contains some important config that you need to set,
otherwise it might not work how you want. This will need to be done on the server and the client.

## Configuation

---

Hydrogen takes a table in when you call Start, this is for configuration and has three values:

- Module Directory (ModuleDirectory)
- Module Suffix (ModuleSuffix)
- Lifecycles (RunLifecycles)

---

### Module Directory

Module Directory is a required parameter. This is where you will put your modules. One example could be the current script.

Please place this at the **bottom** of your bootstrapper script. This is so that any custom config can be
handled before any code is ran and also so that you can initialise any custom lifecycles before anything is ran.

```luau
Hydrogen:Start({ModuleDirectory = script})
```

---

### Module Suffix

Module suffix is **NOT** required, however we strongly recommend to change this to your own 
personal preference.

> [!WARNING] 
> By default, Module suffix is set to be "Handler". We recommend you to change this to your own personal 
> preference for familiarity, and to distinguish easily between server and client.

An example is:

```luau
Hydrogen:Start({ModuleSuffix = "Service"})
```

---

### Lifecycles

Lifecycles are a very helpful feature. These will be explained in more detail over [here.](./lifecycles.md)
However, you need to enable the default lifecycles in your bootstrapping code.

There are a couple of ways to configure your lifecycles

---

#### Method 1: Booleans (Recommended)

> [!NOTE]
> We recommend that you enable all lifecycles by default. This is to make it easier
> for you to begin programming and prevent forgetting to enable any custom lifecycles or ones you may need
> in the future.

By default, lifecycles are disabled. However, you can set this to true and enable every single lifecycle.
This makes things much simpler and can be done through

```luau
Hydrogen:Start({RunLifecycles = true})
```

---

#### Method 2: Arrays

Lifecycles can also be custom configured to however you want. Maybe you want a RenderStepped but not a Heartbeat, you can do this!

This is done simply by passing in an array of strings of lifecycle names. These will need to match the exact names

As references to in our [lifecycles page](./lifecycles.md), all default lifecycles are the same as their Roblox connection and we recommend that you do the same for your custom lifecycles

Here is an example of how to do this:

```luau
Hydrogen:Start({RunLifecycles = {"PlayerAdded", "Heartbeat"}})
```

This example above will only enable the PlayerAdded and Heartbeat lifecycles.

## A full setup

Now you know what each parameter does, here is an example of a Hydrogen Start you might want to
do on the server:

> [!NOTE]
> This does NOT contain an entire script for bootstrapping, as there is much more in Hydrogen than just bootstrapping. 

```luau
Hydrogen:Start(
    {
        ModuleDirectory = script,
        ModuleSuffix = "Service",
        RunLifecycles = true
    }
)
```

