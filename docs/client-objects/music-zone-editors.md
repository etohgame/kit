# Music Zone Editors

Music Zone Editors are used to edit the properties of a music zone.

## Use Cases

Music Zone Editors can change the priority of a Music Zone as well as any properties in the music zone's `Sound` object. Any changes made to a music zone with this client object will automatically reset back to their default values when respawning.

## Editor Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Cooldown` | 1 | Time in seconds to wait before the Music Zone Editor can activate again.
| `OneTimeUse` | false | When true, the music zone editor can only be used one time.
| `ZoneName` | `Floor1` | The name of the music zone to edit. For organization purposes, it is highly recommended to have your music zones' names start with the name of your tower.

## Music Configuration

The music configuration module can be found inside of the main `Configuration` object. If a configuration listed here is not present, it will be ignored.

### ZoneDisabled

The music zone will be disabled if this value is set to `true`.

### ZonePriority

The music zone's priority will be set to this value when triggered.

### SoundConfiguration

This table lists properties that will be applied to the music zone's `Sound` object when triggered.
Example usage:

```lua
SoundConfiguration = {
    PlaybackSpeed = 2,
    Volume = 1,
},
```

### EffectConfiguration

This table lists properties that will be applied to any `SoundEffects` inside the music zone's `Sound` object when triggered. There should be one table per effect, listed by name.
Example usage:

```lua
EffectConfiguration = {
    FlangeSoundEffect = {
        Depth = 0.75,
    },
},
```

### ExtraConfiguration

This table holds extra configurations for the music.

#### KeepTimePosition

When enabled, the music zone will keep the currently playing song's time position plus the defined Offset. Useful for dynamically changing between songs that have multiple versions.

```lua
KeepTimePosition = { Enabled = false, Offset = 0 },
```
