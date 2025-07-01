# Elevators

Elevators are used to propel players and objects in the direction they are facing.

## Use Cases

Elevators can be used to move players and objects around, or launch them away. Elevators will keep applying a set velocity as long as the object is touching or inside of the Elevator.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `ContinuousUpdates` | false | When true, the direction players and objects will be moved in will update when the Elevator moves. Otherwise, they will keep moving in the direction the Elevator was facing when they entered the Elevator.
| `MaxForce` | Infinity | The maximum amount of force the Elevator can use when moving objects. Lower values will give the player more control over their movement while in the Elevator. Please note that the Elevator may not function if set to very low values (~2000 or lower).
| `Speed` | 40 | The speed the Elevator will move objects at, in studs per second.
| `HitboxMode` | `StaticWholeBody` | The [hitbox mode](/docs/misc.md#hitbox-modes) used by the Elevator.
| `Vector` | `UpVector` | Which facing direction of the Elevator it will launch objects in. Supported values are `UpVector`, `RightVector` and `LookVector`. Use a negative `Speed` value if you want to reverse these directions.