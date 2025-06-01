# Turrets
Turrets are objects that shoot out bullets that damage the player. They are also able to be customized to shoot out other things.

## Use Cases
* Shooting projectiles the player has to avoid
* Shooting out other objects, such as platforms or other COs

## Configuration
| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Damage` | 5 | How much damage the bullet will deal upon impact with the player. Note that only parts named "Bullet" will deal damage.
| `DestroyOnTouch` | true | When true, the bullet will be destroyed upon impact with the player. If you are making the turret shoot out anything the player should be able to interact with, this should be set to false.
| `FireRate` | 1 | The amount of bullets that will be shot per second.
| `MaxLifetime` | 5 | The maximum amount of time in seconds that bullets should exist for. Bullets will automatically despawn after this time if they haven't already been destroyed.
| `Range` | 50 | The turret's maximum activation range, measured in studs. If the player is further away than this value, the turret will not fire.
| `Speed` | 50 | The speed that fired bullets will move at, measured in studs per second

## Additional notes
When making complex bullets (e.g. firing other client objects), you should keep in mind that the "main" part of the bullet will be automatically positioned at the turret's position and rotation when firing, moving all other parts welded to it as well. The main part is determined by going through these steps and picking the first one that applies:
* The bullet model's PrimaryPart
* A part inside the bullet model named "Bullet"
* If neither of these apply, a default bullet will be used as a failsafe.