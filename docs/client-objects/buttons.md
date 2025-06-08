# Buttons

Buttons are parts that, when touched by objects allowed via a `TouchConfiguration`, toggle a set of parts between a Pressed and Unpressed state.

Buttons are defined as [`Models`](https://create.roblox.com/docs/reference/engine/classes/Model) containing a `ButtonConfiguration` and a [`BasePart`](https://create.roblox.com/docs/reference/engine/classes/BasePart) named `ButtonPart`. By default, Buttons are linked to their corresponding Button Activated Objects if the [`Color`](https://create.roblox.com/docs/reference/engine/classes/BasePart#Color) of the `ButtonPart` matches that of the Button Activated Object.

## Use Cases

Buttons may be used to create toggleable parts and objects, or to display text on the player's screen.

## Configuration

### `PressedMaterial`

The [`Material`](https://create.roblox.com/docs/reference/engine/enums/Material) of the Button when pressed. `Neon` by default.

### `PressOffset`

Consists of two [`Vector3`](https://create.roblox.com/docs/reference/engine/datatypes/Vector3) values, `Position` and `Orientation`. `Position` is the offset, in Studs, of the `ButtonPart`. `Orientation` is the offset, in degrees, of the `ButtonPart`. The time it takes for the `ButtonPart` to reach the `Position` and `Orientation` may be determined via a `TweenConfiguration`.

### `Timer`

The time, in seconds, a Button remains pressed before returning to the unpressed state. If positive, it will display the remaining time on a [`SurfaceGui`](https://create.roblox.com/docs/reference/engine/classes/SurfaceGui) on the `Top` surface of the `ButtonPart` as well as a [`ScreenGui`](https://create.roblox.com/docs/reference/engine/classes/ScreenGui) on the player's screen. By default, Buttons do not have timers.

### `TimerDecimalPlaces`

The number of decimal places displayed by any timer displays.

### `TimerText`

The text that appears on any timer display. Can be any [`string`](https://create.roblox.com/docs/reference/engine/libraries/string).
See [this page](/api/ClientObjects#formatTimerText) for more info.

### `TimerLabel`

If the main Button `Model` contains a [`TextLabel`](https://create.roblox.com/docs/reference/engine/classes/TextLabel) named `TimerLabel`, it will be used on the [`SurfaceGui`](https://create.roblox.com/docs/reference/engine/classes/SurfaceGui) on the `Top` surface of the `ButtonPart` as well as the [`ScreenGui`](https://create.roblox.com/docs/reference/engine/classes/ScreenGui).

#### `UseSpecialColor`

This [`Tag`](https://create.roblox.com/docs/reference/engine/classes/CollectionService) should only be used on a `TimerLabel`. If present, it disables the automatic coloring of the `TimerLabel`.

### `HideGui`

Determines whether a timer is displayed on both the surface of the Button as well as on the player's screen. If `true`, neither will appear.

## Button Activated Objects

Any [`BasePart`](https://create.roblox.com/docs/reference/engine/classes/BasePart) and certain Client Objects containing a [`Tag`](https://create.roblox.com/docs/reference/engine/classes/CollectionService) named `ButtonActivated` is considered a Button Activated Object.

By default, a Button Activated Part behaves as follows:

| State of corresponding button | [`CanCollide`](https://create.roblox.com/docs/reference/engine/classes/BasePart#CanCollide) | [`Transparency`](https://create.roblox.com/docs/reference/engine/classes/BasePart#Transparency) | Client Object State |
|-------------------------------|--------------|----------------|----------------|
| Unpressed                     | `false`      | `0.6`          | disabled |
| Pressed                       | `true`       | `0`            | enabled |

It should be noted that if 64 or more parts are toggled at once, there will be a 1 frame delay every 64 parts to improve performance.

### Supported Visual Instances

Instances of the following classes that are parented to the Button Activated Part will have their `Transparency` tweened to match the Part's transparency:

| Transparency-tweenable instances |
|--------------------------------|
| [`Decal`](https://create.roblox.com/docs/reference/engine/classes/Decal) |
| [`Texture`](https://create.roblox.com/docs/reference/engine/classes/Texture) |
| [`SelectionBox`](https://create.roblox.com/docs/reference/engine/classes/SelectionBox) |
| [`SelectionSphere`](https://create.roblox.com/docs/reference/engine/classes/SelectionSphere) |
| [`Frame`](https://create.roblox.com/docs/reference/engine/classes/Frame) |
| [`CanvasGroup`](https://create.roblox.com/docs/reference/engine/classes/CanvasGroup) |
| [`TextLabel`](https://create.roblox.com/docs/reference/engine/classes/TextLabel) |
| [`ImageLabel`](https://create.roblox.com/docs/reference/engine/classes/ImageLabel) |

Instances of the following classes that are parented to the Button Activated Part will have their `Enabled` property toggled to match the Button Activated Part's collision state:

| Enabled toggle instances |
|---------------------------|
| [`Beam`](https://create.roblox.com/docs/reference/engine/classes/Beam) |
| [`ParticleEmitter`](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter) |
| [`Fire`](https://create.roblox.com/docs/reference/engine/classes/Fire) |
| [`Sparkles`](https://create.roblox.com/docs/reference/engine/classes/Sparkles) |
| [`Smoke`](https://create.roblox.com/docs/reference/engine/classes/Smoke) |
| [`Trail`](https://create.roblox.com/docs/reference/engine/classes/Trail) |
| [`UIStroke`](https://create.roblox.com/docs/reference/engine/classes/UIStroke) |
| [`UIGradient`](https://create.roblox.com/docs/reference/engine/classes/UIGradient) |

## Button Activated Part Configurations

### `ColorOverride`

If a [`Color3`](https://create.roblox.com/docs/reference/engine/datatypes/Color3) attribute called `ColorOverride` is parented to a Button Activated Part, the part will be considered a Button Activated Object of that Color. If a `ButtonPart` has this attribute, its functionality may be toggled by other Buttons.

Below are [`Tags`](https://create.roblox.com/docs/reference/engine/classes/CollectionService) that may be added to a Button Activated Part.

### `FullHidePlatform`

Sets the Unpressed `Transparency` to `1`.

### `SetTransparency`

Attribute. Its value is the `Transparency` of the Button Activated Part in the Unpressed state.

### `IgnoreTransparency`

`Transparency` of the Button Activated Part will not be changed and remains in its default state.

### `Invisible`

The `Transparency` of the Button Activated Part is always `1`.

### `IgnoreCanCollide`

The `CanCollide` property of the Button Activated Part will not be toggled and remains in its default state.

### `IgnoreEnabled`

[Enabled toggle instances](#supported-visual-instances) will not have their `Enabled` property toggled.

### `InvertPlatform`

Swaps the collision and Transparency data in the Pressed and Unpressed states.

### `IgnoreInitialActivate`

The Button Activated Part will retain its properties as they were in Studio, instead of having its collision and `Transparency` match the default Unpressed state. If the Button is deactivated by any means, it will behave identically to any other Button Activated Part that does not have this Tag.

### `IgnoreAll`

The Button Activated Part will not have its collision or Transparency changed.

## Unsupported Client Objects

Below is a list of all the client objects that cannot currently be toggled by a Button.

| Unsupported Client Objects | Notes |
|------------| ------------------|
| Vanishers | Inconsistent behaviour when toggled while vanishing |
