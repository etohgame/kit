# Buttons

Buttons are parts that toggle a set of parts between a Pressed and Unpressed state. They are linked to their corresponding button activated objects by their `Color` property.

## Use Cases

Buttons may be used to create toggleable parts and objects.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `HideGUI` | false | When true, the timer label displayed on the button and the game's UI will not be shown.
| `PressedMaterial` | `Neon` | The material of the Button when pressed.
| `PressOffset` | [`CFrame.new(0, -0.75, 0)`](https://create.roblox.com/docs/reference/engine/datatypes/CFrame) | The offset of the ButtonPart when pressed. Uses the provided [TweenConfiguration](/docs/global-configurations/tween-configurations.md).
| `Timer` | 0 | The time the button will be activated for before automatically deactivating. If set to 0, the button will not have a timer.
| `TimerDecimalPlaces` | 0 | The number of decimal places displayed on the timer label.
| `TimerText` | `{T}` | The text that appears on the timer display. See [this page](/api/ClientObjects#formatTimerText) for more info.

The `TimerLabel` is found inside the `ButtonConfiguration` and can be configured seperately.
The `UseSpecialColor` tag can be used on the `TimerLabel` to disable its automatic coloring.

## Button Activated Objects

Any Part with the `ButtonActivated` tag will be considered a button activated object. By default, button activated objects behave as follows:

| Button State | CanCollide | Transparency | Client Object State |
|:-----:|:-----:|:-----:|:-----:
| Unpressed | `false` | `0.6` | Disabled |
| Pressed | `true` | `0` | Enabled |

These will be inverted if the object has the `Invert` tag.

Please note that if 64 or more parts are toggled at once, there will be a 1 frame delay every 64 parts to improve performance.

### Supported Visual Instances

If the following objects are found inside of a button activated object, they will match the object's transparency when toggled:

| Object | Property Affected |
|:-----:|:-----:
| [`Decal`](https://create.roblox.com/docs/reference/engine/classes/Decal) | `Transparency` |
| [`Texture`](https://create.roblox.com/docs/reference/engine/classes/Texture) | `Transparency` |
| [`SelectionBox`](https://create.roblox.com/docs/reference/engine/classes/SelectionBox) | `Transparency` |
| [`SelectionSphere`](https://create.roblox.com/docs/reference/engine/classes/SelectionSphere) | `Transparency` |
| [`Frame`](https://create.roblox.com/docs/reference/engine/classes/Frame) | `BackgroundTransparency` |
| [`CanvasGroup`](https://create.roblox.com/docs/reference/engine/classes/CanvasGroup) | `GroupTransparency` |
| [`TextLabel`](https://create.roblox.com/docs/reference/engine/classes/TextLabel) | `TextTransparency` |
| [`ImageLabel`](https://create.roblox.com/docs/reference/engine/classes/ImageLabel) | `ImageTransparency` |

If the following objects are found inside of a button activated object, they will have their `Enabled` property toggled to match the button's state:

| Object |
|---------------------------|
| [`Beam`](https://create.roblox.com/docs/reference/engine/classes/Beam) |
| [`ParticleEmitter`](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter) |
| [`Fire`](https://create.roblox.com/docs/reference/engine/classes/Fire) |
| [`Sparkles`](https://create.roblox.com/docs/reference/engine/classes/Sparkles) |
| [`Smoke`](https://create.roblox.com/docs/reference/engine/classes/Smoke) |
| [`Trail`](https://create.roblox.com/docs/reference/engine/classes/Trail) |
| [`UIStroke`](https://create.roblox.com/docs/reference/engine/classes/UIStroke) |
| [`UIGradient`](https://create.roblox.com/docs/reference/engine/classes/UIGradient) |

## Button Activated Object Configurations

Button activated objects have special configurations that can be modified using Attributes and Tags:

| Name | Type | Description
|:-----:|:-----:|:-----:
| `ColorOverride` | `Color3` Attribute | The object will behave as if it is linked to that `Color` rather than the object's actual color. If a `ButtonPart` has this attribute, its functionality may be toggled by other Buttons.
| `FullHide` | Tag | Sets the Unpressed `Transparency` to 1.
| `SetTransparency` | `number` Attribute | Changes the `Transparency` of the object in the Unpressed state.
| `IgnoreTransparency` | Tag | The `Transparency` of the object will not be changed and remains in its default state from Studio.
| `IgnoreCanCollide` | Tag | The `CanCollide` of the object will not be changed and remains in its default state from Studio.
| `IgnoreEnabled` | Tag | The `Enabled` property of the object will not be changed and remains in its default state from Studio.
| `Invisible` | Tag | The `Transparency` of the object will always be 1 no matter the button state.
| `Invert` | Tag | Swaps the properties of the Pressed and Unpressed states.
| `IgnoreInitialActivate` | Tag | The object will not be affected by the first update that happens when the Button initially loads. It will still be affected by further updates.
| `IgnoreAll` | Tag | The object will act as if the `IgnoreTransparency`, `IgnoreCanCollide` and `IgnoreEnabled` tags are all present.

## Unsupported Client Objects

Below is a list of all the client objects that either cannot currently be toggled by a Button, or have known issues regarding them when button activated.

| Unsupported Client Object | Notes |
|------------| ------------------|
| [Vanishers](vanishers.md) | Inconsistent behaviour when toggled while vanishing |