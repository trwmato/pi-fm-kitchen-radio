#!/bin/bash

BASE=~/radio
MAINT_MUSIC="$BASE/maintenance_music"

play_random_maintenance_track() {
    TRACK=$(find "$MAINT_MUSIC" \
        -type f \( -iname "*.mp3" -o -iname "*.m4a" -o -iname "*.flac" \) \
        | shuf -n 1)

    if [ -z "$TRACK" ]; then
        echo "[maintenance] no maintenance music found"
        sleep 10
        return
    fi

    MAC="$("$BASE/scripts/current_bt_speaker.sh")"

    if [ -z "$MAC" ]; then
        echo "[maintenance] no bluetooth speaker connected; waiting"
        sleep 10
        return
    fi

    echo "[maintenance] playing: $TRACK"
    echo "[maintenance] using bluetooth speaker: $MAC"

    cvlc --intf dummy \
         --no-video \
         --play-and-exit \
         --aout=alsa \
         --alsa-audio-device="bluealsa:DEV=$MAC" \
         "$TRACK"
}

play_music_while_running() {
    CMD="$1"
    LABEL="$2"

    echo "[maintenance] starting $LABEL in background..."
    bash -c "$CMD" &
    JOB_PID=$!

    while ps -p "$JOB_PID" > /dev/null; do
        echo "[maintenance] $LABEL still running"
        play_random_maintenance_track
    done

    wait "$JOB_PID"
    EXIT_CODE=$?

    echo "[maintenance] $LABEL finished with code $EXIT_CODE"
}

play_music_while_running "nice -n 19 /usr/bin/podget" "podget"

play_music_while_running "$BASE/scripts/curl_retry_failed_podget.sh" "curl retry"

echo "[maintenance] renaming downloaded shows"

{
    find "$BASE/dailyshow" -type f 2>/dev/null
    find "$BASE/weeklyshow" -type f 2>/dev/null
} | while IFS= read -r file; do

    dir=$(dirname "$file")

    ext="${file##*.}"
    name="$(basename "$file" ".$ext")"

    # skip already-renamed files
    case "$name" in
        *_????????-??????_*)
            continue
            ;;
    esac

    stamp=$(date +%Y%m%d-%H%M%S)
    rand=$RANDOM

    new="$dir/${name}_${stamp}_${rand}.${ext}"

    echo "[rename] $file -> $new"

    mv -- "$file" "$new"

done

echo "[maintenance] cleaning old news bulletins"

# keep newest RNZ bulletin
ls -t "$BASE/news/RNZ_Bulletin"/* 2>/dev/null | tail -n +2 | xargs -r rm

# keep newest BBC bulletin
ls -t "$BASE/news/BBC_News_5_min"/* 2>/dev/null | tail -n +2 | xargs -r rm

echo "[maintenance] cleanup show phase"
"$BASE/scripts/cleanup_show.sh"

echo "[maintenance] handing off to radio_loop"
exec "$BASE/scripts/radio_loop.sh"

