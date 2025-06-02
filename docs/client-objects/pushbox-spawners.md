# Pushbox Spawners

Pushbox spawners are objects that spawn a Pushbox upon pressing the button. It can also be used to spawn other objects.

## Use Cases

Pushbox spawners can be used to spawn a box that can be pushed around, or to reset a contraption parented inside the Pushbox model.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Cooldown` | 0.5 | Delay between being able to respawn the Pushbox group.
| `DontSpawnFirst` | true | When true, the Pushbox group will not automatically spawn when the spawner loads. The button must be pressed for it to spawn.