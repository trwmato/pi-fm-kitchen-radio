#!/bin/bash

BASE=~/radio
OUT="$BASE/playlists/loop.m3u"

DAILY="$BASE/dailyshow"
WEEKLY="$BASE/weeklyshow"
BACKUP_DAILY="$BASE/backupdaily"
BACKUP_WEEKLY="$BASE/backupweekly"

mkdir -p "$(dirname "$OUT")"
mkdir -p "$BASE/logs"
mkdir -p "$DAILY" "$WEEKLY" "$BACKUP_DAILY" "$BACKUP_WEEKLY"

> "$OUT"

USED_SHOWS=""

pick_one() {
    find "$1" -type f 2>/dev/null | shuf -n 1
}

pick_news() {
    if [ "$((RANDOM % 2))" -eq 0 ]; then
        pick_one "$BASE/news/BBC_News_5_min"
    else
        pick_one "$BASE/news/RNZ_Bulletin"
    fi
}

unused_only() {
    while IFS= read -r file; do
        printf "%s\n" "$USED_SHOWS" | grep -Fxq "$file" && continue
        echo "$file"
    done
}

pick_show() {
    SHOW_FILE=$(
        {
            find "$DAILY" -type f 2>/dev/null
            find "$WEEKLY" -type f 2>/dev/null
        } | unused_only | shuf -n 1
    )

    if [ -z "$SHOW_FILE" ]; then
        SHOW_FILE=$(
            {
                find "$BACKUP_DAILY" -type f -printf '%T@ %p\n' 2>/dev/null
                find "$BACKUP_WEEKLY" -type f -printf '%T@ %p\n' 2>/dev/null
            } | sort -n | cut -d' ' -f2- | unused_only | head -n 1
        )
    fi

    [ -n "$SHOW_FILE" ] && echo "$SHOW_FILE"
}

add_show() {
    SHOW_FILE=$(pick_show)

    if [ -n "$SHOW_FILE" ]; then
        echo "$SHOW_FILE" >> "$OUT"
        USED_SHOWS="${USED_SHOWS}
$SHOW_FILE"
    fi
}

add_block() {
    case "$1" in
        NEWS)   pick_news >> "$OUT" ;;
        JINGLE) pick_one "$BASE/jingles" >> "$OUT" ;;
        MUSIC)  pick_one "$BASE/music" >> "$OUT" ;;
        SHOW)   add_show ;;
        EGG)    pick_one "$BASE/eggs" >> "$OUT" ;;
        *)      echo "[playlist] unknown block: $1" >&2 ;;
    esac
}

CONFIG="$BASE/config/playlist_blocks"

if [ ! -f "$CONFIG" ]; then
    echo "[playlist] missing config file: $CONFIG" >&2
    exit 1
fi

while IFS= read -r BLOCK; do
    BLOCK="${BLOCK%%#*}"
    BLOCK="$(echo "$BLOCK" | xargs)"
    [ -z "$BLOCK" ] && continue

    add_block "$BLOCK"
done < "$CONFIG"

