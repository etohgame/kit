# Changelog

## [V6.0.0]

The kit has been fully reworked, and several objects now work differently.

* New client objects:
[Attachers](https://etohgame.github.io/kit/docs/client-objects/attachers.md),
[Gradient Parts](https://etohgame.github.io/kit/docs/client-objects/gradient-parts.md),
[GUI Displayers](https://etohgame.github.io/kit/docs/client-objects/gui-displayers.md), <!-- change link later -->
[Jump Launchers](https://etohgame.github.io/kit/docs/client-objects/jump-launchers.md),
[One-Way Platforms](https://etohgame.github.io/kit/docs/client-objects/one-way-platforms.md),
[Property Changers](https://etohgame.github.io/kit/docs/client-objects/property-changers.md),
[Swings](https://etohgame.github.io/kit/docs/client-objects/swings.md),
and [Sequencers](https://etohgame.github.io/kit/docs/client-objects/sequencers.md)
* Various additions and changes to existing client objects
* Value objects inside Client Objects have been removed in favor of `Configuration` objects for settings and [Tags](https://etohgame.github.io/kit/docs/misc.md#object-tags) for object flags. `ClientObject` values are also no longer needed or used.
* [Distance Culling](https://etohgame.github.io/kit/docs/client-objects/distance-culling.md) is now enabled by default for most physics objects to increase performance.
* There is now a [`KitSettings`](https://etohgame.github.io/kit/docs/misc.md#kit-settings) module found in `ReplicatedStorage` that allows you to toggle global kit settings.

A guide on converting towers made using v5.5 to v6 will be written at a later date.
