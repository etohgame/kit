# Falling Platforms

Falling Platforms are platforms that will fall when stepped on. Once it touches the `End` part, it will become uncollidable until it's back at its original position.

## Use Cases

Falling Platforms can be used for advanced gameplay mechanics or to force the player not to wait around on certain sections. It is heavily recommended not to use them as traps as it can create frustrating and unfair gameplay.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `ActivateConnectedParts` | true | When true, all other parts welded to the falling platform will also become uncollidable when the main platform touches the `End` part.
| `ActivateCanCollide` | false | The `CanCollide` of the falling platform when active.
| `ActiveTime` | 1.5 | Time in seconds the falling platform will be uncollidable for after it touches the `End` part.
| `ActiveTransparency` | 0.75 | The transparency the falling platform will use while uncollidable.
| `BaseMass` | 12.6 | The mass of the falling platform, used to set the density of the platform. Higher values will make the platform heavier. Very low values may make the platform unstable.
| `InactiveTransparency` | 0 | The transparency the falling platform will use while collidable.
