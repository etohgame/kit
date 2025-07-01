# Vines

Vines are objects that attach the player or a Pushbox to a part using the provided constraint ([RopeConstraint](https://create.roblox.com/docs/reference/engine/classes/RopeConstraint) by default). The used constraint can be modified by inserting a new constraint named `VineConstraint` to the Vine.
Objects on Vines dismount either when touching a [Dismounter](dismounters.md) or when the player jumps.

The Vine's sounds can be changed by modifying the `Sound` objects inside the `Sounds` folder.

## Use Cases

Vines are used in gameplay, for example to swing to platforms that are otherwise impossible to reach. They can be combined with fast elevators to make unique momentum jumps.
The length of the Vine can be adjusted by editing the length of the constraint.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `AllowJumpDismount` | true | Determines whether the Vine can be dismounted by jumping.
| `KeepMomentum` | true | When true, objects will retain their momentum upon grabbing the Vine.
| `RespawnTime` | 1 | The time it takes for the Vine's `AttachmentPart` to re-appear after the player dismounts it.
