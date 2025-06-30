# Property Changers

Property Changers are objects that can change the properties of any object.

## Use Cases

Property Changers can be used to change properties of objects. They can be used in combination with [Sequencers](sequencers.md) in order to make complex contraptions and sequences.

## Using Property Changers

The Property Changer's `Properties` module can be found inside the `PropertyChangerConfiguration` object. This module contains all of the data of the Property Changer.

Do **not** tamper with the lines placed at the top of the script or write non-intended custom code in functions. There are restrictions in place in order to prevent doing things that aren't allowed, and doing this will make your tower ineligible for submission according to the Custom Client Objects rule.

The table contains a list of properties to change, as well as a `Instance` field that is required for the Property Changer to function. For example, the default properties look like this:

```lua
local Properties: _C.Format = {
    {
        Instance = Toucher(),
        Tween = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        Color = function(_E)
            return _E.Changer():Property("Color")
        end,
    },
}
```

This will change the `Color` of any part that touches the Property Changer to the color of the changer.

The Bullet Velocity Changer (a pre-made PropertyChanger) found in the kit has fields that look like this:

```lua
Instance = Toucher():FindChildOfClass("LinearVelocity"),
Tween = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
VectorVelocity = function(_E)
    return _E.Changer():Property("CFrame").LookVector * _E.Changer():FindChild("PropertyChangerConfiguration"):Property("Speed")
end,
```

This will search for the `LinearVelocity` inside the touching object and set its `VectorVelocity` to the changer's facing direction multiplied by the `Speed` attribute in the `PropertyChangerConfiguration`. More information on these functions can be found below.

* The `Instance` field defines what objects will be affected by the Property Changer.
* If present, the `Tween` field will tween these properties. Note that tweens may be laggy if you are affecting a large amount of objects at once.
* If present, the `Condition` function will make the Property Changer not run if the condition is not met. Read [the documentation on property checkers](#property-checkers) for more info.

Every other field defines properties of the object to change. You can either directly define values or use a function to calculate the value or retrieve the value from another object. More info can be found below.

### Instance Field

There are multiple ways to retrieve the set of objects to affect: `Toucher`, `Tagged`, `TagFromSequenceVariable`, and `Changer`.

`Toucher` will affect the part that touched the Property Changer. An example of this is in the default properties shown earlier.

`Tagged` will look through all Client Objects and affect any objects that have the given [Tag].
Example usage:

```lua
-- This will affect any object in the Client Object folder that has the tag "MyCoolPart"
Instance = Tagged("MyCoolPart"),
```

`TagFromSequenceVariable` is similar to `Tagged`, but the given value is treated as a [Sequence Variable](sequencers.md#sequence-variables) instead.

`Changer` will simply affect the Property Changer itself.

More functions (`:FindChild()`, `:FindDescendant()`, `:FindChildOfClass()`, `:FindDescendantOfClass()`, `:FindAncestor()`, `:FindAncestorOfClass()`, `:Parent()`) can be appended to these to instead affect the object's parent or
children. An example of this is shown in the Bullet Velocity Changer snippet above, with the function grabbing the `LinearVelocity` inside the bullet.

### Built-In Functions

The Property Changer has built-in functions that allow you to retrieve values from other objects. These are listed below.

#### _E.Value()

This function lets you retrieve certain values for usage in the Property Changer. The list of retrievable values is as follows:

| Value | Description | Example Usage
|:-----:|:-----:|:-----:
| `PlayerName` | The player's username | `_E.GetValue("PlayerName")`
| `PlayerDisplayName` | The player's display name | `_E.GetValue("PlayerDisplayName")`
| `UserId` | The player's user ID | `_E.GetValue("UserId")`
| `Distance` | The distance between the player's character and the given position | `_E.GetValue("Distance", Vector3.zero)`
| `CharacterPosition` | The position of the player's character | `_E.GetValue("CharacterPosition")`
| `CharacterCFrame` | The CFrame of the player's character | `_E.GetValue("CharacterCFrame")`
| `PlayerHealth` | The player's health | `_E.GetValue("Health")`
| `CameraCFrame` | The camera's CFrame | `_E.GetValue("CameraCFrame")`
| `HumanoidState` | The player's HumanoidStateType | `_E.GetValue("HumanoidState")`
| `FormatTimer` | Formats the given timer value with the string. See: [the documentation on formatTimerText](/api/ClientObjects#formatTimerText) | `_E.GetValue("FormatTimer", "{M}:{S}:{MS}", 1, 120)`
| `SequenceVariable` | This function lets you retrieve the [Sequence Variable](sequencers.md#sequence-variables) with the given name.| `_E.GetValue("SequenceVariable", "MyAwesomeVariable")`

#### _E.Changer()

This function lets you retrieve any property from the Property Changer itself. This example will change the `Color` of any touching Part to the `Color` of the changer itself:

```lua
Color = function(_E)
    return _E.Changer():Property("Color")
end,
```

#### _E.Instance()

This function lets you retrieve any property from the object you are affecting. This example will change the `Transparency` of any affected Part based on how far away you are from it, with a radius of 30 studs:

```lua
Transparency = function(_E)
    return _E.Value("Distance", _E.Instance():Property("Position")) / 30
end,
```

#### _E.Tagged()

This function lets you retrieve any property from an object with the given [Tag]. This example will retrieve the `Color` of an object that has the tag `MyCoolPart`:

Note that this function only retrieves one object from the tag.

```lua
Color = function(_E)
    return _E.Tagged("MyCoolPart"):Property("Color")
end,
```

#### _E.SequenceInstance()

This function lets you retrieve any property from an object provided by a Sequencer.

Sequencers provide two values:

* TouchingPart - The Part that touched the sequencer's activator
* ActivatingPart - The Activator part that activated the sequencer

This example will retrieve the `Color` of the sequence instance `ActivatingPart`:

```lua
Color = function(_E)
    return _E.SequenceInstance("ActivatingPart"):Property("Color")
end,
```

### Property Checkers

Property Checkers are a special type of Property Changer. If the `Condition` function is present, the Property Changer will not run if the condition is not met. This example will make the Property Changer only work if you are within 50 studs of it:

```lua
local Properties: _C.CheckerFormat = {
    {
        Instance = Changer(),
        Condition = function(_E)
            return _E.Value("Distance", _E.Instance():Property("Position")) < 50
        end,
    },
}
```

If the Property Checker has the `ConditionalEnabled` configuration and is used in a [Sequencer](sequencers.md), its sequence will automatically stop if the condition is not met.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Cooldown` | 0.5 | Delay between being able to activate the Property Changer again.

[Tag]: https://create.roblox.com/docs/studio/properties#instance-tags
