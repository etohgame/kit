# Bounce Pads

Bounce Pads are objects that bounce players and objects when touched.

## Use Cases

Bounce Pads can be used to launch objects in any direction. They only apply a single impulse, unlike [Elevators](elevators.md) which continously apply force until the object stops touching the Elevator.

The sounds and particles inside the Boost Pad can be modified to your liking.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Cooldown` | 0.05 | Delay between being able to use the Bounce Pad again.
| `Power` | 100 | The power the bounce pad will launch objects at.
| `RelativeForce` | true | When true, interacting parts will be launched in the direction the bounce pad is facing. Otherwise, they will launch directly upwards no matter the rotation of the pad.
