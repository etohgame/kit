# Ziplines

Ziplines carry attached objects along a set path.

## Use Cases

Ziplines can be used to transport players or Pushboxes along a set path. They will always try to keep attached objects upright.

## Configuration

A Zipline's route is determined using [De Casteljou's algorithm](https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm) on all points in the `Points` folder. These must be named in a numbered sequence (eg. `1`, `2`, `3`). Any other parts in the folder are ignored. All points are automatically welded to the `MountPart`.

The Zipline's particles and sounds can be adjusted by adding particles to the `GuideEffects` folder and editing the `Sound` objects in the `Sounds` folder. Defaults will be used if these folders are not present.

Please note that any configuration related to player input will also apply when non-player objects are mounted on the Zipline.

| Name | Default Value | Description
|:-----:|:-----:|:-----:
|`AllowEndDismount` | `true` | When true, the attached object will automatically detach from the Zipline when it reaches the end.
|`AllowJumpDismount` | `true` | When true, jumping will cause the attached object to dismount from the Zipline.
|`AllowUserControl` | `false` | When true, moving forwards or backwards will allow the attached object to move themselves along the Zipline. When changing directions, the attached object will accelerate and deccelerate at 4 studs per second squared up to the maximum speed.
|`GuideColor` | `(255, 255, 0)` | The color of the part that connects the Zipline to the attached object.
|`KeepMomentum` | `false` | Whether the attached object retains its momentum when dismounted. Note that if a player has negative vertical momentum, it will not be retained because the player performs a jump when dismounting.
|`Loop` | false | When true, and `AllowEndDismount` is false, the Zipline will reset back to the start of the path when it reaches the end. May behave oddly if the start and end of the path are not at the same location.
|`RopeLength`| 5 | The length of the rope formed between the attached object and the guide part.
|`Segments`| 20 | The amount of segments the curve is formed by. Please note that there is a limit of 100 segments in order to reduce lag.
|`Speed` | 5 | The speed the guide part travels at, in studs per second.
