# Bounce Pads

Bounce Pads are objects that bounce players and objects when touched.

## Use Cases
Bounce pads can be used to launch the player in any direction.

## Configuration
| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Cooldown` | 0.05 | Delay between being able to use the Bounce Pad again.
| `Power` | 100 | The power the bounce pad will launch objects at.
| `RelativeForce` | false | When true, interacting parts will be launched in the direction the bounce pad is facing. Otherwise, they will launch directly upwards no matter the rotation of the pad.