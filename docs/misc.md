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
| `DoNotFlipPlayer` | If present alongside the `CanFlip` tag, performing a Corner Flip on a Part will not move/rotate the player. Useful for flip-activated client objects.
| `OnlyInStudio` | If present, the object will only be visible in Studio and will automatically be deleted when playing the tower.

# Client Object Specific

| Name | Description
|:-----:|:-----:
| `ButtonActivated` | If present, the client object will become inactive until activated by a [Button](client-objects/buttons.md).
| `SkipObjectLoad` | If present inside a client object, it will not be automatically loaded when the tower loads. Required for client objects that have the capability of spawning other client objects, such as [Pushboxes](/docs/client-objects/pushbox-spawners.md) or [Turrets](/docs/client-objects/turrets.md)

## Hitbox Modes

Certain client objects have a HitboxMode configuration attribute that lets you control what parts of the player are allowed to trigger a touch on that object. These hitboxes ignore animations and as such should be more consistent. A list is provided below.

| Name | Description
|:-----:|:-----:
| `RootPart` | HumanoidRootPart only
| `StaticWholeBody` | Character's entire body
| `StaticCenter` | Character's entire body, excluding arms
| `StaticArms` | Arms & torso only

There are more hitbox types that include the character's actual limbs, note that these do *not* ignore animations:

| Name | Description
|:-----:|:-----:
| `WholeBody` | All limbs
| `Center` | All limbs, excluding the arms

## Music Sync Configuration

Certain client objects have a `MusicSyncConfiguration` inside their main Configuration object. This can be used to make them music synced. They contain a `SyncEnabled` attribute and a `ZoneName` attribute which specifies whether to use music sync, and the music zone to sync to.

It also contains a `Sync` module where the actual sync is defined, an example of it looks like this:

```lua
return {
	TimingOffset = 000.000, -- Change this to sync your song
	BeatsPerMinute = {
        -- Example: { beat = 016.000, bpm = 180.000 },
        { beat = 000.000, bpm = 130.000 },
	},
	Stops = {
		-- Example stop: { beat = 002.000, seconds = 000.500 },
		-- Stops the music at beat 2 for 0.5 seconds
	},
}
```

`TimingOffset` is the timestamp in seconds that defines the start of the song. Use this if your song doesn't directly start as soon as the sound plays.

`BeatsPerMinute` is a table that defines the BPM for certain timestamps of the song, measured in beats. The BPM set in beat 0 defines the BPM of the start of the song.

`Stops` is a table that defines pauses in the song. The timestamp of where to stop is measured in beats, and the amount of time to pause for is measured in seconds.

## Writing/Editing Repository Scripts

NOTE: Keep in mind that custom scripts are **not allowed** unless you have the Verified Builder role or are in a collaboration with someone who has the role.

When writing custom Client Object repository scripts, PLEASE keep the following things in mind as not following them can and will lead to many issues ingame:

* Do not edit existing scripts under any circumstance. These changes will not carry over ingame and will break your tower. If you want to make slight behavioral edits, copy the script instead, parent it into the `ExternalRepositories.TowerKit` folder in `ReplicatedStorage`, and give it a new name, preferably with your tower's name in it for organization purposes.
* Make sure to put any events or connections you create into a [Scope](/api/Scope), so that they will automatically be cleaned up when the tower unloads.
* Make sure to optimize your code as much as you can in order to reduce potential lag issues.
* Read the [API Documentation](/api/ClientObjects) carefully as these contain many functions to speed up the process of writing repository scripts.
* Read the existing scripts to get a general idea of how your code should be written. Try to maintain a similar style to make your tower easier to bugfix should it get ingame.