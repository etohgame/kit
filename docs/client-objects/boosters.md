# Boosters

Boosters grant the player a boost when they are interacted with.

## Use Cases

Boosters can be used to give the player a movement boost. These can be either temporary or permanent until removed.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Mode` | Default | The [mode](#modes) of the booster.
| `Type` | Speed | The [type](#types) of the boost.
| `Power` | 32 (Speed), 100 (Jump) | The [power](#types) of the boost.
| `Duration` | 5 | Duration of the boost in seconds. If set to 0, the boost will be infinite until removed.
| `TimerDecimals` | 1 | The amount of decimals to show on the boost timer.
| `HideGUI` | false | When true, the boost GUI will not be shown.

## Types

| Type | Humanoid Property affected | Default Value
|:-----:|:-----:|:-----:
| `Speed` | `WalkSpeed` | 16
| `Jump` | `JumpPower` | 50

## Modes

| Mode | Description
|:-----:|:-----:
| `Default` | Booster will behave as normal. Boost can only be removed by a Boost Remover or by letting the timer expire.
| `Zone` | The boost will automatically end once the player stops interacting with the booster.
