---
sidebar_position: 3
---

# Music System

The music system allows you to play background music in your tower.  

The only thing required for your tower to have music is the `Music` folder, which should be placed in `ServerScriptService`.  
(or alternatively `Workspace`, if you would like to manipulate the size/position of zones).  
The `Insert` script inside of this folder will automatically load in the music system for you, so you do not need to update it.

The music system itself can be found [on the creator marketplace][music-system] (Reminder: you do _not_ need to have this in your game for the music system to work, this link is here for those looking to work more in-depth with the system).

## Uploading Music

If you are not using publicly available music, you **must** reupload the songs yourself for them to play.
To avoid false moderation action on Roblox, it is **heavily recommended** to upload all audio on an alt account, then give your main account permission to use the songs.

Songs can be uploaded via the Asset Manager in Studio or via the [Creator Dashboard](https://create.roblox.com/dashboard/creations?activeTab=Audio). After uploading your audio, you can find the ID of the asset by going to its page and copying the number found in the link. After this, find the `Sound` object inside the music zone you want to edit and change the `SoundId` property to the ID of the audio.

If the asset is uploaded on an alt, you can share permission with your main account to use the song in your tower. Go to the `Permissions` tab on the asset's page, click on the `Add Collaborators` button and type in your main account's username. Note that your main account and your alt account must be friends in order to share asset permissions.

## Music Folder

The music folder should contain 3 objects:

* The `BackgroundMusicZones` folder, which contains all music zones that play in the tower
* The `GlobalBackgroundMusic` folder, which contains Sounds that are played when the player is not within any music zone
* The `Insert` script, which loads in the music system from its AssetID, so it is always up-to-date

## Music Zones

Music zones are models placed inside the `BackgroundMusicZones` folder, which contain parts and a `Music` folder.  
The `Music` folder contains all songs (`Sound` objects) which will play when the player is inside of any part in the zone model.  

When multiple songs are present, the next is chosen randomly when the current song stops playing. This can be changed by configuring `OrderedTracklist`, see [Music Zone Configuration](#music-zone-configuration) for more information.

When multiple zones overlap with eachother, the zone with higher priority will play its music.

## Music Zone Configuration

All configurations can either be attributes of the zone model or value objects inside of it.

| Name | Type | Default Value | Description
|------|------|---------------|------------
| `Priority` | number | 1 | Determines a zone's priority value (for explanation on priority, see [Music Zones](#music-zones)).
| `NoFadeIn` | boolean | false | Determines whether music fades in or instantly plays when entering a zone and the previous song has stopped playing.
| `NoFadeOut` | boolean | false | Determines whether music fades out or instantly stops when exiting a zone.
| `OrderedTracklist` | boolean | false | When true, songs will play in order based on their corresponding `Sound` object's name, instead of playing randomly.
| `ExitZoneBehavior` | "Stop" or "Pause" | "Stop" | Pause will resume music from where it left off when a zone is re-entered, Stop will reset it instead.
| `Disabled` | boolean | false | Disables a zone entirely (including its priority effects).
| `ButtonActivated` | Color3 | none | **DEPRECATED, use [Music Zone Editors](client-objects/music-zone-editors.md) to simulate button activated behavior.** Allows zones to be activated via the use of the v5.2/5.3 kit's buttons.
| `Invert` | boolean | false | **DEPRECATED**, swaps the zone's button activated state.

## Sound Configuration

Sounds in the `Music` folder (and `GlobalBackgroundMusic`) can also be configured.
Just like music zones, all of these can be attributes of the sound or values in it.

| Name | Type | Default Value | Description
|------|------|---------------|------------
| `StartAt` | number | 0 | Used as a replacement for the `TimePosition` property (which does not work due to songs looping when they end)
| `FadeIncrement` | number | 30 | Determines how fast the sound fades in & out. The formula to calculate the exact time is `0.1 * FadeIncrement`
| `MusicName` | string | - | A custom name that will be displayed instead of the sound asset's name (not to be confused with the Sound object's name in studio).

In addition to this, when a sound is named `IntroMusic`, it will always be the first to play and will never play again unless the zone is re-entered. This can be used for better song loops.

## Settings Module

**Note: This section is meant for people with some scripting knowledge**  
An optional ModuleScript named `Settings` can be passed as the 2nd parameter to the function returned by the `require` call.  
This module should return a table with the following optional keys.

| Key | Type | Default Value | Description
|-----|------|---------------|------------
| `UseDefaultMuteButton` | boolean | false | Disables the default mute button. Allows for custom mute buttons, a template for which is provided in the [music system model][music-system].
| `UseSmoothAsDefaultTransition` | boolean | true | Determines whether to transition music using the Smooth or Classic style, like the EToH setting.

[music-system]: https://create.roblox.com/store/asset/16989944963
