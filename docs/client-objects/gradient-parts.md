# Gradient Parts

Gradient Parts change their `Color` and `Transparency` over time by using a `UIGradient` instance.

To improve performance, the shifting of Gradient Parts will temporarily pause when the player is
further than a set distance away from the `DistancePivot` part.

All affected parts must either be named `GradientPart` or have a `GradientPart` tag.

## Use Cases

Gradient Parts can be used for decoration. A few examples of these are pulsing parts and rainbow parts.
Unlike `Beam`s, which can have multiple colors at once, the color of Gradient Parts is uniform across all parts.

Gradient Parts automatically affect any applicable objects inside them as well. This can be disabled by adding a `DoNotColor` tag to any objects you don't want colored.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `MaxDistance` | 100 | The furthest the player can be from the `DistancePivot` before the Gradient Parts will pause to improve performance.
| `RefreshRate` | 30 | How many times per second the Gradient Parts will update.
| `TickOffset` | 0 | The offset in seconds for the shifting calculation.
| `Throttle` | 64 | The part throttle limit. If there are more parts in a Gradient Parts group than the configured maximum, there will be a 1 frame delay every that amount of parts to improve performance.
