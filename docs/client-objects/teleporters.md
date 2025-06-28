# Teleporters

Teleporters teleport whitelisted instances via a [TouchConfiguration](/docs/global-configurations/touch-configurations.md) to a destination upon touch. Teleporters are defined as any `Model` containing a `TeleporterConfiguration`. Parts named `Teleporter` within the `Model` are considered teleporters, and parts named `Destination` are considered destinations. When any teleporter part in the `Model` is touched, the instance is moved to a random destination within the same `Model`.

## Use Cases

Teleporters can be used to move players and parts to a designated position.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `DisableCollision` | false | Only applies to players. If true, the player will not activate objects they interact with while teleporting.
| `Instant` | true | If true, the teleported object will be instantly moved to the destination. Otherwise, they will move to the destination using the provided [TweenConfiguration](/docs/global-configurations/tween-configurations.md)
| `KeepVelocity` | true | If true, the teleported object will retain its previous velocity when teleporting. Otherwise, it will be reset to 0.
| `Offset` | [`CFrame.new(0, 0, 0)`](https://create.roblox.com/docs/reference/engine/datatypes/CFrame) | When being teleported, the location the teleported object will teleport to will be offset by this value.
| `SeamlessTeleport` | false | If true, the teleported object will be moved and rotated so that it ends up in the same position and orientation relative to the destination as it was relative to the teleporter. Additionally, if a character is being teleported, the player's camera will be oriented relative to the player's new world orientation. Overrides `Offset.Position` and `Offset.Orientation`.