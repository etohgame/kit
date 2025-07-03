# Changelog

## [V6.0.1]

### Fixes

- Fixed a bug where Vanishers have canFlip enabled even if it's turned off in
    the TouchConfiguration
- Fixed Vanishers' Shrink mode not working properly if orientated
- Fixed an issue where AutoRemove didn't work on GuiDisplayers
- Fixed Activator parts on Turrets using the wrong TouchConfiguration
- Fixed canFlip support for Turret activators & Trip Parts
- Fixed buggy behavior with IndicatorInterval on Beat Blocks when Indicator is
    turned off
- Fixed player hitboxes for every single client object.
- Fixed button activated BouncePads not deactivating

### Improvements

- Swings, Vines & Ziplines can now have their mount models customized.
- Added a configuration to Dismounters where pushboxes can dismount parts for
    the player instead of the pushbox itself. (ForceDismountPlayer)
- Allows you to have multiple Trigger parts for Attachers
- Added an ActiveCanCollide configuration to Falling Platforms
- Added a CleanDelay configuration to Attachers
- Added MoveVector, IsShiftLocked & IsJumping to the list of retrievable values
    in Property Changers
- Added a Loop configuration to Ziplines
- Renamed frame parts to their floor number
    (NOTE: The update kit does not make this change.)
- Added support for Gradient Parts to affect its children as well
- Added a StunDuration configuration to Trip Parts that immobilizes the player
- Added a SitOffset configuration to Seats
- Jump Launchers now support being made completely invisible
- Added a configuration to PropertyCheckers in which if the condition fails,
    the entire sequencer loop will stop. (ConditionalBreakSequence)
- Added a configuration to PropertyCheckers in which it yields the seqeuence,
    until the condition has passed. (ConditionalYieldSequence)
- Added a new field "Event" to PropertyCheckers in which it yields the seqeuence,
    until the Event has fired. (Useful for ProximityPrompts, jump detection, etc)
- Added the ability to use & change character instances in PropertyChangers.
- Added a "FlipCooldown" Attribute to flips
- Added "CollisionGroup" support to TouchConfiguration

## [V6.0.0]

The kit has been fully reworked, and several objects now work differently.

* New client objects:
[Attachers](https://etohgame.github.io/kit/docs/client-objects/attachers),
[Gradient Parts](https://etohgame.github.io/kit/docs/client-objects/gradient-parts),
[GUI Displayers](https://etohgame.github.io/kit/docs/client-objects/gui-displayers), <!-- change link later -->
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
