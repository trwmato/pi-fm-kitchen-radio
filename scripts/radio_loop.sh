#!/bin/bash

BASE=~/radio
PLAYLIST="$BASE/playlists/loop.m3u"

# Wait for a trusted connected Bluetooth speaker
MAC=""

while [ -z "$MAC" ]; do
  MAC="$("$BASE/scripts/current_bt_speaker.sh")"

  if [ -z "$MAC" ]; then
    echo "[radio] waiting for trusted bluetooth speaker..."
    sleep 10
  fi
done

echo "[radio] using bluetooth speaker: $MAC"

# 1. Build playlist snapshot
"$BASE/scripts/make_playlist.sh"

# 2. Play playlist
cvlc --intf dummy \
     --no-video \
     --play-and-exit \
     --aout=alsa \
     --alsa-audio-device="bluealsa:DEV=$MAC" \
     "$PLAYLIST"

# 3. Capture exit status
VLC_EXIT=$?

echo "[radio] VLC exited with code $VLC_EXIT"

# 4. Hand off to maintenance phase
exec "$BASE/scripts/maintenance.sh"
