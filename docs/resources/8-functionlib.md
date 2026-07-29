# FunctionLib

A collection of general-purpose utility functions used throughout Hydrogen —
number formatting, string/table helpers, and dictionary utilities.

## Number Formatting

### ToSuffixString

Converts a number into a shortened, suffixed string (e.g. `1000` → `1K`).

```lua
Hydrogen.FunctionLib:ToSuffixString(1500000) --> "2M"
```

### ToScientificNotation / ToRegularNumber

Converts between a regular number and scientific notation string.

```lua
Hydrogen.FunctionLib:ToScientificNotation(1500) --> "1.5e3"
Hydrogen.FunctionLib:ToRegularNumber("1.5e3")   --> 1500
```

::: warning
`ToRegularNumber` expects the exact format returned by `ToScientificNotation`
(`"Ae+B"` or `"Ae-B"`). Malformed strings will error.
:::

## Time

### SecsToMins

Converts seconds into minutes/seconds, either as a table or formatted string.

```lua
Hydrogen.FunctionLib:SecsToMins(90)             --> { Mins = 1, Secs = 30 }
Hydrogen.FunctionLib:SecsToMins(90, true)       --> "1:30"
Hydrogen.FunctionLib:SecsToMins(45, true)       --> "45s"
```

## Strings & Tables

### FindPossibleStringsInString

Returns the first value from `Values` that appears inside `String`, or `nil`.

```lua
Hydrogen.FunctionLib:FindPossibleStringsInString("HelloWorld", { "World", "Foo" }) --> "World"
```

### FindStringsInTable

Returns `true` only if every string in `Strings` also exists in `Values`.

```lua
Hydrogen.FunctionLib:FindStringsInTable({ "A", "B" }, { "A", "B", "C" }) --> true
```

### FindFirstDescendant

Same idea as `FindFirstChild`, but searches all descendants for a matching name.

```lua
Hydrogen.FunctionLib:FindFirstDescendant(SomeFolder, "Explosion")
```

::: warning
If multiple descendants share the same name, the **last** one found is returned,
not necessarily the first in hierarchy order.
:::

## Instances

### CheckIfPartIsPlayer

Checks whether a `BasePart`'s parent is a character model (has a `Humanoid`).

```lua
Hydrogen.FunctionLib:CheckIfPartIsPlayer(Hit) --> true / false
```

Useful in `Touched` events to filter for player characters.

## Dictionaries

::: tip
`MergeDictionary` and `CopyDeep` are adapted from [Sift](https://github.com/cxmeel/sift) — credit to cxmeel and contributors.
:::

### MergeDictionary

Merges any number of dictionaries into one. Later tables override earlier ones.

```lua
Hydrogen.FunctionLib:MergeDictionary({ A = 1, B = 2 }, { B = 3 }) --> { A = 1, B = 3 }
```

::: warning
Setting a key's value to `Hydrogen.FunctionLib.None` removes it from the result — useful for
deleting a key during a merge rather than overwriting it.
:::

### CopyDeep

Returns a full deep copy of a table, including nested tables.

```lua
local Copy = Hydrogen.FunctionLib:CopyDeep(OriginalTable)
```
