# Changelog

## [v6.0.3 - September 25th 2025]

**IMPORTANT NOTE**: Boost Pads have been deprecated and are no longer included in the kit.
The regular Booster object now includes a `Pad` mode that has matching behavior.

Old Boost Pads will still function in towers that use them, but they will no longer be maintained.
Please convert old Boost Pads to regular Boosters after using the update kit.
The update kit will not automatically perform this conversion to avoid potential problems.

### Fixes
- Fixed Dismounters not respecting `AllowJumpDismount` on Balloons, Vines and 
    Ziplines
- Fixed Morpher buttons not changing colors when activated
- Fixed Morpher's main part having weird movement behavior if unanchored
- Fixed Morpher's `NewMorph` parts not updating their material correctly
- Fixed an issue where Morphers keep running their movement code even after
	they finish moving
- Fixed some Client Objects not working randomly
- Actually changed the configuration version tag this time
- Added a sound pool to BeatBlocks to prevent memory leaks
- Fixed a typo in the Property Changer script that made the `SequenceVariable`
	function not work
- Fixed TouchConfigurations for Gui Displayers not working properly
- Fixed Sequencers using RunOnStart and SyncEnabled not working when music is
	not preloaded
- Fixed Turrets not registering touch events at all unless DestroyOnTouch is
	enabled

### Improvements
- Added `OutlineColor` and `ShrinkToZero` configuration to Vanishers
- Added `IgnoreCanCollide` and `IgnoreTransparency` tag support to Vanishers
- Added Transparency support for Gradient Parts
- Added Stopper parts to Sequencers
- Replaced `HitboxMode` configuration on client objects with a
	`playerHitboxMode` attribute on TouchConfigurations
- Improved Property Changer Functionality & warnings
- Updates to Boosters:
	- Updated boost system, allowing for custom boosts through custom modules
	- `Pad` mode added to regular Boosters. **BoostPads are now deprecated and
	should be replaced with regular Boosters**
- Slightly optimized Morphers
- Morphers with the `CarryObjects` configuration enabled now also affect
	orientation
- Added a visible Corner Flip button on mobile
- Added `IndicatorScaleMultiplier` configuration to Beat Blocks

## [v6.0.2 - July 3rd 2025]

### Fixes

* Fixed incorrect default `TouchConfiguration`s being used internally, breaking some Client Objects
* Fixed Teleporters not working
* Fixed Dismounters not being able to dismount Attachers

## [v6.0.1 - July 3rd 2025]

### Fixes

* Fixed a bug where Vanishers have `canFlip` enabled even if it's turned off in
    the `TouchConfiguration`
* Fixed the `Shrink` mode in Vanishers not working properly if orientated
* Fixed an issue where `AutoRemove` didn't work on GuiDisplayers
* Fixed Activator parts on Turrets using the wrong `TouchConfiguration`
* Fixed `canFlip` support for Turret activators & Trip Parts
* Fixed buggy behavior with `IndicatorInterval` on Beat Blocks when their `Indicator`
    is turned off
* Fixed player hitboxes for every single client object.
* Fixed button activated Bounce Pads not deactivating

### Improvements

* Swings, Vines & Ziplines can now have their mount models customized.
* Added a configuration to Dismounters where pushboxes can dismount parts for
    the player instead of the pushbox itself. (`ForceDismountPlayer`)
* Allows you to have multiple Trigger parts for Attachers
* Added an `ActiveCanCollide` configuration to Falling Platforms
* Added a `CleanDelay` configuration to Attachers
* Added `MoveVector`, `IsShiftLocked` & `IsJumping` to the list of retrievable values
    in Property Changers
* Added a `Loop` configuration to Ziplines
* Renamed frame parts to their floor number
    (NOTE: The update kit does not make this change.)
* Added support for Gradient Parts to affect its children as well
* Added a `StunDuration` configuration to Trip Parts that immobilizes the player
* Added a `SitOffset` configuration to Seats
* Jump Launchers now support being made completely invisible
* Added a configuration to PropertyCheckers in which if the condition fails,
    the entire sequencer loop will stop. (`ConditionalBreakSequence`)
* Added a configuration to PropertyCheckers in which it yields the sequence
    until the condition has passed. (`ConditionalYieldSequence`)
* Added a new `Event` field to PropertyCheckers in which it yields the sequence
    until the Event has fired. (Useful for ProximityPrompts, jump detection, etc)
* Added the ability to use & change character instances in PropertyChangers.
* Added a `FlipCooldown` Attribute to flips
* Added `CollisionGroup` support to TouchConfiguration

## [v6.0.0 - June 30th 2025]

The kit has been fully reworked, being fully rescripted from scratch. This brings a lot of changes to what's inside the kit, such as client object functionality, as well as various other things such as optimization and script readability.

* New client objects:
[Attachers](https://etohgame.github.io/kit/docs/client-objects/attachers),
[Gradient Parts](https://etohgame.github.io/kit/docs/client-objects/gradient-parts),
[GUI Displayers](https://etohgame.github.io/kit/docs/client-objects/gui-displayers),
[Jump Launchers](https://etohgame.github.io/kit/docs/client-objects/jump-launchers),
[One-Way Platforms](https://etohgame.github.io/kit/docs/client-objects/one-way-platforms),
[Property Changers](https://etohgame.github.io/kit/docs/client-objects/property-changers),
[Swings](https://etohgame.github.io/kit/docs/client-objects/swings),
and [Sequencers](https://etohgame.github.io/kit/docs/client-objects/sequencers)
* Various additions and changes to existing client objects
* Value objects inside Client Objects have been removed in favor of `Configuration` objects for settings and [Tags](https://etohgame.github.io/kit/docs/misc#object-tags) for object flags. `ClientObject` values are also no longer needed or used.
* [Distance Culling](https://etohgame.github.io/kit/docs/client-objects/distance-culling) is now enabled by default for most physics objects to increase performance.
* There is now a [`KitSettings`](https://etohgame.github.io/kit/docs/misc#kit-settings) module found in `ReplicatedStorage` that allows you to toggle global kit settings.

A guide on converting towers made using v5.5 to v6 will be written at a later date.