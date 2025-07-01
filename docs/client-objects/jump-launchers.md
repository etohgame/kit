# Jump Launchers

Jump Launchers are parts that will launch objects inside of it when the player jumps.
If there is a [Pushbox](pushbox-spawners.md) inside of the Jump Launcher, the launcher can be activated simply by jumping. Otherwise, the player has to be inside of the launcher in order to activate it for themselves.

The Jump Launcher's sounds can be modified by editing the `Sound` objects found in the `Sounds` folder. Its particles can be edited by editing the `ParticleEmitter` objects found in the `Particles` attachment.

## Use Cases

Jump Launchers are most commonly used as double jumps. They can be buffered by holding the jump button before touching them, in order to make timing them easier.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Cooldown` | 0.25 | Time in seconds to wait before the Jump Launcher can activate again.
| `Force` | 60 | The speed interacting objects will be launched at when activated.
