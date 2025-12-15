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
| `PadDistance` | 10 | Vertical range of the booster when using `Pad` mode

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
| `Pad` | Similar to `Zone`, but the booster's range extends upwards by a set amount controlled by `PadDistance`.

Unlike older kits, when using the `Pad` mode, the booster will still respect its `TweenConfiguration`s. To replicate the older behavior (instant changes), set both of the `TweenConfiguration`s to a length of 0.

# Creating Custom Boosts

NOTE: Keep in mind that custom scripts are **not allowed** in towers meant for EToH unless you have the Verified Builder role or are in a collaboration with someone who has the role.

Custom boosts can be created by creating a module and registering it using the [Character utility]. The required components are listed below:

* **Boost.Information** holds the information of the boost displayed on its GUI, such as the `Icon` asset ID and `Color`.
* **Boost.Start()** runs whenever the boost starts.
* **Boost.Update()** runs whenever the boost updates. This happens when first started, or when it gets refreshed by touching the booster again while the boost is still active
* **Boost.End()** runs whenever the boost ends.
* **Boost.GetMultiplier()** calculates the multiplier value that is shown in the boost's GUI.

To make your boost usable, register the boost using the Character utility's `registerCustomBoost` function and change your booster's `Type` configuration to that newly set name. Note that any registered boosts will automatically be unregistered when the player respawns.

<details>
<summary>Boost Module Template</summary>

```lua
--!strict
--!optimize 2
--!@version 6.X.X

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _TDefs = require(ReplicatedStorage.Framework.Kit.Managers.CharacterManager.TypeDefs)

local Boost = {}

-- the information that will show up on the boost's ui
Boost.Information = {
	icon = "rbxassetid://13492318225",
	color = Color3.fromRGB(255, 255, 0),
}

-- this function will run when the boost starts
-- Boost.Update() will also be called once when the boost starts, use that
-- function to change any properties
function Boost.Start(boostData: _TDefs.BoostData)
	
end

-- this function will run when the boost updates (whenever it starts or refreshes)
-- if you are changing properties of anything do it in here
function Boost.Update(boostData: _TDefs.BoostData)
	
end

-- this function will run when the boost ends
function Boost.End(boostData: _TDefs.BoostData)
	
end

-- the value calculated here will show up as the multiplier on the boost's ui
function Boost.GetMultiplier(boostData: _TDefs.BoostData): number
	return 1
end

return Boost
```

</details>

[Character utility]: /api/Character#registerCustomBoost