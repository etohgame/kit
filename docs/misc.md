---
sidebar_position: 1
---

# Miscellaneous

This page will contain miscellaneous information related to the kit.

## Kit Settings

There is a `KitSettings` module found in `ReplicatedStorage` that allows you to toggle global kit settings. These settings will alter how the kit functions in your place.

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `ResetOnDeath` | true | When true, all client objects will reload when you die and respawn. This mimics how your tower will behave when placed ingame and can be useful for bugtesting.
| `DisplaySettingsGui` | true | When true, you will have access to a settings menu that allows you to quickly rejoin the game and change settings such as your corner flip keybind.
| `DisplayDebugGuis` | false | When true, the kit will display a debug menu that shows stats about your play session, such as FPS, RAM usage, the amount of instances, etc.
| `DisplayMemoryDebug` | false | When true, the kit will display a debug menu that shows an overview of the RAM usage in your place and what is using it. Useful for optimization.

## Object Tags

In Kit v6, value objects are no longer used in favor of `Configuration` objects for settings, and [Tags](https://create.roblox.com/docs/studio/properties#instance-tags) for object flags. Below is a table of all usable tags.

# General

| Name | Description
|:-----:|:-----:
| `Invisible`, `AltInvisible` | Makes parts invisible if present. `Invisible` will use `Transparency` while `AltInvisible` will use [`LocalTransparencyModifier`](https://create.roblox.com/docs/reference/engine/classes/BasePart#LocalTransparencyModifier).
| `kills`, `double`, `ouch`, `instakills`, `heals` | Used in [Kill Bricks](client-objects/killbricks.md), but can be added to any part.
| `CanFlip` | If present, the player will be able to perform Corner Flips on the part.
| `DoNotFlipPlayer` | If present alongside the `CanFlip` tag, performing a Corner Flip on a Part will not move the player. Useful for flip-activated client objects.
| `OnlyInStudio` | If present, the object will only be visible in Studio and will automatically be deleted when playing the tower.

# Client Object Specific

| Name | Description
|:-----:|:-----:
| `ButtonActivated` | If present, the client object will become inactive until activated by a [Button](client-objects/buttons.md).
| `SkipObjectLoad` | If present inside a client object, it will not be automatically loaded when the tower loads. Required for client objects that have the capability of spawning other client objects.

# Writing/Editing Repository Scripts

NOTE: Keep in mind that custom scripts are **not allowed** unless you have the Verified Builder role or are in a collaboration with someone who has the role.

When writing custom Client Object repository scripts, PLEASE keep the following things in mind as not following them can and will lead to many issues ingame:

* Do not edit existing scripts under any circumstance. These changes will not carry over ingame and will break your tower. If you want to make slight behavioral edits, copy the script instead, parent it into the `ExternalRepositories.TowerKit` folder in `ReplicatedStorage`, and give it a new name, preferably with your tower's name in it for organization purposes.
* Make sure to put any events or connections you create into a [Scope](/api/Scope), so that they will automatically be cleaned up when the tower unloads.
* Read the [API Documentation](/api/ClientObjects) carefully as these contain many functions to speed up the process of writing repository scripts.