# TweenConfiguration

All client objects that use tweens have a `TweenConfiguration` configuration object parented inside of their regular configuration. This object holds extra settings relating to what properties the [Tween](https://create.roblox.com/docs/reference/engine/datatypes/TweenInfo#properties) will use.

## Configuration
| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Time` | 1 | The duration of the tween.
| `Style` | `Enum.EasingStyle.Quad` | The [EasingStyle](https://create.roblox.com/docs/reference/engine/enums/EasingStyle) of the tween.
| `Direction` | `Enum.EasingDirection.Out` | The [EasingDirection](https://create.roblox.com/docs/reference/engine/enums/EasingDirection) of the tween.