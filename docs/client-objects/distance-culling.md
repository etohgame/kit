# Distance Culling

Distance Culling is a folder that will freeze or unload any physics objects inside of it.

## Use Cases

Distance Culling is used for lag reduction. From Kit v6 onwards, most physics objects are now in this folder by default.

You can disable Distance Culling on a per-object basis by dragging them out of this folder, however this is *heavily discouraged unless absolutely necessary* as having too many permanently active objects can cause performance issues, especially if the objects are very big or if you have a lot of them.

Objects inside Distance Culling must have a `PrimaryPart` in order for them to function.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Range` | 150 | How far away the player can be before objects toggle. Can be overridden on a per-object basis by adding a `number` `Attribute` named `CustomRange` to the object.
| `UpdateInterval` | 0.2 | How often the distance culling system will update.
| `Mode` | `Anchor` | How the distance culling system will behave. See [Modes](#modes) for more information.

## Modes

| Mode | Description
|:-----:|:-----:
| `Anchor` | Far-away objects will freeze in place.
| `Unload` | Far-away objects will unload entirely.