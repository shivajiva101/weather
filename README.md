# Weather
[![Build status](https://github.com/shivajiva101/weather/workflows/Check%20&%20Release/badge.svg)](https://github.com/shivajiva101/weather/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This mod provides diverse weather for mapgen v5, v7 and a somewhat simpler weather for v6.

The reason v6 maps are handled differently is due to the inability to detect the current biome of a players position, v6 maps report 'default' for every biome.  
Without any granularity the only possible detection is from the nodes around the player. I may add that level of detection, depending on demand.

## Features
This mod includes an API to add weather types and define the biome weather system.  
For further information, check the [full API](/api.md).

## Installation

### Cloning the repository
Clone the repository using Git:  
```
git clone https://github.com/shivajiva101/weather
```

### Manual download

- Unzip the archive, rename the folder to weather and
place it in .. minetest/mods/

- GNU/Linux: If you use a system-wide installation place
    it in ~/.minetest/mods/.

- If you only want this to be used in a single world, place
    the folder in .. worldmods/ in your world directory.

For further information or help, see:  
https://wiki.minetest.net/Installing_Mods

## Dependencies
None.

## Requirements
Works with MT/MTG 5.0.0+.

## License
[MIT](https://github.com/shivajiva101/weather/LICENSE) for everything.

## Issues, features, suggestions & bugfixes
Report bugs or suggest ideas by [creating an issue](https://github.com/shivajiva101/weather/issues/new).   
If you know how to fix an issue, or want something to be added, consider opening a [pull request](https://github.com/shivajiva101/weather/compare).
