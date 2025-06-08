# Teleporters

Teleporters teleport whitelisted instances via a `TouchConfiguration` to a destination upon touch. Teleporters are defined as any `Model` containing a `TeleporterConfiguration`. Parts named `Teleporter` within the `Model` are considered teleporters, and parts named `Destination` are considered destinations. When any teleporter part in the `Model` is touched, the instance is moved to a random destination within the same `Model`.

## Use Cases

Teleporters can be used to move instances to a designated position.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
|`DisableCollision` | false | Only applies to characters. If true, `BasePart`s in the character have their `CollisionGroup` changed to `NeverCollide` and `CanTouch` set to `false` during the teleport.
|`Instant`| true | If false, the teleported object is translated to the destination based on a `TweenConfiguration`.
|`KeepVelocity`|true|If false, the teleported object's [`AssemblyLinearVelocity`](https://create.roblox.com/docs/reference/engine/classes/BasePart#AssemblyLinearVelocity) and [`AssemblyAngularVelocity`](https://create.roblox.com/docs/reference/engine/classes/BasePart#AssemblyAngularVelocity) are both reset to [`Vector3.zero`](https://create.roblox.com/docs/reference/engine/datatypes/Vector3#zero) immedietely after teleport.
|`Offset.Position`| (0, 0, 0) | The offset, in studs, relative to the destination, the teleported object is teleported.
|`Offset.Orientation`| (0, 0, 0) | The offset, in degrees, relative to the destination, the teleported object is rotated.
|`SeamlessTeleport`| false | If true, the teleported object will be moved and rotated so that it ends up in the same position and orientation relative to the destination as it was relative to the teleporter. Additionally, if a character is being teleported, the player's camera will be oriented relative to the player's new world orientation. Overrides `Offset.Position` and `Offset.Orientation`.
