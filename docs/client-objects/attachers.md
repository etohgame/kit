# Attachers

Attachers are objects that enable players and parts to "attach" a set of parts to themselves upon contact.

## Use Cases

Attaching objects (e.g. trails, lights, or spinning killbricks) to the object that interacted with the Attacher.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `AttachUsingAlign` | true | If `false`, uses a WeldConstraint to attach the PrimaryPart. Otherwise, it uses an AlignOrientation and AlignPosition object.
| `CleanDelay` | 3 | Time in seconds to wait before cleaning up attachment objects after dismount.
| `Cooldown` | 0.5 | Time in seconds to wait before the Attacher can activate again
| `DismountState` | [`Enum.HumanoidStateType.Jumping`](https://create.roblox.com/docs/reference/engine/enums/HumanoidStateType#Jumping) | The humanoid state that will trigger a dismount. Some dismount states are not allowed, as they never trigger. In those cases, use [`Enum.HumanoidStateType.None`](https://create.roblox.com/docs/reference/engine/enums/HumanoidStateType#None)
| `DismountStateEnabled` | true | Whether the dismount state check is enabled.
| `Offset` | [`CFrame.new(0, 0, -5)`](https://create.roblox.com/docs/reference/engine/datatypes/CFrame) | Offset applied to the primary part when attaching.
| `WeldToLimb` | [`Enum.Limb.Torso`](https://create.roblox.com/docs/reference/engine/enums/Limb#Torso) | The limb to attach the object to. Ignored if the target is not a player.
