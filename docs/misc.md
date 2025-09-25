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
| `DisplayMemoryDebug` | false | When true, the kit will display a debug menu that shows a more in-depth overview of the RAM usage in your place and what is using it. Useful for optimization.

## Object Tags

In Kit v6, value objects are no longer used in favor of `Configuration` objects for settings, and [Tags](https://create.roblox.com/docs/studio/properties#instance-tags) for object flags. Below is a table of all usable tags.

## General

| Name | Description
|:-----:|:-----:
| `Invisible`, `AltInvisible` | Makes parts invisible if present. `Invisible` will use `Transparency` while `AltInvisible` will use [`LocalTransparencyModifier`](https://create.roblox.com/docs/reference/engine/classes/BasePart#LocalTransparencyModifier).
| `CanFlip` | If present, the player will be able to perform Corner Flips on the part.
| `DoNotFlipPlayer` | If present alongside the `CanFlip` tag, performing a Corner Flip on a Part will not move/rotate the player. Useful for flip-activated client objects.
| `OnlyInStudio` | If present, the object will only be present while building in Studio and will automatically be deleted at runtime.

## Client Object Specific

| Name | Description
|:-----:|:-----:
| `ButtonActivated` | If present, the client object will become inactive until activated by a [Button](client-objects/buttons.md).
| `SkipObjectLoad` | If present inside a client object, it will not be automatically loaded when the tower loads. Required for client objects that have the capability of spawning other client objects, such as [Pushboxes](/docs/client-objects/pushbox-spawners.md) or [Turrets](/docs/client-objects/turrets.md)

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

NOTE: Keep in mind that custom scripts are **not allowed** in towers meant for EToH unless you have the Verified Builder role or are in a collaboration with someone who has the role.

When writing custom Client Object repository scripts, PLEASE keep the following things in mind as not following them can and will lead to many issues ingame:

* Do not edit existing scripts under any circumstance. These changes will not carry over ingame and will break your tower. New scripts (or edits to existing ones) should be put in the `ExternalRepositories.TowerKit` folder in `ReplicatedStorage`. Client objects are linked to their respective script by a `Tag` in their `Configuration` object. If your script is located at `ExternalRepositories.TowerKit.Interactables.MyNewCO`, then the tag will be `CO_Interactables/MyNewCO`. You can take a look at the base COs in the kit to see how this is set up. The `ExternalRepositories` folder is to be included in your tower's model upon submission.
* Make sure to put any events or connections you create into a [Scope](/api/Scope), so that they will automatically be cleaned up when the tower unloads.
* Make sure to optimize your code as much as you can in order to reduce potential lag issues.
* Read the [API Documentation](/api/ClientObjects) carefully as these contain many functions to speed up the process of writing repository scripts.
* Read the existing scripts to get a general idea of how your code should be written. Try to maintain a similar style to make your tower easier to bugfix should it get ingame.

<details>
<summary>Repository Script Template</summary>

```lua
--!strict
--!optimize 2
--@version template-6.0.0
--@creator you

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local Module = {
    -- Determines whether or not the script can be used by client objects
    CanQueue = true,
    -- Determines whether or not the script will be loaded upon entering
    -- (the script will be loaded without an instance attacted to the scope,
    --  remove the lines that use the "objectConfig" variables if you use this)
    RunOnStart = false,
}

-- This function only runs once, and can be used to set up stuff
-- (e.g. config templates)
function Module.Init(utility: _T.Utility)
    -- init code here
end

function Module.Run(scope: _T.Scope, utility: _T.Utility)
    local objectConfig = scope.instance
    if not objectConfig or not objectConfig.Parent then
        return
    end

    -- Your client object code goes here
end

return Module
```

</details>