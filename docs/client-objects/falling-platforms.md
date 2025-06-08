# Falling Platforms

Falling Platforms are platforms that will fall when stepped on. Once they touch the `End` part, they will become uncollidable until they are back at their original position.

## Use Cases

Falling Platforms can be used to force the player not to wait around on certain sections. It is heavily recommended not to use them as traps as it can create frustrating and unfair gameplay.

## Configuration
| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `ActiveTime` | 1.5 | Time in seconds the falling platform will be uncollidable for after it reaches the `End` part.
| `ActiveTransparency` | 0.75 | The transparency the falling platform when use while uncollidable.
| `BaseMass` | 4.8 | The mass of the falling platform. Change this when resizing the falling platform.
| `InactiveTransparency` | 0 | The transparency the falling platform when use while collidable.