# Damage Bricks

Damage Bricks deal damage to players that come into contact with them. Damage from Damage Bricks are typically dealt in fixed values.

## Use Cases

Damage Bricks are used to deal damage to the player, for example to punish the player for falling or to keep them moving. Avoid using them excessively as this can create annoying gameplay.

## Damage Brick Types

| Type | Damage |
|:-----:|:--------:|
| `kills` | 5 |
| `double` | 10 |
| `ouch` | 20 |
| `instakills`| infinite |
| `heals` | Heals the player to full health |  
| `custom` | Custom damage value |  

## Damage Brick Configuration

| Name | Default Value | Description |
|:-----:|:-----:|:-----: |
| `Cooldown` | 1 | Time in seconds to wait before the Damage Brick can deal damage again. |
| `Type` | `kills` | The type of damage brick. See [the list of types.](#damage-brick-types) |
| `Damage` | 0 | The amount of damage the player will take. The damage type must be set to `custom` for this to work. |
