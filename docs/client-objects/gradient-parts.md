# GradientParts

GradientParts shifts it's `Color` over time by using a `UIGradient` instance.

For performance, GradientParts will stop shifting colors when the player is
further than a set distance from a child `DistancePivot` part.

## Use Cases

GradientParts can be used for decoration, such as the rainbow parts shown in
Citadel of Void.

Unlike Beam instances, which uses a texture, the `Color` of GradientParts are
uniform.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `DistanceAnchor` | 100 | The furthest the player can be from it's `DistancePivot` to shift colors
| `Speed` | 60 | How long, in seconds, to fully cycle colors from the `UIGradient`.
