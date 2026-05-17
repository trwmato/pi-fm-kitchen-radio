# Pi FM Kitchen Radio Station

Raspberry Pi Zero project that creates a self-updating 24/7 FM radio station for passive listening.

Built as part of an attempt at digital minimalism / reducing screen time / having overseas content on the radio dial

It pulls podcasts and news from RSS feeds, mixes them with local music/jingles, and beams out via bluetooth.

My setup involves a 12v bluetooth-FM transmitter that is received by the radio in my kitchen. Bluetooth speaker is fine too.

## Features

- RSS podcast + news ingestion via `podget`
- Retry handling for failed downloads via curl. This has been useful for some BBC feeds.
- Automatically regenerated playlists
- Mix of music / podcasts / news / jingles / oddities
- Prioritises fresh content while spacing out repeats
- Different retention rules for news / daily / weekly content
- Maintenance mode for downloads + cleanup
- Automatic boot startup via `systemd`
- Bluetooth output
- Samba access for easy content management

## Hardware used

- Raspberry Pi Zero W
- Cheap Bluetooth FM transmitter
- Any FM radio

## Signal path

RSS feeds 
 podget 
 bash scripts 
 CVLC 
 Bluetooth 
 FM transmitter 
 radio 

## Project structure

```text
pi-fm-radio-station/
├── scripts/
│   ├── radio_loop.sh
│   ├── maintenance.sh
│   ├── make_playlist.sh
│   ├── cleanup_show.sh
│   ├── current_bt_speaker.sh
│   └── curl_retry_failed_podget.sh
├── config/
│   ├── serverlist
│   └── playlist_blocks
└── systemd/
    └── radio.service
```

## Runtime folder structure

The scripts expect a `~/radio` runtime directory on the Pi.

Typical structure:

```text
~/radio/
├── dailyshow/           # frequently refreshed podcasts
├── weeklyshow/          # slower-refresh podcasts
├── backupdaily/         # fallback daily content
├── backupweekly/        # fallback weekly content
├── news/                # downloaded news bulletins
├── music/               # your music library
├── maintenance_music/   # music played during maintenance tasks
├── jingles/             # station IDs / transitions
├── eggs/                # optional oddities / bonus content
├── playlists/           # generated playlists
├── logs/                # runtime logs
├── config/              # feed + playlist config
└── scripts/             # runtime scripts
```

Example jingles and an egg are included in `/assets` if you want something to test with. 

## Dependencies

Install on Raspberry Pi OS:

```bash
sudo apt update
sudo apt install podget vlc bluealsa alsa-utils curl samba
```

## Setup

Create folders:

```bash
mkdir -p ~/radio/{dailyshow,weeklyshow,backupdaily,backupweekly,news,music,maintenance_music,jingles,eggs,playlists,logs,config,scripts}

Copy files:

```bash
cp scripts/* ~/radio/scripts/
cp config/* ~/radio/config/
```

Setup Bluetooth ALSA, use bluetoothctl to trust your chosen transmitter or speaker(s)

Install systemd service:

```bash
sudo cp systemd/radio.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable radio.service
sudo systemctl start radio.service
```

## Customisation

`config/serverlist` is for RSS feed URL's- you'll need to set podget to use this as its serverlist. I've left a couple of feeds in the config as examples.

`config/playlist_blocks` can be used to change the playlist structure

`scripts/cleanup_show.sh` has some values for max. episodes in a feed, max episodes in reserve 

## Issues

Getting Bluetooth to work is very annoying- I'd consider removing all the bluetooth functionality and outputting to a USB DAC 

BBC feeds can be hit or miss- Curl usually works where podget fails. 

Curl 'should' figure out what feeds it's retrying- but will default to an 'unknown' folder if it can't do so. 

Some RSS feeds use standard filenames like `media.mp3`- the files get renamed to counter this, but lead to occasional duplication (not enough to be annoying in my experience) 

Yes it's all using Bash, I don't know any better.

## Potential Upgrades

I'll probably get it to work over USB audio at some point 

Adding more categories (current affairs, sport, comedy, etc) 

Jingles for specific shows (eg news-only jingle) 

Playlist behaviour dependent on what day/time- it could just play music midnight-6am, I also like the idea of household jingles like 'remember to put the bins out today' 

Making config simpler/easier

## Have fun

Chuck me a Reddit DM if you end up using this! 
