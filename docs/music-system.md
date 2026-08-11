---
sidebar_position: 3
---

# Music System

The music system allows you to play background music in your tower.  
It is automatically loaded by the `Insert` script located in the `Music` folder in `ServerScriptService`. Both of these objects are included in the kit place.  
If you would like to work more in-depth with the system (or are missing any of its components for whatever reason), its model can be found [on the creator marketplace][music-system]
(be aware that it lacks the `Insert` script, since Roblox does not allow its code in free models)

## Uploading Music

If you are not using publicly available music, you **must** reupload the songs yourself for them to play.
To avoid moderation action on Roblox, it is **heavily recommended** to upload all audio on an alt account, then give your main account permission to use it.

Songs can be uploaded via the [Asset Manager](https://create.roblox.com/docs/projects/assets/manager) in Studio or via the [Creator Dashboard](https://create.roblox.com/dashboard/creations?activeTab=Audio). After uploading your audio, you can find its asset ID by going to its page and copying the number found in the URL (or by clicking the dots to the right of its name and clicking "Copy Asset ID"). After this, find the `Sound` object inside the music zone you'd like the song to play in and change the `SoundId` property to the asset ID of the audio.

If the asset is uploaded on an alt, you can share permission with your main account to use the song in your tower. Go to the `Permissions` tab on the asset's page, click on the `Add Collaborators` button and type in your main account's username. Note that your main account and your alt account must be friends in order to share asset permissions.

## Music Folder

The music folder contains 3 objects:

* The `BackgroundMusicZones` folder, which contains all music zones that play in the tower
* The `GlobalBackgroundMusic` folder, which contains Sounds that are played when the player is not within any music zone
* The `Insert` script, which loads in the music system from its AssetID, so it is always up-to-date

If you'd like to edit the properties of music zone parts, feel free to move this folder to `Workspace`, the music system will still function properly (and zone parts will have their transparency set to 1 in-game).

## Music Zones

Music zones are models placed inside the `BackgroundMusicZones` folder, which contain parts and a `Music` folder.  
Whenever the player is standing inside a zone's parts, said zone's music will play.  
If several music zones overlap with each other, the zone with the highest priority will play its music.  
The `Music` folder stores all songs as `Sound` objects. If multiple are present, the order in which they play is random.  
This can be changed by configuring `OrderedTracklist`, see [Music Zone Configuration](#music-zone-configuration) for more information.

## Music Zone Configuration

All configurations can either be attributes of the zone model or `Value` objects inside of it.

| Name | Type | Default Value | Description
|------|------|---------------|------------
| `Priority` | number | 1 | Determines a zone's priority value (for explanation on priority, see [Music Zones](#music-zones)).
| `NoFadeIn` | boolean | false | Determines whether music fades in or instantly plays when entering a zone and the previous song has stopped playing.
| `NoFadeOut` | boolean | false | Determines whether music fades out or instantly stops when exiting a zone.
| `OrderedTracklist` | boolean | false | When true, songs will play in order based on their corresponding `Sound` object's name, instead of playing in random order.
| `ExitZoneBehavior` | `Stop` or `Pause` | `Stop` | `Pause` will resume music from where it left off when a zone is re-entered, `Stop` will reset it instead.
| `Disabled` | boolean | false | Disables a zone entirely (including its priority effects).
| `ButtonActivated` | Color3 | none | **DEPRECATED, use [Music Zone Editors](client-objects/music-zone-editors.md) to simulate button activated behavior.** Allows zones to be activated via the use of the v5.2/5.3 kit's buttons.
| `Invert` | boolean | false | **DEPRECATED**, swaps the zone's button activated state.

## Sound Configuration

Sounds in the `Music` folder (and `GlobalBackgroundMusic`) can also be configured.
Just like music zones, all of these can either be attributes of the sound or `Value` objects inside of it.

| Name | Type | Default Value | Description
|------|------|---------------|------------
| `StartAt` | number | 0 | Used as a replacement for the `TimePosition` property (which does not work due to songs looping when they end).
| `FadeIncrement` | number | 30 | Determines how fast the sound fades in & out. The formula to calculate the exact fade time is: `0.1 * FadeIncrement`
| `MusicName` | string | - | A custom name that will be displayed instead of the sound asset's name (not to be confused with the sound object's name in studio).
| `Artist` | string | - | The song artist's name (only visible on `Modern` music GUI)

In addition to this, if a sound is named `IntroMusic`, it will always be the first to play and will never play again unless the zone is re-entered. This can be used for better song loops.

## Settings Module

**Note: This section is meant for those with scripting knowledge looking to work more in-depth with the music system.**  
An optional ModuleScript named `Settings` can be passed as the 2nd parameter to the function returned by the `require` call.  
This module should return a table with the following optional keys.

| Key | Type | Default Value | Description
|-----|------|---------------|------------
| `UseSmoothAsDefaultTransition` | boolean | true | Determines whether to transition music using the Smooth or Classic style, same as the EToH setting.
| `GuiMode` | string | `Modern` | Determines the look of the default music GUI, either `Modern`, `Legacy` or `None`.

[music-system]: https://create.roblox.com/store/asset/16989944963
