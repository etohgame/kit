# Lighting Changers

LightingChangers change the game lighting or lighting instance effects when
touched.

## Use Cases

LightingChangers are used for cinematic effects and help bring together the
mood of towers. Dark lighting can create a gloomy feel. In contrast, bright and
vibrant lighting can heighten the final stretch of a tower.

LightingChangers can be activated by Pushbox, and thus be used in Pushbox
contraptions.

## `Lighting` Module

LightingChangers are configured by a `Lighting` ModuleScript inside the
`LightingChangerConfiguration` that looks like this:

```lua
--!strict
local Change = require(game:GetService("ReplicatedStorage").Framework.Kit.Repository.Visual.LightingChanger.TypeDefs)
-- DON'T TOUCH THE LINE ABOVE -- -- DON'T TOUCH THE LINE ABOVE --

return Change "Atmosphere" {
    TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Configuration = {
        Enabled = false,
    },
}
```

Parentheses are omitted for brevity, but it is okay to write this:

```lua
return Change("Atmosphere")({
    TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Configuration = {
        Enabled = false,
    },
})
```

For ergonomics, the LightingChanger repository type definitions exports a helper
`Change` function that can be used to enforce and create a new
`LightingConfiguration`.

This `Change` function is roughly of type:

<!--
    FUCK YOU MEAN WE USING TYPESCRIPT NOW
    Rahhh curse of developing the welcome to hell codebase -fire
-->
```typescript
type Default = "PlaceDefault" | "TowerDefault" | string

type SupportedLightingObjects = {
    ColorCorrectionEffect: ColorCorrectionEffect | APIDump.ColorCorrectionEffect,
    BlurEffect: BlurEffect | APIDump.BlurEffect,
    Lighting: Lighting | APIDump.Lighting,
    BloomEffect: BloomEffect | APIDump.BloomEffect,
    DepthOfFieldEffect: DepthOfFieldEffect | APIDump.DepthOfFieldEffect,
    Atmosphere: Atmosphere | APIDump.Atmosphere,
    Sky: Sky | APIDump.Sky,
}

type ChangeProps<T> = {
    Configuration: T?,
    SetDefault: Default?,
    UseDefault: Default?,
    TweenInfo: TweenInfo?,
}

function Change<T: keyof<SupportedLightingObjects>>(
    lightingObject: T
): (props: ChangeProps<SupportedLightingObjects[T]>) -> LightingManager.LightingConfiguration
```

### Supported Lighting Objects

<!-- TODO: actual table types? -->

The following lighting object names, which correspond to actual instances under
the Lighting service, can be specified as the first argument:

| Name            | Configurable Properties | Additional Notes
|:---------------:|:-----:|:-----:
| `Configuration` | Brightness, Contrast, Saturation, TintColor |
| `BlurEffect` | Size |
| `Lighting`    | Ambient, Brightness, ClockTime, ColorShift_Bottom, ColorShift_Top, EnvironmentDiffuseScale, EnvironmentSpecularScale, ExposureCompensation, FogColor, FogEnd, FogStart, GeographicLatitude, GlobalShadows,  OutdoorAmbient, ShadowSoftness, TimeOfDay |
| `BloomEffect` | Intensity, Size, Threshold |
| `DepthOfFieldEffect` | FarIntensity, FocusDistance, InFocusRadius, NearIntensity |
| `Atmosphere` | Enabled, Density, Offset, Color, Decay, Glare, Haze | `Enabled` toggles if the Atmosphere effect is parented to `Lighting`.
| `Sky` | MoonAngularSize, MoonTextureId, SkyboxBk, SkyboxDn, SkyboxFt, SkyboxLf, SkyboxRt, SkyboxUp, StarCount, SunAngularSize, SunTextureId, SkyboxOrientation |

### Properties

The second argument is a `ChangeProps` table that is used to specify the
properties that can be changed for a given lighting object.

| Name            | Type                                                | Description
|:---------------:|:---------------------------------------------------:|:-----:
| `Configuration` | `Instance \| APIDump.Instance \| nil`               | A table of new properties for the lighting object, OR a reference to an instance of the lighting object to copy it's properties.
| `SetDefault`    | `"PlaceDefault" \| "TowerDefault" \| string \| nil` | Sets the default properties for either the place or the tower.
| `UseDefault`    | `"PlaceDefault" \| "TowerDefault" \| string \| nil` | Uses the default properties of either the place or the tower.
| `TweenInfo`     | `TweenInfo?`                                        | The `TweenInfo` object used to transition the properties of the lighting object.
