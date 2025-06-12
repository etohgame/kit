# Morphers

Morphers are objects that can spawn and move parts.

## Use Cases
Morphers can be used to spawn parts the player can interact with.
If the morpher has only one NewMorph part, the main Morph part will move to that part's position rather than creating clones. You can weld parts to the main Morph part and use this functionality to create complex mechanics such as moving objects and cutscenes.

## Configuration
The main Morpher object does not have configurable properties, this list is for the configuration found inside each specific morpher button.

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `CarryObjects` | true | When true, morphing parts will carry objects that are on top of them.
| `EasingStyle` | `Enum.EasingStyle.Quad` | The [EasingStyle](https://create.roblox.com/docs/reference/engine/enums/EasingStyle) of the morpher's movement.
| `EasingDirection` | `Enum.EasingDirection.Out` | The [EasingDirection](https://create.roblox.com/docs/reference/engine/enums/EasingDirection) of the morpher's movement.
| `MoveTime` | 3 | The duration of the morpher's movement, in seconds
| `ReturnTime` | 3 | The duration of the morpher's movement when moving back to the default position, in seconds
| `Timer` | 5 | The duration the morpher will stay active for, after this time has passed the morpher will move back to its default position. If set to 0, the timer does not apply and the morpher will stay active until another morpher button is activated.
| `TimerDecimalPlaces` | 0 | The amount of decimals that will be shown on the timer.
| `TimerText` | `{T}` | The text that will be displayed on the timer. See [this page](/api/ClientObjects#formatTimerText) for more info.