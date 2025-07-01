# Seats

Seats are parts that weld a player to them when touched. Sitting players are immedietely moved to the `Top` surface of the part and placed in a sitting animation. When the player attempts to jump, they will dismount from the Seat. Being a mountable, a player may be forcibly dismounted from a seat using a [Dismounter](dismounters.md).

Seats only support Players and any other object (even objects allowed in the [TouchConfiguration](/docs/global-configurations/touch-configurations.md)) will be ignored.

## Use Cases

Seats may be used to temporarily weld a player to a part.

Keep in mind that the player might interact oddly with other client objects whilst sitting on a Seat due to being directly welded to it.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Cooldown` | 1 | The time it takes the Seat to be mountable again after dismounting.
