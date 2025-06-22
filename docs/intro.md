---
sidebar_position: 0
---

# Introduction

Welcome to the documentation page for Version 6 of the EToH Tower Building Kit! This site will tell you everything that you should know about the kit; including setup instructions, detailed documentation, and more!

## Installation Instructions

The kit is distributed using a pre-made place, making it simple and straight-forward to get started. It can be obtained by:
* Opening the [uncopylocked template place](https://github.com/etohgame/kit) on Roblox **(recommended)**
* Downloading the .rbxl file from our [GitHub releases page](https://github.com/etohgame/kit)

TEMPORARY NOTE: actual links tba

## Website Navigation

The website can be navigated by using the navigation bars on the top side and left side of the site. The top bar is used to switch between different sections of the website, and the left bar is used to navigate through categories within these sections.

## Documentation

Detailed documentation for each Client Object in the kit can be found in the Client Objects category. These pages will contain a list of possible configurations for the Client Object, as well as additional info such as a description of the object and potential use cases.

### Global Configuration Documentation

The Global Configurations category contains documentation for the various types of global configurations in the kit. These configurations are used by several Client Objects in the kit and as such are listed seperately for convenience.

### API Documentation

Documentation for the kit's scripts can be found in the API section found in the top bar. These are meant to assist people that are working on custom scripts for the kit. Please note that you are **not allowed** to use custom scripts unless you have the Verified Builder role or are in a collaboration with someone who has the role.

## What's different compared to Version 5?

The kit has been fully reworked, and several objects now work differently.
If you are experienced with building towers using an old kit, please read through these as it contains important information:

* New client objects: 
[Attachers](client-objects/attachers.md), 
[Gradient Parts](client-objects/gradient-parts.md),
[GUI Displayers](client-objects/gradient-parts.md), <!-- change link later -->
[Jump Launchers](client-objects/jump-launchers.md),
[One-Way Platforms](client-objects/one-way-platforms.md),
[Property Changers](client-objects/property-changers.md),
[Swings](client-objects/swings.md),
and [Sequencers](client-objects/sequencers.md)
* Various additions and changes to existing client objects
* Value objects inside Client Objects have been removed in favor of `Configuration` objects and [Tags](misc.md#object-tags). `ClientObject` values are also no longer needed and client objects are instead detected by searching for said `Configuration` object.
* [Distance Anchoring](client-objects/distance-anchoring.md) is now enabled by default for most physics objects to increase performance.
* There is a [`KitSettings`](misc.md#kit-settings) module found in `ReplicatedStorage` that allows you to toggle global kit settings.