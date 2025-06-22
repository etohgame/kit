# Balloons

Balloon Dispensers attach an object that touches them to a balloon using a [rope][RopeConstraint].  
The balloon is propelled up by a force.  
Objects on balloons dismount them when the player jumps or when the object/balloon touches a [dismounter](dismounters.md).  
Alternatively, they are dismounted when specific conditions are met, which are listed in the [configurations](#configuration).

Balloon visuals can be customized by editing the `BalloonModel` inside the balloon dispenser.  
Balloon timers can be customized by editing the `TimerGui` inside the balloon's configuration.

## Use Cases
Balloons can be used to slowly lift the player upwards or downwards while allowing free horizontal movement.

## Configuration

| Name | Default Value | Description
|------|---------------|------------
| `AllowJumpDismount` | true | Determines whether the balloon can be dismounted by jumping
| `DestroyWhenExpired` | true | When true, balloons are automatically dismounted upon expiring, otherwise they lose their velocity and do not rise
| `Force` | 5 | The velocity at which the balloon rises (or falls, if negative)
| `KeepMomentum` | true | When true, objects will keep any momentum they had on the balloon after dismounting
| `MaxHeight` | 0 | The maximum height difference between the balloon and the dispenser before expiring. Ignored if set to 0.
| `RopeLength` | 8 | The length of the balloon's [rope][RopeConstraint]
| `Timer` | 0 | The amount of time before the balloon expires automatically (infinite if set to 0)

[RopeConstraint]: https://create.roblox.com/docs/reference/engine/classes/RopeConstraint