# Keys

Keys are objects that can open Key Doors. Keys and key doors can have their model fully customized.

## Use Cases
Keys are used to open any key doors that are in the same group as the key. They can also optionally be used as light sources if one is added into it.

Key doors can be used to require the player to pick them up in order to proceed.
A key door can be destroyed in multiple ways when opened, based on what the parts inside are named:
| Part Name | Function
|:-----:|:-----:
| `Vanish` | The part will fade out, being destroyed after the fade ends.
| `Fall` | The part will become unanchored, being destroyed after 10 seconds.
| `Destroy` | The part will simply be destroyed immediately.

Any parts named `ReturnKey` inside of the key group will cause the key to return to its original spot upon being touched.

## Key Configuration
| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `SpinSpeed` | 5 | How fast the key will spin, measured in radians per second.
| `Timer` | 0 | The amount of time you can pick this key up for before it'll return to its original spot. If set to 0, the key will not have a timer


## Door Configuration
| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `RequiredKeys` | 1 | The amount of keys needed to open the door