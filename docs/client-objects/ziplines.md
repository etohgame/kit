# Ziplines

Ziplines carry attached objects allowed via a `TouchConfiguration` along a set path. A Zipline is a [`Model`](https://create.roblox.com/docs/reference/engine/classes/Model) that contains a `ZiplineConfiguration`, a [`Folder`](https://create.roblox.com/docs/reference/engine/classes/Folder) called `Points`, and a [`BasePart`](https://create.roblox.com/docs/reference/engine/classes/BasePart) called `MountPart`. The zipline will always try to keep attached objects upright.

## Use Cases

Ziplines can be used to transport players or pushboxes along a set path.

## Configuration

Ziplines must contain a folder called `Points`. This folder must contain at least one `BasePart` named `1`. Additional guide points may be added, with integer names in sequence (eg. `1`, `2`, `3`). Any other parts in the folder are ignored. The positions of the segments are determined through [De Casteljou's algorithm](https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm). Segments are automatically welded to `MountPart`.

Ziplines may also contain two additional `Folder`s called `GuideEffects` and `Sounds`. If these folders are not present, default fallbacks will be used.

[`Sound`](https://create.roblox.com/docs/reference/engine/classes/Sound) instances named `ZiplineLoop` placed inside the `GuideEffects` folder will be looped while the player is travelling through the zipline.
`ParticleEmitter` instances placed inside the `GuideEffects` folder will follow the guide part.
`Sound` instances named `Grab` placed inside the `Sounds` folder will be played when the player initially mounts the zipline.
`Sound` instances named `Jump` placed inside the `Sounds` folder will be played when the player dismounts the zipline.

Please note that any configuration related to player input will also apply when non-player objects are mounted on the zipline.

| Name | Default Value | Description
|:-----:|:-----:|:-----:
|`AllowEndDismount` | `true` | When false, the attached object will automatically detach from the zipline when it reaches the end
|`AllowJumpDismount` | `true` | When true, jumping will cause the attached object to dismount from the zipline
|`AllowUserControl` | `false` | When true, moving forwards or backwards will allow the attached object to move themselves along the zipline. When changing directions, the attached object will accelerate and deccelerate at 4 studs per second squared up to the maximum speed.
|`GuideColor` | `(255, 255, 0)` | The color of the part that connects the zipline to the attached object
|`KeepMomentum` | `false` | Whether the attached object retains its momentum when dismounted. Note that if a player has negative vertical momentum, it will not be retained because the player performs a jump when dismounting
|`RopeLength`| 0 | The length of the rope formed between the attached object and the guide part
|`Segments`| 20 | The amount of segments the curve is formed by. Must be a positive integer. Please note that there is a limit of 100 segments in order to reduce lag.
|`Speed` | 5 | The speed the guide part travels at, in studs per second
