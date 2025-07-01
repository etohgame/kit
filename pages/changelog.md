# Changelog

## [V6.0.0]

The kit has been fully reworked, and several objects now work differently.

* New client objects:
[Attachers](client-objects/attachers.md),
[Gradient Parts](client-objects/gradient-parts.md),
[GUI Displayers](client-objects/gui-displayers.md), <!-- change link later -->
[Jump Launchers](client-objects/jump-launchers.md),
[One-Way Platforms](client-objects/one-way-platforms.md),
[Property Changers](client-objects/property-changers.md),
[Swings](client-objects/swings.md),
and [Sequencers](client-objects/sequencers.md)
* Various additions and changes to existing client objects
* Value objects inside Client Objects have been removed in favor of `Configuration` objects for settings and [Tags](misc.md#object-tags) for object flags. `ClientObject` values are also no longer needed or used.
* [Distance Culling](client-objects/distance-culling.md) is now enabled by default for most physics objects to increase performance.
* There is now a [`KitSettings`](misc.md#kit-settings) module found in `ReplicatedStorage` that allows you to toggle global kit settings.

A guide on converting towers made using v5.5 to v6 will be written at a later date.
