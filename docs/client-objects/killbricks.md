# Kill Bricks

Kill Bricks deal damage to characters that come into contact with them. Damage from Kill Bricks are typically dealt in fixed values.

## Use Cases
Kill bricks are used to deal damage to the player. Avoid using them excessively as this can cause annoying gameplay.

## Configuration

Below are [`Tags`](https://create.roblox.com/docs/reference/engine/classes/CollectionService) and their respective damage outputs per touch. Neither damage nor healing bypass [`ForceField`](https://create.roblox.com/docs/reference/engine/classes/ForceField).

| Tag | Damage |
|:-----:|:--------:|
| `kills` | 5 |
| `double` | 10 |
| `ouch` | 20 |
| `instakills`| infinite |
| `heals` | Heals the player to full health |  

Damage may be dynamically set by adding a `number` [`Attribute`](https://create.roblox.com/docs/scripting/attributes) called `damage` (case sensitive) to the part.