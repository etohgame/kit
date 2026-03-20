# EToH Kit v6 Documentation

This repository is used to host the documentation website for EToH Kit v6.

## Kit Download

The kit can be obtained by:

* Opening the [uncopylocked template place](https://www.roblox.com/games/104814418357350) on Roblox **(recommended)**
* Downloading the .rbxl file from the [GitHub releases page](https://github.com/etohgame/kit/releases)

## Contributing

Issue reports and suggestions (for the kit or the documentation) are welcomed!

For issue reports:
* Make sure you are using the latest kit version
* Give clear instructions on what the bug is, how to reproduce it, preferably including footage

For kit suggestions:
* At the moment, we are not looking for suggestions regarding new client objects to add to the kit
* Please keep in mind that all additions and changes in the kit must be fully backwards compatible with previous versions of the kit due to possible breaking changes to towers using older kit versions.

For documentation changes:
* Make a pull request that includes your changes, along with an explanation of what changes were made and why

## Documentation Setup

To run the documentation site locally, make sure you have [Rokit](https://github.com/rojo-rbx/rokit), [Lune](https://github.com/lune-org/lune) and [Moonwave](https://github.com/evaera/moonwave) installed.

Clone this repository, download a copy of the kit place to the repository's folder, and rename the file to `place.rbxl`. Extract the scripts from the place by running the command `lune run scripts/extract-scripts`. You can then view the website by running the command `moonwave dev --code mirror`

Credit to Elttob for [Vanilla 3 icons](https://elttob.itch.io/vanilla-3-for-roblox-studio) (curated list of icons are being used under `.moonwave/static/vanilla_icons`)