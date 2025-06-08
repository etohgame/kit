# Elevators

Elevators are used to propel players and objects in the direction the elevator is facing.

## Use Cases


## Configuration
| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `ContinuousUpdates` | true | When true, the direction players and objects will be moved in will update when the elevator moves. Otherwise, they will keep moving in the direction the elevator was facing when they entered the elevator.
| `MaxForce` | Infinity | The maximum amount of force the elevator can use when moving objects. Lower values will give the player more control over their movement while in the elevator. Please note that the elevator may not function if set to very low values (~2000 or lower)
| `Speed` | 5 | The speed the elevator will move objects at, in studs per second
| `Vector` | `UpVector` | Which facing direction of the elevator it will move you in. Supported values are `UpVector`, `RightVector` and `LookVector`. Use a negative `Speed` value if you want to reverse these directions