# Dialog System

Dialog System allows you to display dialog on the player's screen, including special effects and other functionality.

## Use Cases

The Dialog System allows you to display text with special effects on the player's screen along with other functionality such as activating buttons.

## Dialog Parts

Configurations of Dialog Parts work differently compared to the usual configurations in the kit. Configurations regarding the activation of Dialog Parts are Attributes directly on the part.

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `ActionText` | `Dialog` | When `ProximityActivated` is true, the text that will show up on the `ProximityPrompt`.
| `ClickActivated` | false | When true, the dialog part can be activated using a click detector.
| `ClickDistance` | 16 | When `ClickActivated` is true, the maximum distance the dialog part can be activated from.
| `ColorSpecificCheck` | false | When true and `PushboxTouchActivated` is true, the color of the Pushbox must match the color of the dialog part for it to be activated.
| `PlayerTouchActivated` | true | When true, the dialog part can be activated by the player touching it.
| `ProximityActivated` | true | When true, the dialog part can be activated by the player activating a `ProximityPrompt` on it.
| `PushboxTouchActivated` | false | When true, the dialog part can be activated by Pushboxes.
| `Uses` | Infinite | The amount of times the dialog part can be activated.

## Dialog Setup

Dialogs are set up by creating dialog configuration instances inside the `__DIALOG__` folder found inside the dialog part. The dialogs are ordered by name.
Each dialog object has attributes that control how the text displays, and also contains `StringValue` objects ordered by name containing more attributes that control how the text displays. The `StringValue` also contains an `Effects` folder that lets you toggle text effects.

### Dialog Configuration Attributes

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `ActivateButtonBeforeDialog` | N/A (Color3 Attribute) | Activates any button (before the dialog plays) that is the same color as the attribute.
| `ActivateButton` | N/A (Color3 Attribute) | Activates any button that is the same color as the attribute.
| `AwaitFinish` | true | Determines whether the dialog will wait for the text to finish typing.
| `AwaitTextFade` | false | Determines whether the dialog will wait for the text to fade out.
| `ClearInterval` | 0.02 | How long it takes for each letter in the dialog to play the fade-out animation.
| `DelayAfterFinish` | 0 | How long the dialog will wait after the current dialog has finished to display the next dialog sequence.
| `RemoveAfter` | 2 | How long the dialog will stay on the screen after it has finished typing.

### Dialog StringValue Attributes

The `Value` property of each `StringValue` will determine the text that will be displayed.

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `CanSkip` | true | Determines whether the player can click/tap on the screen to skip the dialog.
| `Damping` | 0.45 | The damping ratio of the dialog fade-in effect. Recommended to not modify unless you know what you're doing
| `Font` | Montserrat Medium | The font the dialog will have.
| `Frequency` | 2.65 | The frequency of the dialog fade-in effect. Recommended to not modify unless you know what you're doing
| `FromTop` | false | Determines whether the text will come from the top or bottom of the dialog frame.
| `Interval` | 0.02 | How long it takes for each letter to play the fade-in animation.
| `TextColor` | (255, 255, 255) | The color the text will be.
| `TextSize` | 30 | The size the text will be.

### Text Effects

Each text effect is a `BoolValue`. The set value of the object determines if the effect will be used.

| Name | Description | Attributes
|:-----:|:-----:|:-----:
| `Gradient` | Text gradient. | GradientColor (Color3 / ColorSequence), GradientRotation (number), GradientTransparency (number)
| `RNGRainbow` | Each label will have a rainbow animation of different colors. | N/A
| `Rainbow` | Each label will have a rainbow animation that is consistent through the entire text. | N/A
| `Shake` | Each label will shake. | N/A
| `Shine` | Each label will shine. | ShineColor (Color3)
| `TextStroke` | Text outline. | StrokeColor (Color3), Transparency (number), Thickness (number)
| `TweenSize` | Allows you to grow/shrink the text over time. | Size (number), Time (number), EasingStyle (string), EasingDirection (string)
| `Wave` | Each label will have a wave effect. | N/A