# Booster

Boosters grant the player a boost when they are interacted with.

## Use Cases

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Mode` | Default | The mode of the booster. See the Modes section below for more details
| `Type` | Speed | The type of the boost. See the Types section below for more details
| `Power` | 50 | The power of the boost. See the Types section below for more details
| `Duration` | 5 | Duration of the boost in seconds. If set to 0, the boost will be infinite until removed.
| `TimerDecimals` | 1 | The amount of decimals to show on the boost timer.

## Modes

| Mode | Humanoid Property affected | Default Value
|:-----:|:-----:|:-----:
| `Speed` | `WalkSpeed` | 16
| `Jump` | `JumpPower` | 50

## Types

| Type | Description
|:-----:|:-----:
| `Default` | Booster will behave as normal. Boost can only be removed by a Boost Remover or by letting the timer expire.
| `Zone` | The boost will automatically end once the player stops interacting with the booster.