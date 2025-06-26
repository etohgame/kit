# Seats

Seats are parts that weld a player to them when touched. Sitting players are immedietely moved to the `Top` surface of the part and placed in a sitting animation. When the player attempts to jump, they will dismount from the Seat. Being a mountable, a player may be forcibly dismounted from a seat using a [Dismounter](dismounters.md).

## Use Cases

Seats may be used to temporarily weld a player to a part.

## Swing Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Cooldown` | 1 | The time it takes the Seat to be mountable again
