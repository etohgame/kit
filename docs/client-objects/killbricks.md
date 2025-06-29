# Kill Bricks

Kill Bricks deal damage to players that come into contact with them. Damage from Kill Bricks are typically dealt in fixed values.

## Use Cases

Kill Bricks are used to deal damage to the player, for example to punish the player for falling or to keep them moving. Avoid using them excessively as this can create annoying gameplay.

## Configuration

Below is a list of [`Tags`](https://create.roblox.com/docs/reference/engine/classes/CollectionService) and their respective damage outputs per touch.
The player will not be affected if they have a [`ForceField`](https://create.roblox.com/docs/reference/engine/classes/ForceField).

| Tag | Damage |
|:-----:|:--------:|
| `kills` | 5 |
| `double` | 10 |
| `ouch` | 20 |
| `instakills`| infinite |
| `heals` | Heals the player to full health |  

Custom damage values may be set by adding a `number` [`Attribute`](https://create.roblox.com/docs/scripting/attributes) called `customDamage` (case sensitive) to the part.
