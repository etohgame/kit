# GUI Displayers

GUI Displayers are objects that will display a GUI on your screen when interacted with.

The GUI will be displayed upon touching any part that is named `Displayer` or has a `GuiDisplayer` tag. It will be removed upon touching any part that is named `Remover` or has a `GuiRemover` tag.

## Use Cases

GUI Displayers can be used to display any GUI on the player's screen. Displayed GUIs can be modified using [Property Changers](property-changers.md) to edit or animate them.

## Folder Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `Cooldown` | 0.25 | Delay between being able to activate the GUI Displayer again.

## Displayer Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `AutoRemove` | 0 | The displayed GUI will automatically be destroyed after this amount of time. If set to 0, the GUI will be displayed forever until manually removed.
