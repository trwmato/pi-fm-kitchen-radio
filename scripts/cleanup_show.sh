#!/bin/bash

BASE=~/radio
PLAYLIST="$BASE/playlists/loop.m3u"

DAILY="$BASE/dailyshow"
WEEKLY="$BASE/weeklyshow"
BACKUP_DAILY="$BASE/backupdaily"
BACKUP_WEEKLY="$BASE/backupweekly"

MAX_DAILY_PER_FEED=5
MAX_WEEKLY_PER_FEED=8
MAX_BACKUP_DAILY=25
MAX_BACKUP_WEEKLY=50

mkdir -p "$BACKUP_DAILY" "$BACKUP_WEEKLY"

trim_feeds() {
    ROOT="$1"
    CAP="$2"
    LABEL="$3"

    find "$ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while IFS= read -r FEED_DIR; do
        COUNT=$(find "$FEED_DIR" -type f | wc -l)

        if [ "$COUNT" -gt "$CAP" ]; then
            REMOVE=$((COUNT - CAP))

            echo "[cleanup] trimming $LABEL feed $(basename "$FEED_DIR"): deleting $REMOVE oldest file(s)"

            find "$FEED_DIR" -type f -printf '%T@ %p\n' \
                | sort -n \
                | head -n "$REMOVE" \
                | cut -d' ' -f2- \
                | xargs -r rm --
        fi
    done
}

trim_backup() {
    BACKUP_DIR="$1"
    CAP="$2"
    LABEL="$3"

    COUNT=$(find "$BACKUP_DIR" -type f 2>/dev/null | wc -l)

    if [ "$COUNT" -gt "$CAP" ]; then
        REMOVE=$((COUNT - CAP))

        echo "[cleanup] trimming $LABEL backup to $CAP files"

        find "$BACKUP_DIR" -type f -printf '%T@ %p\n' \
            | sort -n \
            | head -n "$REMOVE" \
            | cut -d' ' -f2- \
            | xargs -r rm --
    fi
}

process_played_file() {
    file="$1"

    case "$file" in
        "$DAILY/"*)
            [ -f "$file" ] || return
            echo "[cleanup] deleting played daily show: $file"
            rm -- "$file"
            ;;

        "$WEEKLY/"*)
            [ -f "$file" ] || return
            echo "[cleanup] moving played weekly show to backupweekly: $file"
            mv -- "$file" "$BACKUP_WEEKLY/"
            ;;

        "$BACKUP_DAILY/"*)
            [ -f "$file" ] || return
            echo "[cleanup] rotating played backupdaily show: $file"
            touch -- "$file"
            ;;

        "$BACKUP_WEEKLY/"*)
            [ -f "$file" ] || return
            echo "[cleanup] rotating played backupweekly show: $file"
            touch -- "$file"
            ;;
    esac
}

while IFS= read -r file; do
    process_played_file "$file"
done < "$PLAYLIST"

trim_feeds "$DAILY" "$MAX_DAILY_PER_FEED" "daily"
trim_feeds "$WEEKLY" "$MAX_WEEKLY_PER_FEED" "weekly"

trim_backup "$BACKUP_DAILY" "$MAX_BACKUP_DAILY" "daily"
trim_backup "$BACKUP_WEEKLY" "$MAX_BACKUP_WEEKLY" "weekly"

