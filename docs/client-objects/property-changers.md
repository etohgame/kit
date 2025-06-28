# Property Changers

Property Changers are objects that can change the properties of any object.

## Use Cases

Property Changers can be used to change properties of objects. They can be used in combination with [Sequencers](sequencers.md) in order to make complex contraptions and sequences.

## Using Property Changers

The Property Changer's `Properties` module can be found inside the `PropertyChangerConfiguration` object. This module contains all of the data of the Property Changer.

Do **not** tamper with the lines placed at the top of the script or write non-intended custom code in functions. There are restrictions in place in order to prevent doing things that aren't allowed, and doing this will make your tower ineligible for submission according to the Custom Client Objects rule.

The table contains a list of properties to change, as well as a `Instance` field that is required for the Property Changer to function. For example, the default properties look like this:
```lua
local Properties: Types.Format = {
	{
        Instance = Toucher(),
        Tween = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),

        Color = function(_C)
			return _C.PropertyFromChanger("Color")
		end,
	},
}
```
This will change the `Color` of any part that touches the Property Changer to the color of the changer.

The Bullet Velocity Changer (a pre-made PropertyChanger) found in the kit has fields that look like this:
```lua
Instance = Toucher():FindChildOfClass("LinearVelocity"),

VectorVelocity = function(_C)
    return _C.PropertyFromChanger("CFrame").LookVector * _C.PropertyFromChanger("Speed", "PropertyChangerConfiguration")
end,
```
This will search for the `LinearVelocity` inside the touching object and set its `VectorVelocity` to the changer's facing direction multiplied by the `Speed` attribute in the `PropertyChangerConfiguration`. More information on these functions can be found below.

The `Instance` field defines what objects will be affected by the Property Changer, and if present, the `Tween` field will tween these properties. Note that tweens may be laggy if you are affecting a large amount of objects at once.

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

`TagFromSequenceVariable` is similar to `Tagged`, but the given value is treated as a [Sequence Pointer](sequencers.md#using-sequencers) instead.

`Changer` will simply affect the Property Changer itself.

More functions (`:FindChild()`, `:FindDescendant()`, `:FindChildOfClass()`, `:FindDescendantOfClass()`, `:FindAncestor()`, `:FindAncestorOfClass()`, `:Parent()`) can be appended to these to instead affect the object's parent or
children. An example of this is shown in the Bullet Velocity Changer snippet above, with the function grabbing the `LinearVelocity` inside the bullet.

### Built-In Functions

The Property Changer has built-in functions that allow you to retrieve values from other objects. These are listed below.

#### _C.Value()

This function lets you retrieve certain values for usage in the Property Changer. The list of retrievable values is as follows:

| Value | Description | Example Usage
|:-----:|:-----:|:-----:
| `PlayerName` | The player's username | `_C.GetValue("PlayerName")`
| `DisplayName` | The player's display name | `_C.GetValue("DisplayName")`
| `UserId` | The player's user ID | `_C.GetValue("UserId")`
| `CharacterPosition` | The position of the player's character | `_C.GetValue("CharacterPosition")`
| `CharacterCFrame` | The CFrame of the player's character | `_C.GetValue("CharacterCFrame")`
| `Distance` | The distance between the player's character and the given position | `_C.GetValue("Distance", Vector3.zero)`
| `PlayerHealth` | The player's health | `_C.GetValue("Health")`

#### _C.PropertyFromChanger()

This function lets you retrieve any property from the Property Changer itself. This example will change the `Color` of any touching Part to the `Color` of the changer itself:
```lua
Color = function(_C)
    return _C.PropertyFromChanger("Color")
end,
```

#### _C.PropertyFromInstance()

This function lets you retrieve any property from the object you are affecting. This example will change the `Transparency` of any affected Part based on how far away you are from it, with a radius of 30 studs:
```lua
Transparency = function(_C)
    return _C.Value("Distance", _C.PropertyFromInstance("Position")) / 30
end,
```

#### _C.PropertyFromTag()

This function lets you retrieve any property from an object with the given [Tag]. This example will retrieve the `Color` of an object that has the tag `MyCoolPart`:
```lua
Color = function(_C)
    return _C.PropertyFromTag("MyCoolPart", "Color")
end,
```

#### _C.SequenceVariable()

This function lets you retrieve the [Sequence Variable](sequencers.md#using-sequencers) with the given name. This example will retrieve the value from the sequence variable `MyAwesomeVariable`:
```lua
Color = function(_C)
    return _C.SequenceVariable("MyAwesomeVariable")
end,
```

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Cooldown` | 0.5 | Delay between being able to activate the Property Changer again.

[Tag]: https://create.roblox.com/docs/studio/properties#instance-tags