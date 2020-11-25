# Runeterra Wallpapers Downloader

Are you a [Runeterra](https://universe.leagueoflegends.com) fan? Do you want the amazing art of the Legends of Runeterra cards as your wallpaper? Wait no more, this tool will help you get all those amazing wallpapers with no effort.

![03PZ001-full](03PZ001-full.jpg)

This tool downloads the [official card assets](https://developer.riotgames.com/docs/lor#data-dragon) from Legends of Runeterra and copies the card full screen art into the desired location.  I built this to help me keep up to date the wallpapers every time a new set is released. Doing it manually takes too much time since the assets come organised in folders that have together the card images and the full screen art, also those folders contain images for the spells which don't have big images that can be used as wallpapers.

# Supported Sets

As of 25/11/2020 this tool supports:

- Set 1: Foundations
- Set 2: Rising Tides
- Set 3: Call of the Mountain

# How to use

1. Download the latest version from the [Releases](https://github.com/alexito4/RuneterraWallpapersDownloader/releases) page.
2. Run the CLI passing the path to the folder where you want the images to be copied.

```sh
./runeterrawallpaper path/to/folder
```

The tool will start downloading all the data sets, it may take a while. Once the poros finish downloading the assets they will extract the zips and copy the wallpapers on the desired folder.

# Author

Alejandro Martinez | http://alejandromp.com | [@alexito4](https://twitter.com/alexito4)