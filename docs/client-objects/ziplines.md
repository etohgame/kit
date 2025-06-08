# Ziplines

Ziplines carry attached objects allowed via a `TouchConfiguration` along a set path. Ziplines are `Models` that contain a `ZiplineConfiguration`, a folder called `Points`, and a `BasePart` called `MountPart`. The zipline will always try to keep attached objects upright.

## Use Cases

Ziplines can be used to transport players or pushboxes along a set path.

## Configuration

Ziplines must contain a folder called `Points`. This folder must contain at least one `BasePart` named `1`. Additional guide points may be added, with integer names in sequence (eg. `1`, `2`, `3`). Any other parts in the folder are ignored. The positions of the guide points are determined through [De Casteljou's algorithm](https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm).

Ziplines may also contain two additional folders called `GuideEffects` and `Sounds`. If these folders are not present, default fallbacks will be used.

`Sound` instances named `ZiplineLoop` placed inside the `GuideEffects` folder will be looped while the player is travelling through the zipline.
`ParticleEmitter` instances placed inside the `GuideEffects` folder will follow the guide part.
`Sound` instances named `Grab` placed inside the `Sounds` folder will be played when the player initially mounts the zipline.
`Sound` instances named `Jump` placed inside the `Sounds` folder will be played when the player dismounts the zipline.

| Name | Default Value | Description
|:-----:|:-----:|:-----:
|`AllowEndDismount`|`true`|If false, the attached object will automatically detach from the zipline when it reaches the end
|`AllowJumpDismount`|`true`|If true, players may dismount themselves from a zipline by jumping. Note: currently, attached nonplayer objects can be detached by jumping
|`AllowUserControl`|`false`|If true, pressing W/S on PC or using the thumbsticks on other devices will allow players to move themselves along the zipline. When changing directions, the attached object will accelerate and deccelerate at 4 studs per second squared up to the maximum speed. Note: currently, attached nonplayer objects can be moved by using the aformentioned inputs
|`GuideColor`|`rgb(255, 255, 0)`|The color of the part that connects the zipline to the attached object
|`KeepMomentum`|`false`|Whether the attached object retains its momentum when dismounted. Note: If a player has negative vertical momentum, it will not be retained because the player performs a jump when dismounting
|`RopeLength`| 0 |The length of the rope formed between the attached object and the guide part
|`Segments`| 20 | The amount of segments the curve is formed by. Must be a positive integer
|`Speed`|5|The speed, in studs per second, the guide part travels
