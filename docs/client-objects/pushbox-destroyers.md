# Pushbox Destroyers

Pushbox Destroyers are parts that destroy any [Pushbox](pushbox-spawners.md) that touches it.

## Use Cases

Pushbox Destroyers can be used to destroy Pushboxes or contraptions parented within a Pushbox model, or to prevent a Pushbox from going outside its intended use area.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `ColorSpecific` | false | When true, the Pushbox part that touches the Destroyer must match the Destroyer's color for it to be destroyed.
| `DestroyWholeModel` | false | When true, the entire Pushbox model will be destroyed upon touch. Otherwise, only the part that touched the Destroyer will be destroyed.
