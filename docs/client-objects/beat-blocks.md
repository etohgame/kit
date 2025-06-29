# Beat Blocks

Beat blocks are groups of parts that will toggle on and off on a set interval.

## Use Cases

Beat blocks can be used for gameplay where the player has to time their jumps, or as animated design.

## Music Sync

Beat blocks can be synced to the tower's music. This will make the beat blocks toggle on every beat of the currently playing song. See [the documentation on music sync](/docs/misc.md#music-sync-configuration) for more information.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Indicator` | true | When true, an indicator will be shown on the next set of parts before they toggle. This will help the player time their movement. It is heavily recommended to leave this enabled if you are using the beat blocks for gameplay purposes.
| `Interval` | 1 | The interval in seconds between the beat blocks toggling on and off.
| `MaterialIndicator` | SmoothPlastic | When the `Indicator` configuration is enabled, the indicator will use this material.
| `OffCanCollide` | false | When a beat block is off, its CanCollide property will be set to this value.
| `OffCanTouch` | true | When a beat block is off, its CanTouch property will be set to this value.
| `OffTransparency` | 0.7 | When a beat block is off, its Transparency property will be set to this value.
| `OnCanCollide` | true | When a beat block is on, its CanCollide property will be set to this value.
| `OnCanTouch` | true | When a beat block is on, its CanTouch property will be set to this value.
| `OnTransparency` | 0 | When a beat block is on, its Transparency property will be set to this value.
