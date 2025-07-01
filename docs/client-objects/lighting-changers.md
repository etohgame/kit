# Lighting Changers

Lighting Changers change the game's lighting and lighting effects when used.

## Use Cases

Lighting Changers are used for cinematic effects and help bring together the
mood of towers. For example, dark lighting can create a gloomy feel. In contrast, bright and
vibrant lighting can heighten intense or upbeat sections of towers.

## `Lighting` Module

Lighting Changers are configured inside of a `Lighting` ModuleScript that is found inside the
`LightingChangerConfiguration` object. This module contains a list of lighting objects to change, as well as their properties.
You can define either a single object to change or multiple objects to change at once.

Example usage, changing only a single object:

```lua
return Change "Lighting" {
    TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Configuration = {
        ClockTime = 0,
    },
}
```

Example usage, changing multiple lighting objects at once:

```lua
return {
    TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    Change "Lighting" {
        Configuration = {
            ClockTime = 0,
        },
    },
    Change "ColorCorrectionEffect" {
        Configuration = {
            TintColor = Color3.fromRGB(255, 0, 0),
        },
    },
}
```

### Lighting Presets

Lighting presets can be used to better organize different sets of lighting.
You can create a lighting preset by using `SetDefault` as a `string` parameter in a
lighting changer's configuration module. These can then be reused by using `UseDefault`
as a `string` parameter with the same value.

`PlaceDefault` and `TowerDefault` are special presets that refer to the default lighting of either the place or the tower.

### Supported Lighting Objects

The following lighting object names, which correspond to actual instances under
the Lighting service, can be specified as the object to change:

| Name | Configurable Properties | Additional Notes
|:-----:|:-----:|:-----:
| `Lighting` | Ambient, Brightness, ClockTime, ColorShift_Bottom, ColorShift_Top, EnvironmentDiffuseScale, EnvironmentSpecularScale, ExposureCompensation, FogColor, FogEnd, FogStart, GeographicLatitude, GlobalShadows,  OutdoorAmbient, ShadowSoftness, TimeOfDay | When an `Atmosphere` object is used, fog will automatically be disabled and have no effect.
| `Atmosphere` | Enabled, Density, Offset, Color, Decay, Glare, Haze | Because `Atmosphere` objects do not have an `Enabled` property, it instead toggles whether the Atmosphere effect is parented to `Lighting`.
| `BlurEffect` | Size.
| `BloomEffect` | Intensity, Size, Threshold.
| `ColorCorrectionEffect` | Brightness, Contrast, Saturation, TintColor.
| `DepthOfFieldEffect` | FarIntensity, FocusDistance, InFocusRadius, NearIntensity.
| `Sky` | MoonAngularSize, MoonTextureId, SkyboxBk, SkyboxDn, SkyboxFt, SkyboxLf, SkyboxRt, SkyboxUp, StarCount, SunAngularSize, SunTextureId, SkyboxOrientation.

### Properties

The lighting configuration contains a table that is used to specify the
properties that can be changed for a given lighting object.

| Name | Description
|:-----:|:-----:
| `Configuration` | A table of new properties for the lighting object, OR a reference to an instance of the lighting object to copy it's properties.
| `SetDefault` | Sets the default properties for the given [lighting preset](#lighting-presets).
| `UseDefault` | Uses the default properties from the given [lighting preset](#lighting-presets).
| `TweenInfo` | The `TweenInfo` object used to transition the properties of the lighting object.
