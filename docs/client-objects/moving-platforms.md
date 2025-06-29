# Moving Platforms

Moving Platforms are parts that will periodically move between set destinations.

## Use Cases

Moving Platforms can be used to transport players and objects between various locations. They can also rotate if the destinations are rotated.
You can use them to mimic Shoving Platforms from older kits.

## Moving Platform Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `TouchActivated` | false | When true, the platform will not start moving until it is interacted with. Useful for not making the player wait around too long.
| `Tween` | false | When true, the platform will move using the [TweenConfiguration](/docs/global-configurations/tween-configurations.md) found in each destination part instead of moving with the default speed. It will still carry objects. Please note that when this is enabled, the `Reponsiveness` on both the `AlignPosition` and `AlignOrientation` objects must be increased in order to have it function properly.

## Position Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `MoveDelay` | 2 | How long the platform will stay at this position before moving onto the next.
