# Swings

Swings are objects that the player can mount and swing around on.

## Use Cases

Swings can be used to create complex gameplay sections and jumps.

## Swing Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `AllowJumpDismount` | true | When true, the Swing is able to be dismounted by jumping.
| `BallSocketMode` | false | When true, the Swing will use a BallSocketConstraint instead of HingeConstraints. Allows 360-degree movement.
| `Boost` | 0 | The velocity the player will dismount with. If set to 0, they will dismount while preserving the velocity they currently have. Otherwise, they will be launched in the direction the Swing part is facing.
| `Cooldown` | 1 | Time in seconds to wait before the Swing can be mounted again.
| `DontAnchor` | false | When true, the Swing part will be locked in place below the `Top` part until the player mounts the Swing. Otherwise, it can move around freely. Recommended to keep as false if you are making the Swing move around.
| `JumpOff` | true | When true, the player will jump when dismounting. Otherwise, they will simply start falling.

## Control Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `CanControl` | true | When true, the player will be able to control the movement of the Swing.
| `Force` | 750 | The amount of force exerted when the player controls the swing.
| `MaxVelocity` | 75 | The maximum speed the swing can move at while being controlled by the player.