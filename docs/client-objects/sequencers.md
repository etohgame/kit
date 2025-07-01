# Sequencers

Sequencers are objects that remotely activate a configured sequence of other client objects.

## Use Cases

Sequencers are used as the replacement for [Pushbox](pushbox-spawners.md) contraptions that were widely used in older kits, and have several benefits such as them being much more consistent due to not being prone to physics issues.

## Using Sequencers

Objects activated by Sequencers must be placed in the Sequencer's `Sequence` folder. When activated, the Sequencer will begin moving in the direction it is facing. Objects in the sequence will be activated when the Sequencer passes through the center point of the object.
When placing these objects in the `Sequence` folder, please make sure to do the following (if applicable):

* Set all of the object's `Transparency` to 0.
* Set all of the object's `CanCollide` & `CanTouch` to `false`.
* Disable all [TouchConfigurations](../global-configurations/touch-configurations.md#touchconfiguration).

This is to make sure that nothing unwanted or unpredictable happens, and to prevent any sorts of lag.

If a reached object has a `YieldSequence` tag, the Sequencer will pause until that object's function finishes running. In the case of button platforms, it will pause until the button platform activates.
If a part named `EndPoint` is reached in the sequence, the Sequencer will stop running early. This can be used for debugging purposes.

For performance reasons, Sequencers will not run when the game is running below 10FPS.
A warning message will also be displayed if the Sequencer is looping at an obscene rate (20+ times per second)

### Sequence Groups

A `SequenceGroup` template can be found in the `Extra Sequencer Stuff` folder in the kit. If you parent objects into this group, they will have special behavior based on the `GroupConfiguration`'s `Mode` when activated in a sequence:

* `Random` will simply select and activate a random object from the group.
* `And` and `Or` are conditional modes that rely on [Property Checkers](property-changers.md#property-checkers). The Sequencer will activate all Property Checkers in the group and cancel the sequence if their conditions are not met. If using `And`, all conditions have to be met, and if using `Or`, only one condition has to be met.

### Sequence Pointers

Sequence Pointers can also be found in the `Extra Sequencer Stuff` folder. When activated in a sequence, the Sequencer will search for any objects with [Tag]s matching its `Pointer` attribute, and activate those objects.

[Sequence Variables] are also supported, by making the sequence pointer's `Pointer` attribute a sequence variable wrapped around in curly braces.

### Sequence Variables

Every `Activator` part has a `SequenceVariables` Configuration object. Any attributes you add to this object can be read by [Property Changers](property-changers.md#_esequencevariable).

## Sequencer Support

The following objects are currently supported by Sequencers:

| Object | Notes |
|:-----:|:-----:|
| [Attachers](attachers.md) | |
| [Balloons](balloons.md) | |
| [Boosters](boosters.md) | |
| [Boost Removers](boosters.md) | |
| [Buttons](buttons.md) | |
| [Button Deactivators](button-deactivators.md) | |
| [Dismounters](dismounters.md) | |
| [Emitters](emitters.md) | Use with [Sequence Pointers] |
| [GUI Displayers](gui-displayers.md) | |
| [Lighting Changers](lighting-changers.md) | |
| [Morphers](morphers.md) | |
| [Music Zone Editors](music-zone-editors.md) | |
| [Property Changers](property-changers.md) | |
| [Pushbox Spawners](pushbox-spawners.md) | |
| [Pushbox Destroyers](pushbox-destroyers.md) | |
| [Seats](seats.md) | Use with [Sequence Pointers] |
| [Swings](swings.md) | Use with [Sequence Pointers] |
| [Teleporters](teleporters.md) | Seamless mode will not function correctly. |
| [Trip Parts](trip-parts.md) | |
| [Turrets](turrets.md) | Use with [Sequence Pointers] |
| [Vanishers](vanishers.md) | Use with [Sequence Pointers] |
| [Vines](vines.md) | Use with [Sequence Pointers] |
| [Ziplines](ziplines.md) | Use with [Sequence Pointers] |

## Music Sync

Sequencers can be synced to the tower's music. This will adjust the speed of the Sequencer to match the BPM of the currently playing song. See [the documentation on music sync](/docs/misc.md#music-sync-configuration) for more information.

## Configuration

| Name | Default Value | Description |
|:-----:|:-----:|:-----:|
| `Cooldown` | 0 | The amount of time it will take for the Sequencer to be usable again after it finishes. |
| `LoopAmount` | 0 | The amount of times the Sequencer will run when activated. If set to 0, it will only run once. If set to any negative number, it will keep running forever. |
| `LoopDelay` | 0 | The amount of time the Sequencer will wait before reactivating after every loop. |
| `RunAtStart` | false | When true, the Sequencer will automatically run when it loads, without it having to be activated by touch. |
| `Speed` | 1 | The speed the Sequencer will move at, in studs per second. |
| `Visualize` | true | When true, the Sequencer will move to show its progress, and color itself to show its current state. Useful for debugging sequences. |

[Tag]: https://create.roblox.com/docs/studio/properties#instance-tags
[Sequence Pointers]: #sequence-pointers
[Sequence Variables]: #sequence-variables
