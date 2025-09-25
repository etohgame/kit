# TouchConfiguration

All client objects that can be interacted with have a `TouchConfiguration` configuration object parented inside of their regular configuration. This object holds extra settings relating to what objects are allowed to interact with the client object.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `player` | true | When true, the client object can be interacted with by the player.
| `pushbox` | true | When true, the client object can be interacted with by [Pushboxes](/docs/client-objects/pushbox-spawners.md).
| `balloon` | false | When true, the client object can be interacted with by [Balloons](/docs/client-objects/balloons.md).
| `turret` | false | When true, the client object can be interacted with by [Turret bullets](/docs/client-objects/turrets.md).
| `colorSpecific` | false | When true, the part that interacted with the client object must match the color of the client object to be able to interact with it. This does not affect players.
| `canFlip` | false | When true, the client object can be interacted with using Corner Flips.
| `collisionGroup` | false | If set, the `CollisionGroup` of the interacting object and the client object must match in order to be able to interact with it.
| `playerHitboxMode` | `StaticWholeBody` | If set, determines what parts of the player can interact with the client object. See the [Hitbox Modes](#hitbox-modes) section below for more details.

# Hitbox Modes

The `playerHitboxMode` configuration lets you control what parts of the player can interact with the object. These hitboxes ignore animations and as such should be more consistent. A list is provided below.

| Name | Description
|:-----:|:-----:
| `RootPart` | HumanoidRootPart only
| `StaticWholeBody` | Character's entire body
| `StaticCenter` | Character's entire body, excluding arms
| `StaticArms` | Arms & torso only

There are more hitbox types that include the character's actual limbs, note that these do *not* ignore animations:

| Name | Description
|:-----:|:-----:
| `WholeBody` | All limbs
| `Center` | All limbs, excluding the arms