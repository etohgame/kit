# TouchConfiguration

All client objects that can be interacted with have a `TouchConfiguration` configuration object parented inside of their regular configuration. This object holds extra settings relating to what objects are allowed to interact with the client object.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `player` | true | When true, the client object can be interacted with by the player.
| `pushbox` | true | When true, the client object can be interacted with by [Pushboxes](/docs/client-objects/pushbox-spawners.md).
| `turret` | false | When true, the client object can be interacted with by [Turret bullets](/docs/client-objects/turrets.md).
| `balloon` | false | When true, the client object can be interacted with by [Balloons](/docs/client-objects/balloons.md).
| `colorSpecific` | false | When true, the part that interacted with the client object must match the color of the client object to be able to interact with it. This does not affect players.
| `canFlip` | false | When true, the client object can be interacted with using Corner Flips.
