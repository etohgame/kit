# Distance Anchoring

Distance Anchoring is a folder that will freeze any physics objects inside of it.

## Use Cases

Distance Anchoring is used for lag reduction. From Kit v6 onwards, most physics objects are now in this folder by default. 

You can disable Distance Anchoring on a per-object basis by dragging them out of this folder, however this is *heavily discouraged unless absolutely necessary* as having too many permanently active objects can cause performance issues, especially if the objects are very big or if you have a lot of them.

## Configuration
| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Range` | 150 | How far away the player can be before objects freeze. Can be overridden on a per-object basis by adding a `number` `Attribute` named `CustomRange` to the object.
| `UpdateInterval` | 0.2 | How often the distance anchoring system will update.