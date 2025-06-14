# Vines

Vines are objects that attach the player or a pushbox to a part using a [rope][RopeConstraint].
Objects on vines dismount either when touching a [Dismounter](dismounters.md) or when the player jumps.

## Use Cases

## Configuration

| Name | Default Value | Description
|------|---------------|------------
| `AllowJumpDismount` | true | Determines whether the vine can be dismounted by jumping
| `KeepMomentum` | true | When true, objects will retain their momentum upon grabbing the vine
| `RespawnTime` | 1 | The time it takes for the vine's `AttachmentPart` to re-appear after the player dismounts it
| `RopeLength` | 8 | The length of the vine's [rope][RopeConstraint]

[RopeConstraint]: https://create.roblox.com/docs/reference/engine/classes/RopeConstraint