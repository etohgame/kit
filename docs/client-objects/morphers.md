# Morphers

Morphers are objects that can spawn and move parts.

## Use Cases

Morphers can be used to spawn parts the player can interact with.
If the Morpher has only one NewMorph part, the main Morph part will move to that part's position rather than creating clones. You can weld parts to the main Morph part and use this functionality to create complex mechanics such as moving objects in cutscenes.

The Morpher's sounds can be modifiedd by changing them inside each Morpher button's configuration.

## Configuration

The main Morpher object does not have configurable properties, this list is for the configuration found inside each specific Morpher button.

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `CarryObjects` | true | When true, morphing parts will carry objects that are on top of them.
| `Timer` | 0 | The duration the Morpher will stay active for, after this time has passed the Morpher will move back to its default position. If set to 0, the timer does not apply and the Morpher will stay active until another Morpher button is activated.
| `TimerDecimalPlaces` | 0 | The amount of decimals that will be shown on the timer.
| `TimerText` | `{T}` | The text that will be displayed on the timer. See [this page](/api/ClientObjects#formatTimerText) for more info.

Each Morpher button has two [TweenConfiguration](/docs/global-configurations/tween-configurations.md)s, one for activating the Morpher and one for when it deactivates. The time it takes for the Morpher to move (or return to its default spot) can be configured inside these TweenConfigurations.
