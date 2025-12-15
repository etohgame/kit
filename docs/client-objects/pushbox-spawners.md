# Pushbox Spawners

Pushbox Spawners are objects that spawn a Pushbox upon pressing the button. It can also be used to spawn other objects.

The Pushbox model requires the `SkipObjectLoad` tag in order for the spawner to function.

## Use Cases

Pushbox Spawners can be used to spawn a box that can be pushed around, or to reset a contraption parented inside the Pushbox model.
If the `PushboxSpawnConfiguration` contains a `Sound` named `SpawnSound`, it will be played when the Pushbox spawns.

They can be used to respawn physics objects, to provide consistent setups and prevent them getting stuck in impassable positions.

Starting in v6.1.2, all parts of the Pushbox model will be automatically unanchored when spawned unless they have the `BoxAnchor` tag. It is heavily recommended to keep the entire Pushbox model anchored in Studio to prevent issues caused by delays in client object loading.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Cooldown` | 0.5 | Delay between being able to respawn the Pushbox group.
| `DontSpawnFirst` | true | When true, the Pushbox group will not automatically spawn when the spawner loads. The button must be pressed for it to spawn.
