# Pushbox Destroyers

Pushbox destroyers are parts that destroy any Pushbox that touches it.

## Use Cases
Pushbox destroyers can be used to destroy Pushboxes or contraptions parented within a Pushbox model.

## Configuration
| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `ColorSpecific` | false | If enabled, the Pushbox part that touches the destroyer must match the destroyer's color for it to be destroyed.
| `DestroyWholeModel` | false | When enabled, the entire Pushbox model will be destroyed upon touch. Otherwise, only the part that touched the destroyer will be destroyed.