# Ziplines

Ziplines carry attached objects along a set path.

## Use Cases

Ziplines can be used to transport players or Pushboxes along a set path. They will always try to keep attached objects upright.

## Configuration

A zipline's route is determined using [De Casteljou's algorithm](https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm) on all points in the `Points` folder. These must be named in a numbered sequence (eg. `1`, `2`, `3`). Any other parts in the folder are ignored. All points are automatically welded to the `MountPart`.

The zipline's particles and sounds can be adjusted by adding particles to the `GuideEffects` folder and editing the `Sound` objects in the `Sounds` folder. Defaults will be used if these folders are not present.

The appearance of the zipline's segments can be customized by adding a `Part` with the name `BaseSegment` to the zipline's model. Note that the part's size on the X axis will scale to the size of the segment.

Please note that any configuration related to player input will also apply when non-player objects are mounted on the Zipline.

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `AllowEndDismount` | true | When true, the attached object will automatically detach from the Zipline when it reaches the end.
| `AllowJumpDismount` | true | When true, jumping will cause the attached object to dismount from the Zipline.
| `AllowUserControl` | false | When true, moving forwards or backwards will allow the attached object to move themselves along the Zipline. When changing directions, the attached object will accelerate and deccelerate at 4 studs per second squared up to the maximum speed.
| `HandleAnimation` | true | When true, the player will have an animation of holding on to the zipline.
| `JumpOnDismount` | true | When true, the player will jump when dismounting from the zipline.
| `KeepMomentum` | false | Whether the attached object retains its momentum when dismounted. Note that if a player has negative vertical momentum, it will not be retained because the player performs a jump when dismounting.
| `Loop` | false | When true, and `AllowEndDismount` is false, the Zipline will act like a loop, moving the player between the start and end when passing them. May behave oddly if the position of the zipline and the first point do not match or the position of the first and last points do not match.
| `RopeLength`| 5 | The length of the rope formed between the attached object and the guide part.
| `Segments`| 20 | The amount of segments the curve is formed by. Please note that there is a segment limit in order to reduce lag. The limit is 200 if anchored and 100 if unanchored.
| `Speed` | 5 | The speed the guide part travels at, in studs per second.
| `StartInCenter` | false | When true, the attached object will be warped to the mid-way point of the zipline's path when mounting.
| `UseWeld` | false | When true, mounted objects will be directly welded to the rope bar using a `WeldConstraint` instead of being connected by a `RopeConstraint`. Please note that the player will not interact with any client objects they touch while welded.