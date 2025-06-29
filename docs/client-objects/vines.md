# Vines

Vines are objects that attach the player or a pushbox to a part using the provided constraint ([RopeConstraint](https://create.roblox.com/docs/reference/engine/classes/RopeConstraint) by default). The used constraint can be modified by inserting a new constraint named `VineConstraint` to the Vine.
Objects on vines dismount either when touching a [Dismounter](dismounters.md) or when the player jumps.

The Vine's sounds can be changed by modifying the `Sound` objects inside the `Sounds` folder.

## Use Cases

Vines are used in gameplay, for example to swing to platforms that are otherwise impossible to reach.
The length of the vine can be adjusted by editing the length of the constraint.

## Configuration

| Name | Default Value | Description
|------|---------------|------------
| `AllowJumpDismount` | true | Determines whether the vine can be dismounted by jumping
| `KeepMomentum` | true | When true, objects will retain their momentum upon grabbing the vine
| `RespawnTime` | 1 | The time it takes for the vine's `AttachmentPart` to re-appear after the player dismounts it
