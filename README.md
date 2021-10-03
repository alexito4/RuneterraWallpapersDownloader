# Runeterra Wallpapers Downloader
![CI](https://github.com/alexito4/RuneterraWallpapersDownloader/workflows/CI/badge.svg)

Are you a [Runeterra](https://universe.leagueoflegends.com) fan? Do you want the amazing art of the [Legends of Runeterra](https://playruneterra.com) cards as your wallpaper? Wait no more, this tool will help you get those **more than 800** amazing wallpapers with no effort.

**Updated for Beyond the Bandlewood!**

![](05BC194-full.jpg)

This tool downloads the [official card assets](https://developer.riotgames.com/docs/lor#data-dragon) from Legends of Runeterra and copies the card full screen art into the desired location.  I built this to help me keep up to date the wallpapers every time a new set is released. Doing it manually takes too much time since the assets come organised in folders that have together the card images and the full screen art, also those folders contain images for the spells which don't have big images that can be used as wallpapers.

# Supported Sets

*updated 03/10/2021*

- Set 1: 
  - [x] Foundations
- Set 2: 
  - [x] Rising Tides
- Set 3
  - [x] Call of the Mountain
  - [x] Monuments of Power
  - [x] Cosmic Creation
  - [x] Aphelios Champion Expansion
- Set 4
  - [x] Empires of the Ascended (March)
  - [x] Guardians of the Ancient (May)
  - [x] Rise of the Underworlds (June)
  - [x] Champion Expansion (July)
- Set 5
  - [x] Beyond the Bandlewood (August)
  - [ ] Magical Misadventures (December)
- Events


[LoR 2021 Roadmap](https://twitter.com/PlayRuneterra/status/1420058901643472899/photo/1)

# How to use

1. Download the latest version from the [Releases](https://github.com/alexito4/RuneterraWallpapersDownloader/releases) page.
2. Run the CLI passing the path to the folder where you want the images to be copied.

```sh
USAGE: runeterraWallpaper <destination> [--set <set> ...] [--skip-download] [--keep-zips]

ARGUMENTS:
  <destination>           Directory to save the wallpapers. 

OPTIONS:
  --set <set>             Specify all the Card Sets you want download. Use the set index. Ex: --set 1 --set 2.
                          (default: 1: Foundations, 2: Rising Tides, 3: Call of the Mountain, 4: Empires of the
                          Ascended)
  --skip-download         If true it reads the destination folder to find the zips instead of downloading them
                          again. 
  --keep-zips             If true downloaded zips won't be removed. Useful if you want to use `skipDownload` later. 
  -h, --help              Show help information.
```

The tool will start downloading all the data sets, it may take a while. Once the poros finish downloading the assets they will extract the zips and copy the wallpapers on the desired folder.

# Library

The main code is exposed as a library module called `RuneterraWallpapersDownloader`.

# Author

Alejandro Martinez | http://alejandromp.com | [@alexito4](https://twitter.com/alexito4)
