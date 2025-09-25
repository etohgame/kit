# One-Way Platforms

One-Way platforms are parts that are only solid from one side. When the player is on the other side of the part, it will not be collidable.

## Use Cases

One-Way platforms are useful for making mechanics such as platforms that you can jump through from the bottom, or trapdoors that the player can fall through but not jump back up onto.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `ActivateConnectedParts` | true | When true, all other parts welded to the platform will update their state when the main platform does.
| `ActiveTransparency` | 0 | The transparency the platform will use while collidable.
| `InactiveTransparency` | 0.5 | The transparency the platform will use while uncollidable.
| `Offset` | [`CFrame.new(0, 0, 0)`](https://create.roblox.com/docs/reference/engine/datatypes/CFrame) | Offset applied to the player's checked position when the platform updates.
| `SetActive` | true | When true, toggled platforms will have their Activated attribute update when they toggle their state.
